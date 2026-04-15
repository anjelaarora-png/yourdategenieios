-- Partner planning: phase tracking, independent rankings, winner selection, audit trail
-- Extends partner_sessions and partner_session_plans; adds four new tables.

-- ─────────────────────────────────────────────
-- 1. Extend partner_sessions with phase columns
-- ─────────────────────────────────────────────
ALTER TABLE public.partner_sessions
  ADD COLUMN IF NOT EXISTS phase text NOT NULL DEFAULT 'preferences_pending',
  ADD COLUMN IF NOT EXISTS partner_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS partner_name text;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Raise partner_session_plans plan_index ceiling from 3 to 5 (3–5 options)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.partner_session_plans
  DROP CONSTRAINT IF EXISTS partner_session_plans_plan_index_check;
ALTER TABLE public.partner_session_plans
  ADD CONSTRAINT partner_session_plans_plan_index_check
    CHECK (plan_index >= 1 AND plan_index <= 5);

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 3. option_rankings — each user's private ranked list; hidden from other user until both submit
-- ─────────────────────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.option_rankings (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_session_id uuid NOT NULL REFERENCES public.partner_sessions(id) ON DELETE CASCADE,
  user_id          uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  role             text NOT NULL CHECK (role IN ('inviter', 'partner')),
  -- JSON array: [{"plan_index": 1, "rank_position": 2}, ...]
  rankings         jsonb NOT NULL DEFAULT '[]',
  submitted_at     timestamptz DEFAULT now() NOT NULL,
  UNIQUE(partner_session_id, role)
);

CREATE INDEX IF NOT EXISTS idx_option_rankings_session ON public.option_rankings(partner_session_id);

-- ────────────────────────────────────────────────────────────────────
-- 4. final_option_selection — computed winner after both users rank
-- ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.final_option_selection (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_session_id    uuid NOT NULL REFERENCES public.partner_sessions(id) ON DELETE CASCADE UNIQUE,
  winning_plan_index    smallint NOT NULL,
  runner_up_plan_index  smallint,
  selection_reason      text,
  -- JSON map of plan_index -> combined_score  e.g. {"1": 5, "2": 4, "3": 3}
  scoring_payload       jsonb,
  selected_at           timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_final_option_session ON public.final_option_selection(partner_session_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. plan_phase_history — full audit trail of every phase transition
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.plan_phase_history (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_session_id uuid NOT NULL REFERENCES public.partner_sessions(id) ON DELETE CASCADE,
  phase              text NOT NULL,
  triggered_by       text,   -- 'inviter' | 'partner' | 'system'
  metadata           jsonb,
  created_at         timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_plan_phase_history_session ON public.plan_phase_history(partner_session_id);

-- ──────────────────────────────────────────────────────────────────
-- 6. notification_events — in-app event log; structured for push later
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notification_events (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  partner_session_id uuid REFERENCES public.partner_sessions(id) ON DELETE CASCADE,
  type               text NOT NULL,
  title              text NOT NULL,
  body               text NOT NULL,
  read_at            timestamptz,
  created_at         timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notification_events_user    ON public.notification_events(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_events_session ON public.notification_events(partner_session_id);

-- ──────────────────────────────────────────────────────────────────────
-- 7. RLS — all tables use the same link-based open access model as the
--    existing partner_sessions/partner_session_plans tables.  Tighter
--    user-scoped policies can be applied once APNs tokens are tracked.
--    All CREATE POLICY statements are guarded with DROP IF EXISTS so
--    this migration is safe to re-run after a partial failure.
-- ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.option_rankings        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.final_option_selection ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_phase_history     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_events    ENABLE ROW LEVEL SECURITY;

-- option_rankings
DROP POLICY IF EXISTS "option_rankings_select" ON public.option_rankings;
DROP POLICY IF EXISTS "option_rankings_insert" ON public.option_rankings;
DROP POLICY IF EXISTS "option_rankings_update" ON public.option_rankings;
CREATE POLICY "option_rankings_select" ON public.option_rankings FOR SELECT USING (true);
CREATE POLICY "option_rankings_insert" ON public.option_rankings FOR INSERT WITH CHECK (true);
CREATE POLICY "option_rankings_update" ON public.option_rankings FOR UPDATE USING (true) WITH CHECK (true);

-- final_option_selection
DROP POLICY IF EXISTS "final_option_select" ON public.final_option_selection;
DROP POLICY IF EXISTS "final_option_insert" ON public.final_option_selection;
DROP POLICY IF EXISTS "final_option_update" ON public.final_option_selection;
CREATE POLICY "final_option_select" ON public.final_option_selection FOR SELECT USING (true);
CREATE POLICY "final_option_insert" ON public.final_option_selection FOR INSERT WITH CHECK (true);
CREATE POLICY "final_option_update" ON public.final_option_selection FOR UPDATE USING (true) WITH CHECK (true);

-- plan_phase_history (append-only, no update needed)
DROP POLICY IF EXISTS "plan_phase_history_select" ON public.plan_phase_history;
DROP POLICY IF EXISTS "plan_phase_history_insert" ON public.plan_phase_history;
CREATE POLICY "plan_phase_history_select" ON public.plan_phase_history FOR SELECT USING (true);
CREATE POLICY "plan_phase_history_insert" ON public.plan_phase_history FOR INSERT WITH CHECK (true);

-- notification_events — reads scoped to owner; writes open so inviter can write for partner
DROP POLICY IF EXISTS "notification_events_select" ON public.notification_events;
DROP POLICY IF EXISTS "notification_events_insert" ON public.notification_events;
DROP POLICY IF EXISTS "notification_events_update" ON public.notification_events;
CREATE POLICY "notification_events_select" ON public.notification_events
  FOR SELECT USING (user_id IS NULL OR auth.uid() = user_id);
CREATE POLICY "notification_events_insert" ON public.notification_events
  FOR INSERT WITH CHECK (true);
CREATE POLICY "notification_events_update" ON public.notification_events
  FOR UPDATE USING (user_id IS NULL OR auth.uid() = user_id)
  WITH CHECK (true);
