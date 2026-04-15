-- Self-healing guard for user_preferences mirror rows.
--
-- Part 0 ensures every column referenced in the restore function and backfill
-- INSERT exists on both tables — safe to run even if prior migrations already
-- added them (ADD COLUMN IF NOT EXISTS is idempotent). This covers the case
-- where 20260407150000_sync_all_missing_fields.sql was not applied.

-- ─────────────────────────────────────────────────────────────────────────────
-- 0a. Ensure all required columns exist on user_preferences (web table)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.user_preferences
  ADD COLUMN IF NOT EXISTS love_languages          TEXT[],
  ADD COLUMN IF NOT EXISTS partner_love_languages  TEXT[],
  ADD COLUMN IF NOT EXISTS relationship_stage      TEXT,
  ADD COLUMN IF NOT EXISTS conversation_topics     TEXT[],
  ADD COLUMN IF NOT EXISTS additional_notes        TEXT,
  ADD COLUMN IF NOT EXISTS default_starting_point  TEXT,
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
  ADD COLUMN IF NOT EXISTS gender                  TEXT,
  ADD COLUMN IF NOT EXISTS partner_gender          TEXT,
  ADD COLUMN IF NOT EXISTS activity_preferences    TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS drink_preferences       TEXT,
  ADD COLUMN IF NOT EXISTS dietary_restrictions    TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS allergies               TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS accessibility_needs     TEXT[] DEFAULT '{}';

-- ─────────────────────────────────────────────────────────────────────────────
-- 0b. Ensure all required columns exist on preferences (iOS table)
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
-- 1. Restore function + AFTER DELETE trigger
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.restore_user_preferences_from_preferences()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Suppress the forward trigger to avoid a loop when the INSERT fires it.
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
  SELECT
    p.user_id,
    p.cuisine_types,
    p.activity_types,
    p.drink_preferences,
    p.dietary_restrictions,
    p.budget_range,
    p.food_allergies,
    p.hard_nos,
    p.accessibility_needs,
    p.gender,
    p.partner_gender,
    p.love_languages,
    p.partner_love_languages,
    p.default_city,
    p.default_starting_point,
    p.default_neighborhood,
    p.energy_level,
    p.transportation_mode,
    p.travel_radius,
    p.smoking_preference,
    p.smoking_activities,
    p.gift_recipient,
    p.gift_interests,
    p.gift_budget,
    p.gift_occasion,
    p.gift_notes,
    p.gift_recipient_identity,
    p.gift_style,
    p.gift_favorite_brands,
    p.gift_sizes,
    p.relationship_stage,
    p.conversation_topics,
    p.additional_notes,
    now()
  FROM public.preferences p
  WHERE p.user_id = OLD.user_id
  ON CONFLICT (user_id) DO NOTHING;

  PERFORM set_config('app.prefs_sync_layer', '', true);
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_preferences_self_heal ON public.user_preferences;
CREATE TRIGGER trg_user_preferences_self_heal
  AFTER DELETE ON public.user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public.restore_user_preferences_from_preferences();

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. One-time backfill: recreate missing mirror rows for all affected users
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.user_preferences DISABLE TRIGGER trg_user_preferences_sync_preferences;

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
SELECT
  p.user_id,
  p.cuisine_types,
  p.activity_types,
  p.drink_preferences,
  p.dietary_restrictions,
  p.budget_range,
  p.food_allergies,
  p.hard_nos,
  p.accessibility_needs,
  p.gender,
  p.partner_gender,
  p.love_languages,
  p.partner_love_languages,
  p.default_city,
  p.default_starting_point,
  p.default_neighborhood,
  p.energy_level,
  p.transportation_mode,
  p.travel_radius,
  p.smoking_preference,
  p.smoking_activities,
  p.gift_recipient,
  p.gift_interests,
  p.gift_budget,
  p.gift_occasion,
  p.gift_notes,
  p.gift_recipient_identity,
  p.gift_style,
  p.gift_favorite_brands,
  p.gift_sizes,
  p.relationship_stage,
  p.conversation_topics,
  p.additional_notes,
  now()
FROM public.preferences p
WHERE NOT EXISTS (
  SELECT 1 FROM public.user_preferences up WHERE up.user_id = p.user_id
)
ON CONFLICT (user_id) DO NOTHING;

ALTER TABLE public.user_preferences ENABLE TRIGGER trg_user_preferences_sync_preferences;
