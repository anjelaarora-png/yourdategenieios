# Cursor Task — Create `subscriptions` table + schema for StoreKit receipt validation

**Owner:** Anjela (executing in Cursor)
**Specced by:** backend-developer agent
**Priority:** P0 — required for §3.1.2 compliance + cross-device premium gating
**Estimated effort:** 1 hour

---

## Context for Cursor

Today, premium status is trusted from the iOS client (the app says "I'm premium" and the backend believes it). This is exploitable — anyone with a jailbroken phone can flip the local flag and get premium for free.

The fix has two parts:
1. **This task:** create a `subscriptions` table that holds server-verified premium state per user
2. **Next task (09):** create the Edge Function that validates Apple receipts and writes to this table

Web app premium gating, future Android premium gating, and any backend feature that should be premium-only all read from this table.

---

## Locked decisions

- **Pricing tiers:**
  - Monthly: `$14.99/mo` (product ID: `com.yourdategenie.premium.monthly` — confirm in App Store Connect)
  - Annual: `$99.99/yr` (product ID: `com.yourdategenie.premium.annual`)
  - Future Couple Plan: `$19.99/mo` (product ID: `com.yourdategenie.couple.monthly`) — schema should support but not required for v1

- **Free tier limits enforced server-side:**
  - 3 AI date plans / month
  - 5 saved plans
  - Read-only trending dates

---

## Task breakdown

### Step 1 — Create the migration

`supabase/migrations/<timestamp>_subscriptions_table.sql`:

```sql
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Apple/Store identifiers
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    product_id TEXT NOT NULL,                    -- e.g. "com.yourdategenie.premium.monthly"
    original_transaction_id TEXT,                -- Apple's stable cross-renewal ID
    latest_transaction_id TEXT,                  -- Most recent renewal transaction
    apple_receipt_data TEXT,                     -- Full base64 receipt for re-verification

    -- State
    status TEXT NOT NULL CHECK (status IN ('active', 'trialing', 'in_grace_period', 'expired', 'revoked', 'paused')),
    tier TEXT NOT NULL CHECK (tier IN ('premium', 'couple')),

    -- Lifecycle
    started_at TIMESTAMPTZ NOT NULL,
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    trial_end_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,

    -- Audit
    last_verified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    raw_payload JSONB,                           -- Last full validation response from Apple, for debugging

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (platform, original_transaction_id)
);

-- One active sub per user per platform
CREATE UNIQUE INDEX idx_subscriptions_active_per_user
    ON public.subscriptions(user_id, platform)
    WHERE status IN ('active', 'trialing', 'in_grace_period');

CREATE INDEX idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX idx_subscriptions_period_end ON public.subscriptions(current_period_end) WHERE status IN ('active', 'trialing');

-- Updated-at trigger
CREATE TRIGGER set_subscriptions_updated_at
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();
-- (Reuses existing set_updated_at function if present; otherwise create it inline.)

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can only read their own subscription
CREATE POLICY "Users read own subscriptions"
    ON public.subscriptions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Only service-role (Edge Functions) can insert/update — never the client directly
CREATE POLICY "Service role only writes"
    ON public.subscriptions
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);
```

### Step 2 — Create a `is_premium` SQL helper

Add a function the rest of the app can use:

```sql
CREATE OR REPLACE FUNCTION public.is_premium(p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.subscriptions
        WHERE user_id = p_user_id
          AND status IN ('active', 'trialing', 'in_grace_period')
          AND current_period_end > now()
    );
$$;
```

This lets RLS policies and Edge Functions cleanly check premium status without joining the table inline everywhere.

### Step 3 — Update RLS for premium-gated features

Identify which tables/operations should be premium-only. Likely candidates:
- `date_plans` insert: free tier capped at N per month
- `saved_plans` insert: free tier capped at 5 total
- Couple Plan tables: premium-only

For each, update or add RLS policies that check `public.is_premium()`. Example pattern:

```sql
-- Free tier: max 3 date plans per calendar month
CREATE POLICY "Free tier limit on date plan creation"
    ON public.date_plans
    FOR INSERT
    WITH CHECK (
        public.is_premium()
        OR (
            SELECT COUNT(*)
            FROM public.date_plans
            WHERE user_id = auth.uid()
              AND created_at >= date_trunc('month', now())
        ) < 3
    );
```

### Step 4 — Verify the migration compiles cleanly

Run locally:
```bash
supabase db reset    # nuke local + reapply all migrations
```

If `set_updated_at()` doesn't exist in the project, define it in the same migration:

```sql
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;
```

### Step 5 — Don't push to prod yet

This migration plus task 09 (the Edge Function) need to ship together. Push them in a single deploy to avoid a window where the table exists but nothing writes to it (or vice versa).

---

## Verification checklist

- [ ] Migration runs cleanly on a fresh local Supabase: `supabase db reset` succeeds
- [ ] `subscriptions` table exists with all columns from spec
- [ ] Unique partial index prevents duplicate active subs per user per platform
- [ ] `public.is_premium()` function exists and returns boolean
- [ ] RLS policies are in place — try inserting from anon role, should fail
- [ ] Service role (Edge Function) can insert via `service_role` JWT
- [ ] Free-tier RLS limits work: as a free user, the 4th `date_plans` insert in a calendar month is rejected

## Out of scope

- The Edge Function that calls Apple verifyReceipt / App Store Server API → task 09
- Webhook receiver for Apple Server-to-Server Notifications V2 → task 09
- Android / Google Play Billing → post-launch (Android is July)

## When you're done

Tell me ("chief-of-staff, subscriptions table done") and I'll mark P0 #8 as complete and unblock task 09.
