-- Add gift search preferences to user_preferences table
ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS gift_recipient text,
ADD COLUMN IF NOT EXISTS gift_interests text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS gift_budget text,
ADD COLUMN IF NOT EXISTS gift_occasion text,
ADD COLUMN IF NOT EXISTS gift_notes text;