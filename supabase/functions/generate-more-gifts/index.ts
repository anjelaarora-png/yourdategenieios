import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const GATEWAY_URL = "https://ai.gateway.lovable.dev/v1/chat/completions";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { 
      planTitle, 
      occasion, 
      existingGifts, 
      partnerInterests, 
      giftBudget,
      // New standalone gift finder params
      interests,
      priceRange,
      partnerDescription,
      count = 3,
    } = await req.json();

    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) {
      console.error("LOVABLE_API_KEY is not configured");
      return jsonResponse(500, { error: "AI service not configured" });
    }

    const existingGiftNames = existingGifts?.map((g: any) => g.name).join(", ") || "none";
    const giftCount = Math.min(Math.max(count, 3), 6); // 3-6 gifts

    // Build context based on whether this is a date plan gift or standalone search
    const isStandalone = !planTitle || planTitle.includes("Gift Ideas for");
    
    let contextSection = "";
    if (isStandalone) {
      contextSection = `
Occasion: ${occasion || "Just because"}
Partner's interests: ${interests || "not specified"}
Partner description: ${partnerDescription || "not specified"}
Budget preference: ${priceRange || "any"}`;
    } else {
      contextSection = `
Date theme: ${planTitle}
Occasion: ${occasion || "Just because"}
Partner interests: ${partnerInterests?.join(", ") || interests || "not specified"}
Budget: ${giftBudget || priceRange || "moderate"}`;
    }

    const prompt = `You are a thoughtful gift advisor. Generate ${giftCount} creative, romantic gift suggestions.

Context:${contextSection}

${existingGiftNames !== "none" ? `Existing gifts already suggested (DO NOT repeat these): ${existingGiftNames}` : ""}

Generate ${giftCount} thoughtful gift ideas. Each gift should be:
- Romantic, thoughtful, and memorable
- Practically purchasable (available online or in common stores)
- Include specific product recommendations when possible
- Match the occasion and any mentioned interests

Focus on variety: mix experience gifts, physical items, and personalized options.`;

    console.log("[generate-more-gifts] Generating gifts with context:", contextSection);

    const response = await fetch(GATEWAY_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-3-flash-preview",
        messages: [
          { role: "system", content: "You are a gift suggestion expert. Always respond with valid JSON only." },
          { role: "user", content: prompt }
        ],
        tools: [{
          type: "function",
          function: {
            name: "add_gift_suggestions",
            description: "Add new gift suggestions",
            parameters: {
              type: "object",
              properties: {
                gifts: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      name: { type: "string", description: "Name of the gift" },
                      description: { type: "string", description: "Why this gift is special" },
                      priceRange: { type: "string", description: "Price range like '$30-50'" },
                      whereToBuy: { type: "string", description: "Store name or 'Amazon', 'Etsy'" },
                      purchaseUrl: { type: "string", description: "Direct URL to buy (optional)" },
                      whyItFits: { type: "string", description: "Why it matches the occasion" },
                      emoji: { type: "string" },
                    },
                    required: ["name", "description", "priceRange", "whereToBuy", "whyItFits", "emoji"],
                  },
                },
              },
              required: ["gifts"],
            },
          },
        }],
        tool_choice: { type: "function", function: { name: "add_gift_suggestions" } },
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("AI API error:", response.status, errText);
      
      if (response.status === 429) {
        return jsonResponse(429, { error: "Rate limit exceeded. Please try again in a moment." });
      }
      if (response.status === 402) {
        return jsonResponse(402, { error: "Service temporarily unavailable." });
      }
      return jsonResponse(503, { error: "AI service temporarily unavailable" });
    }

    const data = await response.json();
    console.log("[generate-more-gifts] AI response received");

    const toolCall = data?.choices?.[0]?.message?.tool_calls?.[0];
    if (!toolCall || toolCall.function?.name !== "add_gift_suggestions") {
      console.error("No valid tool call:", JSON.stringify(data));
      return jsonResponse(500, { error: "Failed to generate gift suggestions" });
    }

    const parsed = JSON.parse(toolCall.function.arguments);
    console.log("[generate-more-gifts] Generated", parsed.gifts?.length, "gifts");
    return jsonResponse(200, { gifts: parsed.gifts });
  } catch (error) {
    console.error("Error generating gifts:", error);
    return jsonResponse(500, {
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
