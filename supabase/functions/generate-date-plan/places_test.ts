import { assert, assertEquals } from "jsr:@std/assert@1";
import { copyMatchesPlaceTypes, namesLikelyMatch, placeTypesMatchVenue, validateAllStops } from "./places.ts";

Deno.test("names: an invented venue does not match a different real business", () => {
  assert(!namesLikelyMatch("Rooftop Cinema Club", "Rooftop Bar & Lounge"));
  assert(!namesLikelyMatch("Starlight Movie Garden", "Starlight Diner"));
  assert(!namesLikelyMatch("The Coffee Collective", "Collective Brewing Co"));
});

Deno.test("names: real venues still match Google's longer or shorter listing", () => {
  assert(namesLikelyMatch("Blue Bottle Coffee", "Blue Bottle Coffee - Williamsburg"));
  assert(namesLikelyMatch("Carbone NYC", "Carbone"));
  assert(namesLikelyMatch("Death & Co", "Death & Co New York"));
  assert(namesLikelyMatch("Joe's Pizza", "Joe's Pizza Broadway"));
  assert(namesLikelyMatch("Brooklyn Bowl", "Brooklyn Bowl Williamsburg"));
});

// Reported case 2: "tells me to go to a movie screening but the place doesn't do screenings".
Deno.test("reported: a movie screening is rejected at a venue that is not a cinema", () => {
  assert(!placeTypesMatchVenue(["bar", "restaurant", "food", "point_of_interest", "establishment"], "Movie screening"));
  assert(!placeTypesMatchVenue(["park", "point_of_interest", "establishment"], "Outdoor film night"));
  assert(placeTypesMatchVenue(["movie_theater", "point_of_interest", "establishment"], "Movie screening"));
});

Deno.test("reported: screening copy on a bar stop is rejected even when venueType says bar", () => {
  const stop = {
    name: "Rooftop Bar & Lounge",
    venueType: "Rooftop bar",
    description: "Catch an outdoor movie screening under the stars.",
  };
  assert(!copyMatchesPlaceTypes(stop, ["bar", "point_of_interest", "establishment"]));
  assert(copyMatchesPlaceTypes({ ...stop, description: "Cocktails with a skyline view." }, ["bar"]));
});

Deno.test("types: a generic point of interest no longer passes for a specific venue type", () => {
  assert(!placeTypesMatchVenue(["tourist_attraction", "point_of_interest", "establishment"], "Theater"));
  assert(placeTypesMatchVenue(["performing_arts_theater", "establishment"], "Theater"));
});

Deno.test("types: common date venues still match", () => {
  assert(placeTypesMatchVenue(["cafe", "food", "establishment"], "Coffee shop"));
  assert(placeTypesMatchVenue(["restaurant", "food"], "Italian Restaurant"));
  assert(placeTypesMatchVenue(["bar", "establishment"], "Speakeasy cocktail bar"));
  assert(placeTypesMatchVenue(["bowling_alley", "establishment"], "Bowling"));
  assert(placeTypesMatchVenue(["park", "point_of_interest"], "Sunset stroll"));
});

Deno.test("types: an unrecognized venue type needs a date-friendly Google type", () => {
  assert(!placeTypesMatchVenue(["point_of_interest", "establishment"], "Sunset stroll"));
});

function stubFetch(handler: (url: string) => unknown) {
  const calls: string[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = ((input: string | URL | Request) => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
    calls.push(url);
    return Promise.resolve(new Response(JSON.stringify(handler(url)), { status: 200 }));
  }) as typeof fetch;
  return { calls, restore: () => (globalThis.fetch = original) };
}

const geocodeOk = {
  status: "OK",
  results: [{ formatted_address: "Brooklyn, NY, USA", geometry: { location: { lat: 40.678, lng: -73.944 } } }],
};

Deno.test("reported: an unfound venue is dropped, not swapped for a random business of the same type", async () => {
  const stub = stubFetch((url) => (url.includes("geocode") ? geocodeOk : { status: "ZERO_RESULTS", candidates: [], results: [] }));
  try {
    const stops = await validateAllStops(
      [{ order: 1, name: "Starlight Movie Garden", venueType: "Movie screening", timeSlot: "8:00 PM", duration: "2 hours", description: "", whyItFits: "", romanticTip: "", emoji: "" }],
      "Brooklyn, NY",
      "test-key",
    );
    assertEquals(stops.length, 0);
    assert(!stub.calls.some((u) => u.includes("/textsearch/")), "fallback text search must not run");
  } finally {
    stub.restore();
  }
});

Deno.test("validated stops carry Google's machine-readable opening periods", async () => {
  const periods = [{ open: { day: 5, time: "0700" }, close: { day: 5, time: "1900" } }];
  const stub = stubFetch((url) => {
    if (url.includes("geocode")) return geocodeOk;
    if (url.includes("findplacefromtext")) {
      return {
        status: "OK",
        candidates: [{
          place_id: "abc",
          name: "Devoción",
          formatted_address: "69 Grand St, Brooklyn, NY 11249, USA",
          business_status: "OPERATIONAL",
          types: ["cafe", "food", "establishment"],
          geometry: { location: { lat: 40.716, lng: -73.965 } },
        }],
      };
    }
    return {
      status: "OK",
      result: {
        name: "Devoción",
        business_status: "OPERATIONAL",
        types: ["cafe", "food", "establishment"],
        formatted_address: "69 Grand St, Brooklyn, NY 11249, USA",
        geometry: { location: { lat: 40.716, lng: -73.965 } },
        opening_hours: { periods, weekday_text: ["Friday: 7:00 AM – 7:00 PM"] },
      },
    };
  });
  try {
    const stops = await validateAllStops(
      [{ order: 1, name: "Devoción", venueType: "Coffee shop", timeSlot: "3:00 PM", duration: "45 mins", description: "", whyItFits: "", romanticTip: "", emoji: "" }],
      "Brooklyn, NY",
      "test-key",
    );
    assertEquals(stops.length, 1);
    assertEquals(stops[0].openingPeriods, periods);
  } finally {
    stub.restore();
  }
});
