-- Align date_plans schema with iOS DBDatePlan expectations.
--
-- Root cause: date_plans was created manually with web-era column names
-- (plan_id, plan_title, plan_tagline, scheduled_at, itinerary, genies_secret_touch, etc.)
-- The iOS app expects: id, title, tagline, date_scheduled, stops, genie_secret_touch, etc.
-- Without this migration iOS date plan sync silently fails on every upsert.
--
-- Strategy:
--   - Add all missing iOS columns alongside the legacy web columns (non-destructive)
--   - Backfill iOS columns from legacy web columns where names differ
--   - Add id column (UUID, unique-indexed) backfilled from plan_id so existing rows
--     are immediately readable and upsertable by the iOS app
--   - Legacy web columns (plan_title, plan_tagline, itinerary, etc.) are kept intact

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. id column — iOS primary key; backfill from plan_id for all existing rows
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.date_plans
  ADD COLUMN IF NOT EXISTS id UUID;

UPDATE public.date_plans SET id = plan_id WHERE id IS NULL;

ALTER TABLE public.date_plans
  ALTER COLUMN id SET NOT NULL,
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

DROP INDEX IF EXISTS idx_date_plans_id;
CREATE UNIQUE INDEX idx_date_plans_id ON public.date_plans(id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. iOS-named equivalents of renamed / missing columns
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.date_plans
  ADD COLUMN IF NOT EXISTS title               TEXT,
  ADD COLUMN IF NOT EXISTS tagline             TEXT,
  ADD COLUMN IF NOT EXISTS date_scheduled      TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS total_duration      TEXT,
  ADD COLUMN IF NOT EXISTS estimated_cost      TEXT,
  ADD COLUMN IF NOT EXISTS stops               JSONB NOT NULL DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS genie_secret_touch  JSONB,
  ADD COLUMN IF NOT EXISTS packing_list        TEXT[],
  ADD COLUMN IF NOT EXISTS gift_suggestions    JSONB,
  ADD COLUMN IF NOT EXISTS updated_at          TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS rating              INTEGER,
  ADD COLUMN IF NOT EXISTS rating_notes        TEXT;

-- Backfill from legacy web columns so existing rows surface correctly in the iOS app
UPDATE public.date_plans SET
  title             = COALESCE(title, plan_title),
  tagline           = COALESCE(tagline, plan_tagline),
  date_scheduled    = COALESCE(date_scheduled, scheduled_at),
  stops             = COALESCE(NULLIF(stops, '[]'::jsonb), itinerary, '[]'::jsonb),
  genie_secret_touch = COALESCE(
    genie_secret_touch,
    CASE WHEN genies_secret_touch IS NOT NULL THEN to_jsonb(genies_secret_touch) ELSE NULL END
  ),
  packing_list      = COALESCE(packing_list, what_to_bring)
WHERE
  title IS NULL
  OR stops = '[]'
  OR genie_secret_touch IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. conversation_starters: DB has TEXT[], iOS sends JSONB.
--    Add a jsonb column and backfill from the array; keep the array column
--    intact so the web side is not broken.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.date_plans
  ADD COLUMN IF NOT EXISTS conversation_starters_jsonb JSONB;

UPDATE public.date_plans
SET conversation_starters_jsonb = to_jsonb(conversation_starters)
WHERE conversation_starters IS NOT NULL
  AND conversation_starters_jsonb IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. RLS — allow iOS to read/write by user_id OR couple membership
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Users can view their own plans"   ON public.date_plans;
DROP POLICY IF EXISTS "Users can insert their own plans" ON public.date_plans;
DROP POLICY IF EXISTS "Users can update their own plans" ON public.date_plans;
DROP POLICY IF EXISTS "Users can delete their own plans" ON public.date_plans;

CREATE POLICY "Users can view their own plans"
ON public.date_plans FOR SELECT
USING (
  auth.uid() = user_id
  OR couple_id IN (
    SELECT couple_id FROM public.couples
    WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
  )
);

CREATE POLICY "Users can insert their own plans"
ON public.date_plans FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own plans"
ON public.date_plans FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own plans"
ON public.date_plans FOR DELETE
USING (auth.uid() = user_id);
