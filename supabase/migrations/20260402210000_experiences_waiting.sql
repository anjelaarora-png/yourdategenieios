-- Experiences Waiting: unsaved generated date plans (separate from date_plans = saved/past).
-- Full plan payload in JSONB; scoped by user_id + couple_id like date_plans.

CREATE TABLE public.experiences_waiting (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  couple_id UUID REFERENCES public.couples(couple_id) ON DELETE SET NULL,
  plan JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_experiences_waiting_couple_id ON public.experiences_waiting(couple_id);
CREATE INDEX idx_experiences_waiting_user_id ON public.experiences_waiting(user_id);

ALTER TABLE public.experiences_waiting ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own experiences waiting"
ON public.experiences_waiting FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own experiences waiting"
ON public.experiences_waiting FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own experiences waiting"
ON public.experiences_waiting FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own experiences waiting"
ON public.experiences_waiting FOR DELETE
USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.experiences_waiting_default_couple_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;
  IF NEW.couple_id IS NULL THEN
    NEW.couple_id := (
      SELECT c.couple_id
      FROM public.couples c
      WHERE c.user_id_1 = NEW.user_id
      ORDER BY c.created_at
      LIMIT 1
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_experiences_waiting_default_couple_id ON public.experiences_waiting;
CREATE TRIGGER trg_experiences_waiting_default_couple_id
  BEFORE INSERT OR UPDATE OF user_id ON public.experiences_waiting
  FOR EACH ROW
  EXECUTE FUNCTION public.experiences_waiting_default_couple_id();

CREATE TRIGGER update_experiences_waiting_updated_at
  BEFORE UPDATE ON public.experiences_waiting
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
