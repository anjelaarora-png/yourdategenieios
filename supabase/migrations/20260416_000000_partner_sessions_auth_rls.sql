-- Partner sessions: replace open USING(true) policies with auth.uid()-scoped ones.
-- partner_user_id was already added in 20260411160000_partner_planning_phase_ranking.sql.
-- All DROP POLICY statements are idempotent (IF EXISTS).

-- ── partner_sessions ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "partner_sessions_select_by_session_id" ON public.partner_sessions;
DROP POLICY IF EXISTS "partner_sessions_insert"               ON public.partner_sessions;
DROP POLICY IF EXISTS "partner_sessions_update"               ON public.partner_sessions;
DROP POLICY IF EXISTS "partner_sessions_select_v2"            ON public.partner_sessions;
DROP POLICY IF EXISTS "partner_sessions_insert_v2"            ON public.partner_sessions;
DROP POLICY IF EXISTS "partner_sessions_update_v2"            ON public.partner_sessions;
DROP POLICY IF EXISTS "partner_sessions_delete_v2"            ON public.partner_sessions;

-- SELECT: inviter, joined partner, or anyone viewing an unclaimed session
CREATE POLICY "partner_sessions_select_v2"
ON public.partner_sessions FOR SELECT
USING (
  auth.uid() = inviter_user_id
  OR auth.uid() = partner_user_id
  OR partner_user_id IS NULL
);

-- INSERT: any authenticated user (becomes the inviter)
CREATE POLICY "partner_sessions_insert_v2"
ON public.partner_sessions FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- UPDATE: inviter updates their session; any authed user can claim an unclaimed session;
-- confirmed partner can update their own data
CREATE POLICY "partner_sessions_update_v2"
ON public.partner_sessions FOR UPDATE
USING (
  auth.uid() = inviter_user_id
  OR auth.uid() = partner_user_id
  OR (partner_user_id IS NULL AND auth.uid() IS NOT NULL)
)
WITH CHECK (
  auth.uid() = inviter_user_id
  OR auth.uid() = partner_user_id
  OR (partner_user_id IS NULL AND auth.uid() IS NOT NULL)
);

-- DELETE: inviter only
CREATE POLICY "partner_sessions_delete_v2"
ON public.partner_sessions FOR DELETE
USING (auth.uid() = inviter_user_id);

-- ── partner_session_plans ─────────────────────────────────────────────────────
DROP POLICY IF EXISTS "partner_session_plans_select" ON public.partner_session_plans;
DROP POLICY IF EXISTS "partner_session_plans_insert" ON public.partner_session_plans;
DROP POLICY IF EXISTS "partner_session_plans_update" ON public.partner_session_plans;
DROP POLICY IF EXISTS "partner_session_plans_select_v2" ON public.partner_session_plans;
DROP POLICY IF EXISTS "partner_session_plans_insert_v2" ON public.partner_session_plans;
DROP POLICY IF EXISTS "partner_session_plans_update_v2" ON public.partner_session_plans;

CREATE POLICY "partner_session_plans_select_v2"
ON public.partner_session_plans FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (
      auth.uid() = ps.inviter_user_id
      OR auth.uid() = ps.partner_user_id
      OR ps.partner_user_id IS NULL
    )
  )
);

CREATE POLICY "partner_session_plans_insert_v2"
ON public.partner_session_plans FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (auth.uid() = ps.inviter_user_id OR auth.uid() = ps.partner_user_id)
  )
);

CREATE POLICY "partner_session_plans_update_v2"
ON public.partner_session_plans FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (auth.uid() = ps.inviter_user_id OR auth.uid() = ps.partner_user_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (auth.uid() = ps.inviter_user_id OR auth.uid() = ps.partner_user_id)
  )
);

-- ── option_rankings ───────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "option_rankings_select"    ON public.option_rankings;
DROP POLICY IF EXISTS "option_rankings_insert"    ON public.option_rankings;
DROP POLICY IF EXISTS "option_rankings_update"    ON public.option_rankings;
DROP POLICY IF EXISTS "option_rankings_select_v2" ON public.option_rankings;
DROP POLICY IF EXISTS "option_rankings_insert_v2" ON public.option_rankings;
DROP POLICY IF EXISTS "option_rankings_update_v2" ON public.option_rankings;

-- Own rows always readable; also readable once winner is determined (both parties can see vote results)
CREATE POLICY "option_rankings_select_v2"
ON public.option_rankings FOR SELECT
USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1 FROM public.final_option_selection fos
    WHERE fos.partner_session_id = partner_session_id
  )
  OR EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND auth.uid() = ps.inviter_user_id
  )
);

CREATE POLICY "option_rankings_insert_v2"
ON public.option_rankings FOR INSERT
WITH CHECK (
  auth.uid() = user_id
  AND EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (auth.uid() = ps.inviter_user_id OR auth.uid() = ps.partner_user_id)
  )
);

CREATE POLICY "option_rankings_update_v2"
ON public.option_rankings FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ── final_option_selection ────────────────────────────────────────────────────
DROP POLICY IF EXISTS "final_option_select"    ON public.final_option_selection;
DROP POLICY IF EXISTS "final_option_insert"    ON public.final_option_selection;
DROP POLICY IF EXISTS "final_option_update"    ON public.final_option_selection;
DROP POLICY IF EXISTS "final_option_select_v2" ON public.final_option_selection;
DROP POLICY IF EXISTS "final_option_insert_v2" ON public.final_option_selection;
DROP POLICY IF EXISTS "final_option_update_v2" ON public.final_option_selection;

CREATE POLICY "final_option_select_v2"
ON public.final_option_selection FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (auth.uid() = ps.inviter_user_id OR auth.uid() = ps.partner_user_id)
  )
);

CREATE POLICY "final_option_insert_v2"
ON public.final_option_selection FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (auth.uid() = ps.inviter_user_id OR auth.uid() = ps.partner_user_id)
  )
);

CREATE POLICY "final_option_update_v2"
ON public.final_option_selection FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (auth.uid() = ps.inviter_user_id OR auth.uid() = ps.partner_user_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (auth.uid() = ps.inviter_user_id OR auth.uid() = ps.partner_user_id)
  )
);

-- ── plan_phase_history ────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "plan_phase_history_select"    ON public.plan_phase_history;
DROP POLICY IF EXISTS "plan_phase_history_insert"    ON public.plan_phase_history;
DROP POLICY IF EXISTS "plan_phase_history_select_v2" ON public.plan_phase_history;
DROP POLICY IF EXISTS "plan_phase_history_insert_v2" ON public.plan_phase_history;

CREATE POLICY "plan_phase_history_select_v2"
ON public.plan_phase_history FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (auth.uid() = ps.inviter_user_id OR auth.uid() = ps.partner_user_id)
  )
);

CREATE POLICY "plan_phase_history_insert_v2"
ON public.plan_phase_history FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.partner_sessions ps
    WHERE ps.id = partner_session_id
    AND (auth.uid() = ps.inviter_user_id OR auth.uid() = ps.partner_user_id)
  )
);
