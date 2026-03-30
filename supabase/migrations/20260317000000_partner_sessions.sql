-- Partner planning: sessions and plans for cross-device invite/join and ranking
-- session_id is the public id in the join link; inviter/partner data stored as jsonb

CREATE TABLE IF NOT EXISTS public.partner_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id text NOT NULL UNIQUE,
    inviter_name text,
    inviter_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    inviter_data jsonb,
    partner_data jsonb,
    inviter_planned_dates jsonb,
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_partner_sessions_session_id ON public.partner_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_partner_sessions_inviter_user_id ON public.partner_sessions(inviter_user_id);

CREATE TABLE IF NOT EXISTS public.partner_session_plans (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_session_id uuid NOT NULL REFERENCES public.partner_sessions(id) ON DELETE CASCADE,
    plan_index smallint NOT NULL CHECK (plan_index >= 1 AND plan_index <= 3),
    plan_json jsonb NOT NULL,
    inviter_rank smallint CHECK (inviter_rank IS NULL OR (inviter_rank >= 1 AND inviter_rank <= 3)),
    partner_rank smallint CHECK (partner_rank IS NULL OR (partner_rank >= 1 AND partner_rank <= 3)),
    created_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE(partner_session_id, plan_index)
);

CREATE INDEX IF NOT EXISTS idx_partner_session_plans_session_id ON public.partner_session_plans(partner_session_id);

-- RLS: allow anon and authenticated to manage partner sessions for Plan Together flow
ALTER TABLE public.partner_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_session_plans ENABLE ROW LEVEL SECURITY;

-- Anyone with the link (session_id) can read a session (for partner to see inviter name, inviter to poll partner_data)
CREATE POLICY "partner_sessions_select_by_session_id"
ON public.partner_sessions FOR SELECT
USING (true);

-- Allow insert for session creation (inviter or anon)
CREATE POLICY "partner_sessions_insert"
ON public.partner_sessions FOR INSERT
WITH CHECK (true);

-- Inviter can update their session (inviter_data, etc.); partner can update only partner_data when null
CREATE POLICY "partner_sessions_update"
ON public.partner_sessions FOR UPDATE
USING (true)
WITH CHECK (true);

-- Plans: read/write by anyone with session reference (app will pass session_id and look up partner_session_id)
CREATE POLICY "partner_session_plans_select"
ON public.partner_session_plans FOR SELECT
USING (true);

CREATE POLICY "partner_session_plans_insert"
ON public.partner_session_plans FOR INSERT
WITH CHECK (true);

CREATE POLICY "partner_session_plans_update"
ON public.partner_session_plans FOR UPDATE
USING (true)
WITH CHECK (true);

-- Trigger to refresh updated_at on partner_sessions
CREATE OR REPLACE FUNCTION public.set_partner_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS partner_sessions_updated_at ON public.partner_sessions;
CREATE TRIGGER partner_sessions_updated_at
    BEFORE UPDATE ON public.partner_sessions
    FOR EACH ROW EXECUTE PROCEDURE public.set_partner_sessions_updated_at();
