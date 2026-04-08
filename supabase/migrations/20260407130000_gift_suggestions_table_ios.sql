-- Standalone gift rows (liked / purchased tracking per plan). Referenced by iOS `SupabaseService` (`gift_suggestions`).
-- `date_plans.gift_suggestions` JSONB is separate (embedded in plan payload). This table is for row-level gift state.

CREATE TABLE IF NOT EXISTS public.gift_suggestions (
  gift_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES public.date_plans(id) ON DELETE CASCADE,
  couple_id UUID NOT NULL REFERENCES public.couples(couple_id) ON DELETE CASCADE,
  name TEXT,
  price_range TEXT,
  description TEXT,
  why_it_fits TEXT,
  where_to_buy TEXT,
  liked BOOLEAN,
  purchased BOOLEAN NOT NULL DEFAULT false,
  purchased_at TIMESTAMPTZ,
  purchased_for_plan_id UUID REFERENCES public.date_plans(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gift_suggestions_plan ON public.gift_suggestions(plan_id);
CREATE INDEX IF NOT EXISTS idx_gift_suggestions_couple ON public.gift_suggestions(couple_id);
CREATE INDEX IF NOT EXISTS idx_gift_suggestions_fresh
  ON public.gift_suggestions(couple_id, purchased, liked)
  WHERE purchased = false AND (liked IS NULL OR liked = true);

ALTER TABLE public.gift_suggestions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Couples can view own gift_suggestions" ON public.gift_suggestions;
CREATE POLICY "Couples can view own gift_suggestions"
ON public.gift_suggestions FOR SELECT
USING (
  couple_id IN (
    SELECT couple_id FROM public.couples
    WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
  )
);

DROP POLICY IF EXISTS "Couples can insert own gift_suggestions" ON public.gift_suggestions;
CREATE POLICY "Couples can insert own gift_suggestions"
ON public.gift_suggestions FOR INSERT
WITH CHECK (
  couple_id IN (
    SELECT couple_id FROM public.couples
    WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
  )
);

DROP POLICY IF EXISTS "Couples can update own gift_suggestions" ON public.gift_suggestions;
CREATE POLICY "Couples can update own gift_suggestions"
ON public.gift_suggestions FOR UPDATE
USING (
  couple_id IN (
    SELECT couple_id FROM public.couples
    WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
  )
);

DROP POLICY IF EXISTS "Couples can delete own gift_suggestions" ON public.gift_suggestions;
CREATE POLICY "Couples can delete own gift_suggestions"
ON public.gift_suggestions FOR DELETE
USING (
  couple_id IN (
    SELECT couple_id FROM public.couples
    WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid()
  )
);

COMMENT ON TABLE public.gift_suggestions IS 'Per-plan gift ideas with like/skip/purchase; couple-scoped.';
