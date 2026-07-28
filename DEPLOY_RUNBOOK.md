# Your Date Genie — Production Deploy Runbook (Subscription & Backend Integrity)

> Scope: ships the server-verified subscription system + UGC safety tables + all Edge
> Functions to the **production** Supabase project. Grounded in the actual repo state at
> `/Users/anjelaarora/Downloads/yourdategenie-main`.
>
> **DANGER — production.** Every step here touches the live project, real secrets, the
> App Store Connect account, and live API keys. **Anjela (founder) runs these commands.**
> An agent must never execute `supabase secrets set`, `supabase db push`,
> `supabase functions deploy`, or any anon-key rotation. The commands below are
> copy-paste ready; read each step fully before running it.

- **Supabase project ref:** `jhpwacmsocjmzhimtbxj` (from `supabase/config.toml` → `project_id`, confirmed in `.cursorrules`)
- **iOS bundle id:** `com.yourdategenie.app` (from `ios/YourDateGenie.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER`)
- **StoreKit product ids:** `com.yourdategenie.premium.monthly`, `com.yourdategenie.premium.annual` (from `ios/YourDateGenie/Managers/PurchaseManager.swift` + `ios/YourDateGenie/Products.storekit`)
- **Functions base URL:** `https://jhpwacmsocjmzhimtbxj.supabase.co/functions/v1/<name>`

Set this once in your shell so every command below is copy-pasteable:

```bash
export PROJECT_REF="jhpwacmsocjmzhimtbxj"
```

---

## Edge Functions inventory (what actually exists)

13 functions live in `supabase/functions/`. JWT enforcement is declared in
`supabase/config.toml`; only `apple-notifications-v2` is `verify_jwt = false`.

| Function | gateway JWT | Secrets it reads (beyond auto-injected `SUPABASE_*`) |
|---|---|---|
| `generate-date-plan` | verify | `OPENAI_API_KEY`, `GOOGLE_PLACES_API_KEY` |
| `generate-more-gifts` | verify | `OPENAI_API_KEY` |
| `generate-playlist` | verify | `LASTFM_API_KEY` |
| `rewrite-love-note` | verify | `OPENAI_API_KEY` |
| `send-date-plan-email` | verify | `RESEND_API_KEY` |
| `send-date-plan-sms` | verify | `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER` |
| `notify-new-signup` | verify | `RESEND_API_KEY`, `ADMIN_NOTIFICATION_EMAIL` (optional; falls back to `Anjela.arora@yourdategenie.com`) |
| `send-welcome-email` | verify | `RESEND_API_KEY` |
| `submit-report` | verify | `RESEND_API_KEY` |
| `delete-account` | verify | (only auto-injected `SUPABASE_*`) |
| `import-eventbrite-event` | verify *(also requires a `service_role` JWT inside the function)* | (only auto-injected `SUPABASE_*`) |
| `validate-receipt` | verify | `APPLE_BUNDLE_ID` (optional; falls back to `com.yourdategenie.app`) |
| `apple-notifications-v2` | **NO verify (`--no-verify-jwt`)** | `APPLE_BUNDLE_ID` (optional; falls back to `com.yourdategenie.app`) |

> **Important grounding note (read this):** the Apple functions (`validate-receipt`,
> `apple-notifications-v2`) verify Apple's **JWS signature against the Apple Root CA
> chain that they fetch at runtime** (`@apple/app-store-server-library`). They do **NOT**
> read an App Store Connect API key. There is therefore **no `APPLE_PRIVATE_KEY`,
> `APPLE_KEY_ID`, or `APPLE_ISSUER_ID`** to set for the current code — the only Apple
> secret either function reads is the optional `APPLE_BUNDLE_ID`. (See "Discrepancies"
> at the bottom.)

---

## Prereqs

```bash
# 1. Supabase CLI installed and up to date
supabase --version            # need a recent v1/v2 CLI; upgrade if older than ~1.180

# 2. Log in (opens browser for an access token)
supabase login

# 3. Link this working copy to the production project
cd /Users/anjelaarora/Downloads/yourdategenie-main
supabase link --project-ref "$PROJECT_REF"

# 4. Sanity check you're pointed at the right project
supabase projects list        # confirm jhpwacmsocjmzhimtbxj is the linked (●) project
```

Rollback: `supabase link` is non-destructive — re-run it against a different ref to switch.

---

## Step 1 — Set Edge Function secrets

Set every secret a function reads. **Do not** prefix anything with `SUPABASE_` —
`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are **auto-injected
by the platform** and the CLI rejects user-set secrets with that reserved prefix.

```bash
supabase secrets set --project-ref "$PROJECT_REF" \
  OPENAI_API_KEY="sk-...replace..." \
  GOOGLE_PLACES_API_KEY="AIza...replace..." \
  LASTFM_API_KEY="replace-lastfm-api-key" \
  RESEND_API_KEY="re_...replace..." \
  TWILIO_ACCOUNT_SID="AC...replace..." \
  TWILIO_AUTH_TOKEN="replace-twilio-auth-token" \
  TWILIO_PHONE_NUMBER="+15551234567" \
  ADMIN_NOTIFICATION_EMAIL="Anjela.arora@yourdategenie.com" \
  APPLE_BUNDLE_ID="com.yourdategenie.app"
```

Where each value comes from:

| Secret | Source |
|---|---|
| `OPENAI_API_KEY` | OpenAI dashboard → API keys (used by date-plan / gifts / love-note generation) |
| `GOOGLE_PLACES_API_KEY` | Google Cloud console → Places API + Directions API key (venue validation in `generate-date-plan`) |
| `LASTFM_API_KEY` | last.fm/api/account/create (playlist generation) |
| `RESEND_API_KEY` | Resend dashboard → API keys (all transactional + safety/report email) |
| `TWILIO_ACCOUNT_SID` | Twilio console → Account Info |
| `TWILIO_AUTH_TOKEN` | Twilio console → Account Info |
| `TWILIO_PHONE_NUMBER` | Twilio console → your purchased number, E.164 (e.g. `+15551234567`) |
| `ADMIN_NOTIFICATION_EMAIL` | Optional. Where new-signup notices go; omit to use the in-code fallback |
| `APPLE_BUNDLE_ID` | Optional but recommended. The app bundle id `com.yourdategenie.app`; both Apple functions fall back to this literal if unset |

> `APPLE_BUNDLE_ID` is **not** a `.p8` file — it is just the bundle id string. The current
> code reads no `.p8` / App Store Connect API private key. (If a future change adds the
> App Store Server API, `APPLE_PRIVATE_KEY` would hold the **full contents of the `.p8`
> file** — newlines preserved, e.g. `APPLE_PRIVATE_KEY="$(cat AuthKey_XXXX.p8)"` — alongside
> `APPLE_KEY_ID` and `APPLE_ISSUER_ID`. That is not required by the code in this repo today.)

Verify the names landed (values are never shown):

```bash
supabase secrets list --project-ref "$PROJECT_REF"
```

Rollback: secrets are versioned by the platform. To remove an accidental one:
`supabase secrets unset --project-ref "$PROJECT_REF" NAME`. Re-running `set` overwrites.

---

## Step 2 — Apply database migrations

Migrations live in `supabase/migrations/`. The launch-integrity ones are:

| File | What it creates |
|---|---|
| `20260416000001_auth_users_cascade_delete.sql` | `ON DELETE CASCADE` FKs so `delete-account` hard-delete cleans all user data (GDPR / Apple §5.1.1) |
| `20260429120000_subscriptions_table.sql` | `subscriptions` table, `is_premium()` helper, free-tier RLS caps on `date_plans` (Task 08) |
| `20260429130000_blocked_users_table.sql` | `blocked_users` table + RLS (Apple §1.2) |
| `20260429140000_user_reports_table.sql` | `user_reports` table + RLS (backs `submit-report`, Apple §1.2) |

`supabase db push` applies **all** local migrations not yet recorded on the remote
(not just the four above). Pre-check what will run first:

```bash
# Pre-check: shows Local vs Remote migration versions. Anything Local-only WILL be applied.
supabase migration list --project-ref "$PROJECT_REF"

# Apply. --linked targets the linked project; review the diff it prints before confirming.
supabase db push --linked
```

Rollback: Supabase migrations are forward-only; there is no `db pop` for remote.
Before pushing, take a snapshot: Dashboard → Database → Backups (or `supabase db dump
--linked -f pre_deploy_backup.sql`). To undo a table, write a **new** dated migration that
drops it (e.g. `DROP TABLE public.subscriptions;`) and push that — never edit a shipped
migration file.

---

## Step 3 — Deploy Edge Functions

Deploy with `--project-ref` set. Only `apple-notifications-v2` gets `--no-verify-jwt`
(Apple sends its own JWS, not a Supabase JWT). All others keep gateway JWT verification.

```bash
# ── Subscription / backend integrity (deploy these first) ──────────────────────
supabase functions deploy validate-receipt          --project-ref "$PROJECT_REF"
supabase functions deploy apple-notifications-v2     --project-ref "$PROJECT_REF" --no-verify-jwt

# ── UGC safety (Apple §1.2) ────────────────────────────────────────────────────
supabase functions deploy submit-report             --project-ref "$PROJECT_REF"

# ── Account lifecycle ──────────────────────────────────────────────────────────
supabase functions deploy delete-account            --project-ref "$PROJECT_REF"

# ── AI generation ──────────────────────────────────────────────────────────────
supabase functions deploy generate-date-plan        --project-ref "$PROJECT_REF"
supabase functions deploy generate-more-gifts       --project-ref "$PROJECT_REF"
supabase functions deploy generate-playlist         --project-ref "$PROJECT_REF"
supabase functions deploy rewrite-love-note         --project-ref "$PROJECT_REF"

# ── Notifications / sharing ──────────────────────────────────────────────────────
supabase functions deploy send-date-plan-email      --project-ref "$PROJECT_REF"
supabase functions deploy send-date-plan-sms        --project-ref "$PROJECT_REF"
supabase functions deploy send-welcome-email        --project-ref "$PROJECT_REF"
supabase functions deploy notify-new-signup         --project-ref "$PROJECT_REF"

# ── Admin tooling ────────────────────────────────────────────────────────────────
supabase functions deploy import-eventbrite-event   --project-ref "$PROJECT_REF"
```

> Do **not** pass `--no-verify-jwt` to any function other than `apple-notifications-v2`.
> Doing so would let unauthenticated callers hit OpenAI/Twilio/Resend on your bill.

Rollback: redeploy a known-good version from a prior git commit
(`git checkout <sha> -- supabase/functions/<name> && supabase functions deploy <name>
--project-ref "$PROJECT_REF"`). To disable a function entirely:
`supabase functions delete <name> --project-ref "$PROJECT_REF"`.

---

## Step 4 — App Store Connect (manual, in the web console)

Do this in App Store Connect → your app **Your Date Genie** (`com.yourdategenie.app`).

1. **Subscription group**
   - Go to **Monetization → Subscriptions** → create a group named **Premium** (matches
     `Products.storekit` reference name). Both products live in the same group so users
     can up/downgrade.

2. **Create the two auto-renewable subscriptions** (use the **exact** product ids found in code):

   | Product ID | Reference name | Duration | Price |
   |---|---|---|---|
   | `com.yourdategenie.premium.monthly` | Premium Monthly | 1 month | **$14.99** |
   | `com.yourdategenie.premium.annual` | Premium Annual | 1 year | **$119.99** |

3. **Introductory offer (free trial)** — add to **both** products:
   - Type: **Free**, Duration: **7 days** (`P7D`), one period. (Locked pricing per `.cursorrules`.)

4. **Register the App Store Server Notifications V2 webhook**
   - **Monetization → App Store Server Notifications** (or App Information depending on
     console version).
   - **Production Server URL** and **Sandbox Server URL**:
     ```
     https://jhpwacmsocjmzhimtbxj.supabase.co/functions/v1/apple-notifications-v2
     ```
   - Version: **Version 2** for both Production and Sandbox.

> **Price note:** the local `Products.storekit` test file and App Store Connect must use
> **$14.99 / $119.99** per `.cursorrules`. Enter the real prices in App Store Connect; the
> local file is only for Xcode StoreKit testing and does not affect production.

Rollback: subscriptions can't be deleted once submitted, but you can mark a price/offer
as not-current or remove the introductory offer. The webhook URL can be cleared or
repointed at any time in the console.

---

## Step 5 — Rotate the Supabase anon key

The anon key may have been exposed historically (P0 task 02). Rotate it as the final step
so old, leaked keys stop working.

1. Supabase Dashboard → **Project Settings → API**.
2. Under **Project API keys**, **roll / rotate** the `anon` (public) key.
3. Update the new anon key in:
   - `ios/Secrets.xcconfig` (git-ignored — Anjela edits locally; key is read into
     `Config.swift` via Info.plist substitution. Never hardcode it in source.)
   - CI / build secrets (Xcode Cloud / GitHub Actions env, and Vercel/Netlify env if the
     web app uses it).
4. Rebuild and re-archive the iOS app with the new key before submitting the build.

> ⚠️ **Rotating the anon key immediately invalidates the old key.** Any already-shipped
> client (TestFlight build, web deploy) still using the old key will start getting `401`s
> until it ships with the new key. Rotate right before cutting the build that carries the
> new key — not days earlier. The auto-injected `SUPABASE_ANON_KEY` inside Edge Functions
> updates automatically; you do not re-set it as a secret.

Rollback: there is no "un-rotate." If clients break, the fix-forward is to ship a build
with the new key (or, in an emergency, rotate again and redistribute). Keep the previous
key value noted privately until the new build is confirmed live.

---

## Verification

Run after Steps 1–3. The automated checks live in `scripts/verify_deploy.sh`.

```bash
chmod +x scripts/verify_deploy.sh   # one-time

export PROJECT_REF="jhpwacmsocjmzhimtbxj"
export SUPABASE_ANON_KEY="your-(new)-anon-key"   # the public anon key, used for smoke curls

./scripts/verify_deploy.sh
```

What it (and you) should confirm:

1. **All functions deployed**
   ```bash
   supabase functions list --project-ref "$PROJECT_REF"
   ```
   Expect all 13 names present and ACTIVE.

2. **`validate-receipt` is live and rejecting unauthenticated calls** — a call with **no**
   bearer token must be rejected by the gateway (`401`), proving it's deployed *and*
   JWT-protected (not a `404`/`5xx`):
   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" \
     -X POST "https://$PROJECT_REF.supabase.co/functions/v1/validate-receipt" \
     -H "Content-Type: application/json" -d '{}'
   # Expect: 401
   ```
   With a valid anon key but no user JWT it should still be `401` (function checks
   `auth.getUser`). A real authenticated call with a bogus `transactionJWS` returns `400`.

3. **`apple-notifications-v2` accepts unauthenticated POSTs** (it's `--no-verify-jwt` and
   always returns `200` to Apple, even on a junk body):
   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" \
     -X POST "https://$PROJECT_REF.supabase.co/functions/v1/apple-notifications-v2" \
     -H "Content-Type: application/json" -d '{"signedPayload":"not-a-real-jws"}'
   # Expect: 200  (returns OK; logs a verification-failed warning)
   ```

4. **`subscriptions` table exists with RLS**
   - Dashboard → Table Editor → `public.subscriptions` is present, RLS enabled.
   - Or SQL editor: `SELECT to_regclass('public.subscriptions');` → returns the table name
     (not NULL). Also confirm `blocked_users` and `user_reports` the same way.
   - Confirm helper: `SELECT public.is_premium('00000000-0000-0000-0000-000000000000');` → `false`.

5. **End-to-end Apple webhook** — App Store Connect → App Store Server Notifications →
   **Send Test Notification** (to the production and/or sandbox URL). Then check it landed:
   ```bash
   supabase functions logs apple-notifications-v2 --project-ref "$PROJECT_REF"
   ```
   Expect a log line for the received `TEST` notification (it returns `200`; with no
   matching subscription row it logs "no subscription row …", which is expected for a test).

Rollback for verification: read-only — nothing to undo. The smoke curls send no real data.

---

## Discrepancies found while grounding this runbook

1. **No App Store Connect API key secrets are used.** The brief assumed `APPLE_*` secrets
   (e.g. an App Store Connect API `.p8`). In the actual code, `validate-receipt` and
   `apple-notifications-v2` verify Apple's JWS via the **Apple Root CA chain fetched at
   runtime** and read **only the optional `APPLE_BUNDLE_ID`**. There is no
   `APPLE_PRIVATE_KEY` / `APPLE_KEY_ID` / `APPLE_ISSUER_ID` in any function. Step 1 reflects
   the real secret list.
2. **`SUPABASE_URL` / `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY` are auto-injected**
   by the platform and cannot be set via `supabase secrets set` (reserved prefix). They're
   listed as function inputs above only for completeness.
3. **StoreKit local prices ≠ launch prices.** `ios/YourDateGenie/Products.storekit` shows
   placeholder `$4.99` (monthly) / `$49.99` (annual). The real App Store Connect prices are
   `$14.99` / `$119.99` (per `.cursorrules`). Product ids and the `P7D` free trial match.
4. **`import-eventbrite-event` is double-gated.** `config.toml` sets `verify_jwt = true`,
   **and** the function additionally requires the caller's JWT `role` to be `service_role`.
   A normal user token passes the gateway but gets a `403` from the function body — expected,
   not a deploy failure.
5. **Mixed CORS origins (informational).** `validate-receipt`, `apple-notifications-v2`, and
   `submit-report` restrict `Access-Control-Allow-Origin` to `https://yourdategenie.com`;
   the other functions use `*`. iOS callers don't send `Origin`, so this only affects any
   web callers. No action needed for this deploy.
