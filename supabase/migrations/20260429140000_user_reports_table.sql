-- user_reports: Apple §1.2 requirement — mechanism for users to report offensive content/behavior.
-- Admin reviews reports manually via Supabase dashboard for v1.

CREATE TABLE IF NOT EXISTS public.user_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reported_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    category TEXT NOT NULL CHECK (category IN ('harassment', 'inappropriate_content', 'spam', 'safety', 'other')),
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reviewed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_user_reports_reporter ON public.user_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_status ON public.user_reports(status);

ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create reports"
    ON public.user_reports
    FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

-- Only the reporter can see their own submitted reports — reported_id cannot see they were reported.
CREATE POLICY "Users can view own reports"
    ON public.user_reports
    FOR SELECT
    USING (auth.uid() = reporter_id);
