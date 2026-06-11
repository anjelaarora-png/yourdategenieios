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

const GATEWAY_URL = "https://api.openai.com/v1/chat/completions";

/** Decodes a base64url JWT payload without verification (Supabase already verified via config.toml). */
function jwtRole(authHeader: string | null): string | null {
  if (!authHeader?.startsWith("Bearer ")) return null;
  try {
    const parts = authHeader.slice(7).split(".");
    if (parts.length !== 3) return null;
    const padded = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const pad = padded.length % 4 === 0 ? "" : "=".repeat(4 - (padded.length % 4));
    const payload = JSON.parse(atob(padded + pad));
    return typeof payload?.role === "string" ? payload.role : null;
  } catch {
    return null;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  // Require a signed-in user — anon-key-only calls are rejected.
  const role = jwtRole(req.headers.get("Authorization"));
  if (role !== "authenticated") {
    return jsonResponse(401, { error: "Authenticated user required" });
  }

  try {
    const { originalText, systemRole, styleInstruction } = await req.json();

    if (!originalText || typeof originalText !== "string" || originalText.trim() === "") {
      return jsonResponse(400, { error: "Missing required field: originalText" });
    }
    if (!systemRole || !styleInstruction) {
      return jsonResponse(400, { error: "Missing required fields: systemRole, styleInstruction" });
    }

    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
    if (!OPENAI_API_KEY) {
      console.error("OPENAI_API_KEY is not configured");
      return jsonResponse(500, { error: "AI service not configured" });
    }

    const systemPrompt = `${systemRole}

Rules:
- Keep the same meaning and sentiment; do not add new facts or make things up.
- Keep it concise: 2–5 sentences or one short paragraph. No lists or bullets.
- Write in second person ("you") as if the author is speaking to their loved one.
- Do not use clichés or generic phrases; keep their voice and their specific message.
- Output only the rewritten love note, no quotes, no preamble, no "Here's your love note:".`;

    const userPrompt = `${styleInstruction}

"${originalText}"`;

    console.log("[rewrite-love-note] Rewriting note, style instruction length:", styleInstruction.length);

    const response = await fetch(GATEWAY_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.8,
        max_tokens: 400,
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
    let content: string | undefined = data?.choices?.[0]?.message?.content;

    if (!content || content.trim() === "") {
      console.error("Empty content from AI:", JSON.stringify(data));
      return jsonResponse(500, { error: "No rewritten text in AI response" });
    }

    // Strip surrounding quotes the model occasionally adds
    content = content
      .trim()
      .replace(/^[\"']|[\"']$/g, "")
      .trim();

    console.log("[rewrite-love-note] Success, response length:", content.length);
    return jsonResponse(200, { rewrittenText: content });

  } catch (error) {
    console.error("Error rewriting love note:", error);
    return jsonResponse(500, {
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
