-- Drop the problematic trigger and function that uses pg_net
DROP TRIGGER IF EXISTS on_new_user_signup ON public.profiles;
DROP FUNCTION IF EXISTS public.notify_new_signup();

-- Recreate a simpler function that doesn't block signup
-- The edge function will be called directly from the app instead
CREATE OR REPLACE FUNCTION public.notify_new_signup()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- This function is now a no-op placeholder
  -- Email notifications are handled separately
  RETURN NEW;
END;
$$;