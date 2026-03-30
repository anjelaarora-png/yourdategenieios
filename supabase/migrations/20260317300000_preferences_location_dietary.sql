-- Add default_city, default_starting_point, and dietary_restrictions to preferences
-- so saved preferences automatically fill everywhere (questionnaire, Explore, Home, etc.).
ALTER TABLE public.preferences
  ADD COLUMN IF NOT EXISTS default_city TEXT,
  ADD COLUMN IF NOT EXISTS default_starting_point TEXT,
  ADD COLUMN IF NOT EXISTS dietary_restrictions TEXT[] DEFAULT '{}';
