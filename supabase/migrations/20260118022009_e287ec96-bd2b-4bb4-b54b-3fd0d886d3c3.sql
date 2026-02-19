-- First, let's insert the admin role for the existing user
-- We need to get the user_id from profiles and add them as admin
INSERT INTO public.user_roles (user_id, role)
SELECT user_id, 'admin'::app_role
FROM public.profiles
WHERE NOT EXISTS (
  SELECT 1 FROM public.user_roles 
  WHERE user_roles.user_id = profiles.user_id 
  AND user_roles.role = 'admin'
)
LIMIT 1;

-- Create a view for user statistics (easier to query)
CREATE OR REPLACE VIEW public.user_stats AS
SELECT 
  p.user_id,
  p.display_name,
  p.avatar_url,
  p.created_at as signup_date,
  p.updated_at as last_updated,
  COALESCE(ur.role, 'user') as role,
  (SELECT COUNT(*) FROM public.date_plans dp WHERE dp.user_id = p.user_id) as total_date_plans,
  (SELECT MAX(created_at) FROM public.date_plans dp WHERE dp.user_id = p.user_id) as last_plan_date
FROM public.profiles p
LEFT JOIN public.user_roles ur ON p.user_id = ur.user_id;

-- Grant access to the view
GRANT SELECT ON public.user_stats TO authenticated;

-- Create RLS policy for the view (admins only)
ALTER VIEW public.user_stats SET (security_invoker = true);

-- Create a function to check if current user is admin
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
    AND role = 'admin'
  );
$$;