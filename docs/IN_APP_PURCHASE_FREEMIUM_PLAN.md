# In-App Purchase & Freemium Implementation Plan

**Goal:** Add a **monthly subscription only** with a freemium model. New users get a **7-day free trial** with full premium access; after 7 days the monthly subscription starts charging. Free (non-subscribed) users get limited usage.

---

## 1. Freemium Model (Recommendation)

| Aspect | Free | Premium (Monthly) |
|--------|------|-------------------|
| **Date plans** | 1 plan per month (or 1 one-time trial) | Unlimited |
| **Plan options** | 1 option only | 3 options (current behavior) |
| **Gift finder** | Limited (e.g. 1 search or locked) | Full access |
| **Love notes** | 1 per month or locked | Unlimited |
| **Saved plans** | Last 1–2 saved | Unlimited (current) |
| **Memories** | Limited (e.g. 5) or full | Full |
| **Playbook / Explore** | Optional: free | Optional: premium |

**Suggested default:**  
- **Free (no subscription):** 1 date plan generation per month; 1 plan option; gift finder and love notes locked or heavily limited.  
- **7-day free trial:** Full premium access for 7 days—no charge. After 7 days, Apple automatically starts the monthly subscription charge unless the user cancels.  
- **Premium (paying):** Same as trial—unlimited plans, 3 options, full gifts + love notes + memories.

You can tune the free tier (e.g. “first plan free forever” vs “1 plan per calendar month”) based on conversion goals.

---

## 2. High-Level Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  iOS App        │────▶│  Apple StoreKit 2 │────▶│  App Store      │
│  (Swift)        │     │  (or RevenueCat)  │     │  Connect        │
└────────┬────────┘     └─────────┬──────────┘     └─────────────────┘
         │                        │
         │  Sync entitlement      │  Server Notifications (optional)
         ▼                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Supabase                                                           │
│  - profiles.subscription_status, period_end, product_id              │
│  - Or: subscription_entitlements table (user_id, product_id,        │
│         expires_at, source: 'apple' | 'revenuecat')                 │
└─────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Edge / Backend │  (optional) Validate receipt or RevenueCat webhook
│  (Supabase Fn)  │  and set subscription_entitlements
└─────────────────┘
```

- **iOS:** Use **StoreKit 2** for purchase and subscription status. Optionally add **RevenueCat** for cross-platform entitlement and analytics.
- **Backend:** Store “is premium” and expiry in Supabase (profile or dedicated table). Optionally validate receipts or rely on RevenueCat webhooks to keep DB in sync.
- **Web app:** If you later add paid web, use Stripe (or similar) and the same Supabase entitlement so one subscription can apply to both (handled later).

---

## 3. App Store Connect Setup

1. **Agreements & banking**
   - Sign **Paid Applications** and **In-App Purchase** agreements.
   - Add banking and tax info.

2. **In-App Purchase product**
   - **Type:** Auto-Renewable Subscription.
   - **Reference name:** e.g. “Your Date Genie Premium”.
   - **Product ID:** e.g. `com.yourdategenie.premium.monthly` (must match code).
   - **Subscription group:** Create one group, e.g. “Premium”. (Only one product for now; group still required.)
   - **Price:** Set monthly price (e.g. $4.99–$9.99).
   - **Duration:** 1 month.
   - **Free trial (optional):** 7-day or 1-month trial to improve conversion.

3. **App Store Connect → App → App Information**
   - Enable **In-App Purchase** capability for the app.

4. **Sandbox testers**
   - Create Sandbox Apple IDs in Users and Access → Sandbox → Testers. Use these on device to test purchases without being charged.

---

## 4. iOS Implementation (StoreKit 2)

### 4.1 Xcode

- **Signing & Capabilities:** Add **In-App Purchase**.
- No extra SPM dependency for StoreKit 2 (built-in).

### 4.2 New / updated files

| File | Purpose |
|------|--------|
| `Managers/SubscriptionManager.swift` | Load products, purchase, restore, observe current entitlements (StoreKit 2). |
| `Models/SubscriptionModels.swift` | Product ID constant, subscription state enum (none, premium, expired, etc.). |
| `Views/Subscription/PaywallView.swift` | Paywall UI: benefits, price, Subscribe + Restore. |
| `Views/Subscription/SubscriptionGateView.swift` | Wrapper that shows paywall when action requires premium. |
| Update `Config.swift` or `Secrets` | Product ID string (e.g. from xcconfig). |

### 4.3 SubscriptionManager responsibilities

- **Product ID:** Single constant, e.g. `com.yourdategenie.premium.monthly`.
- **Fetch product:** `Product.products(for: [productId])`. The returned `Product` will include introductory offer info (e.g. 7-day free); the system purchase sheet shows “7 days free, then $X/month” automatically.
- **Purchase:** `Product.purchase()` and handle `Transaction` result. During the 7-day trial the user is not charged; `Transaction` still appears and the user is “entitled” just like a paying subscriber. On success, update local state and (if you persist server-side) call Supabase or your backend.
- **Restore:** `Transaction.currentEntitlements` (and optionally `AppTransaction.shared`). Rebuild “is premium” from current entitlements. Trial period counts as active entitlement.
- **Listen for renewals/cancellations:** `Transaction.updates` and re-check entitlements; when the trial ends, Apple may create a new transaction for the first paid period—keep treating the user as premium until `expires_at` (or revocation). Update Supabase if using server-side state.
- **Entitlement:** Expose `isPremium: Bool` and optionally `expirationDate: Date?` for the app to gate features. During the 7-day trial, `isPremium` is true; after trial, it remains true as long as the subscription is active (renewed or not cancelled).

### 4.4 Where to gate (freemium)

- **Before starting plan generation (questionnaire):**
  - If free and already used “1 plan this month”, show paywall (or “You’ve used your free plan this month” + CTA to subscribe).
- **After questionnaire, before calling API:**
  - Same check: free tier limited to 1 plan per month (or 1 ever); premium unlimited.
- **Number of plan options:**
  - Free: request 1 plan from backend and show single result; premium: keep current 3-option flow.
- **Gift finder / Love note:**
  - From their entry points (e.g. tab or button), check `isPremium`; if false, present paywall (or locked screen with “Upgrade to unlock”).
- **Saving plans:**
  - Free: cap at 1–2 saved plans; premium: unlimited (current behavior).
- **Memories:**
  - Optional cap for free (e.g. 5); premium unlimited.

Implement a single source of truth (e.g. `SubscriptionManager.shared.isPremium` and optional `freeTierPlansUsedThisMonth`) and use it in:
- `QuestionnaireView` (before/after generate),
- `NavigationCoordinator` or Home when opening questionnaire,
- `GiftsTabView` / `GiftFinderView`,
- Love note entry,
- Save-plan logic,
- Memories if you cap.

### 4.5 Paywall placement and copy (7-day free trial)

- **Primary:** When user hits a limit (e.g. “You’ve used your free plan this month”) or taps a locked feature (Gifts, Love note).
- **Secondary:** Profile/Settings — “Manage subscription” / “Upgrade to Premium” that presents `PaywallView` or system subscription management.
- **Paywall copy for 7-day trial:**
  - Headline: e.g. “Try Premium free for 7 days”.
  - Subtext: “Then $X.XX/month. Cancel anytime before the trial ends and you won’t be charged.”
  - CTA: “Start 7-day free trial” (or “Try free for 7 days”). The system sheet will still show Apple’s standard “7 days free, then $X.XX/month” and “Cancel anytime.”
- **Optional:** Soft paywall after first successful free plan (“Try 7 days free—unlock 3 plan options, unlimited plans, and gifts”).

### 4.6 Sync with Supabase (recommended)

- **Why:** So you can enforce limits on the backend (e.g. Edge Function for date-plan generation) and, later, treat web and iOS under one entitlement.
- **Option A – Client-only for now:** iOS uses StoreKit 2 only; no DB. Easiest; limits enforced only in app (can be bypassed if app is modified).
- **Option B – Client + DB:** On purchase/restore/renewal, iOS calls a Supabase Edge Function or `supabase.from('subscription_entitlements').upsert(...)` with `user_id`, `product_id`, `expires_at`, `platform: 'apple'`. Backend reads this for server-side gating (e.g. reject generation when over free limit and not premium).
- **Option C – Server-side receipt validation:** Edge Function receives receipt from iOS, validates with Apple, and writes entitlement. More work; use if you don’t trust client or add Android later with different flow.

Start with **Option B** and a simple table (see below); you can add receipt validation later.

---

## 5. Supabase Schema (Subscription State)

Add a small table or columns so the app (and optionally Edge Functions) know if the user is premium.

### Option A: Columns on `profiles`

```sql
-- Migration: add_subscription_to_profiles.sql
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS subscription_product_id TEXT,
  ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS subscription_platform TEXT DEFAULT 'apple';
```

- **subscription_product_id:** e.g. `com.yourdategenie.premium.monthly` when active.
- **subscription_expires_at:** End of current period; NULL if not subscribed.
- **subscription_platform:** `apple` (later: `stripe` for web).

RLS: users can `SELECT` and `UPDATE` their own row (or only allow update from a service role / Edge Function if you sync from server).

### Option B: Dedicated table (better for history and multiple products)

```sql
-- Migration: create_subscription_entitlements.sql
CREATE TABLE public.subscription_entitlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'apple',
  expires_at TIMESTAMPTZ NOT NULL,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, platform)
);

CREATE INDEX idx_subscription_entitlements_user_expires
  ON public.subscription_entitlements (user_id, expires_at);

ALTER TABLE public.subscription_entitlements ENABLE ROW LEVEL SECURITY;

-- Users can read their own rows
CREATE POLICY "Users can view own entitlements"
  ON public.subscription_entitlements FOR SELECT
  USING (auth.uid() = user_id);

-- Only backend or service role can insert/update (when Apple or webhook confirms)
-- Or allow user to upsert if you trust client (Option B from iOS)
CREATE POLICY "Users can upsert own entitlements"
  ON public.subscription_entitlements FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

Use a single row per user per platform; on renew, update `expires_at` and `updated_at`.

**Free-tier usage (e.g. “1 plan per month”):**

```sql
-- Optional: track free plan usage per user per month
CREATE TABLE public.free_plan_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  period_start DATE NOT NULL,  -- e.g. first day of month
  plans_generated INT NOT NULL DEFAULT 0,
  UNIQUE (user_id, period_start)
);
```

Your Edge Function (or RPC) that generates plans can: check `subscription_entitlements` for valid premium; if not premium, check/increment `free_plan_usage` and reject if already ≥ 1 for current month.

---

## 6. Edge Function / Backend Gating (Optional but Recommended)

- **generate-date-plan:**  
  - Accept `user_id` (from auth) or get from JWT.  
  - If premium (valid row in `subscription_entitlements` with `expires_at > now()`): allow and optionally set “options count” to 3.  
  - If free: check `free_plan_usage` for current month; if under limit, allow and set options to 1; if over, return 402 or 403 with message “Upgrade for more plans this month.”  
- **Gift finder / love note APIs:** If you have dedicated endpoints, return 402 when not premium so the app can show paywall.

This keeps limits enforceable even if the client is tampered with.

---

## 7. Implementation Order

1. **App Store Connect**  
   Agreements, subscription product, subscription group, sandbox testers.

2. **Supabase**  
   Migration: `subscription_entitlements` (and optionally `free_plan_usage`). RLS and policies.

3. **iOS – SubscriptionManager**  
   StoreKit 2: load product, purchase, restore, `Transaction.updates`, expose `isPremium` (and `expiresAt`).

4. **iOS – Paywall UI**  
   `PaywallView` and “Manage subscription” in Settings.

5. **iOS – Gating**  
   Use `SubscriptionManager.shared.isPremium` and free-tier count in:
   - Questionnaire (before generate; plan count 1 vs 3),
   - Gift finder / Love note entry,
   - Save plan limit,
   - Memories cap (if any).

6. **iOS → Supabase sync**  
   On purchase/restore/renewal, upsert `subscription_entitlements` for current user (and update `expires_at` on renewal).

7. **Backend (optional)**  
   In `generate-date-plan` (and other premium-only endpoints), check `subscription_entitlements` and `free_plan_usage`; enforce limits and option count.

8. **Testing**  
   Sandbox purchases, restore, expiry (use short renewal in sandbox), and gating in app and backend.

---

## 8. RevenueCat (Optional)

- **Pros:** Receipt validation, webhooks to your backend, cross-platform (iOS + Android), analytics, and “offer paywall” A/B tests.  
- **Cons:** Extra dependency and dashboard; free tier has limits.

If you use RevenueCat:

- Create project, add iOS app, configure product ID and App Store Connect credentials.
- Replace direct StoreKit purchase/restore in app with RevenueCat SDK; keep using RevenueCat’s “entitlement” for `isPremium`.
- Add webhook to Supabase Edge Function or external endpoint to update `subscription_entitlements` on subscribe/cancel/renew.

You can start with pure StoreKit 2 and add RevenueCat later without changing the rest of the plan (same product ID and same Supabase entitlement shape).

---

## 9. Web App (Future)

- For true “subscription” on web, use **Stripe** (or similar) and create a “Premium monthly” product.
- On successful subscription, write to `subscription_entitlements` with `platform: 'stripe'` (and same logical “premium” entitlement).
- Web and iOS can both read `subscription_entitlements` so one purchase can unlock both (if you choose to offer that).

---

## 10. Free trial behavior (7-day)

- **When user starts trial:** They tap “Start 7-day free trial” (or equivalent). Apple shows the subscription sheet with “7 days free, then $X.XX/month.” No charge at sign-up.
- **During trial:** User has full premium access (unlimited plans, 3 options, gifts, love notes). Your app treats them like any other subscriber (`isPremium == true`).
- **After 7 days:** If they didn’t cancel, Apple charges them for the first month and then every month. If they cancelled before day 7, they drop back to free tier and are never charged.
- **StoreKit 2:** You don’t need to special-case “trial” vs “paid” for gating—both have an active entitlement. Optionally expose `isInTrialPeriod` (from `Transaction.offerType` or product subscription period) for UI only (e.g. “You’re on a free trial—cancel anytime in Settings”).

---

## 11. Summary

| Item | Action |
|------|--------|
| **Product** | Single auto-renewable monthly subscription in App Store Connect with **7-day free trial** as introductory offer. |
| **Trial** | Users get 7 days free with full premium access; then monthly charge starts unless they cancel. |
| **iOS** | StoreKit 2 in `SubscriptionManager`; `PaywallView` with “Try 7 days free” copy; gate questionnaire, gifts, love notes, save count, and optionally memories. |
| **Backend** | `subscription_entitlements` (+ optional `free_plan_usage`); optional gating in Edge Functions. |
| **Sync** | After purchase/restore/renewal (and trial start), upsert entitlement in Supabase from iOS (or via RevenueCat webhook). |
| **Freemium** | Free: e.g. 1 plan/month, 1 option, gifts/love notes locked. Trial + Premium: unlimited plans, 3 options, full access. |

This gives you a clear path to **monthly subscription with 7-day free trial** and freemium, with room to add server-side enforcement and web later.
