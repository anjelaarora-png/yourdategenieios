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
        title: { type: "string", description: "Short creative name (2-6 words), not only cuisine/neighborhood; e.g. 'Sunset & Vinyl'" },
        tagline: { type: "string", description: "Romantic one-liner; can mention cuisine or area" },
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
