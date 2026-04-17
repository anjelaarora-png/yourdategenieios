// Lovable AI tool schema for structured output
export const datePlanTool = {
  type: "function",
  function: {
    name: "create_date_plan",
    description:
      "Creates a structured romantic date plan with multiple stops and a special surprise",
    parameters: {
      type: "object",
      properties: {
        title: { type: "string", description: "Magical, cinematic 2-6 word title evoking MOOD or ATMOSPHERE. NEVER use lazy generic titles like 'Mediterranean Evening' or 'Italian Night'. Cuisine words ARE allowed if used creatively (e.g. 'Mediterranean Moonlight', 'Saffron & Slow Jazz'). No generic phrases like 'Date Night' or 'Evening Out'. Examples: 'Velvet & City Lights', 'The Midnight Detour', 'Salt Air & Starlight'" },
        tagline: { type: "string", description: "Romantic one-liner that sets the scene; this is where you can mention cuisine or neighborhood (NOT the title)" },
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
          items: {
            type: "object",
            properties: {
              order: { type: "number" },
              name: { type: "string" },
              venueType: { type: "string" },
              timeSlot: { type: "string" },
              duration: { type: "string" },
              description: { type: "string" },
              whyItFits: { type: "string" },
              romanticTip: { type: "string" },
              emoji: { type: "string" },
              reservationPlatforms: {
                type: "array",
                items: { type: "string" },
                description: "Reservation platforms this venue is confirmed on. Valid values: 'opentable', 'resy'. Only include if confident. Leave empty if unsure."
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
      },
      required: [
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
} as const;
