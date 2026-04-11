-- Fix: user_preferences.updated_at was only ever set at row creation (DEFAULT now()).
-- It was NEVER auto-updated on subsequent UPDATEs, so the timestamp guard added in
-- 20260409120000_fix_reverse_sync_timestamp_guard.sql was always bypassed:
-- every iOS sync arrives with updated_at = NOW() which is always greater than a
-- creation-time timestamp, allowing stale iOS data to unconditionally overwrite
-- any web save.
--
-- Fix:
--   1. Add a BEFORE UPDATE trigger on user_preferences so that updated_at is
--      automatically stamped to NOW() on every row update (web or context save).
--   2. Refresh all existing rows to updated_at = NOW() so the guard is effective
--      immediately for everyone, not just on the next save.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Auto-update trigger
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

DROP TRIGGER IF EXISTS trg_user_preferences_updated_at ON public.user_preferences;
CREATE TRIGGER trg_user_preferences_updated_at
  BEFORE UPDATE ON public.user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Backfill: stamp all existing rows with NOW() so the reverse-sync timestamp
--    guard in sync_preferences_to_user_preferences_row() treats them as freshly
--    saved by the web and won't let a future iOS sync clobber them.
--    Disable the sync triggers during the backfill to avoid side effects.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.user_preferences DISABLE TRIGGER trg_user_preferences_sync_preferences;

UPDATE public.user_preferences
SET updated_at = now()
WHERE updated_at < now() - INTERVAL '1 minute';  -- skip rows just saved

ALTER TABLE public.user_preferences ENABLE TRIGGER trg_user_preferences_sync_preferences;
