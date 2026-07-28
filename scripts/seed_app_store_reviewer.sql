-- Seed data for the App Store review demo account.
-- Replace USER_ID_HERE with the auth.users UUID before running in Supabase SQL Editor.

-- ── Preferences (iOS reads `public.preferences`) ─────────────────────────────
INSERT INTO public.preferences (
    user_id,
    default_city,
    default_starting_point,
    default_neighborhood,
    energy_level,
    transportation_mode,
    travel_radius,
    cuisine_types,
    activity_types,
    drink_preferences,
    budget_range,
    gender,
    partner_gender,
    love_languages,
    relationship_stage,
    updated_at
) VALUES (
    'USER_ID_HERE'::uuid,
    'New York, NY',
    'Times Square, New York, NY',
    'Manhattan',
    'moderate',
    'walking',
    '30min',
    ARRAY['italian', 'american'],
    ARRAY['dining', 'drinks', 'entertainment'],
    ARRAY['wine', 'cocktails'],
    '$$',
    'woman',
    'man',
    ARRAY['quality_time', 'acts_of_service'],
    'dating',
    now()
)
ON CONFLICT (user_id) DO UPDATE SET
    default_city           = EXCLUDED.default_city,
    default_starting_point = EXCLUDED.default_starting_point,
    default_neighborhood   = EXCLUDED.default_neighborhood,
    energy_level           = EXCLUDED.energy_level,
    transportation_mode    = EXCLUDED.transportation_mode,
    travel_radius          = EXCLUDED.travel_radius,
    cuisine_types          = EXCLUDED.cuisine_types,
    activity_types         = EXCLUDED.activity_types,
    drink_preferences      = EXCLUDED.drink_preferences,
    budget_range           = EXCLUDED.budget_range,
    gender                 = EXCLUDED.gender,
    partner_gender         = EXCLUDED.partner_gender,
    love_languages         = EXCLUDED.love_languages,
    relationship_stage     = EXCLUDED.relationship_stage,
    updated_at             = now();

-- ── Premium access (server-side gate) ────────────────────────────────────────
DELETE FROM public.subscriptions
WHERE user_id = 'USER_ID_HERE'::uuid
  AND platform = 'ios'
  AND original_transaction_id = 'appstore-review-demo';

INSERT INTO public.subscriptions (
    user_id,
    platform,
    product_id,
    original_transaction_id,
    latest_transaction_id,
    status,
    tier,
    started_at,
    current_period_start,
    current_period_end,
    trial_end_at,
    last_verified_at
) VALUES (
    'USER_ID_HERE'::uuid,
    'ios',
    'com.yourdategenie.premium.annual',
    'appstore-review-demo',
    'appstore-review-demo',
    'trialing',
    'premium',
    now(),
    now(),
    now() + interval '1 year',
    now() + interval '1 year',
    now()
);

-- ── Display name on profile ──────────────────────────────────────────────────
INSERT INTO public.profiles (user_id, display_name)
VALUES ('USER_ID_HERE'::uuid, 'App Store Review')
ON CONFLICT (user_id) DO UPDATE SET display_name = EXCLUDED.display_name;
