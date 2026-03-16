-- Add gift personalization columns to user_preferences (recipient identity, style, brands, sizes)
ALTER TABLE public.user_preferences
  ADD COLUMN IF NOT EXISTS gift_recipient_identity text,
  ADD COLUMN IF NOT EXISTS gift_style text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS gift_favorite_brands text,
  ADD COLUMN IF NOT EXISTS gift_sizes text;
