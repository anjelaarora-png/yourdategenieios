import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders } from "./cors.ts";
import { buildPrompt } from "./prompt.ts";
import { generateMultipleDatePlans } from "./multiPlanAi.ts";
import { validateAllStops } from "./places.ts";

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
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

    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) {
      console.error("LOVABLE_API_KEY is not configured");
      return jsonResponse(500, { error: "AI service not configured" });
    }

    const GOOGLE_PLACES_API_KEY = Deno.env.get("GOOGLE_PLACES_API_KEY");

    const prompt = buildPrompt(preferences);

    let aiResponse: any;
    try {
      aiResponse = await generateMultipleDatePlans({ apiKey: LOVABLE_API_KEY, prompt });
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

    // Validate venues using Google Places API if available
    const city = preferences.city || preferences.location || "";
    console.log(`[Validation] City: "${city}", Has API Key: ${!!GOOGLE_PLACES_API_KEY}`);
    
    if (GOOGLE_PLACES_API_KEY && city) {
      console.log(`[Validation] Starting venue validation for ${plans.length} plans`);
      
      // Validate each plan with error isolation
      for (const plan of plans) {
        if (plan.stops && Array.isArray(plan.stops) && plan.stops.length > 0) {
          const originalStops = plan.stops.map((stop: any, index: number) => ({
            ...stop,
            validated: false,
            order: index + 1,
          }));
          
          try {
            console.log(`[Validation] Validating ${plan.stops.length} stops for plan: ${plan.title || 'Untitled'}`);
            const validatedStops = await validateAllStops(plan.stops, city, GOOGLE_PLACES_API_KEY);
            
            // Use validated stops (includes both verified and unverified venues)
            plan.stops = validatedStops;
            
            // Log validation results
            const verified = plan.stops.filter((s: any) => s?.validated).length;
            const unverified = plan.stops.filter((s: any) => !s?.validated).length;
            const withWebsite = plan.stops.filter((s: any) => s?.websiteUrl).length;
            
            console.log(`[Validation] Results - Verified: ${verified}, Unverified: ${unverified}, With Website: ${withWebsite}`);
          } catch (validationError) {
            // Log error but don't fail - keep original stops as unverified
            console.error(`[Validation] Error validating plan "${plan.title || 'Untitled'}":`, validationError);
            plan.stops = originalStops;
          }
        } else if (!plan.stops || !Array.isArray(plan.stops)) {
          // Ensure stops is at least an empty array
          plan.stops = [];
        }
      }
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

    // Ensure all plans have required fields with safe defaults
    const sanitizedPlans = plans.map((plan: any) => ({
      ...plan,
      title: plan.title || "Your Date Plan",
      tagline: plan.tagline || "A special experience awaits",
      totalDuration: plan.totalDuration || "3-4 hours",
      estimatedCost: plan.estimatedCost || "$50-100",
      stops: Array.isArray(plan.stops) ? plan.stops : [],
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
    
    return jsonResponse(200, { datePlans: sanitizedPlans });
  } catch (error) {
    console.error("Error generating date plans:", error);
    return jsonResponse(500, {
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
