-- Persist every app field that was previously local-only or missing from the other platform.
-- Changes:
--   1. user_preferences  – add love_languages, partner_love_languages, relationship_stage,
--                          conversation_topics, additional_notes
--   2. preferences (iOS) – add all web-only columns so the bidirectional mirror is complete
--   3. users             – add phone_number
--   4. date_plans        – add starting_point JSONB
--   5. gift_suggestions  – make plan_id nullable (standalone Gift Finder items have no plan);
--                          add user_id, purchase_url, emoji, store_search_query, image_url
--   6. Rebuild both mirror triggers to cover every shared field

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. user_preferences – new fields
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.user_preferences
  ADD COLUMN IF NOT EXISTS love_languages          TEXT[],
  ADD COLUMN IF NOT EXISTS partner_love_languages  TEXT[],
  ADD COLUMN IF NOT EXISTS relationship_stage      TEXT,
  ADD COLUMN IF NOT EXISTS conversation_topics     TEXT[],
  ADD COLUMN IF NOT EXISTS additional_notes        TEXT;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. preferences (iOS) – add columns that previously only existed on web side
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.preferences
  ADD COLUMN IF NOT EXISTS energy_level            TEXT,
  ADD COLUMN IF NOT EXISTS transportation_mode     TEXT,
  ADD COLUMN IF NOT EXISTS travel_radius           TEXT,
  ADD COLUMN IF NOT EXISTS smoking_preference      TEXT,
  ADD COLUMN IF NOT EXISTS smoking_activities      TEXT[],
  ADD COLUMN IF NOT EXISTS default_neighborhood    TEXT,
  ADD COLUMN IF NOT EXISTS gift_recipient          TEXT,
  ADD COLUMN IF NOT EXISTS gift_interests          TEXT[],
  ADD COLUMN IF NOT EXISTS gift_budget             TEXT,
  ADD COLUMN IF NOT EXISTS gift_occasion           TEXT,
  ADD COLUMN IF NOT EXISTS gift_notes              TEXT,
  ADD COLUMN IF NOT EXISTS gift_recipient_identity TEXT,
  ADD COLUMN IF NOT EXISTS gift_style              TEXT[],
  ADD COLUMN IF NOT EXISTS gift_favorite_brands    TEXT,
  ADD COLUMN IF NOT EXISTS gift_sizes              TEXT,
  ADD COLUMN IF NOT EXISTS partner_love_languages  TEXT[],
  ADD COLUMN IF NOT EXISTS relationship_stage      TEXT,
  ADD COLUMN IF NOT EXISTS conversation_topics     TEXT[],
  ADD COLUMN IF NOT EXISTS additional_notes        TEXT;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. users – add phone_number
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS phone_number TEXT;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. date_plans – persist starting point so it survives a cloud round-trip
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.date_plans
  ADD COLUMN IF NOT EXISTS starting_point JSONB;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. gift_suggestions – support standalone (Gift Finder) rows not tied to a plan
-- ─────────────────────────────────────────────────────────────────────────────

-- Make plan_id optional (standalone Gift Finder items have no plan)
ALTER TABLE public.gift_suggestions
  ALTER COLUMN plan_id DROP NOT NULL;

-- Drop old FK, re-add without NOT NULL cascade check
ALTER TABLE public.gift_suggestions
  DROP CONSTRAINT IF EXISTS gift_suggestions_plan_id_fkey;
ALTER TABLE public.gift_suggestions
  ADD CONSTRAINT gift_suggestions_plan_id_fkey
    FOREIGN KEY (plan_id) REFERENCES public.date_plans(id) ON DELETE CASCADE;

-- Add ownership / display columns
ALTER TABLE public.gift_suggestions
  ADD COLUMN IF NOT EXISTS user_id           UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS purchase_url      TEXT,
  ADD COLUMN IF NOT EXISTS emoji             TEXT,
  ADD COLUMN IF NOT EXISTS store_search_query TEXT,
  ADD COLUMN IF NOT EXISTS image_url         TEXT;

-- Backfill user_id from couples so existing rows are still accessible
UPDATE public.gift_suggestions gs
SET user_id = c.user_id_1
FROM public.couples c
WHERE c.couple_id = gs.couple_id
  AND gs.user_id IS NULL;

-- Update RLS to allow user-based access as well as couple-based
DROP POLICY IF EXISTS "Couples can view own gift_suggestions" ON public.gift_suggestions;
CREATE POLICY "Users can view own gift_suggestions"
ON public.gift_suggestions FOR SELECT
USING (
  user_id = auth.uid()
  OR couple_id IN (
    SELECT couple_id FROM public.couples
    WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
  )
);

DROP POLICY IF EXISTS "Couples can insert own gift_suggestions" ON public.gift_suggestions;
CREATE POLICY "Users can insert own gift_suggestions"
ON public.gift_suggestions FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  OR couple_id IN (
    SELECT couple_id FROM public.couples
    WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
  )
);

DROP POLICY IF EXISTS "Couples can update own gift_suggestions" ON public.gift_suggestions;
CREATE POLICY "Users can update own gift_suggestions"
ON public.gift_suggestions FOR UPDATE
USING (
  user_id = auth.uid()
  OR couple_id IN (
    SELECT couple_id FROM public.couples
    WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
  )
);

DROP POLICY IF EXISTS "Couples can delete own gift_suggestions" ON public.gift_suggestions;
CREATE POLICY "Users can delete own gift_suggestions"
ON public.gift_suggestions FOR DELETE
USING (
  user_id = auth.uid()
  OR couple_id IN (
    SELECT couple_id FROM public.couples
    WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
  )
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Rebuild mirror triggers: user_preferences (web) ↔ preferences (iOS)
--    Now covers every shared preference field.
-- ─────────────────────────────────────────────────────────────────────────────

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
    -- core diet / activity
    cuisine_types,
    activity_types,
    drink_preferences,
    dietary_restrictions,
    budget_range,
    food_allergies,
    hard_nos,
    accessibility_needs,
    -- identity
    gender,
    partner_gender,
    love_languages,
    partner_love_languages,
    -- location / travel
    default_city,
    default_starting_point,
    default_neighborhood,
    energy_level,
    transportation_mode,
    travel_radius,
    -- lifestyle
    smoking_preference,
    smoking_activities,
    -- gift preferences
    gift_recipient,
    gift_interests,
    gift_budget,
    gift_occasion,
    gift_notes,
    gift_recipient_identity,
    gift_style,
    gift_favorite_brands,
    gift_sizes,
    -- relationship context
    relationship_stage,
    conversation_topics,
    additional_notes,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    NEW.user_id,
    v_couple,
    NEW.food_preferences,
    NEW.activity_preferences,
    NEW.drink_preferences,
    NEW.dietary_restrictions,
    NEW.budget_range,
    NEW.allergies,
    NEW.deal_breakers,
    NEW.accessibility_needs,
    NEW.gender,
    NEW.partner_gender,
    NEW.love_languages,
    NEW.partner_love_languages,
    NEW.default_city,
    NEW.default_starting_point,
    NEW.default_neighborhood,
    NEW.energy_level,
    NEW.transportation_mode,
    NEW.travel_radius,
    NEW.smoking_preference,
    NEW.smoking_activities,
    NEW.gift_recipient,
    NEW.gift_interests,
    NEW.gift_budget,
    NEW.gift_occasion,
    NEW.gift_notes,
    NEW.gift_recipient_identity,
    NEW.gift_style,
    NEW.gift_favorite_brands,
    NEW.gift_sizes,
    NEW.relationship_stage,
    NEW.conversation_topics,
    NEW.additional_notes,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    couple_id               = COALESCE(EXCLUDED.couple_id, public.preferences.couple_id),
    cuisine_types           = EXCLUDED.cuisine_types,
    activity_types          = EXCLUDED.activity_types,
    drink_preferences       = EXCLUDED.drink_preferences,
    dietary_restrictions    = EXCLUDED.dietary_restrictions,
    budget_range            = EXCLUDED.budget_range,
    food_allergies          = EXCLUDED.food_allergies,
    hard_nos                = EXCLUDED.hard_nos,
    accessibility_needs     = EXCLUDED.accessibility_needs,
    gender                  = EXCLUDED.gender,
    partner_gender          = EXCLUDED.partner_gender,
    love_languages          = EXCLUDED.love_languages,
    partner_love_languages  = EXCLUDED.partner_love_languages,
    default_city            = EXCLUDED.default_city,
    default_starting_point  = EXCLUDED.default_starting_point,
    default_neighborhood    = EXCLUDED.default_neighborhood,
    energy_level            = EXCLUDED.energy_level,
    transportation_mode     = EXCLUDED.transportation_mode,
    travel_radius           = EXCLUDED.travel_radius,
    smoking_preference      = EXCLUDED.smoking_preference,
    smoking_activities      = EXCLUDED.smoking_activities,
    gift_recipient          = EXCLUDED.gift_recipient,
    gift_interests          = EXCLUDED.gift_interests,
    gift_budget             = EXCLUDED.gift_budget,
    gift_occasion           = EXCLUDED.gift_occasion,
    gift_notes              = EXCLUDED.gift_notes,
    gift_recipient_identity = EXCLUDED.gift_recipient_identity,
    gift_style              = EXCLUDED.gift_style,
    gift_favorite_brands    = EXCLUDED.gift_favorite_brands,
    gift_sizes              = EXCLUDED.gift_sizes,
    relationship_stage      = EXCLUDED.relationship_stage,
    conversation_topics     = EXCLUDED.conversation_topics,
    additional_notes        = EXCLUDED.additional_notes,
    updated_at              = now();

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
    dietary_restrictions,
    budget_range,
    allergies,
    deal_breakers,
    accessibility_needs,
    gender,
    partner_gender,
    love_languages,
    partner_love_languages,
    default_city,
    default_starting_point,
    default_neighborhood,
    energy_level,
    transportation_mode,
    travel_radius,
    smoking_preference,
    smoking_activities,
    gift_recipient,
    gift_interests,
    gift_budget,
    gift_occasion,
    gift_notes,
    gift_recipient_identity,
    gift_style,
    gift_favorite_brands,
    gift_sizes,
    relationship_stage,
    conversation_topics,
    additional_notes,
    updated_at
  )
  VALUES (
    NEW.user_id,
    NEW.cuisine_types,
    NEW.activity_types,
    NEW.drink_preferences,
    NEW.dietary_restrictions,
    NEW.budget_range,
    NEW.food_allergies,
    NEW.hard_nos,
    NEW.accessibility_needs,
    NEW.gender,
    NEW.partner_gender,
    NEW.love_languages,
    NEW.partner_love_languages,
    NEW.default_city,
    NEW.default_starting_point,
    NEW.default_neighborhood,
    NEW.energy_level,
    NEW.transportation_mode,
    NEW.travel_radius,
    NEW.smoking_preference,
    NEW.smoking_activities,
    NEW.gift_recipient,
    NEW.gift_interests,
    NEW.gift_budget,
    NEW.gift_occasion,
    NEW.gift_notes,
    NEW.gift_recipient_identity,
    NEW.gift_style,
    NEW.gift_favorite_brands,
    NEW.gift_sizes,
    NEW.relationship_stage,
    NEW.conversation_topics,
    NEW.additional_notes,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    food_preferences        = EXCLUDED.food_preferences,
    activity_preferences    = EXCLUDED.activity_preferences,
    drink_preferences       = EXCLUDED.drink_preferences,
    dietary_restrictions    = EXCLUDED.dietary_restrictions,
    budget_range            = EXCLUDED.budget_range,
    allergies               = EXCLUDED.allergies,
    deal_breakers           = EXCLUDED.deal_breakers,
    accessibility_needs     = EXCLUDED.accessibility_needs,
    gender                  = EXCLUDED.gender,
    partner_gender          = EXCLUDED.partner_gender,
    love_languages          = EXCLUDED.love_languages,
    partner_love_languages  = EXCLUDED.partner_love_languages,
    default_city            = EXCLUDED.default_city,
    default_starting_point  = EXCLUDED.default_starting_point,
    default_neighborhood    = EXCLUDED.default_neighborhood,
    energy_level            = EXCLUDED.energy_level,
    transportation_mode     = EXCLUDED.transportation_mode,
    travel_radius           = EXCLUDED.travel_radius,
    smoking_preference      = EXCLUDED.smoking_preference,
    smoking_activities      = EXCLUDED.smoking_activities,
    gift_recipient          = EXCLUDED.gift_recipient,
    gift_interests          = EXCLUDED.gift_interests,
    gift_budget             = EXCLUDED.gift_budget,
    gift_occasion           = EXCLUDED.gift_occasion,
    gift_notes              = EXCLUDED.gift_notes,
    gift_recipient_identity = EXCLUDED.gift_recipient_identity,
    gift_style              = EXCLUDED.gift_style,
    gift_favorite_brands    = EXCLUDED.gift_favorite_brands,
    gift_sizes              = EXCLUDED.gift_sizes,
    relationship_stage      = EXCLUDED.relationship_stage,
    conversation_topics     = EXCLUDED.conversation_topics,
    additional_notes        = EXCLUDED.additional_notes,
    updated_at              = now();

  PERFORM set_config('app.prefs_sync_layer', '', true);
  RETURN NEW;
END;
$$;

-- Re-wire triggers (functions were replaced in-place so DROP/CREATE not strictly needed,
-- but ensures clean state if the trigger definition changed)
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
