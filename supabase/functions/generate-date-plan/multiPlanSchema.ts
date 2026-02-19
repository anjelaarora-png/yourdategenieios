// Lovable AI tool schema for generating 3 complete date plans
export const multiDatePlanTool = {
  type: "function",
  function: {
    name: "create_date_plans",
    description:
      "Creates 3 different romantic date plan options, each with unique themes and venues",
    parameters: {
      type: "object",
      properties: {
        plans: {
          type: "array",
          description: "Array of 3 different date plan options",
          minItems: 3,
          maxItems: 3,
          items: {
            type: "object",
            properties: {
              optionLabel: {
                type: "string",
                description: "Short label like 'Classic Romance', 'Adventure', 'Cozy & Intimate'",
              },
              title: { type: "string", description: "Creative name for the date" },
              tagline: { type: "string", description: "Romantic one-liner" },
              totalDuration: {
                type: "string",
                description: "Total time like '3-4 hours'",
              },
              estimatedCost: {
                type: "string",
                description: "Cost range like '$100-$200'",
              },
              stops: {
                type: "array",
                description: "REQUIRED: Array of 3-4 venue stops for the date. Must not be empty!",
                minItems: 3,
                maxItems: 5,
                items: {
                  type: "object",
                  properties: {
                    order: { type: "number" },
                    name: { type: "string", description: "Real, well-known venue name that exists in the specified city" },
                    venueType: { type: "string" },
                    timeSlot: { type: "string" },
                    duration: { type: "string" },
                    description: { type: "string" },
                    whyItFits: { type: "string" },
                    romanticTip: { type: "string" },
                    emoji: { type: "string" },
                    travelTimeFromPrevious: { 
                      type: "string", 
                      description: "Travel time from previous stop, e.g. '10 mins by walking'. Empty for first stop." 
                    },
                    travelDistanceFromPrevious: { 
                      type: "string", 
                      description: "Distance from previous stop, e.g. '0.5 miles' or '3 blocks'. Empty for first stop." 
                    },
                    travelMode: {
                      type: "string",
                      description: "Mode of transport used, e.g. 'walking', 'driving', 'rideshare', 'transit'. Empty for first stop."
                    },
                    // Phase 3: Enhanced venue info
                    websiteUrl: {
                      type: "string",
                      description: "Official website URL for the venue. Must be a real, valid URL."
                    },
                    bookingUrl: {
                      type: "string",
                      description: "Direct booking/reservation URL if available (e.g., OpenTable, Resy, or venue's own booking page)"
                    },
                    phoneNumber: {
                      type: "string",
                      description: "Phone number for the venue in format (XXX) XXX-XXXX"
                    },
                    estimatedCostPerPerson: {
                      type: "string",
                      description: "Estimated cost per person for this stop, e.g. '$25-40' or 'Free'"
                    },
                  },
                  required: [
                    "order",
                    "name",
                    "venueType",
                    "timeSlot",
                    "duration",
                    "description",
                    "whyItFits",
                    "romanticTip",
                    "emoji",
                    "estimatedCostPerPerson",
                  ],
                },
              },
              genieSecretTouch: {
                type: "object",
                properties: {
                  title: { type: "string" },
                  description: { type: "string" },
                  emoji: { type: "string" },
                },
                required: ["title", "description", "emoji"],
              },
              packingList: { type: "array", items: { type: "string" } },
              weatherNote: { type: "string" },
              // Phase 5: Gift suggestions
              giftSuggestions: {
                type: "array",
                description: "At least 3 personalized gift suggestions based on partner interests and occasion. Always include 3-5 suggestions.",
                minItems: 3,
                items: {
                  type: "object",
                  properties: {
                    name: { type: "string", description: "Name of the gift item" },
                    description: { type: "string", description: "Brief description of why this gift is special" },
                    priceRange: { type: "string", description: "Price range like '$30-50'" },
                    whereToBuy: { type: "string", description: "Where to purchase (store name or 'Amazon', 'Etsy', etc.)" },
                    purchaseUrl: { type: "string", description: "Direct URL to purchase the gift online" },
                    whyItFits: { type: "string", description: "Why this gift matches their interests and the occasion" },
                    emoji: { type: "string" },
                  },
                  required: ["name", "description", "priceRange", "whereToBuy", "whyItFits", "emoji"],
                },
              },
              // Phase 5: Conversation starters
              conversationStarters: {
                type: "array",
                description: "10-15 tailored conversation starters based on relationship stage and topics",
                items: {
                  type: "object",
                  properties: {
                    question: { type: "string", description: "The conversation starter question" },
                    category: { type: "string", description: "Category like 'Dreams', 'Memories', 'Fun', 'Deep'" },
                    emoji: { type: "string" },
                  },
                  required: ["question", "category", "emoji"],
                },
              },
            },
            required: [
              "optionLabel",
              "title",
              "tagline",
              "totalDuration",
              "estimatedCost",
              "stops",
              "genieSecretTouch",
              "packingList",
              "weatherNote",
            ],
          },
        },
      },
      required: ["plans"],
    },
  },
} as const;
