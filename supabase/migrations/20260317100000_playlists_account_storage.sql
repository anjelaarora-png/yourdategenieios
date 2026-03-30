-- Playlists table: store generated/saved soundtracks under user account (couple_id).
-- plan_id is nullable so we can save playlists not tied to a specific date plan.
CREATE TABLE IF NOT EXISTS public.playlists (
    playlist_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NULL,
    couple_id UUID NOT NULL,
    title TEXT,
    description TEXT,
    platform TEXT,
    external_url TEXT,
    external_playlist_id TEXT,
    tracks JSONB DEFAULT '[]',
    total_duration_minutes INT,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;

-- Users can only access playlists for their couple (couples table: user_id_1, user_id_2).
CREATE POLICY "Couples can view own playlists"
ON public.playlists FOR SELECT
USING (
    couple_id IN (
        SELECT couple_id FROM public.couples
        WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
    )
);

CREATE POLICY "Couples can insert own playlists"
ON public.playlists FOR INSERT
WITH CHECK (
    couple_id IN (
        SELECT couple_id FROM public.couples
        WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
    )
);

CREATE POLICY "Couples can update own playlists"
ON public.playlists FOR UPDATE
USING (
    couple_id IN (
        SELECT couple_id FROM public.couples
        WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
    )
);

CREATE POLICY "Couples can delete own playlists"
ON public.playlists FOR DELETE
USING (
    couple_id IN (
        SELECT couple_id FROM public.couples
        WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
    )
);

COMMENT ON TABLE public.playlists IS 'Soundtrack playlists generated or saved by the user; scoped by couple_id.';
