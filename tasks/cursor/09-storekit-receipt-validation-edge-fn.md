# Cursor Task — StoreKit 2 receipt validation Edge Function + Apple S2S webhook

**Owner:** Anjela (executing in Cursor)
**Specced by:** backend-developer agent
**Priority:** P0 — without server-side validation, premium state is exploitable
**Estimated effort:** 4–5 hours
**Depends on:** Task 08 (subscriptions table) must be done first

---

## Context for Cursor

Currently, premium state is whatever the iOS client says it is. We need:
1. iOS sends the StoreKit 2 transaction JWS to the backend after every purchase / restore
2. Backend verifies the JWS against Apple's signing keys and writes verified state to `subscriptions` table
3. Apple sends Server-to-Server Notifications V2 (renewals, cancellations, refunds, etc.) directly to a webhook on our backend, which updates the `subscriptions` table without iOS involvement
4. Every backend feature that gates on premium reads from `subscriptions`, never trusts the client

This task creates two Edge Functions: `validate-receipt` (called by iOS) and `apple-notifications-v2` (called by Apple).

---

## Locked decisions

- **Product IDs in App Store Connect:**
  - `com.yourdategenie.premium.monthly` — $14.99/mo
  - `com.yourdategenie.premium.annual` — $99.99/yr
  - (Configure these in App Store Connect → Subscriptions before testing)
- **Apple environment URLs:**
  - Sandbox JWS verification: certificates from `https://www.apple.com/certificateauthority/AppleRootCA-G3.cer` (root) + Apple's intermediate
  - App Store Server API base: `https://api.storekit.itunes.apple.com/inApps/v1/` (production), `https://api.storekit-sandbox.itunes.apple.com/inApps/v1/` (sandbox)

---

## Task breakdown

### Step 1 — Set Apple credentials in Supabase secrets

Apple App Store Server API uses an issuer + key ID + private key (.p8 file). Generate in App Store Connect → Users and Access → Keys → In-App Purchase.

```bash
supabase secrets set APPLE_ISSUER_ID=<your issuer ID> --project-ref jhpwacmsocjmzhimtbxj
supabase secrets set APPLE_KEY_ID=<your key ID> --project-ref jhpwacmsocjmzhimtbxj
supabase secrets set APPLE_PRIVATE_KEY="$(cat AuthKey_XXXXX.p8)" --project-ref jhpwacmsocjmzhimtbxj
supabase secrets set APPLE_BUNDLE_ID=com.yourdategenie.app --project-ref jhpwacmsocjmzhimtbxj
```

(Confirm exact bundle ID from `ios/Info.plist` — `CFBundleIdentifier`.)

### Step 2 — Create `validate-receipt` Edge Function

`supabase/functions/validate-receipt/index.ts`

Accepts POST with `{ "transactionJWS": string }` — the JWS string from `Transaction.currentEntitlements` in iOS. Returns the parsed and verified subscription state.

Use the `app-store-server-api` npm package OR roll your own JWS verification with `jose` (Deno-compatible). Recommended approach for reliability:

```typescript
import { decodeJwt, jwtVerify, createRemoteJWKSet } from 'npm:jose@5'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Apple's public keys for JWS verification
const APPLE_JWKS_URL = 'https://api.storekit.itunes.apple.com/inApps/v1/publicKeys'  // or fetch via App Store Server API

Deno.serve(async (req) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

    try {
        const authHeader = req.headers.get('Authorization')
        if (!authHeader) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders })

        // Verify the user's Supabase JWT and get their user_id
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )
        const { data: { user }, error: userErr } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''))
        if (userErr || !user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders })

        const { transactionJWS } = await req.json()
        if (!transactionJWS) return new Response(JSON.stringify({ error: 'Missing transactionJWS' }), { status: 400, headers: corsHeaders })

        // Verify JWS signature against Apple's keys
        // (Apple's signing certs come from the JWS x5c header — verify the chain against AppleRootCA-G3)
        const verifiedPayload = await verifyAppleJWS(transactionJWS)

        // Validate bundle ID matches
        if (verifiedPayload.bundleId !== Deno.env.get('APPLE_BUNDLE_ID')) {
            return new Response(JSON.stringify({ error: 'Invalid bundle ID' }), { status: 400, headers: corsHeaders })
        }

        // Map to subscription record
        const status = mapAppleStateToStatus(verifiedPayload)
        const tier = mapProductIdToTier(verifiedPayload.productId)

        // Upsert subscriptions row
        const { error: dbError } = await supabase
            .from('subscriptions')
            .upsert({
                user_id: user.id,
                platform: 'ios',
                product_id: verifiedPayload.productId,
                original_transaction_id: String(verifiedPayload.originalTransactionId),
                latest_transaction_id: String(verifiedPayload.transactionId),
                status,
                tier,
                started_at: new Date(verifiedPayload.originalPurchaseDate).toISOString(),
                current_period_start: new Date(verifiedPayload.purchaseDate).toISOString(),
                current_period_end: new Date(verifiedPayload.expiresDate).toISOString(),
                last_verified_at: new Date().toISOString(),
                raw_payload: verifiedPayload,
            }, { onConflict: 'platform,original_transaction_id' })

        if (dbError) {
            console.error('DB upsert error:', dbError)
            return new Response(JSON.stringify({ error: 'Database error' }), { status: 500, headers: corsHeaders })
        }

        return new Response(JSON.stringify({
            isPremium: status === 'active' || status === 'trialing' || status === 'in_grace_period',
            tier,
            expiresAt: new Date(verifiedPayload.expiresDate).toISOString(),
        }), { status: 200, headers: corsHeaders })

    } catch (err) {
        console.error(err)
        return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: corsHeaders })
    }
})

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Content-Type': 'application/json',
}

function mapAppleStateToStatus(payload: any): string {
    // Apple transaction status codes; consult JWSTransactionDecodedPayload spec
    if (payload.revocationDate) return 'revoked'
    if (payload.expiresDate < Date.now()) return 'expired'
    if (payload.offerType === 1 /* introductory */) return 'trialing'
    return 'active'
}

function mapProductIdToTier(productId: string): string {
    if (productId.startsWith('com.yourdategenie.couple')) return 'couple'
    return 'premium'
}

async function verifyAppleJWS(jws: string): Promise<any> {
    // Parse the JWS, extract x5c cert chain, verify chain roots to AppleRootCA-G3,
    // verify signature, return decoded payload.
    // Recommended: use the official 'app-store-server-library' package for Node:
    //   import { SignedDataVerifier } from 'npm:@apple/app-store-server-library'
    // It handles certificate verification and gives you a typed payload.
    throw new Error('Implement using @apple/app-store-server-library SignedDataVerifier')
}
```

**Cursor: do NOT skip the JWS signature verification.** The JWS payload is trivially decodable without verification — but if you skip verification, an attacker can forge any payload. Use Apple's `@apple/app-store-server-library` package which handles this correctly.

### Step 3 — Tighten the CORS origin

Replace `'Access-Control-Allow-Origin': '*'` with `'Access-Control-Allow-Origin': 'https://yourdategenie.com'` for the web app, and rely on iOS apps not needing CORS at all. (If iOS calls fail with CORS, it's a config issue elsewhere — iOS doesn't send Origin headers normally.)

For all 9 existing Edge Functions, do the same hardening pass (separate sub-task — flag it but don't block on it).

### Step 4 — Create `apple-notifications-v2` Edge Function

`supabase/functions/apple-notifications-v2/index.ts`

This receives Apple's Server-to-Server Notifications V2. Apple POSTs a `signedPayload` JWS that contains the notification type + signed transaction info.

```typescript
Deno.serve(async (req) => {
    if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 })

    try {
        const { signedPayload } = await req.json()
        if (!signedPayload) return new Response('Missing signedPayload', { status: 400 })

        // Verify and decode (same JWS verification as receipt validation)
        const payload = await verifyAppleJWS(signedPayload)
        // payload contains: notificationType, subtype, data.signedTransactionInfo, data.signedRenewalInfo, ...

        const transactionInfo = await verifyAppleJWS(payload.data.signedTransactionInfo)
        const renewalInfo = payload.data.signedRenewalInfo
            ? await verifyAppleJWS(payload.data.signedRenewalInfo)
            : null

        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )

        // Look up the user by original_transaction_id (must already exist from initial validate-receipt call)
        const { data: existingSub } = await supabase
            .from('subscriptions')
            .select('user_id')
            .eq('platform', 'ios')
            .eq('original_transaction_id', String(transactionInfo.originalTransactionId))
            .maybeSingle()

        if (!existingSub) {
            // First time we've seen this — log it but don't fail. Apple may notify before iOS posts the receipt.
            console.warn('Notification for unknown transaction:', transactionInfo.originalTransactionId)
            return new Response('OK', { status: 200 })
        }

        // Map notificationType to subscription status update
        const statusUpdate = mapNotificationToStatus(payload.notificationType, payload.subtype, transactionInfo)

        await supabase
            .from('subscriptions')
            .update({
                status: statusUpdate.status,
                current_period_end: new Date(transactionInfo.expiresDate).toISOString(),
                latest_transaction_id: String(transactionInfo.transactionId),
                cancelled_at: statusUpdate.cancelled_at,
                revoked_at: statusUpdate.revoked_at,
                last_verified_at: new Date().toISOString(),
                raw_payload: { notification: payload, transaction: transactionInfo, renewal: renewalInfo },
            })
            .eq('platform', 'ios')
            .eq('original_transaction_id', String(transactionInfo.originalTransactionId))

        // Always return 200 to Apple — non-200 makes Apple retry forever
        return new Response('OK', { status: 200 })

    } catch (err) {
        console.error('Apple notification error:', err)
        // STILL return 200 if it's a parse error — Apple retries on non-200
        return new Response('OK', { status: 200 })
    }
})

function mapNotificationToStatus(notificationType: string, subtype: string | undefined, transaction: any) {
    // Apple notificationType values: SUBSCRIBED, DID_RENEW, DID_FAIL_TO_RENEW, EXPIRED,
    // GRACE_PERIOD_EXPIRED, REFUND, REVOKE, DID_CHANGE_RENEWAL_STATUS, etc.
    switch (notificationType) {
        case 'SUBSCRIBED':
        case 'DID_RENEW':
            return { status: 'active', cancelled_at: null, revoked_at: null }
        case 'EXPIRED':
        case 'GRACE_PERIOD_EXPIRED':
            return { status: 'expired', cancelled_at: null, revoked_at: null }
        case 'DID_FAIL_TO_RENEW':
            return { status: 'in_grace_period', cancelled_at: null, revoked_at: null }
        case 'REFUND':
        case 'REVOKE':
            return { status: 'revoked', cancelled_at: null, revoked_at: new Date().toISOString() }
        case 'DID_CHANGE_RENEWAL_STATUS':
            // subtype tells us if user turned auto-renew off
            return subtype === 'AUTO_RENEW_DISABLED'
                ? { status: 'active', cancelled_at: new Date().toISOString(), revoked_at: null }
                : { status: 'active', cancelled_at: null, revoked_at: null }
        default:
            return { status: 'active', cancelled_at: null, revoked_at: null }
    }
}
```

### Step 5 — Register the webhook URL with Apple

Anjela manual step:
1. Go to App Store Connect → Apps → Your Date Genie → App Information → App Store Server Notifications
2. Set the Production Server URL to: `https://jhpwacmsocjmzhimtbxj.supabase.co/functions/v1/apple-notifications-v2`
3. Set the Sandbox Server URL to the same (Apple uses the same URL but flags it as sandbox in the payload)
4. Set Notifications Version to "Version 2"

### Step 6 — Deploy both functions

```bash
supabase functions deploy validate-receipt --project-ref jhpwacmsocjmzhimtbxj
supabase functions deploy apple-notifications-v2 --project-ref jhpwacmsocjmzhimtbxj --no-verify-jwt
```

The `--no-verify-jwt` on the webhook is important — Apple does NOT send a Supabase user JWT, so JWT verification at the Supabase gateway must be disabled for that function. The function instead verifies Apple's JWS signature internally.

### Step 7 — iOS: Call `validate-receipt` after every purchase / restore

In `ios/YourDateGenie/Managers/SubscriptionManager.swift` (or wherever StoreKit 2 listener lives), after a successful `Transaction.updates` event:

```swift
for await result in Transaction.updates {
    switch result {
    case .verified(let transaction):
        // Get the JWS string
        let jwsString = transaction.jsonRepresentation
        // Or: let jwsString = result.payloadValue (depends on API version)

        // POST to validate-receipt
        do {
            let response = try await SupabaseService.shared.client.functions.invoke(
                "validate-receipt",
                options: FunctionInvokeOptions(body: ["transactionJWS": jwsString])
            )
            // Update local UI based on response
            await transaction.finish()
        } catch {
            // Don't finish() — let StoreKit retry
            print("Receipt validation failed: \(error)")
        }

    case .unverified(_, let error):
        print("Unverified transaction: \(error)")
    }
}
```

### Step 8 — Replace client-side `isPremium` checks with server query

Anywhere in iOS that reads `Config.isPremium` or similar local flag, replace with a query against the `subscriptions` table:

```swift
let { data, error } = await client.from("subscriptions")
    .select("status, tier, current_period_end")
    .eq("user_id", userId)
    .in("status", ["active", "trialing", "in_grace_period"])
    .single()

let isPremium = data != nil && Date(timeIntervalSince1970: data.current_period_end) > Date()
```

Cache the result in memory for the session — re-query on app launch + every paywall view.

---

## Verification checklist

- [ ] `validate-receipt` deploys cleanly
- [ ] `apple-notifications-v2` deploys with `--no-verify-jwt`
- [ ] Apple Sandbox server URL is set in App Store Connect
- [ ] Webhook URL responds 200 to a manual Apple test ping (App Store Connect has a "Send Test Notification" button)
- [ ] Buying a subscription in StoreKit sandbox creates a `subscriptions` row with `status = 'active'`
- [ ] Cancelling auto-renew in sandbox triggers a notification → `cancelled_at` is set in the row
- [ ] Letting the sandbox subscription expire triggers a notification → `status` flips to `'expired'`
- [ ] `is_premium()` SQL function returns true for active sub user, false otherwise
- [ ] iOS UI correctly gates premium features based on the server-side query, not local state
- [ ] Forging a transaction JWS (modifying the payload but not re-signing) is rejected by `validate-receipt`

## Out of scope

- Web app subscription flow (we don't sell on web at v1)
- Android Play Billing webhooks → post-launch
- Refund handling UX (just record it; no automatic emails or ban logic for v1)
- Family Sharing complexity (v1 is single-user only)

## When you're done

Tell me ("chief-of-staff, receipt validation done") and I'll mark P0 #7 as complete.
