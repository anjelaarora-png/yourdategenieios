-- ─────────────────────────────────────────────────────────────────────────────
-- P0 Task 08: subscriptions table + is_premium() helper + free-tier RLS limits
--
-- Context: Premium status is currently trusted from the iOS client, which is
-- exploitable. This migration adds a server-verified subscriptions table so all
-- premium gating is authoritative from the database.
--
-- Ships together with Task 09 (StoreKit receipt validation Edge Function).
-- Do NOT push to production until both tasks are deployed in the same release.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────────────────
-- 0. set_updated_at() — defined in 20260409130000 but re-declared idempotently
--    here so a fresh `supabase db reset` always works regardless of run order.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. subscriptions table
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Store / platform identifiers
    platform     TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    product_id   TEXT NOT NULL,           -- e.g. "com.yourdategenie.premium.monthly"
    original_transaction_id TEXT,         -- Apple's stable cross-renewal identifier
    latest_transaction_id   TEXT,         -- Most recent renewal transaction
    apple_receipt_data      TEXT,         -- Full base64 receipt for re-verification

    -- State
    status TEXT NOT NULL CHECK (status IN (
        'active', 'trialing', 'in_grace_period', 'expired', 'revoked', 'paused'
    )),
    tier TEXT NOT NULL CHECK (tier IN ('premium', 'couple')),

    -- Lifecycle timestamps
    started_at             TIMESTAMPTZ NOT NULL,
    current_period_start   TIMESTAMPTZ NOT NULL,
    current_period_end     TIMESTAMPTZ NOT NULL,
    trial_end_at           TIMESTAMPTZ,
    cancelled_at           TIMESTAMPTZ,
    revoked_at             TIMESTAMPTZ,

    -- Audit
    last_verified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    raw_payload      JSONB,               -- Last full Apple validation response (debug)

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Compound unique: one transaction_id per platform (nulls excluded by index below)
    UNIQUE (platform, original_transaction_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Indexes
-- ─────────────────────────────────────────────────────────────────────────────

-- Enforce at most one active/trialing/grace-period subscription per user per platform.
-- Partial unique index so expired / revoked rows don't block new subscriptions.
CREATE UNIQUE INDEX idx_subscriptions_active_per_user
    ON public.subscriptions (user_id, platform)
    WHERE status IN ('active', 'trialing', 'in_grace_period');

-- Fast lookup of all subscriptions for a user (profile screen, admin dashboard).
CREATE INDEX idx_subscriptions_user
    ON public.subscriptions (user_id);

-- Fast lookup for expiry sweeps (background job or webhook handler).
CREATE INDEX idx_subscriptions_period_end
    ON public.subscriptions (current_period_end)
    WHERE status IN ('active', 'trialing');

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. updated_at trigger
-- ─────────────────────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS set_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER set_subscriptions_updated_at
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Row-Level Security
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Users may only read their own subscription record.
-- Writing (INSERT / UPDATE / DELETE) is reserved for service-role Edge Functions
-- that call Apple's receipt validation API; clients never write directly.
CREATE POLICY "Users read own subscriptions"
    ON public.subscriptions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role only writes"
    ON public.subscriptions
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. is_premium() helper
--
-- Usage in RLS policies and Edge Functions:
--   SELECT public.is_premium();               -- current session user
--   SELECT public.is_premium('some-uuid');    -- explicit user_id (service role)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_premium(p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.subscriptions
        WHERE user_id          = p_user_id
          AND status           IN ('active', 'trialing', 'in_grace_period')
          AND current_period_end > now()
    );
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Free-tier limits on date_plans INSERT
--
-- Current policy allows any authenticated user to insert unlimited plans.
-- Replace it with a policy that enforces the free-tier caps:
--   • max 3 AI-generated plans per calendar month
--   • max 5 plans stored in the library at any time
-- Premium users (active / trialing / grace-period) bypass both caps.
--
-- The existing SELECT / UPDATE / DELETE policies are unchanged.
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can insert their own plans" ON public.date_plans;

CREATE POLICY "Users can insert their own plans"
    ON public.date_plans
    FOR INSERT
    WITH CHECK (
        -- Must always own the row being inserted
        auth.uid() = user_id
        AND (
            -- Premium users: no caps
            public.is_premium()
            OR (
                -- Free tier cap 1: max 3 new plans per calendar month
                (
                    SELECT COUNT(*)
                    FROM public.date_plans
                    WHERE user_id   = auth.uid()
                      AND created_at >= date_trunc('month', now())
                ) < 3
                AND
                -- Free tier cap 2: max 5 plans in the library total
                (
                    SELECT COUNT(*)
                    FROM public.date_plans
                    WHERE user_id = auth.uid()
                ) < 5
            )
        )
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- Note: no data changes; no backfills needed. The subscriptions table starts
-- empty. Task 09 (StoreKit receipt validation Edge Function) will write the
-- first rows when users restore or initiate purchases.
-- ─────────────────────────────────────────────────────────────────────────────
