-- Drop and recreate user_stats view to include email
DROP VIEW IF EXISTS public.user_stats;

CREATE VIEW public.user_stats AS
SELECT 
    p.user_id,
    p.display_name,
    p.avatar_url,
    p.created_at AS signup_date,
    p.updated_at AS last_updated,
    COALESCE(ur.role, 'user'::app_role) AS role,
    au.email,
    (SELECT count(*) FROM date_plans dp WHERE dp.user_id = p.user_id) AS total_date_plans,
    (SELECT max(dp.created_at) FROM date_plans dp WHERE dp.user_id = p.user_id) AS last_plan_date
FROM profiles p
LEFT JOIN user_roles ur ON p.user_id = ur.user_id
LEFT JOIN auth.users au ON p.user_id = au.id;

-- Enable RLS on the view
ALTER VIEW public.user_stats SET (security_invoker = true);

-- Grant access to authenticated users (admins will be checked via RLS on underlying tables)
GRANT SELECT ON public.user_stats TO authenticated;