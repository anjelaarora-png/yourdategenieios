-- Allow multiple beverage preferences: change drink_preferences from text to text[]
-- Existing single values are converted to a one-element array.

ALTER TABLE user_preferences
  ALTER COLUMN drink_preferences TYPE text[] USING (
    CASE
      WHEN drink_preferences IS NULL THEN NULL
      WHEN trim(drink_preferences) = '' THEN NULL
      ELSE ARRAY[drink_preferences]
    END
  );
