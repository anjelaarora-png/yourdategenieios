-- Unify storage: date_plans ↔ iOS (couple_id + iOS fields), mirror user_preferences ↔ preferences.
-- Session flag prevents infinite trigger recursion.

-- -----------------------------------------------------------------------------
-- 1) date_plans: columns the iOS app expects alongside the web schema
-- Some databases only had legacy columns (e.g. couple_id, plan_id) with no user_id;
-- add user_id first, backfill from couples, then backfill couple_id from user_id.
-- -----------------------------------------------------------------------------
ALTER TABLE public.date_plans
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS couple_id UUID REFERENCES public.couples(couple_id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS selected_option TEXT,
  ADD COLUMN IF NOT EXISTS plan_options JSONB;

CREATE INDEX IF NOT EXISTS idx_date_plans_couple_id ON public.date_plans(couple_id);
CREATE INDEX IF NOT EXISTS idx_date_plans_user_id ON public.date_plans(user_id);

-- Legacy rows: have couple_id, no user_id → set user_id from couples.user_id_1
UPDATE public.date_plans dp
SET user_id = c.user_id_1
FROM public.couples c
WHERE dp.couple_id IS NOT NULL
  AND c.couple_id = dp.couple_id
  AND dp.user_id IS NULL;

-- Web-style rows: have user_id, missing couple_id → set couple_id
UPDATE public.date_plans dp
SET couple_id = c.couple_id
FROM public.couples c
WHERE dp.user_id IS NOT NULL
  AND c.user_id_1 = dp.user_id
  AND dp.couple_id IS NULL;

CREATE OR REPLACE FUNCTION public.date_plans_default_couple_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;
  IF NEW.couple_id IS NULL THEN
    NEW.couple_id := (
      SELECT c.couple_id
      FROM public.couples c
      WHERE c.user_id_1 = NEW.user_id
      ORDER BY c.created_at
      LIMIT 1
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_date_plans_default_couple_id ON public.date_plans;
CREATE TRIGGER trg_date_plans_default_couple_id
  BEFORE INSERT OR UPDATE OF user_id ON public.date_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.date_plans_default_couple_id();

-- -----------------------------------------------------------------------------
-- 2) preferences: ensure columns + unique(user_id) for upserts (older DBs may omit these)
-- -----------------------------------------------------------------------------
ALTER TABLE public.preferences
  ADD COLUMN IF NOT EXISTS couple_id UUID REFERENCES public.couples(couple_id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS cuisine_types TEXT[],
  ADD COLUMN IF NOT EXISTS activity_types TEXT[],
  ADD COLUMN IF NOT EXISTS drink_preferences TEXT[],
  ADD COLUMN IF NOT EXISTS budget_range TEXT,
  ADD COLUMN IF NOT EXISTS love_languages TEXT[],
  ADD COLUMN IF NOT EXISTS food_allergies TEXT[],
  ADD COLUMN IF NOT EXISTS hard_nos TEXT[],
  ADD COLUMN IF NOT EXISTS accessibility_needs TEXT[],
  ADD COLUMN IF NOT EXISTS gender TEXT,
  ADD COLUMN IF NOT EXISTS partner_gender TEXT,
  ADD COLUMN IF NOT EXISTS default_city TEXT,
  ADD COLUMN IF NOT EXISTS default_starting_point TEXT,
  ADD COLUMN IF NOT EXISTS dietary_restrictions TEXT[] DEFAULT '{}';

-- NOT NULL + default only when column was just added is tricky; ensure updated_at exists
ALTER TABLE public.preferences
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE UNIQUE INDEX IF NOT EXISTS preferences_user_id_key ON public.preferences (user_id);

-- Columns used by mirror triggers + backfill (minimal user_preferences may only have food_preferences, deal_breakers, etc.)
ALTER TABLE public.user_preferences
  ADD COLUMN IF NOT EXISTS gender TEXT,
  ADD COLUMN IF NOT EXISTS partner_gender TEXT,
  ADD COLUMN IF NOT EXISTS activity_preferences TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS drink_preferences TEXT[],
  ADD COLUMN IF NOT EXISTS dietary_restrictions TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS allergies TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS accessibility_needs TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS default_city TEXT,
  ADD COLUMN IF NOT EXISTS default_neighborhood TEXT;

-- -----------------------------------------------------------------------------
-- 3) Mirror: user_preferences (web) ↔ preferences (iOS) — overlapping fields only
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_user_preferences_to_preferences_row()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_couple UUID;
BEGIN
  IF current_setting('app.prefs_sync_layer', true) = 'prefs_source' THEN
    RETURN NEW;
  END IF;

  PERFORM set_config('app.prefs_sync_layer', 'user_prefs_source', true);

  SELECT c.couple_id INTO v_couple
  FROM public.couples c
  WHERE c.user_id_1 = NEW.user_id
  ORDER BY c.created_at
  LIMIT 1;

  INSERT INTO public.preferences (
    preference_id,
    user_id,
    couple_id,
    cuisine_types,
    activity_types,
    drink_preferences,
    budget_range,
    food_allergies,
    hard_nos,
    accessibility_needs,
    gender,
    partner_gender,
    default_city,
    default_starting_point,
    dietary_restrictions,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    NEW.user_id,
    v_couple,
    NEW.food_preferences,
    NEW.activity_preferences,
    NEW.drink_preferences,
    NEW.budget_range,
    NEW.allergies,
    NEW.deal_breakers,
    NEW.accessibility_needs,
    NEW.gender,
    NEW.partner_gender,
    NEW.default_city,
    NEW.default_neighborhood,
    NEW.dietary_restrictions,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    couple_id = COALESCE(EXCLUDED.couple_id, public.preferences.couple_id),
    cuisine_types = EXCLUDED.cuisine_types,
    activity_types = EXCLUDED.activity_types,
    drink_preferences = EXCLUDED.drink_preferences,
    budget_range = EXCLUDED.budget_range,
    food_allergies = EXCLUDED.food_allergies,
    hard_nos = EXCLUDED.hard_nos,
    accessibility_needs = EXCLUDED.accessibility_needs,
    gender = EXCLUDED.gender,
    partner_gender = EXCLUDED.partner_gender,
    default_city = EXCLUDED.default_city,
    default_starting_point = EXCLUDED.default_starting_point,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    updated_at = now();

  PERFORM set_config('app.prefs_sync_layer', '', true);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_preferences_to_user_preferences_row()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF current_setting('app.prefs_sync_layer', true) = 'user_prefs_source' THEN
    RETURN NEW;
  END IF;

  PERFORM set_config('app.prefs_sync_layer', 'prefs_source', true);

  INSERT INTO public.user_preferences (
    user_id,
    food_preferences,
    activity_preferences,
    drink_preferences,
    budget_range,
    allergies,
    deal_breakers,
    accessibility_needs,
    gender,
    partner_gender,
    default_city,
    default_neighborhood,
    dietary_restrictions,
    updated_at
  )
  VALUES (
    NEW.user_id,
    NEW.cuisine_types,
    NEW.activity_types,
    NEW.drink_preferences,
    NEW.budget_range,
    NEW.food_allergies,
    NEW.hard_nos,
    NEW.accessibility_needs,
    NEW.gender,
    NEW.partner_gender,
    NEW.default_city,
    NEW.default_starting_point,
    NEW.dietary_restrictions,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    food_preferences = EXCLUDED.food_preferences,
    activity_preferences = EXCLUDED.activity_preferences,
    drink_preferences = EXCLUDED.drink_preferences,
    budget_range = EXCLUDED.budget_range,
    allergies = EXCLUDED.allergies,
    deal_breakers = EXCLUDED.deal_breakers,
    accessibility_needs = EXCLUDED.accessibility_needs,
    gender = EXCLUDED.gender,
    partner_gender = EXCLUDED.partner_gender,
    default_city = EXCLUDED.default_city,
    default_neighborhood = EXCLUDED.default_neighborhood,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    updated_at = now();

  PERFORM set_config('app.prefs_sync_layer', '', true);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_preferences_sync_preferences ON public.user_preferences;
CREATE TRIGGER trg_user_preferences_sync_preferences
  AFTER INSERT OR UPDATE ON public.user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_preferences_to_preferences_row();

DROP TRIGGER IF EXISTS trg_preferences_sync_user_preferences ON public.preferences;
CREATE TRIGGER trg_preferences_sync_user_preferences
  AFTER INSERT OR UPDATE ON public.preferences
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_preferences_to_user_preferences_row();

-- One-time backfill (idempotent): web-only rows → preferences, iOS-only rows → user_preferences
ALTER TABLE public.user_preferences DISABLE TRIGGER trg_user_preferences_sync_preferences;
ALTER TABLE public.preferences DISABLE TRIGGER trg_preferences_sync_user_preferences;

INSERT INTO public.preferences (
  preference_id,
  user_id,
  couple_id,
  cuisine_types,
  activity_types,
  drink_preferences,
  budget_range,
  food_allergies,
  hard_nos,
  accessibility_needs,
  gender,
  partner_gender,
  default_city,
  default_starting_point,
  dietary_restrictions,
  updated_at
)
SELECT
  gen_random_uuid(),
  up.user_id,
  (SELECT c.couple_id FROM public.couples c WHERE c.user_id_1 = up.user_id ORDER BY c.created_at LIMIT 1),
  up.food_preferences,
  up.activity_preferences,
  up.drink_preferences,
  up.budget_range,
  up.allergies,
  up.deal_breakers,
  up.accessibility_needs,
  up.gender,
  up.partner_gender,
  up.default_city,
  up.default_neighborhood,
  up.dietary_restrictions,
  now()
FROM public.user_preferences up
WHERE NOT EXISTS (SELECT 1 FROM public.preferences p WHERE p.user_id = up.user_id);

INSERT INTO public.user_preferences (
  user_id,
  food_preferences,
  activity_preferences,
  drink_preferences,
  budget_range,
  allergies,
  deal_breakers,
  accessibility_needs,
  gender,
  partner_gender,
  default_city,
  default_neighborhood,
  dietary_restrictions,
  updated_at
)
SELECT
  pr.user_id,
  pr.cuisine_types,
  pr.activity_types,
  pr.drink_preferences,
  pr.budget_range,
  pr.food_allergies,
  pr.hard_nos,
  pr.accessibility_needs,
  pr.gender,
  pr.partner_gender,
  pr.default_city,
  pr.default_starting_point,
  pr.dietary_restrictions,
  now()
FROM public.preferences pr
WHERE NOT EXISTS (SELECT 1 FROM public.user_preferences u WHERE u.user_id = pr.user_id);

ALTER TABLE public.user_preferences ENABLE TRIGGER trg_user_preferences_sync_preferences;
ALTER TABLE public.preferences ENABLE TRIGGER trg_preferences_sync_user_preferences;
