// Deterministic schedule checks: venues must be open for the whole stop, and stop
// times are recomputed after any stop is removed. The model's time slots are only
// a starting hint; Google's opening periods are the source of truth.

/** Google Places `opening_hours.periods` entry. day 0 = Sunday; time "HHMM" in venue-local time. */
export interface OpeningPeriod {
  open: { day: number; time: string };
  close?: { day: number; time: string };
}

const MINUTES_PER_DAY = 24 * 60;
const MINUTES_PER_WEEK = 7 * MINUTES_PER_DAY;

/** A venue must stay open at least this long after a stop ends. */
const CLOSING_BUFFER_MINUTES = 30;
/** Gap between stops when the model gave no travel time. */
const DEFAULT_GAP_MINUTES = 15;
const DEFAULT_STOP_MINUTES = 60;
const DEFAULT_START_MINUTES = 18 * 60;
/** Without a scheduled date, a venue must be open for the slot on at least this many days. */
const MIN_OPEN_DAYS_WHEN_UNDATED = 4;

/** "7:00 PM", "9 pm", "19:30", "7:00 PM - 8:30 PM" → minutes after midnight (first time only). */
export function parseClock(text: string): number | null {
  const match = (text || "").trim().match(/(\d{1,2})(?::(\d{2}))?\s*([ap])?\.?\s*m?\.?/i);
  if (!match) return null;
  let hour = parseInt(match[1], 10);
  const minute = match[2] ? parseInt(match[2], 10) : 0;
  const meridiem = match[3]?.toLowerCase();
  if (!meridiem && !match[2]) return null;
  if (hour > 23 || minute > 59) return null;
  if (meridiem) {
    if (hour < 1 || hour > 12) return null;
    hour = hour % 12 + (meridiem === "p" ? 12 : 0);
  }
  return hour * 60 + minute;
}

/** "1.5 hours", "90 mins", "1 hour 30 minutes", "2-3 hours" (midpoint) → minutes. */
export function parseDurationMinutes(text: string): number | null {
  const lower = (text || "").toLowerCase();
  const range = lower.match(/(\d+(?:\.\d+)?)\s*[-–]\s*(\d+(?:\.\d+)?)\s*(h|hour|hr|m|min)/);
  if (range) {
    const mid = (parseFloat(range[1]) + parseFloat(range[2])) / 2;
    return Math.round(range[3].startsWith("h") ? mid * 60 : mid);
  }
  let total = 0;
  let found = false;
  for (const m of lower.matchAll(/(\d+(?:\.\d+)?)\s*(hours?|hrs?|h\b|minutes?|mins?|m\b)/g)) {
    const value = parseFloat(m[1]);
    total += m[2].startsWith("h") ? value * 60 : value;
    found = true;
  }
  return found ? Math.round(total) : null;
}

/** "7:40 PM" style, matching what the iOS app parses ("h:mm a"). */
export function formatClock(minutes: number): string {
  const m = ((minutes % MINUTES_PER_DAY) + MINUTES_PER_DAY) % MINUTES_PER_DAY;
  const hour24 = Math.floor(m / 60);
  const hour12 = hour24 % 12 || 12;
  return `${hour12}:${String(m % 60).padStart(2, "0")} ${hour24 >= 12 ? "PM" : "AM"}`;
}

function toWeekMinutes(point: { day: number; time: string }): number {
  const hhmm = parseInt(point.time, 10);
  return point.day * MINUTES_PER_DAY + Math.floor(hhmm / 100) * 60 + (hhmm % 100);
}

/**
 * True when [startMin, endMin) on `day` (0 = Sunday) falls entirely inside one opening
 * period. endMin may exceed 24h for stops that run past midnight.
 */
export function isOpenDuring(periods: OpeningPeriod[], day: number, startMin: number, endMin: number): boolean {
  if (periods.length === 1 && !periods[0].close) return true; // Google's encoding for 24/7

  const start = day * MINUTES_PER_DAY + startMin;
  const end = day * MINUTES_PER_DAY + endMin;
  for (const period of periods) {
    if (!period.close) continue;
    const open = toWeekMinutes(period.open);
    let close = toWeekMinutes(period.close);
    if (close <= open) close += MINUTES_PER_WEEK; // wraps past Saturday night
    // Check the stop against this period in this week and the adjacent weeks.
    for (const shift of [-MINUTES_PER_WEEK, 0, MINUTES_PER_WEEK]) {
      if (start >= open + shift && end <= close + shift) return true;
    }
  }
  return false;
}

function weekdayOf(isoDate: string): number | null {
  const match = isoDate?.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!match) return null;
  return new Date(Date.UTC(+match[1], +match[2] - 1, +match[3])).getUTCDay();
}

function isOpenForSlot(periods: OpeningPeriod[], weekday: number | null, startMin: number, endMin: number): boolean {
  const required = endMin + CLOSING_BUFFER_MINUTES;
  if (weekday !== null) return isOpenDuring(periods, weekday, startMin, required);
  let openDays = 0;
  for (let day = 0; day < 7; day++) {
    if (isOpenDuring(periods, day, startMin, required)) openDays++;
  }
  return openDays >= MIN_OPEN_DAYS_WHEN_UNDATED;
}

function formatTotalDuration(minutes: number): string {
  const hours = Math.round((minutes / 60) * 10) / 10;
  return `${hours} ${hours === 1 ? "hour" : "hours"}`;
}

export interface ScheduleResult {
  dropped: { name: string; reason: "closed_during_slot" }[];
}

/**
 * Re-times a plan's stops back-to-back from the scheduled start and removes any stop
 * whose venue is closed for its slot (plus a closing buffer). Mutates `plan` in place:
 * stops get new `timeSlot`, `order` and `hoursVerified`; `totalDuration` is recomputed.
 */
/** The stop fields scheduling reads; other fields are carried through untouched. */
export interface TimedStop {
  name: string;
  timeSlot?: string;
  duration?: string;
  travelTimeFromPrevious?: string;
  openingPeriods?: OpeningPeriod[];
  order?: number;
  hoursVerified?: boolean;
}

export function applySchedule<T extends TimedStop>(
  plan: { stops: T[]; totalDuration?: string },
  prefs: { dateScheduled?: string; startTime?: string },
): ScheduleResult {
  const weekday = prefs.dateScheduled ? weekdayOf(prefs.dateScheduled) : null;
  const stops = Array.isArray(plan.stops) ? plan.stops : [];
  const dropped: ScheduleResult["dropped"] = [];
  const kept: T[] = [];

  const firstStart: number = (prefs.startTime ? parseClock(prefs.startTime) : null) ??
    stops.map((s) => parseClock(s?.timeSlot ?? "")).find((m) => m !== null) ??
    DEFAULT_START_MINUTES;
  let previousEnd: number | null = null;

  for (const stop of stops) {
    const gap = parseDurationMinutes(stop.travelTimeFromPrevious ?? "") ?? DEFAULT_GAP_MINUTES;
    const start: number = previousEnd === null ? firstStart : previousEnd + gap;
    const end: number = start + (parseDurationMinutes(stop.duration ?? "") ?? DEFAULT_STOP_MINUTES);
    const periods = stop.openingPeriods?.length ? stop.openingPeriods : undefined;

    if (periods && !isOpenForSlot(periods, weekday, start, end)) {
      dropped.push({ name: stop.name, reason: "closed_during_slot" });
      continue;
    }

    kept.push({ ...stop, timeSlot: formatClock(start), hoursVerified: Boolean(periods) });
    previousEnd = end;
  }

  plan.stops = kept.map((stop, index) => ({ ...stop, order: index + 1 }));
  if (kept.length > 0 && previousEnd !== null) {
    plan.totalDuration = formatTotalDuration(previousEnd - firstStart);
  }
  return { dropped };
}
