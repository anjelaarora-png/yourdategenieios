-- Standalone soundtrack playlists (widget / saved list) have no date_plans row.
-- Some databases were created with plan_id NOT NULL; the app sends null for those rows.
ALTER TABLE public.playlists
  ALTER COLUMN plan_id DROP NOT NULL;
