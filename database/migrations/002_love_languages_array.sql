-- Migration: Change love_language (single) to love_languages (array) for multi-select support

-- Add new column
ALTER TABLE preferences ADD COLUMN IF NOT EXISTS love_languages TEXT[];

-- Migrate existing single value to array (for existing data)
UPDATE preferences
SET love_languages = CASE
  WHEN love_language IS NOT NULL AND love_language != '' THEN ARRAY[love_language]
  ELSE NULL
END;

-- Drop old column
ALTER TABLE preferences DROP COLUMN IF EXISTS love_language;
