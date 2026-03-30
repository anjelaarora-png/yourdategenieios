-- Per-user JSON buckets for love notes, saved conversation starters, and spark sessions (iOS restore after reinstall).

CREATE TABLE IF NOT EXISTS public.user_ios_sync_payload (
    user_id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
    love_notes JSONB NOT NULL DEFAULT '[]'::jsonb,
    saved_conversation_starters JSONB NOT NULL DEFAULT '[]'::jsonb,
    spark_sessions JSONB NOT NULL DEFAULT '[]'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_ios_sync_payload ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_ios_sync_select_own"
    ON public.user_ios_sync_payload FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "user_ios_sync_insert_own"
    ON public.user_ios_sync_payload FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_ios_sync_update_own"
    ON public.user_ios_sync_payload FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "user_ios_sync_delete_own"
    ON public.user_ios_sync_payload FOR DELETE
    USING (auth.uid() = user_id);
