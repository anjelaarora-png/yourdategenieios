-- Add more preference columns to user_preferences table
ALTER TABLE public.user_preferences
ADD COLUMN IF NOT EXISTS transportation_mode text,
ADD COLUMN IF NOT EXISTS travel_radius text,
ADD COLUMN IF NOT EXISTS activity_preferences text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS drink_preferences text,
ADD COLUMN IF NOT EXISTS dietary_restrictions text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS allergies text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS accessibility_needs text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS smoking_preference text,
ADD COLUMN IF NOT EXISTS smoking_activities text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS default_city text,
ADD COLUMN IF NOT EXISTS default_neighborhood text;