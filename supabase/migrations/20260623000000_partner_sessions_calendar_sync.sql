-- Calendar sync for Plan Together (EventKit-only, Apple path).
-- Each device reads its OWN device calendar (EventKit) for free evenings and uploads
-- candidate slots here; the server intersects them so both partners see mutually-free
-- nights. When a night is matched, it is stored server-side as `matched_night` so EACH
-- partner's app can write that SAME night to THEIR OWN calendar with reminders.
-- (One device can only write to its own calendar — there is no cross-device calendar write.)
--
-- Idempotent: ADD COLUMN IF NOT EXISTS. Inherits the existing open, link-based RLS on
-- partner_sessions (see 20260317000000_partner_sessions.sql); no new policies needed.

ALTER TABLE public.partner_sessions
  ADD COLUMN IF NOT EXISTS inviter_free_slots jsonb,
  ADD COLUMN IF NOT EXISTS partner_free_slots jsonb,
  ADD COLUMN IF NOT EXISTS matched_night timestamptz,
  ADD COLUMN IF NOT EXISTS matched_night_label text;
