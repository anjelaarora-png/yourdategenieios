-- Allow admins to view all date_plans
CREATE POLICY "Admins can view all plans"
ON public.date_plans
FOR SELECT
USING (public.has_role(auth.uid(), 'admin'));

-- Allow admins to view all date_memories
CREATE POLICY "Admins can view all memories"
ON public.date_memories
FOR SELECT
USING (public.has_role(auth.uid(), 'admin'));

-- Allow admins to view all user_preferences
CREATE POLICY "Admins can view all preferences"
ON public.user_preferences
FOR SELECT
USING (public.has_role(auth.uid(), 'admin'));