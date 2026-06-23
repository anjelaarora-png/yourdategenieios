/** Post-validation plan copy: creative titles that still hint at the itinerary. */

interface StopLike {
  name?: string;
  venueType?: string;
  validated?: boolean;
}

function stopShortLabel(stop: StopLike): string {
  const type = (stop.venueType || "").toLowerCase();
  if (/restaurant|dining|dinner|trattoria|bistro|eatery|brunch|lunch/.test(type)) {
    return "Dinner";
  }
  if (/bar|cocktail|wine|brewery|pub/.test(type)) return "Drinks";
  if (/cafe|coffee|dessert|bakery|gelato|ice cream/.test(type)) return "Sweet stop";
  if (/park|garden|trail|nature/.test(type)) return "Park stroll";
  if (/museum|gallery|art|exhibit/.test(type)) {
    return /gallery/.test(type) ? "Gallery" : "Museum";
  }
  if (/rooftop|view|observation|skyline/.test(type)) return "Skyline views";
  if (/music|jazz|live|concert|theater|theatre|show/.test(type)) return "Live vibes";
  if (/market|shop|boutique/.test(type)) return "Browse & shop";

  const name = (stop.name || "").trim();
  if (!name) return "Stop";
  const words = name.split(/\s+/).filter(Boolean);
  if (words.length <= 2) return name;
  return words.slice(0, 2).join(" ");
}

export function itineraryHint(stops: StopLike[]): string {
  const labels = stops.slice(0, 4).map(stopShortLabel);
  return labels.join(" → ");
}

export function enrichPlanPresentation(plan: Record<string, unknown>): void {
  const stops = (Array.isArray(plan.stops) ? plan.stops : []) as StopLike[];
  if (stops.length === 0) return;

  const hint = itineraryHint(stops);
  const tagline = typeof plan.tagline === "string" ? plan.tagline.trim() : "";
  if (tagline && !tagline.includes("→")) {
    plan.tagline = `${tagline} · ${hint}`;
  } else if (!tagline) {
    plan.tagline = hint;
  }

  // Ensure optionLabel gives a quick skim of the vibe + anchor stop
  if (typeof plan.optionLabel === "string" && plan.optionLabel.length < 8) {
    const anchor = stopShortLabel(stops[0]);
    plan.optionLabel = `${plan.optionLabel} · ${anchor}`;
  }
}
