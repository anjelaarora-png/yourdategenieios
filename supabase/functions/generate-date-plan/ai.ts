import { datePlanTool } from "./toolSchema.ts";

type GatewayErrorDetails = {
  status: number;
  bodyPreview: string;
};

const SYSTEM_PROMPT =
  "You are 'Your Date Genie', a romantic date planning expert. Create magical, personalized date experiences.";

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
      tools: [datePlanTool],
      tool_choice: { type: "function", function: { name: "create_date_plan" } },
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

export async function generateDatePlanFromAI({
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
