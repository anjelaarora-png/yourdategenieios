-- iOS app expects public.users and public.couples (and preferences) for profile + date plan sync.
-- Without these, after reinstall login finds no user/couple, so syncDatePlansFromCloud never runs and data appears gone.
-- This migration creates these tables if missing and ensures every auth user gets a user + couple row on signup.

-- Table: users (mirrors app's DBUser; user_id = auth.users.id)
CREATE TABLE IF NOT EXISTS public.users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    password_hash TEXT DEFAULT '',
    gender TEXT,
    birthday DATE,
    home_address TEXT,
    travel_mode TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Only allow users to read/update their own row; insert is done by trigger or service role
DROP POLICY IF EXISTS "Users can view own row" ON public.users;
CREATE POLICY "Users can view own row" ON public.users FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own row" ON public.users;
CREATE POLICY "Users can update own row" ON public.users FOR UPDATE
    USING (auth.uid() = user_id);

-- Allow insert so app can create row on signup (and for trigger)
DROP POLICY IF EXISTS "Users can insert own row" ON public.users;
CREATE POLICY "Users can insert own row" ON public.users FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Table: couples (app's DBCouple; one row per user with user_id_1 = auth user)
CREATE TABLE IF NOT EXISTS public.couples (
    couple_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_1 UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    user_id_2 UUID REFERENCES public.users(user_id) ON DELETE SET NULL,
    relationship_type TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_couples_user1 ON public.couples(user_id_1);
CREATE INDEX IF NOT EXISTS idx_couples_user2 ON public.couples(user_id_2);
ALTER TABLE public.couples ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own couples" ON public.couples;
CREATE POLICY "Users can view own couples" ON public.couples FOR SELECT
    USING (user_id_1 = auth.uid() OR user_id_2 = auth.uid());

DROP POLICY IF EXISTS "Users can insert couple as user1" ON public.couples;
CREATE POLICY "Users can insert couple as user1" ON public.couples FOR INSERT
    WITH CHECK (user_id_1 = auth.uid());

DROP POLICY IF EXISTS "Users can update own couple" ON public.couples;
CREATE POLICY "Users can update own couple" ON public.couples FOR UPDATE
    USING (user_id_1 = auth.uid() OR user_id_2 = auth.uid());

-- Table: preferences (app's DBPreferences) – only if not already present from other migrations
CREATE TABLE IF NOT EXISTS public.preferences (
    preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    couple_id UUID REFERENCES public.couples(couple_id) ON DELETE SET NULL,
    cuisine_types TEXT[],
    activity_types TEXT[],
    drink_preferences TEXT[],
    budget_range TEXT,
    love_languages TEXT[],
    food_allergies TEXT[],
    hard_nos TEXT[],
    accessibility_needs TEXT[],
    gender TEXT,
    partner_gender TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_preferences_user ON public.preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_preferences_couple ON public.preferences(couple_id);
ALTER TABLE public.preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own preferences" ON public.preferences;
CREATE POLICY "Users can view own preferences" ON public.preferences FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own preferences" ON public.preferences;
CREATE POLICY "Users can insert own preferences" ON public.preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own preferences" ON public.preferences;
CREATE POLICY "Users can update own preferences" ON public.preferences FOR UPDATE
    USING (auth.uid() = user_id);

-- Trigger: when a new auth user is created, create public.users and public.couples so login/sync work
CREATE OR REPLACE FUNCTION public.ensure_user_and_couple_for_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    u_id UUID := NEW.id;
    u_email TEXT := COALESCE(NEW.email, '');
    u_name TEXT := COALESCE(trim(NEW.raw_user_meta_data->>'name'), trim(NEW.raw_user_meta_data->>'display_name'), split_part(u_email, '@', 1), 'User');
BEGIN
    INSERT INTO public.users (user_id, name, email, password_hash, created_at)
    VALUES (u_id, u_name, u_email, '', now())
    ON CONFLICT (user_id) DO NOTHING;

    IF NOT EXISTS (SELECT 1 FROM public.couples WHERE user_id_1 = u_id) THEN
        INSERT INTO public.couples (user_id_1)
        VALUES (u_id);
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS ensure_user_couple_on_auth_signup ON auth.users;
CREATE TRIGGER ensure_user_couple_on_auth_signup
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.ensure_user_and_couple_for_auth_user();

-- Backfill: create user + couple for any existing auth.users that don't have a row yet (e.g. before this migration)
INSERT INTO public.users (user_id, name, email, password_hash, created_at)
SELECT id,
       COALESCE(trim(raw_user_meta_data->>'name'), trim(raw_user_meta_data->>'display_name'), split_part(COALESCE(email,''), '@', 1), 'User'),
       COALESCE(email, ''),
       '',
       created_at
FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO public.couples (user_id_1)
SELECT id FROM auth.users
WHERE NOT EXISTS (SELECT 1 FROM public.couples c WHERE c.user_id_1 = auth.users.id);
