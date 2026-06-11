-- blocked_users: Apple §1.2 requirement — users can block others from sending couple invites
-- and from any future partner_sessions interaction.

CREATE TABLE IF NOT EXISTS public.blocked_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(blocker_id, blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON public.blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON public.blocked_users(blocked_id);

ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own blocks"
    ON public.blocked_users
    FOR SELECT
    USING (auth.uid() = blocker_id);

CREATE POLICY "Users can create blocks"
    ON public.blocked_users
    FOR INSERT
    WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can unblock"
    ON public.blocked_users
    FOR DELETE
    USING (auth.uid() = blocker_id);

-- Prevent creating a partner_session (couple invite) when the invitee has blocked the current user.
-- partner_sessions uses inviter_user_id; blocked_id = inviter, blocker_id = the person who blocked them.
-- We add a check: cannot insert a session if someone has already blocked you (inviter).
CREATE OR REPLACE FUNCTION public.check_partner_session_not_blocked()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- If inviter_user_id is set, verify no one in the system has blocked the inviter
    -- (we check whether ANY user has blocked the inviter; for MVP we enforce this broadly)
    IF NEW.inviter_user_id IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM public.blocked_users
            WHERE blocked_id = NEW.inviter_user_id
        ) THEN
            RAISE EXCEPTION 'Cannot create session: inviter is blocked by another user';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- Note: this trigger is intentionally scoped to INSERT only.
-- It fires when the inviter creates the session row.
DROP TRIGGER IF EXISTS partner_session_block_check ON public.partner_sessions;
CREATE TRIGGER partner_session_block_check
    BEFORE INSERT ON public.partner_sessions
    FOR EACH ROW
    EXECUTE FUNCTION public.check_partner_session_not_blocked();
