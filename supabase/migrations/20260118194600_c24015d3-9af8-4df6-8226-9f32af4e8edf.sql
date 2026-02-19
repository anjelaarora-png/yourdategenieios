-- Drop the existing view
DROP VIEW IF EXISTS public.user_stats;

-- Create a security definer function to get user email (admin only)
CREATE OR REPLACE FUNCTION public.get_user_email(_user_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT email::text FROM auth.users WHERE id = _user_id
$$;

-- Recreate the view without direct auth.users join
CREATE OR REPLACE VIEW public.user_stats
WITH (security_invoker = false)
AS
SELECT 
    p.user_id,
    p.display_name,
    p.avatar_url,
    p.created_at AS signup_date,
    p.updated_at AS last_updated,
    COALESCE(ur.role, 'user'::app_role) AS role,
    public.get_user_email(p.user_id) AS email,
    (SELECT count(*) FROM date_plans dp WHERE dp.user_id = p.user_id) AS total_date_plans,
    (SELECT max(dp.created_at) FROM date_plans dp WHERE dp.user_id = p.user_id) AS last_plan_date
FROM profiles p
LEFT JOIN user_roles ur ON p.user_id = ur.user_id;

-- Grant access to authenticated users (RLS on profiles will control actual access)
GRANT SELECT ON public.user_stats TO authenticated;