-- Fix 1: Restrict venues table SELECT to authenticated users only
DROP POLICY IF EXISTS "Anyone can view venues" ON public.venues;
CREATE POLICY "Authenticated users can view venues" 
ON public.venues 
FOR SELECT 
USING (auth.uid() IS NOT NULL);

-- Fix 2: Add DELETE policy for user_preferences table
CREATE POLICY "Users can delete their own preferences" 
ON public.user_preferences 
FOR DELETE 
USING (auth.uid() = user_id);