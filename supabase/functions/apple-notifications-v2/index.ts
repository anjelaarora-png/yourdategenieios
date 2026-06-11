// apple-notifications-v2 — Apple App Store Server Notifications V2 webhook
//
// Deployed with --no-verify-jwt because Apple does NOT send a Supabase JWT.
// Security comes from verifying Apple's own JWS signature on the signedPayload.
//
// Register this URL in App Store Connect → Apps → Your Date Genie →
//   App Information → App Store Server Notifications:
//   https://jhpwacmsocjmzhimtbxj.supabase.co/functions/v1/apple-notifications-v2
// Set version to "Version 2" for both Production and Sandbox.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  Environment,
  SignedDataVerifier,
} from "npm:@apple/app-store-server-library@2";

// ─── Apple Root CA certificates — module-level cache ────────────────────────
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

function peekJwsPayload(jws: string): Record<string, unknown> {
  const parts = jws.split(".");
  if (parts.length !== 3) throw new Error("Invalid JWS format");
  const padded = parts[1].replace(/-/g, "+").replace(/_/g, "/").padEnd(
    Math.ceil(parts[1].length / 4) * 4,
    "=",
  );
  return JSON.parse(atob(padded));
}

// ─── Notification type → subscription status ────────────────────────────────
function mapNotificationToStatus(
  notificationType: string,
  subtype: string | undefined,
): { status: string; cancelled_at: string | null; revoked_at: string | null } {
  const now = new Date().toISOString();
  switch (notificationType) {
    case "SUBSCRIBED":
    case "DID_RENEW":
      return { status: "active", cancelled_at: null, revoked_at: null };
    case "EXPIRED":
    case "GRACE_PERIOD_EXPIRED":
      return { status: "expired", cancelled_at: null, revoked_at: null };
    case "DID_FAIL_TO_RENEW":
      return {
        status: "in_grace_period",
        cancelled_at: null,
        revoked_at: null,
      };
    case "REFUND":
    case "REVOKE":
      return { status: "revoked", cancelled_at: null, revoked_at: now };
    case "DID_CHANGE_RENEWAL_STATUS":
      return {
        status: "active",
        cancelled_at: subtype === "AUTO_RENEW_DISABLED" ? now : null,
        revoked_at: null,
      };
    default:
      // Unknown types default to active — they may be new notification types
      // introduced by Apple. Log and continue; don't flip status on unknown.
      return { status: "active", cancelled_at: null, revoked_at: null };
  }
}

// ─── Main handler ────────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  // Apple always returns 200 to the webhook; non-200 triggers indefinite retries.
  // We MUST return 200 even for parse errors after the body is read.
  const ok200 = () => new Response("OK", { status: 200 });

  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  let body: { signedPayload?: string } | null = null;
  try {
    body = await req.json();
  } catch {
    console.error("apple-notifications-v2: failed to parse JSON body");
    return ok200();
  }

  if (!body?.signedPayload || typeof body.signedPayload !== "string") {
    console.error("apple-notifications-v2: missing signedPayload");
    return ok200();
  }

  try {
    // ── 1. Peek at environment to choose verifier ────────────────────────────
    const rawNotification = peekJwsPayload(body.signedPayload);
    const rawData = rawNotification.data as Record<string, unknown> | undefined;
    const envStr = String(rawData?.environment ?? rawNotification.environment ?? "PRODUCTION");
    const isSandbox = envStr === "Sandbox" || envStr === "SANDBOX";
    const env = isSandbox ? Environment.SANDBOX : Environment.PRODUCTION;

    // ── 2. Verify signedPayload JWS signature ───────────────────────────────
    const verifier = await getVerifier(env);
    let notification: Record<string, unknown>;
    try {
      notification = await verifier.verifyAndDecodeNotification(
        body.signedPayload,
      ) as Record<string, unknown>;
    } catch (verifyErr) {
      console.error("apple-notifications-v2: JWS verification failed:", verifyErr);
      return ok200();
    }

    const notificationType = String(notification.notificationType ?? "");
    const subtype = notification.subtype != null
      ? String(notification.subtype)
      : undefined;

    const data = notification.data as Record<string, unknown> | undefined;
    if (!data?.signedTransactionInfo) {
      console.warn("apple-notifications-v2: no signedTransactionInfo in notification");
      return ok200();
    }

    // ── 3. Verify and decode the inner transaction JWS ───────────────────────
    let transactionInfo: Record<string, unknown>;
    try {
      transactionInfo = await verifier.verifyAndDecodeTransaction(
        String(data.signedTransactionInfo),
      ) as Record<string, unknown>;
    } catch (e) {
      console.error("apple-notifications-v2: failed to verify transaction JWS:", e);
      return ok200();
    }

    // ── 4. Optionally decode renewal info (not required for all types) ───────
    let renewalInfo: Record<string, unknown> | null = null;
    if (data.signedRenewalInfo) {
      try {
        renewalInfo = await verifier.verifyAndDecodeRenewalInfo(
          String(data.signedRenewalInfo),
        ) as Record<string, unknown>;
      } catch {
        // Non-fatal — proceed without renewal info
      }
    }

    const originalTransactionId = String(
      transactionInfo.originalTransactionId ?? "",
    );
    if (!originalTransactionId) {
      console.warn("apple-notifications-v2: missing originalTransactionId");
      return ok200();
    }

    // ── 5. Look up existing subscription row by originalTransactionId ────────
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: existingSub } = await supabase
      .from("subscriptions")
      .select("user_id, status")
      .eq("platform", "ios")
      .eq("original_transaction_id", originalTransactionId)
      .maybeSingle();

    if (!existingSub) {
      // Apple may notify before the iOS client has posted a receipt (e.g. introductory
      // offer granted server-side). Log and return 200 — the iOS client will create the
      // row when it calls validate-receipt after the purchase is confirmed locally.
      console.warn(
        `apple-notifications-v2: no subscription row for originalTransactionId ${originalTransactionId}. Notification type: ${notificationType}`,
      );
      return ok200();
    }

    // ── 6. Update subscription state ─────────────────────────────────────────
    const { status, cancelled_at, revoked_at } = mapNotificationToStatus(
      notificationType,
      subtype,
    );

    const expiresDate = typeof transactionInfo.expiresDate === "number"
      ? transactionInfo.expiresDate
      : null;

    const updatePayload: Record<string, unknown> = {
      status,
      latest_transaction_id: String(transactionInfo.transactionId ?? ""),
      last_verified_at: new Date().toISOString(),
      raw_payload: {
        notification,
        transaction: transactionInfo,
        renewal: renewalInfo,
      },
    };
    if (expiresDate) {
      updatePayload.current_period_end = new Date(expiresDate).toISOString();
    }
    if (cancelled_at !== null) updatePayload.cancelled_at = cancelled_at;
    if (revoked_at !== null) updatePayload.revoked_at = revoked_at;

    const { error: updateError } = await supabase
      .from("subscriptions")
      .update(updatePayload)
      .eq("platform", "ios")
      .eq("original_transaction_id", originalTransactionId);

    if (updateError) {
      console.error(
        `apple-notifications-v2: DB update error for ${originalTransactionId}:`,
        updateError,
      );
    } else {
      console.log(
        `apple-notifications-v2: updated ${originalTransactionId} → status=${status} (${notificationType}${subtype ? "/" + subtype : ""})`,
      );
    }

    return ok200();
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("apple-notifications-v2: unhandled error:", message);
    // Always return 200 — non-200 causes Apple to retry indefinitely
    return ok200();
  }
});
