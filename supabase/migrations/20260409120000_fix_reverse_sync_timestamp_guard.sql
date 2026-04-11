-- Fix: iOS → web reverse sync clobbers newer web saves with stale cached data.
--
-- Root cause: when the iOS app writes its locally-cached location ("Michigan") to
-- the `preferences` table, the reverse trigger (sync_preferences_to_user_preferences_row)
-- overwrites `user_preferences.default_city` unconditionally — even when the web
-- row was saved more recently.
--
-- Fix strategy:
--   1. Add a timestamp-aware guard to the reverse trigger so that each location/
--      preference field is only overwritten by an iOS sync if the `preferences`
--      row is genuinely newer than the `user_preferences` row.
--   2. One-time backfill: for every user where `user_preferences.updated_at`
--      is more recent than `preferences.updated_at`, copy the web values back
--      into `preferences` (making the web save the canonical state).

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Timestamp-aware reverse trigger: preferences (iOS) → user_preferences (web)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.sync_preferences_to_user_preferences_row()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_web_updated_at TIMESTAMPTZ;
BEGIN
  -- Prevent recursive loop from the forward trigger
  IF current_setting('app.prefs_sync_layer', true) = 'user_prefs_source' THEN
    RETURN NEW;
  END IF;

  PERFORM set_config('app.prefs_sync_layer', 'prefs_source', true);

  -- Look up how recently the web row was last saved
  SELECT updated_at INTO v_web_updated_at
  FROM public.user_preferences
  WHERE user_id = NEW.user_id;

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
    -- Non-location fields: always accept the iOS value (no conflict risk)
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
    -- Location fields: only overwrite if the iOS sync is genuinely newer than
    -- the last web save. This prevents stale cached iOS data (e.g. "Michigan")
    -- from clobbering a more recent web edit.
    default_city = CASE
      WHEN v_web_updated_at IS NULL OR NEW.updated_at > v_web_updated_at
        THEN EXCLUDED.default_city
      ELSE public.user_preferences.default_city
    END,
    default_neighborhood = CASE
      WHEN v_web_updated_at IS NULL OR NEW.updated_at > v_web_updated_at
        THEN EXCLUDED.default_neighborhood
      ELSE public.user_preferences.default_neighborhood
    END,
    default_starting_point = CASE
      WHEN v_web_updated_at IS NULL OR NEW.updated_at > v_web_updated_at
        THEN EXCLUDED.default_starting_point
      ELSE public.user_preferences.default_starting_point
    END,
    updated_at              = now();

  PERFORM set_config('app.prefs_sync_layer', '', true);
  RETURN NEW;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. One-time backfill: make the iOS preferences table match the web table for
--    every user where the web row was saved more recently (covers Mickey Mouse
--    and any other users with the same stale-iOS-cache problem).
--    Uses a DO block so column existence is checked at runtime — safe whether or
--    not the earlier migration that adds preferences.default_neighborhood has run.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  -- Track which optional columns actually exist on each table
  v_up_has_starting_point  BOOLEAN;
  v_p_has_starting_point   BOOLEAN;
  v_up_has_neighborhood    BOOLEAN;
  v_p_has_neighborhood     BOOLEAN;
BEGIN
  -- Disable triggers so the backfill doesn't trigger a recursive loop
  ALTER TABLE public.user_preferences DISABLE TRIGGER trg_user_preferences_sync_preferences;
  ALTER TABLE public.preferences      DISABLE TRIGGER trg_preferences_sync_user_preferences;

  -- Probe column existence on both tables at runtime
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_preferences' AND column_name = 'default_starting_point'
  ) INTO v_up_has_starting_point;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'preferences' AND column_name = 'default_starting_point'
  ) INTO v_p_has_starting_point;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_preferences' AND column_name = 'default_neighborhood'
  ) INTO v_up_has_neighborhood;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'preferences' AND column_name = 'default_neighborhood'
  ) INTO v_p_has_neighborhood;

  -- Always safe: default_city exists on both tables from the original schema.
  -- Correct every user where iOS preferences.default_city is stale vs the web row.
  UPDATE public.preferences p
  SET
    default_city = up.default_city,
    updated_at   = now()
  FROM public.user_preferences up
  WHERE p.user_id = up.user_id
    AND up.default_city IS NOT NULL
    AND (
      up.updated_at > p.updated_at
      OR p.default_city IS DISTINCT FROM up.default_city
    );

  -- Conditionally backfill default_starting_point when present on both sides
  IF v_up_has_starting_point AND v_p_has_starting_point THEN
    UPDATE public.preferences p
    SET
      default_starting_point = up.default_starting_point,
      updated_at             = now()
    FROM public.user_preferences up
    WHERE p.user_id = up.user_id
      AND up.default_city IS NOT NULL
      AND (
        up.updated_at > p.updated_at
        OR p.default_starting_point IS DISTINCT FROM up.default_starting_point
      );
  END IF;

  -- Conditionally backfill default_neighborhood when present on both sides
  IF v_up_has_neighborhood AND v_p_has_neighborhood THEN
    UPDATE public.preferences p
    SET
      default_neighborhood = up.default_neighborhood,
      updated_at           = now()
    FROM public.user_preferences up
    WHERE p.user_id = up.user_id
      AND up.default_city IS NOT NULL
      AND (
        up.updated_at > p.updated_at
        OR p.default_neighborhood IS DISTINCT FROM up.default_neighborhood
      );
  END IF;

  ALTER TABLE public.user_preferences ENABLE TRIGGER trg_user_preferences_sync_preferences;
  ALTER TABLE public.preferences      ENABLE TRIGGER trg_preferences_sync_user_preferences;
END;
$$;
