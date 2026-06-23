// Hard-no enforcement: a TRUE hard filter so the AI never returns a stop that
// conflicts with a user's stated dealbreakers. The prompt asks the model to avoid
// them; this is the belt-and-suspenders post-filter that removes any that slip through.

/** Keyword expansions for the known structured hard-no values (iOS QuestionnaireOptions.hardNos + web). */
const HARD_NO_KEYWORDS: Record<string, string[]> = {
  "loud-venues": ["loud", "noisy", "nightclub", "night club", "rave", "blasting", "high-volume"],
  "loud": ["loud", "noisy", "nightclub", "night club", "rave"],
  "crowds": ["crowded", "packed crowd", "huge crowd", "massive crowd", "standing-room"],
  "crowded": ["crowded", "packed crowd"],
  "heights": ["rooftop", "observation deck", "sky deck", "skydeck", "ferris wheel", "zip line", "zipline", "aerial", "rock climbing", "cliff", "high ropes", "sky bridge"],
  "water": ["water park", "kayak", "canoe", "scuba", "snorkel", "rafting", "jet ski", "jetski", "paddleboard", "paddle board", "swimming", "swim ", "boat cruise", "river cruise"],
  "spicy-food": ["spicy", "hot sauce", "szechuan", "sichuan", "ghost pepper", "extra hot", "fiery", "habanero"],
  "spicy": ["spicy", "hot sauce", "szechuan", "sichuan", "ghost pepper"],
  "physical": ["hike", "hiking", "workout", "boot camp", "spin class", "rock climbing", "obstacle course", "trampoline", "bike ride", "cycling tour"],
  "physical-activity": ["hike", "hiking", "workout", "boot camp", "spin class", "rock climbing"],
  "late-night": ["after midnight", "midnight", "1 am", "2 am", "1am", "2am", "all night", "late-night"],
};

/** Returns the lowercased keyword list to scan for a single hard-no value. */
function keywordsForHardNo(raw: string): string[] {
  const key = raw.trim().toLowerCase();
  if (!key) return [];
  const mapped = HARD_NO_KEYWORDS[key];
  if (mapped && mapped.length > 0) return mapped;
  // Free-text hard-no (user typed): match the literal phrase and its first significant word.
  const words = key.split(/[\s,/]+/).filter((w) => w.length >= 3);
  return Array.from(new Set([key, ...words]));
}

/** True if the stop's text references any of the given hard-nos. */
export function stopViolatesHardNos(stop: any, hardNos: string[]): boolean {
  if (!Array.isArray(hardNos) || hardNos.length === 0) return false;
  const haystack = [
    stop?.name,
    stop?.venueType,
    stop?.description,
    stop?.whyItFits,
    stop?.romanticTip,
  ]
    .filter((s) => typeof s === "string")
    .join(" ")
    .toLowerCase();
  if (!haystack) return false;
  for (const hardNo of hardNos) {
    for (const kw of keywordsForHardNo(hardNo)) {
      if (kw && haystack.includes(kw)) return true;
    }
  }
  return false;
}

/** Removes every stop that violates a hard-no, in place, and returns count removed. */
export function filterHardNoStops(plan: any, hardNos: string[]): number {
  if (!Array.isArray(plan?.stops) || plan.stops.length === 0) return 0;
  const before = plan.stops.length;
  plan.stops = plan.stops.filter((stop: any) => !stopViolatesHardNos(stop, hardNos));
  return before - plan.stops.length;
}
