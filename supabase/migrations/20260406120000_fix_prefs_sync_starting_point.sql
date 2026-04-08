-- Fix mirror triggers: starting point was written to preferences.default_starting_point using
-- NEW.default_neighborhood, and reverse sync wrote preferences.default_starting_point into
-- user_preferences.default_neighborhood instead of default_starting_point.

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
    NEW.default_starting_point,
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
    default_starting_point,
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
    default_starting_point = EXCLUDED.default_starting_point,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    updated_at = now();

  PERFORM set_config('app.prefs_sync_layer', '', true);
  RETURN NEW;
END;
$$;
