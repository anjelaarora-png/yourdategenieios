-- Add user and partner gender to user_preferences for settings
ALTER TABLE public.user_preferences
  ADD COLUMN IF NOT EXISTS gender text,
  ADD COLUMN IF NOT EXISTS partner_gender text;
