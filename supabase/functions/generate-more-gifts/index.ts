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
      // Standalone gift finder params
      interests,
      priceRange,
      partnerDescription,
      count = 3,
      // Location & preference refinement
      location,
      city,
      country,
      loveLanguages,
      relationshipStage,
      giftRecipient,
      purchasedGiftNames,
      // Gender/identity and extra gift personalization
      recipientIdentity,
      giftStyle,
      favoriteBrandsOrStores,
      recipientSizes,
    } = await req.json();

    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) {
      console.error("LOVABLE_API_KEY is not configured");
      return jsonResponse(500, { error: "AI service not configured" });
    }

    const existingGiftNames =
      existingGifts?.map((g: any) => (typeof g === "string" ? g : g?.name)).filter(Boolean).join(", ") || "none";
    const purchasedNames =
      Array.isArray(purchasedGiftNames) && purchasedGiftNames.length > 0
        ? purchasedGiftNames.join(", ")
        : "";
    const giftCount = Math.min(Math.max(Number(count) || 3, 1), 6);

    const userLocation = location || city || "";
    const userCountry = (country || "").toLowerCase();
    const locationHint = userLocation
      ? `${userLocation}${userCountry ? `, ${userCountry}` : ""}`
      : "United States";

    // Build context from ALL provided preferences for accurate personalization
    const isStandalone = !planTitle || planTitle.includes("Gift Ideas for");
    
    let contextSection = "";
    const identityLine = recipientIdentity ? `Recipient identity: ${recipientIdentity}.` : "";
    const styleLine = giftStyle?.length ? `Gift style preferences: ${Array.isArray(giftStyle) ? giftStyle.join(", ") : giftStyle}.` : "";
    const brandsLine = favoriteBrandsOrStores ? `Favorite brands/stores: ${favoriteBrandsOrStores}.` : "";
    const sizesLine = recipientSizes ? `Sizes if relevant: ${recipientSizes}.` : "";
    const extraContext = [identityLine, styleLine, brandsLine, sizesLine].filter(Boolean).join(" ");

    if (isStandalone) {
      contextSection = `
Occasion: ${occasion || "Just because"}
Who you're shopping for: ${giftRecipient || "not specified"}
Partner's interests: ${interests || "not specified"}
Partner description / notes: ${partnerDescription || "not specified"}
Budget: ${priceRange || "any"}
Location (for where to buy): ${locationHint}
${loveLanguages?.length ? `Love languages (tailor gift style): ${Array.isArray(loveLanguages) ? loveLanguages.join(", ") : loveLanguages}` : ""}
${relationshipStage ? `Relationship stage: ${relationshipStage}` : ""}
${extraContext ? extraContext : ""}`;
    } else {
      contextSection = `
Date theme: ${planTitle}
Occasion: ${occasion || "Just because"}
Who you're shopping for: ${giftRecipient || "partner"}
Partner interests: ${partnerInterests?.join(", ") || interests || "not specified"}
Budget: ${giftBudget || priceRange || "moderate"}
Location (for where to buy): ${locationHint}
${loveLanguages?.length ? `Love languages: ${Array.isArray(loveLanguages) ? loveLanguages.join(", ") : loveLanguages}` : ""}
${relationshipStage ? `Relationship stage: ${relationshipStage}` : ""}
${extraContext ? extraContext : ""}`;
    }

    const prompt = `You are a thoughtful gift advisor. Generate ${giftCount} personalized, UNIQUE gift suggestions. Avoid generic ideas—mix surprising finds, niche brands, and memorable options.

CRITICAL — PERSONALIZATION: Use EVERY detail in the Context below. When the user provides interests, notes, recipient identity, style, budget, or location, each suggestion MUST directly reflect those details. Do NOT suggest vague or generic gifts (e.g. "thoughtful gift", "something they'll love") when specific preferences are given. In "whyItFits" explicitly name the interest, occasion, or note from the context (e.g. "Perfect for a cooking enthusiast" or "Matches their minimalist style").

CRITICAL — NO REPEATS: Do NOT suggest the same or very similar gifts to those listed below. Each suggestion must be clearly different in type, retailer, or category. Vary product types and stores.

Context:${contextSection}

${existingGiftNames !== "none" ? `ALREADY SUGGESTED (do NOT suggest these or very similar items again): ${existingGiftNames}` : ""}
${purchasedNames ? `\nALREADY BOUGHT (do NOT suggest these again): ${purchasedNames}` : ""}

Channels and links:
- Consider two channels: (1) In-person: suggest items available at stores near the user's location (city/region). Name specific store types or chains that exist in ${locationHint}. (2) Online: suggest retailers that ship to the user's location (e.g. US, UK).
- For each gift, set purchaseUrl to a single working link where the item can be bought. Prefer a direct product or category URL when you can infer one (e.g. known product page, store category). If not possible, use the retailer's search URL. purchaseUrl must be a real, working link.
- whereToBuy must name the actual store(s) you used for purchaseUrl. Prefer local + deliverable-online options; if none fit, use Amazon (US or UK by location) as fallback.

Requirements:
- Be UNIQUE: suggest a mix of Etsy finds, Amazon bestsellers, Uncommon Goods, local boutiques, experience gifts, and personalized items. Vary retailers (e.g. Etsy, Amazon, Target, small shops, Bookshop.org, Crate & Barrel).
- Use EVERY detail above: occasion, who they're shopping for, interests, notes, budget, and location.
- Each gift MUST have a purchaseUrl: a real link where they can buy it. Use direct product/category URLs when possible; otherwise use retailer search URLs:
  - Etsy: https://www.etsy.com/search?q=PRODUCT_QUERY
  - Amazon US: https://www.amazon.com/s?k=PRODUCT_QUERY
  - Amazon UK: https://www.amazon.co.uk/s?k=PRODUCT_QUERY
  - Target: https://www.target.com/s?searchTerm=PRODUCT_QUERY
  - Uncommon Goods / niche: use the retailer's search URL or a specific product category URL.
- Match the occasion and interests; tailor "whyItFits" to the person. Use recipient identity, gift style, favorite brands, and sizes (when provided) to tailor suggestions. Name specific interests or notes from the context in whyItFits when relevant.
- Do not give generic suggestions (e.g. "a nice gift for any occasion") when the context includes specific interests, notes, or recipient details—use them.
- Mix variety: physical gifts, experiences, and personalized options.

Generate exactly ${giftCount} gifts. Every gift must have: name, description, priceRange, whereToBuy, purchaseUrl (required), whyItFits, and emoji. If you know a direct, working product image URL for the suggested item, include it in imageUrl; otherwise omit (we will use a placeholder).`;

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
                      whereToBuy: { type: "string", description: "1-2 retailers accessible in user's location (e.g. 'Amazon, Target' or 'Amazon, John Lewis')" },
                      purchaseUrl: { type: "string", description: "REQUIRED: Direct search or product URL where they can buy (e.g. Amazon search link for the product, in user's region)" },
                      whyItFits: { type: "string", description: "Why it matches the occasion" },
                      emoji: { type: "string" },
                      imageUrl: { type: "string", description: "Direct URL to a product image if you know one; otherwise omit (we will use a placeholder)" },
                    },
                    required: ["name", "description", "priceRange", "whereToBuy", "purchaseUrl", "whyItFits", "emoji"],
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
    const gifts = Array.isArray(parsed.gifts) ? parsed.gifts : [];
    const isUK = userCountry === "uk" || userCountry === "united kingdom" || locationHint.toLowerCase().includes("uk");
    const amazonBase = isUK ? "https://www.amazon.co.uk/s?k=" : "https://www.amazon.com/s?k=";
    for (const g of gifts) {
      if (!g.purchaseUrl || typeof g.purchaseUrl !== "string" || !g.purchaseUrl.startsWith("http")) {
        const query = encodeURIComponent((g.name || "gift").replace(/\s+/g, " ").trim());
        g.purchaseUrl = `${amazonBase}${query}`;
      }
      if (g.imageUrl != null && (typeof g.imageUrl !== "string" || !g.imageUrl.startsWith("http"))) {
        delete g.imageUrl;
      }
    }
    console.log("[generate-more-gifts] Generated", gifts.length, "gifts");
    return jsonResponse(200, { gifts });
  } catch (error) {
    console.error("Error generating gifts:", error);
    return jsonResponse(500, {
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
