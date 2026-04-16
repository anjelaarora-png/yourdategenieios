-- Ensure critical user-data tables cascade-delete when auth.users is removed.
-- The delete-account Edge Function (service-role) deletes the auth.users row;
-- this migration guarantees all dependent rows are cleaned up automatically.

-- Helper: drop all existing FKs from a table that reference auth.users, then
-- recreate with ON DELETE CASCADE. Uses dynamic SQL so constraint names don't matter.

DO $$
DECLARE
  r RECORD;
  col_name TEXT;
BEGIN
  -- ── profiles ──────────────────────────────────────────────────────────────
  FOR r IN
    SELECT c.conname, a.attname AS col
    FROM pg_constraint c
    JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
    WHERE c.conrelid  = 'public.profiles'::regclass
      AND c.confrelid = 'auth.users'::regclass
      AND c.contype   = 'f'
  LOOP
    EXECUTE format('ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS %I', r.conname);
    col_name := r.col;
  END LOOP;
  BEGIN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_id_fkey
      FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

  -- ── user_roles ─────────────────────────────────────────────────────────────
  FOR r IN
    SELECT c.conname
    FROM pg_constraint c
    WHERE c.conrelid  = 'public.user_roles'::regclass
      AND c.confrelid = 'auth.users'::regclass
      AND c.contype   = 'f'
  LOOP
    EXECUTE format('ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS %I', r.conname);
  END LOOP;
  BEGIN
    ALTER TABLE public.user_roles
      ADD CONSTRAINT user_roles_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

  -- ── couples (solo-couple row per user) ─────────────────────────────────────
  -- couples.user_id references auth.users; when a user is deleted their couple row goes too.
  FOR r IN
    SELECT c.conname
    FROM pg_constraint c
    WHERE c.conrelid  = 'public.couples'::regclass
      AND c.confrelid = 'auth.users'::regclass
      AND c.contype   = 'f'
  LOOP
    EXECUTE format('ALTER TABLE public.couples DROP CONSTRAINT IF EXISTS %I', r.conname);
  END LOOP;
  BEGIN
    ALTER TABLE public.couples
      ADD CONSTRAINT couples_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

END $$;

-- date_plans already references public.users (not auth.users directly) via user_id;
-- the profiles/users cascade above is sufficient — date_plans will be cleaned up through
-- the public.users delete that the Edge Function triggers via the profile cascade.
