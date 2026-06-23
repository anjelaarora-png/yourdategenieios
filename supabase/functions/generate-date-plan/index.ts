import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders } from "./cors.ts";
import { buildPrompt } from "./prompt.ts";
import { generateMultipleDatePlans } from "./multiPlanAi.ts";
import { validateAllStops, geocodeAddress } from "./places.ts";
import { getDirections, toGoogleTravelMode, toAppTravelMode } from "./directions.ts";
import { enrichPlanPresentation } from "./planPresentation.ts";
import { enrichGiftImages } from "../_shared/linkPreview.ts";
import { requireAuthenticatedUser } from "../_shared/jwtAuth.ts";
import { checkRateLimit } from "../_shared/rateLimit.ts";
import { filterHardNoStops } from "./hardNos.ts";

const MIN_VALIDATED_STOPS_PER_PLAN = 2;
const RATE_LIMIT_MAX = 20;
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000;

function jsonResponse(status: number, body: unknown, extraHeaders: Record<string, string> = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json", ...extraHeaders },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const user = requireAuthenticatedUser(req.headers.get("Authorization"));
  if (!user) {
    return jsonResponse(401, { error: "Sign in required to generate date plans." });
  }

  const rate = checkRateLimit(`generate-date-plan:${user.sub}`, RATE_LIMIT_MAX, RATE_LIMIT_WINDOW_MS);
  if (!rate.allowed) {
    return jsonResponse(
      429,
      { error: "You've reached the hourly plan limit. Try again soon or upgrade to Premium." },
      rate.retryAfterSec ? { "Retry-After": String(rate.retryAfterSec) } : {},
    );
  }

  try {
    const { preferences } = await req.json();
    
    // Debug logging - capture what we receive
    console.log(`[Request] Received preferences:`, JSON.stringify({
      city: preferences?.city,
      neighborhood: preferences?.neighborhood,
      location: preferences?.location,
      dateType: preferences?.dateType,
    }));

    if (!preferences) {
      return jsonResponse(400, { error: "Missing preferences data" });
    }

    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
    if (!OPENAI_API_KEY) {
      console.error("OPENAI_API_KEY is not configured");
      return jsonResponse(500, { error: "AI service not configured" });
    }

    const GOOGLE_PLACES_API_KEY = Deno.env.get("GOOGLE_PLACES_API_KEY");

    const prompt = buildPrompt(preferences);

    let aiResponse: any;
    try {
      aiResponse = await generateMultipleDatePlans({ apiKey: OPENAI_API_KEY, prompt });
    } catch (e) {
      const status = (e as any)?.details?.status as number | undefined;
      const bodyPreview = (e as any)?.details?.bodyPreview as string | undefined;

      if (status === 429) {
        return jsonResponse(429, {
          error: "Rate limit exceeded. Please try again in a moment.",
        });
      }
      if (status === 402) {
        return jsonResponse(402, {
          error: "Service temporarily unavailable. Please try again later.",
        });
      }

      console.error(
        "AI gateway error:",
        status ?? "unknown",
        bodyPreview ? bodyPreview : e,
      );

      return jsonResponse(503, {
        error: "AI service is temporarily unstable. Please try again.",
      });
    }

    const toolCall = aiResponse?.choices?.[0]?.message?.tool_calls?.[0];

    if (!toolCall || toolCall.function?.name !== "create_date_plans") {
      // Check if this is an error response from the AI gateway
      if (aiResponse?.error) {
        const errorCode = aiResponse.error.code;
        const errorMessage = aiResponse.error.message;
        console.error("AI gateway returned error:", errorCode, errorMessage);
        
        // 524 is a timeout error
        if (errorCode === 524) {
          return jsonResponse(503, { 
            error: "Request timed out. Please try again - our AI is working hard!" 
          });
        }
        
        return jsonResponse(503, { 
          error: "AI service temporarily unavailable. Please try again." 
        });
      }
      
      console.error("No valid tool call in response:", JSON.stringify(aiResponse));
      return jsonResponse(500, { error: "AI did not return valid date plans. Please try again." });
    }

    let parsedResult;
    try {
      parsedResult = JSON.parse(toolCall.function.arguments);
    } catch (parseError) {
      console.error(
        "Failed to parse tool call arguments:",
        toolCall.function.arguments,
      );
      return jsonResponse(500, { error: "Failed to parse date plans" });
    }

    const plans = parsedResult.plans;
    if (!Array.isArray(plans) || plans.length === 0) {
      return jsonResponse(500, { error: "No date plans returned" });
    }

    // CRITICAL: Check that at least one plan has stops - if not, it's a failed generation
    const hasAnyStops = plans.some((p: any) => Array.isArray(p.stops) && p.stops.length > 0);
    if (!hasAnyStops) {
      console.error("[Validation] AI returned plans without any stops! Raw plans:", JSON.stringify(plans).slice(0, 2000));
      return jsonResponse(500, { error: "AI failed to generate venue stops. Please try again." });
    }
    
    console.log(`[Parse] Plans received: ${plans.length}, Stops counts: ${plans.map((p: any) => p.stops?.length || 0).join(', ')}`);

    // HARD FILTER: never surface a stop that conflicts with a stated dealbreaker.
    // The prompt already instructs the model to avoid these; this enforces it.
    const hardNos: string[] = Array.isArray(preferences.hardNos) ? preferences.hardNos : [];
    if (hardNos.length > 0) {
      let removed = 0;
      for (const plan of plans) {
        removed += filterHardNoStops(plan, hardNos);
      }
      if (removed > 0) {
        console.log(`[HardNo] Removed ${removed} stop(s) violating hard-nos: ${hardNos.join(", ")}`);
      }
      // Drop any plan left with no stops after hard-no removal.
      const survivingPlans = plans.filter((p: any) => Array.isArray(p.stops) && p.stops.length > 0);
      if (survivingPlans.length === 0) {
        return jsonResponse(422, {
          error:
            "We couldn't build a plan that avoids all your dealbreakers. Please try again or relax a hard-no.",
        });
      }
      plans.length = 0;
      plans.push(...survivingPlans);
    }

    // Validate venues using Google Places API if available
    const city = preferences.city || preferences.location || "";
    console.log(`[Validation] City: "${city}", Has API Key: ${!!GOOGLE_PLACES_API_KEY}`);
    
    if (GOOGLE_PLACES_API_KEY && city) {
      console.log(`[Validation] Starting venue validation for ${plans.length} plans (parallel)`);

      // Validate all plans in parallel — each plan's stops are already parallelised inside validateAllStops.
      await Promise.all(plans.map(async (plan: any) => {
        if (plan.stops && Array.isArray(plan.stops) && plan.stops.length > 0) {
          const originalStops = plan.stops.map((stop: any, index: number) => ({
            ...stop,
            validated: false,
            order: index + 1,
          }));
          try {
            console.log(`[Validation] Validating ${plan.stops.length} stops for plan: ${plan.title || 'Untitled'}`);
            const validatedStops = await validateAllStops(plan.stops, city, GOOGLE_PLACES_API_KEY);
            plan.stops = validatedStops;
            const verified = plan.stops.filter((s: any) => s?.validated).length;
            const unverified = plan.stops.filter((s: any) => !s?.validated).length;
            const withWebsite = plan.stops.filter((s: any) => s?.websiteUrl).length;
            console.log(`[Validation] Results - Verified: ${verified}, Unverified: ${unverified}, With Website: ${withWebsite}`);
          } catch (validationError) {
            console.error(`[Validation] Error validating plan "${plan.title || 'Untitled'}":`, validationError);
            plan.stops = originalStops;
          }
        } else if (!plan.stops || !Array.isArray(plan.stops)) {
          plan.stops = [];
        }
      }));
    } else {
      console.log(`[Validation] Cannot verify venues - missing ${!GOOGLE_PLACES_API_KEY ? 'API key' : 'city'}`);
      // Keep AI-generated stops as unverified - app works anywhere
      for (const plan of plans) {
        if (plan.stops && Array.isArray(plan.stops)) {
          plan.stops = plan.stops.map((stop: any, index: number) => ({
            ...stop,
            validated: false,
            order: index + 1,
          }));
        }
      }
    }

    // Ensure all plans have required fields. Stops = itinerary venues only (step 1 = first venue, not starting point).
    let sanitizedPlans = plans.map((plan: any) => ({
      ...plan,
      title: plan.title || "Your Date Plan",
      tagline: plan.tagline || "A special experience awaits",
      totalDuration: plan.totalDuration || "3-4 hours",
      estimatedCost: plan.estimatedCost || "$50-100",
      stops: Array.isArray(plan.stops) ? plan.stops : [],
      startingPoint: plan.startingPoint ?? undefined,
      genieSecretTouch: plan.genieSecretTouch || {
        title: "Special Touch",
        description: "Make this date memorable with your unique presence.",
        emoji: "✨",
      },
      packingList: Array.isArray(plan.packingList) ? plan.packingList : [],
      weatherNote: plan.weatherNote || "",
      giftSuggestions: Array.isArray(plan.giftSuggestions) ? plan.giftSuggestions : [],
      conversationStarters: Array.isArray(plan.conversationStarters) ? plan.conversationStarters : [],
    }));

    if (GOOGLE_PLACES_API_KEY && city) {
      sanitizedPlans = sanitizedPlans.filter((plan: any) => {
        const validatedCount = (plan.stops || []).filter((s: any) => s?.validated).length;
        if (validatedCount >= MIN_VALIDATED_STOPS_PER_PLAN) return true;
        console.warn(
          `[Validation] Dropping plan "${plan.title}" — only ${validatedCount} verified stops (need ${MIN_VALIDATED_STOPS_PER_PLAN})`,
        );
        return false;
      });

      if (sanitizedPlans.length === 0) {
        return jsonResponse(422, {
          error:
            "We couldn't verify enough real, open venues for your area. Please try again or adjust your city/radius.",
        });
      }
    }

    for (const plan of sanitizedPlans) {
      enrichPlanPresentation(plan);
      if (Array.isArray(plan.giftSuggestions) && plan.giftSuggestions.length > 0) {
        plan.giftSuggestions = await enrichGiftImages(plan.giftSuggestions);
      }
    }

    // Set starting point separately for route map; do NOT add it as step 1 of the itinerary.
    const startingAddress = preferences.startingAddress?.trim();
    const transportationMode = preferences.transportationMode || "walking";
    const googleMode = toGoogleTravelMode(transportationMode);
    const appTravelMode = toAppTravelMode(googleMode);

    if (startingAddress && GOOGLE_PLACES_API_KEY) {
      try {
        const startResult = await geocodeAddress(startingAddress, GOOGLE_PLACES_API_KEY);
        if (startResult) {
          const startingPoint = {
            name: "Your location",
            address: startResult.formatted_address,
            latitude: startResult.latitude,
            longitude: startResult.longitude,
          };
          for (const plan of sanitizedPlans) {
            plan.startingPoint = startingPoint;
          }
          console.log(`[Starting point] Set starting point (not as itinerary step)`);
        }
      } catch (err) {
        console.warn("[Starting point] Geocode failed:", err);
      }
    }

    // Enrich stops with accurate travel time/distance from Directions API (all plans in parallel).
    if (GOOGLE_PLACES_API_KEY && sanitizedPlans.length > 0) {
      await Promise.all(sanitizedPlans.map(async (plan: any) => {
        const stops = Array.isArray(plan.stops) ? plan.stops : [];
        const start = plan.startingPoint;
        const withCoords = stops.filter(
          (s: any) =>
            typeof s.latitude === "number" &&
            typeof s.longitude === "number" &&
            Number.isFinite(s.latitude) &&
            Number.isFinite(s.longitude)
        );
        if (withCoords.length === 0) return;

        let legs: { durationText: string; distanceText: string }[] = [];
        if (start) {
          const origin = { latitude: start.latitude, longitude: start.longitude };
          const waypoints = withCoords.slice(0, -1).map((s: any) => ({ latitude: s.latitude, longitude: s.longitude }));
          const dest = withCoords[withCoords.length - 1];
          const destination = { latitude: dest.latitude, longitude: dest.longitude };
          legs = await getDirections(origin, destination, waypoints, googleMode, GOOGLE_PLACES_API_KEY);
        } else {
          const origin = { latitude: withCoords[0].latitude, longitude: withCoords[0].longitude };
          const waypoints = withCoords.slice(1, -1).map((s: any) => ({ latitude: s.latitude, longitude: s.longitude }));
          const dest = withCoords[withCoords.length - 1];
          const destination = { latitude: dest.latitude, longitude: dest.longitude };
          legs = await getDirections(origin, destination, waypoints, googleMode, GOOGLE_PLACES_API_KEY);
        }

        for (let i = 0; i < legs.length && i < stops.length; i++) {
          const stop = start ? stops[i] : stops[i + 1];
          if (!stop) continue;
          const leg = legs[i];
          if (!leg.durationText) continue;
          stop.travelTimeFromPrevious = leg.durationText + " by " + transportationMode;
          stop.travelDistanceFromPrevious = leg.distanceText || stop.travelDistanceFromPrevious;
          stop.travelMode = appTravelMode;
        }
      }));
      console.log(`[Directions] Enriched travel legs using ${transportationMode}`);
    }

    return jsonResponse(200, { datePlans: sanitizedPlans });
  } catch (error) {
    console.error("Error generating date plans:", error);
    return jsonResponse(500, {
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
