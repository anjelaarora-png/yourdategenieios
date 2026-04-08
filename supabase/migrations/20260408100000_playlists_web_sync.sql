-- Extend playlists table so the web app can sync to Supabase.
--
-- Problems this fixes:
--   1. couple_id was NOT NULL – web users without a couple couldn't insert rows.
--   2. No user_id column – web can only authenticate via auth.uid(), not couple lookup.
--   3. No vibe / date_plan_title / stops / updated_at columns – web metadata was lost.
--   4. No user_id-scoped RLS – only couple-based policies existed (iOS only).
--
-- iOS rows are unchanged: they still write couple_id + tracks (PlaylistTrack[]).
-- Web rows write user_id + vibe + date_plan_title + tracks (PlaylistSong[]) + stops.
-- The trigger auto-fills couple_id from user_id when a couple exists.

-- ── 1. Make couple_id optional (web users may not have a couple yet) ──────────
ALTER TABLE public.playlists
  ALTER COLUMN couple_id DROP NOT NULL;

-- ── 2. Add web-specific columns ───────────────────────────────────────────────
ALTER TABLE public.playlists
  ADD COLUMN IF NOT EXISTS user_id        UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS vibe           TEXT,
  ADD COLUMN IF NOT EXISTS date_plan_title TEXT,
  ADD COLUMN IF NOT EXISTS stops          JSONB       DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS updated_at     TIMESTAMPTZ DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON public.playlists(user_id);

-- ── 3. Backfill user_id for existing iOS rows that have a couple ──────────────
UPDATE public.playlists p
SET user_id = c.user_id_1
FROM public.couples c
WHERE p.couple_id = c.couple_id
  AND p.user_id IS NULL;

-- ── 4. Trigger: auto-fill couple_id from user_id on insert (mirrors date_plans) ──
CREATE OR REPLACE FUNCTION public.playlists_default_couple_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.user_id IS NOT NULL AND NEW.couple_id IS NULL THEN
    NEW.couple_id := (
      SELECT c.couple_id
      FROM public.couples c
      WHERE c.user_id_1 = NEW.user_id OR c.user_id_2 = NEW.user_id
      ORDER BY c.created_at
      LIMIT 1
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_playlists_default_couple_id ON public.playlists;
CREATE TRIGGER trg_playlists_default_couple_id
  BEFORE INSERT OR UPDATE OF user_id ON public.playlists
  FOR EACH ROW EXECUTE FUNCTION public.playlists_default_couple_id();

-- ── 5. User-scoped RLS policies (web: access by auth.uid() directly) ──────────
-- The existing couple-based policies remain for iOS; these are additive (OR logic).

CREATE POLICY "Users can view own playlists by user_id"
ON public.playlists FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert own playlists by user_id"
ON public.playlists FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own playlists by user_id"
ON public.playlists FOR UPDATE
USING (user_id = auth.uid());

CREATE POLICY "Users can delete own playlists by user_id"
ON public.playlists FOR DELETE
USING (user_id = auth.uid());
