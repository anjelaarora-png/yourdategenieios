# Why date plans recommend closed, booked or wrong venues — and how to prevent it

**Date:** 2026-10-26 · **Scope:** `supabase/functions/generate-date-plan/` · **Status:** diagnosis + proposal (no code changed)

## Reported symptoms
1. Dinner at a restaurant with no reservations available.
2. A "movie screening" at a venue that doesn't screen movies.
3. A coffee shop scheduled at 9 PM that closes at 7 PM.

## How a plan is built today
1. `prompt.ts` asks the model (`gpt-4o-mini`, falling back to `gpt-4o`; no live data access) to **invent the whole itinerary from memory**: venue names, activities, time slots, descriptions and booking URLs.
2. `places.ts → validateAllStops` then checks each stop against Google Places. It answers "does a real, open-for-business place with a similar name exist in this city?", and nothing more.
3. Unverified stops are dropped; a plan needs 2 verified stops to be returned.

The model decides *what* and *when*; Google is only consulted afterwards to confirm *that it exists*. Every symptom comes from that ordering.

## Root causes (confirmed in code)

### RC1 — Opening hours are fetched but never compared to the schedule → coffee at 9 PM
- `validateVenue` requests `opening_hours` and keeps only `weekday_text` (display strings), which are attached to the stop for the UI (`places.ts:511`, `:651`, `:823`).
- No code anywhere compares a stop's `timeSlot` to those hours. `opening_hours.periods` (machine-readable) and `utc_offset` are never read.
- The only safeguard is a prompt line: "Make sure all venues will be OPEN at the specified times" (`prompt.ts:540`). The model has no hours data, so it guesses.

### RC2 — Fallback swaps the venue but keeps the AI's story → "movie screening" at a bar
- If the AI's named venue isn't found, `validateVenueWithRetry` falls back to `searchVenueByType("<venueType> in <city>")` and takes the **first** operational result (`places.ts:729-737`, `:592-601`).
- `validateAllStops` then merges that new place into the original stop. It replaces name, address and hours, but **keeps the AI's `description`, `whyItFits`, `romanticTip` and `timeSlot`** (`places.ts:813-826`), which were written about a different venue.

### RC3 — Name and type matching are too permissive
Verified by running the exact functions from `places.ts`:

| Check | Input | Result |
|---|---|---|
| `namesLikelyMatch` | "Rooftop Cinema Club" vs Google "Rooftop Bar & Lounge" | **true** |
| `namesLikelyMatch` | "Starlight Movie Garden" vs "Starlight Diner" | **true** |
| `placeTypesMatchVenue` | venueType "Movie screening" vs a bar/restaurant | **true** (no keyword → no check) |
| `placeTypesMatchVenue` | venueType "Outdoor film night" vs a park | **true** |
| `placeTypesMatchVenue` | venueType "Theater" vs any `tourist_attraction` | **true** |

- Name match needs only ~1/3 token overlap after dropping words like "bar/cafe/restaurant" (`places.ts:131-149`).
- Any venueType not in `VENUE_TYPE_KEYWORDS` skips type checking entirely (`places.ts:106-107`), and generic `point_of_interest` passes for any type (`:113-115`).
- Time-bound **events** (screenings, live music, trivia) can't be verified by Places at all, yet the model is free to invent them.

### RC4 — Reservations are never checked; booking links are written by the model → "no availability"
- Nothing in the pipeline checks reservation availability.
- The prompt asks the model to produce OpenTable/Resy URLs from memory (`prompt.ts:510`); `detectReservationPlatforms` only pattern-matches URLs (`places.ts:180`). Neither confirms the restaurant takes bookings, nor that the slot is free.
- The app's "Reserve" action implies availability that was never established.

### Contributing factors
- When stops are dropped, the remaining stops keep their original AI time slots (gaps/overlaps are not re-timed).
- `gpt-4o-mini` is tried first; it's the model most likely to invent plausible-sounding venues.

## Prevention plan

### 1. Ground the plan in real data before the model writes it (fixes RC1–RC3 at the source)
Flip the pipeline from *generate → verify* to *retrieve → choose → verify*:
1. Server queries Google Places (Nearby/Text Search) for candidates matching each stop's role (dinner, drinks, coffee, activity) within the user's radius.
2. Filter candidates in code: open for the full slot on the scheduled date (see §2), right types, rating/price fit, not closed.
3. Send the model a short list per stop (place_id, name, types, hours, price, editorial summary). The tool schema constrains `placeId` to that list (enum), so the model **can only choose real, open places** and writes copy about the place it chose.
4. Keep the existing Google validation as a final check.

### 2. Enforce opening hours deterministically (RC1)
- Request `opening_hours.periods`, `current_opening_hours` (holiday-aware) and `utc_offset` in Place Details.
- For each stop: compute start/end in the venue's local time on the scheduled date; require *open at start* and *closes ≥ 30 min after the stop ends* (handle overnight periods).
- No date given → default to the next Friday 7 PM and say so, or ask in the planner.
- Hours unknown → drop the stop for evening slots, or label "Hours not listed" (never silently pass).

### 3. Remove silent substitution and tighten matching (RC2, RC3)
- Delete the type-search fallback, or, if a stop is substituted, **regenerate its description from the new place's real data**. Never keep copy written for another venue.
- Name match: require Google's top candidate plus high similarity (e.g., ≥0.8 normalized), or match on `place_id` once grounding (§1) is in place.
- Type check: unknown venueType = **reject**, not allow. Map activities to required Google types (`movie_theater` for screenings; `cafe` for coffee) and drop generic-POI passes.
- **Events only from an events source.** Screenings, concerts and trivia come from Eventbrite (an import function already exists), Ticketmaster or SeatGeek, with date and time; otherwise the prompt forbids them.

### 4. Make reservations honest (RC4)
Live availability for OpenTable/Resy/Tock requires partner API access; there is no open public API. Until then:
- Don't claim availability. Rename "Reserve" to "Check availability" and open the booking page **prefilled** with date, time and party size (OpenTable supports `covers` and `dateTime` URL params).
- Use Google's `reservable` field to know whether a place takes reservations at all; use only booking URLs found on the venue's own Google-listed website, never model-written URLs.
- Give every dinner stop **1–2 pre-verified backup restaurants** (same area, open, similar price), so "fully booked" becomes a one-tap swap.
- Longer term: OpenTable Partner API or Resy/SevenRooms partnerships for real availability.

### 5. Add a plan "linter" and re-timing step (all RCs)
After selection, run deterministic checks on every stop:
- open for the slot · type matches the activity words in the copy · travel time fits between slots · chronological order · no hard-no violations.
- Failing stops are repaired (next candidate) or dropped; then **re-time** the itinerary from durations plus Directions.

### 6. Measure it (so it stays fixed)
- An eval set of ~50 city × date × vibe inputs, run in CI or nightly against the function, scoring: % stops open for slot, % type/activity mismatches, % substitutions, % plans returned.
- In-app "Something's wrong with this stop" button (closed / booked / not as described) that logs placeId + reason, to feed the eval set.

## Suggested order of work
| Step | Fixes | Effort |
|---|---|---|
| Hours check from `periods` + re-timing | coffee at 9 PM | S–M |
| Remove fallback substitution; strict type map; ban unverified events | movie screening | S |
| Honest reservation UX + backup restaurants | no availability | M |
| Retrieval-first grounding (candidate lists, placeId enum) | all, at the source | L |
| Eval harness + report button | regression prevention | M |

All changes would go on a separate branch for the owner's review; nothing is pushed without approval.
