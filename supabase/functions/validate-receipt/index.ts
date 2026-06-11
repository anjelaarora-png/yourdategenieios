import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  Environment,
  SignedDataVerifier,
} from "npm:@apple/app-store-server-library@2";

// ─── CORS (iOS callers don't send Origin, so this header only matters for web) ───
const corsHeaders = {
  "Access-Control-Allow-Origin": "https://yourdategenie.com",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

// ─── Apple Root CA certificates — cached at module level across requests ───────
let appleRootCAs: Buffer[] | null = null;

async function getAppleRootCAs(): Promise<Buffer[]> {
  if (appleRootCAs) return appleRootCAs;
  const [g3, g2] = await Promise.all([
    fetch("https://www.apple.com/certificateauthority/AppleRootCA-G3.cer")
      .then((r) => r.arrayBuffer()),
    fetch("https://www.apple.com/certificateauthority/AppleRootCA-G2.cer")
      .then((r) => r.arrayBuffer()),
  ]);
  appleRootCAs = [Buffer.from(g3), Buffer.from(g2)];
  return appleRootCAs;
}

// ─── Verifier factories (one per environment, cached) ───────────────────────
let prodVerifier: SignedDataVerifier | null = null;
let sandboxVerifier: SignedDataVerifier | null = null;

async function getVerifier(env: Environment): Promise<SignedDataVerifier> {
  const bundleId = Deno.env.get("APPLE_BUNDLE_ID") ?? "com.yourdategenie.app";
  const rootCAs = await getAppleRootCAs();
  if (env === Environment.PRODUCTION) {
    if (!prodVerifier) {
      prodVerifier = new SignedDataVerifier(rootCAs, true, Environment.PRODUCTION, bundleId, null);
    }
    return prodVerifier;
  }
  if (!sandboxVerifier) {
    sandboxVerifier = new SignedDataVerifier(rootCAs, true, Environment.SANDBOX, bundleId, null);
  }
  return sandboxVerifier;
}

// ─── Decode JWS payload without verification — used only to peek at environment ─
function peekJwsPayload(jws: string): Record<string, unknown> {
  const parts = jws.split(".");
  if (parts.length !== 3) throw new Error("Invalid JWS format");
  const padded = parts[1].replace(/-/g, "+").replace(/_/g, "/").padEnd(
    Math.ceil(parts[1].length / 4) * 4,
    "=",
  );
  return JSON.parse(atob(padded));
}

// ─── Map Apple JWS payload to subscription status ───────────────────────────
function mapToStatus(
  payload: { revocationDate?: number; expiresDate?: number; offerType?: number },
): string {
  if (payload.revocationDate) return "revoked";
  if (payload.expiresDate && payload.expiresDate < Date.now()) return "expired";
  if (payload.offerType === 1) return "trialing";
  return "active";
}

function mapToTier(productId: string): string {
  if (productId.startsWith("com.yourdategenie.couple")) return "couple";
  return "premium";
}

// ─── Main handler ────────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    // ── 1. Authenticate the caller via Supabase JWT ──────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: corsHeaders,
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: userErr } = await supabase.auth.getUser();
    if (userErr || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: corsHeaders,
      });
    }

    // ── 2. Parse request body ────────────────────────────────────────────────
    const body = await req.json().catch(() => null);
    if (!body?.transactionJWS || typeof body.transactionJWS !== "string") {
      return new Response(
        JSON.stringify({ error: "Missing or invalid transactionJWS" }),
        { status: 400, headers: corsHeaders },
      );
    }
    const { transactionJWS } = body as { transactionJWS: string };

    // ── 3. Peek at environment field (no trust yet — just picks the verifier) ─
    const rawPayload = peekJwsPayload(transactionJWS);
    const isSandbox = rawPayload.environment === "Sandbox" ||
      rawPayload.environment === "SANDBOX";
    const env = isSandbox ? Environment.SANDBOX : Environment.PRODUCTION;

    // ── 4. Verify JWS signature against Apple's certificate chain ────────────
    //    SignedDataVerifier checks the x5c cert chain, validates it roots to
    //    AppleRootCA-G3, then verifies the JWS signature. Forged payloads fail here.
    const verifier = await getVerifier(env);
    let transaction: Record<string, unknown>;
    try {
      transaction = await verifier.verifyAndDecodeTransaction(
        transactionJWS,
      ) as Record<string, unknown>;
    } catch (verifyErr) {
      console.error("JWS verification failed:", verifyErr);
      return new Response(
        JSON.stringify({ error: "Invalid or unverifiable transaction JWS" }),
        { status: 400, headers: corsHeaders },
      );
    }

    // ── 5. Validate bundle ID matches this app ───────────────────────────────
    const expectedBundleId = Deno.env.get("APPLE_BUNDLE_ID") ??
      "com.yourdategenie.app";
    if (transaction.bundleId !== expectedBundleId) {
      console.error(
        `Bundle ID mismatch: expected ${expectedBundleId}, got ${transaction.bundleId}`,
      );
      return new Response(
        JSON.stringify({ error: "Bundle ID mismatch" }),
        { status: 400, headers: corsHeaders },
      );
    }

    // ── 6. Map to subscription state ─────────────────────────────────────────
    const status = mapToStatus(
      transaction as { revocationDate?: number; expiresDate?: number; offerType?: number },
    );
    const tier = mapToTier(String(transaction.productId ?? ""));
    const originalTransactionId = String(
      transaction.originalTransactionId ?? "",
    );
    const latestTransactionId = String(transaction.transactionId ?? "");

    if (!originalTransactionId) {
      return new Response(
        JSON.stringify({ error: "Missing originalTransactionId in payload" }),
        { status: 400, headers: corsHeaders },
      );
    }

    const expiresDate = typeof transaction.expiresDate === "number"
      ? transaction.expiresDate
      : Date.now() + 30 * 24 * 60 * 60 * 1000;
    const purchaseDate = typeof transaction.purchaseDate === "number"
      ? transaction.purchaseDate
      : Date.now();
    const originalPurchaseDate =
      typeof transaction.originalPurchaseDate === "number"
        ? transaction.originalPurchaseDate
        : purchaseDate;

    // ── 7. Upsert into subscriptions table ───────────────────────────────────
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { error: dbError } = await supabaseAdmin
      .from("subscriptions")
      .upsert(
        {
          user_id: user.id,
          platform: "ios",
          product_id: String(transaction.productId ?? ""),
          original_transaction_id: originalTransactionId,
          latest_transaction_id: latestTransactionId,
          status,
          tier,
          started_at: new Date(originalPurchaseDate).toISOString(),
          current_period_start: new Date(purchaseDate).toISOString(),
          current_period_end: new Date(expiresDate).toISOString(),
          last_verified_at: new Date().toISOString(),
          raw_payload: transaction,
        },
        { onConflict: "platform,original_transaction_id" },
      );

    if (dbError) {
      console.error("DB upsert error:", dbError);
      return new Response(JSON.stringify({ error: "Database error" }), {
        status: 500,
        headers: corsHeaders,
      });
    }

    const isPremium = status === "active" || status === "trialing" ||
      status === "in_grace_period";

    return new Response(
      JSON.stringify({
        isPremium,
        tier,
        status,
        expiresAt: new Date(expiresDate).toISOString(),
      }),
      { status: 200, headers: corsHeaders },
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Internal error";
    console.error("validate-receipt error:", err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: corsHeaders,
    });
  }
});
