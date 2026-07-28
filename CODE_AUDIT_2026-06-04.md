# Your Date Genie — Full Code Audit
**Date:** 2026-06-04 · **Scope:** iOS app (112 Swift files, ~44.6k LOC) · Supabase backend (13 edge functions, 47 migrations) · web scaffold (deprecated) · secrets & git hygiene

---

## The headline (read this if you read nothing else)

**Your app is in better shape than your gut is telling you.** The architecture is security-conscious and the hard things are done right: AI keys live server-side, payments use StoreKit 2 with real receipt validation, account deletion works, and your database has Row-Level Security on every user table. The "it's not ready" feeling is mostly UI/UX complexity — not rot underneath.

**But there are 5 things that genuinely block a clean launch.** None are big. One you must do *today* regardless of everything else: rotate a leaked API key.

**Verdict by area:**

| Area | Grade | One-line |
|------|-------|----------|
| iOS architecture | 🟢 Solid | Clean MVVM-ish, Keychain tokens, server-side AI keys |
| Payments / StoreKit | 🟢 Done right | Server-side JWS receipt validation, no Stripe keys on device |
| Backend / RLS | 🟢 Sound | RLS on all user tables, account deletion works |
| Secrets hygiene | 🔴 One leak | OpenAI key in git history — rotate today |
| App Store readiness | 🟡 Close | Missing 1 required file + a cost-bomb to gate |
| Tests | 🔴 None | Zero tests — acceptable for v1 but a known risk |

---

## 🔴 P0 — Must clear before launch

### 1. A live OpenAI API key is sitting in your git history → **ROTATE TODAY**
`ios/YourDateGenie/Secrets.xcconfig` was committed in two past commits (`4506ca2`, `428e42d`) containing a real `OPENAI_API_KEY = sk-…` plus a Google Places billing key. The file is gitignored *now* and gone from the working tree — but **gitignore doesn't erase history.** Anyone who clones the repo can pull the key out of an old commit and run up your OpenAI bill.

- **Fix (10 min, do this first):** Go to platform.openai.com → API keys → revoke the old key → create a new one → put it in your Supabase function secrets (not the repo). Same for the Google Places key in Google Cloud Console.
- You do *not* need to rewrite git history (painful with 144 pending changes). Rotating the keys makes the leaked ones worthless — that's the faster, safer fix.

### 2. Missing `PrivacyInfo.xcprivacy` manifest → **guaranteed App Store rejection**
Apple has required this file since May 2024 for any app using "required-reason" APIs (you use UserDefaults, location, calendar, photos). It does not exist anywhere in `ios/`. Submitting without it = automatic rejection.
- **Fix:** Add a privacy manifest declaring your data types + API reasons. ~30 min in Xcode. I can generate the exact file for you.

### 3. `generate-date-plan` is a public, unauthenticated cost-bomb
This edge function has `verify_jwt = false`, no rate limit, no per-user throttle, and open CORS (`*`). Every call fans out to OpenAI **and** Google Places **and** Directions — all paid. Anyone who finds the URL can loop it and drain your API budget. With an empty waitlist this hasn't bitten you; the day you get traffic (or an abuser), it will.
- **Fix:** Add a rate limiter (per-IP or per-device), a hard request cap, or require the anon JWT. Highest-leverage backend fix.

### 4. Live Google API key is baked into the shipped binary
Separate from the git leak: the Google key in `Secrets.xcconfig:8` gets compiled into the app bundle, so anyone can extract it from the IPA. You **cannot** hide a client-side Google key — but you can defang it.
- **Fix:** In Google Cloud Console, restrict the key to your iOS bundle ID + only the Places/Geocoding APIs you actually use.

### 5. 94 `print()` statements ship in release builds (some log user IDs)
14 files, 36 in `SupabaseService.swift`. Several log auth flow and user IDs (e.g. `SupabaseService.swift:250`, `:1474`). You already have an `AppLogger` that strips debug logs in release — these just bypass it, leaking PII to the device console.
- **Fix:** Find/replace `print(` → `AppLogger.debug(`. Mostly mechanical. I can script it.

---

## 🟡 P1 — Fix soon (not strictly blocking)

| # | Finding | Where | Action |
|---|---------|-------|--------|
| 6 | **Verify the 4/16 RLS migration actually applied to the live DB.** A malformed filename (`20260416_000000_…`, extra underscore) is the parked CLI history mismatch. That exact file is what re-scopes the partner-planning tables from `USING(true)` (wide open) to `auth.uid()`-scoped. If the history repair skipped it, those tables are world-readable in production. | `supabase/migrations/` | Verify in the live dashboard, not just the repo. **Data-exposure risk if it didn't apply.** |
| 7 | **Zero tests.** `PurchaseManager` entitlement logic and `SupabaseService` auth are completely unverified for a paid app. | `ios/` | Add a handful of unit tests on payment + auth before scaling users. |
| 8 | **God-object: `SupabaseService.swift` (2093 lines)** owns auth, OAuth, CRUD for ~10 entities, 6 function calls, receipts, reporting, uploads. | `SupabaseService.swift` | Post-launch: split into Auth / Database / Functions services. |
| 9 | **5 view files >1,400 lines** mixing logic + presentation (PartnerPlanningSheet 1632, HomeTab 1587, DatePlanOptions 1568, GiftFinder 1541, PlaylistWidget 1482). **This is the source of your "UI/UX got complex" feeling.** | `ios/.../Views/` | Extract view models. This is the cleanup that will make the app feel simpler to work on. |
| 10 | **23 force-unwrapped `URL(string:)!`** — a malformed URL crashes the app. | mostly `SupabaseService.swift` | Convert to `guard let`. |
| 11 | **144 uncommitted changes, last commit 6 weeks ago (4/25).** Nothing dangerous in the set, but real risk of losing 6 weeks of work. | repo | Commit soon to de-risk. |

---

## ⚪ P2 — Hygiene (post-launch)

- App Check not enforced — `VITE_RECAPTCHA_SITE_KEY` is empty (Firebase waitlist is unprotected from bots).
- `xcuserdata` committed — should be gitignored.
- Two lockfiles (`bun.lockb` + `package-lock.json`) — pick one.
- Loose `v5-test.html` / `v6-test.html` with public Firebase key — delete to avoid accidental commits.
- Web scaffold in `src/` is confirmed deprecated (no live secrets, won't auto-deploy) — safe to delete after launch.
- Seed events with generic eventbrite URLs — clean before launch (a migration to remove them already exists).

---

## 🟢 What's already done right (don't touch, don't worry)

- **AI keys are NOT on the client** — all generation routes through Supabase Edge Functions where keys live server-side. This is the right architecture.
- **StoreKit 2 with server-side JWS receipt validation** (`validate-receipt`) — forged receipts fail Apple cert-chain verification. No Stripe keys on device.
- **Account deletion works** (`delete-account` hard-deletes + cascades) — satisfies the App Store requirement that rejects most first-timers.
- **RLS enabled on every user-data table** (`profiles`, `date_plans`, `subscriptions`, etc.) scoped to `auth.uid()`.
- **Tokens in Keychain**, ATS locked down (exception scoped to supabase.co only), privacy usage strings present and well-written, version 1.0 / build 1 correct.

---

## The punch list, in order

1. 🔴 **Rotate the OpenAI + Google keys** (10 min) — today, non-negotiable.
2. 🔴 **Add `PrivacyInfo.xcprivacy`** (30 min) — or you can't submit.
3. 🔴 **Gate `generate-date-plan`** with a rate limit (1–2 hrs).
4. 🔴 **Restrict the Google key** in Cloud Console (15 min).
5. 🔴 **Strip the 94 `print()`s** (30 min, scriptable).
6. 🟡 **Verify the 4/16 RLS migration** is live (15 min).
7. 🟡 **Commit your 144 changes** (15 min).

**That's roughly one focused day of work between you and a clean, submittable build.** Items 8–11 (refactors, tests) make the app nicer to maintain but do not block launch — do them after you're live and learning from real users.

*I can knock out #1, #2, #4, #5, #6, #7 with you in a single working session — most are mechanical or just need your dashboard login. Say the word.*
