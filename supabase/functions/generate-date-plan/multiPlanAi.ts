import { multiDatePlanTool } from "./multiPlanSchema.ts";

type GatewayErrorDetails = {
  status: number;
  bodyPreview: string;
};

const SYSTEM_PROMPT = `You are 'Your Date Genie', a romantic date planning expert. Create magical, personalized date experiences.

CRITICAL RULES:
1. Generate EXACTLY 3 different date plan options with distinct themes
2. **STOPS ARE REQUIRED** - Each plan MUST have 3-4 stops/venues. The stops array CANNOT be empty!
   - Every stop must have: order, name, venueType, timeSlot, duration, description, whyItFits, romanticTip, emoji, estimatedCostPerPerson
   - Example stop: { "order": 1, "name": "Central Park", "venueType": "Park", "timeSlot": "2:00 PM", "duration": "1 hour", "description": "...", "whyItFits": "...", "romanticTip": "...", "emoji": "🌳", "estimatedCostPerPerson": "Free" }
3. **LOCATION IS ABSOLUTE** - Every single venue MUST be in the EXACT city and state specified by the user
   - If user says "Newark, NJ" - ALL venues must be in Newark, New Jersey
   - NEVER suggest venues from other states (no Arizona venues for NJ requests!)
   - NEVER suggest venues from other cities unless explicitly within the travel radius
4. Use ONLY real venues that actually exist in the specified city - Google the venues if unsure
5. Be specific with venue names - use actual restaurant names, actual park names, actual attraction names
6. Do NOT make up fictional venues or use generic placeholder names
7. Each option should offer a genuinely different experience style
8. Include the FULL ADDRESS with city and state abbreviation for every venue

IMPORTANT: The "stops" array is the MOST CRITICAL part of each plan. Never return empty stops!`;

const GATEWAY_URL = "https://ai.gateway.lovable.dev/v1/chat/completions";

const isRetryableStatus = (status: number) =>
  status === 429 || status === 500 || status === 502 || status === 503 ||
  status === 504;

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function callGateway({
  apiKey,
  prompt,
  model,
}: {
  apiKey: string;
  prompt: string;
  model: string;
}) {
  const response = await fetch(GATEWAY_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({
      model,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: prompt },
      ],
      tools: [multiDatePlanTool],
      tool_choice: { type: "function", function: { name: "create_date_plans" } },
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    const preview = text.slice(0, 1200);
    const details: GatewayErrorDetails = { status: response.status, bodyPreview: preview };
    throw Object.assign(new Error("AI_GATEWAY_ERROR"), { details });
  }

  return response.json();
}

export async function generateMultipleDatePlans({
  apiKey,
  prompt,
}: {
  apiKey: string;
  prompt: string;
}) {
  // Use fastest model first for quick response times
  // Models available through Lovable AI gateway
  const models = ["gpt-4o-mini", "gpt-4o"];

  let lastErr: unknown;

  for (const model of models) {
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        return await callGateway({ apiKey, prompt, model });
      } catch (e) {
        lastErr = e;
        const status = (e as any)?.details?.status as number | undefined;

        // Retry only on transient gateway failures.
        if (typeof status === "number" && isRetryableStatus(status) && attempt === 0) {
          await sleep(350 + Math.floor(Math.random() * 250));
          continue;
        }
        break;
      }
    }
  }

  throw lastErr ?? new Error("AI_GATEWAY_ERROR");
}
