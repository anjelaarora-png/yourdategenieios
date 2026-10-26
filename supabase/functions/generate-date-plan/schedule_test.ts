import { assert, assertEquals } from "jsr:@std/assert@1";
import { applySchedule, isOpenDuring, parseClock, parseDurationMinutes, type TimedStop } from "./schedule.ts";

// Google Places `opening_hours.periods`: day 0 = Sunday, time = "HHMM" local to the venue.
const coffeeShopPeriods = [1, 2, 3, 4, 5, 6].map((day) => ({
  open: { day, time: "0700" },
  close: { day, time: "1900" },
}));

const lateBarPeriods = [0, 1, 2, 3, 4, 5, 6].map((day) => ({
  open: { day, time: "1700" },
  close: { day: (day + 1) % 7, time: "0200" },
}));

const restaurantPeriods = [2, 3, 4, 5, 6].map((day) => ({
  open: { day, time: "1700" },
  close: { day, time: "2200" },
}));

function stop(overrides: Partial<TimedStop> & { venueType?: string }) {
  return {
    order: 0,
    name: "Venue",
    venueType: "Restaurant",
    timeSlot: "7:00 PM",
    duration: "1 hour",
    description: "",
    validated: true,
    placeId: "pid",
    ...overrides,
  };
}

// Friday 2026-10-30
const FRIDAY = "2026-10-30";

Deno.test("parseClock reads AI and iOS time formats", () => {
  assertEquals(parseClock("7:00 PM"), 19 * 60);
  assertEquals(parseClock("9 pm"), 21 * 60);
  assertEquals(parseClock("19:30"), 19 * 60 + 30);
  assertEquals(parseClock("12:15 AM"), 15);
  assertEquals(parseClock("7:00 PM - 8:30 PM"), 19 * 60);
  assertEquals(parseClock("whenever"), null);
});

Deno.test("parseDurationMinutes reads common duration phrasing", () => {
  assertEquals(parseDurationMinutes("1.5 hours"), 90);
  assertEquals(parseDurationMinutes("90 mins"), 90);
  assertEquals(parseDurationMinutes("1 hour 30 minutes"), 90);
  assertEquals(parseDurationMinutes("45 min"), 45);
  assertEquals(parseDurationMinutes("2-3 hours"), 150);
  assertEquals(parseDurationMinutes(""), null);
});

Deno.test("isOpenDuring handles overnight closing times", () => {
  // Friday 11:00 PM – 12:30 AM at a bar open until 2 AM.
  assert(isOpenDuring(lateBarPeriods, 5, 23 * 60, 24 * 60 + 30));
  // Coffee shop open 7 AM – 7 PM is not open 9–10 PM.
  assert(!isOpenDuring(coffeeShopPeriods, 5, 21 * 60, 22 * 60));
});

Deno.test("isOpenDuring treats a single open-without-close period as 24/7", () => {
  assert(isOpenDuring([{ open: { day: 0, time: "0000" } }], 3, 2 * 60, 4 * 60));
});

// Reported case 1: "go to a coffee shop at 9 that closes at 7".
Deno.test("reported: coffee shop scheduled after it closes is removed from the plan", () => {
  const plan = {
    stops: [
      stop({ name: "Dinner Spot", timeSlot: "7:00 PM", duration: "1.5 hours", openingPeriods: restaurantPeriods }),
      stop({ name: "Evening Coffee", venueType: "Coffee shop", timeSlot: "9:00 PM", duration: "45 mins", openingPeriods: coffeeShopPeriods }),
    ],
  };
  const result = applySchedule(plan, { dateScheduled: FRIDAY, startTime: "19:00" });
  assertEquals(plan.stops.map((s) => s.name), ["Dinner Spot"]);
  assertEquals(result.dropped.map((d) => d.name), ["Evening Coffee"]);
  assertEquals(result.dropped[0].reason, "closed_during_slot");
});

// Reported case 3 (the part these fixes can cover): a dinner booked into closing time.
Deno.test("reported: dinner that would run into the restaurant's closing time is removed", () => {
  const plan = {
    stops: [
      stop({ name: "Late Dinner", timeSlot: "9:00 PM", duration: "1 hour", openingPeriods: restaurantPeriods }),
    ],
  };
  // Ends 10:00 PM; restaurant closes 10:00 PM, so there is no 30-minute margin.
  const result = applySchedule(plan, { dateScheduled: FRIDAY, startTime: "21:00" });
  assertEquals(plan.stops.length, 0);
  assertEquals(result.dropped[0].reason, "closed_during_slot");
});

Deno.test("re-times remaining stops back-to-back after a stop is dropped", () => {
  const plan = {
    totalDuration: "4 hours",
    stops: [
      stop({ name: "Dinner", timeSlot: "6:00 PM", duration: "1.5 hours", openingPeriods: restaurantPeriods }),
      stop({ name: "Closed Coffee", timeSlot: "7:45 PM", duration: "45 mins", openingPeriods: coffeeShopPeriods }),
      stop({ name: "Night Bar", timeSlot: "8:45 PM", duration: "1 hour", openingPeriods: lateBarPeriods, travelTimeFromPrevious: "10 mins by walking" }),
    ],
  };
  applySchedule(plan, { dateScheduled: FRIDAY, startTime: "18:00" });
  assertEquals(plan.stops.map((s) => [s.name, s.timeSlot, s.order]), [
    ["Dinner", "6:00 PM", 1],
    ["Night Bar", "7:40 PM", 2],
  ]);
  assertEquals(plan.totalDuration, "2.7 hours");
});

Deno.test("stops without published hours are kept but flagged as unverified", () => {
  const plan = { stops: [stop({ name: "City Park", venueType: "Park" })] };
  applySchedule(plan, { dateScheduled: FRIDAY, startTime: "19:00" });
  assertEquals(plan.stops.length, 1);
  assertEquals(plan.stops[0].hoursVerified, false);
});

Deno.test("without a scheduled date, a venue must be open for the slot on most days", () => {
  const plan = {
    stops: [
      stop({ name: "Weekday Coffee", timeSlot: "9:00 PM", duration: "45 mins", openingPeriods: coffeeShopPeriods }),
      stop({ name: "Night Bar", timeSlot: "10:00 PM", duration: "1 hour", openingPeriods: lateBarPeriods }),
    ],
  };
  applySchedule(plan, {});
  assertEquals(plan.stops.map((s) => s.name), ["Night Bar"]);
  assertEquals(plan.stops[0].hoursVerified, true);
});
