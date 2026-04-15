-- Add title and location columns to date_memories so the iOS app's DateMemory.title
-- and DateMemory.location fields survive reinstalls and device switches.
-- Both are optional (existing rows get NULL) and safely applied with IF NOT EXISTS.
ALTER TABLE public.date_memories
  ADD COLUMN IF NOT EXISTS title    text,
  ADD COLUMN IF NOT EXISTS location text;
