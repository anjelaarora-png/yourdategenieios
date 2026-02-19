-- Create a function that calls the notify-new-signup edge function
CREATE OR REPLACE FUNCTION public.notify_new_signup()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_email text;
  payload jsonb;
BEGIN
  -- Get the user's email from auth.users
  SELECT email INTO user_email FROM auth.users WHERE id = NEW.user_id;
  
  -- Build the payload
  payload := jsonb_build_object(
    'user_id', NEW.user_id,
    'email', COALESCE(user_email, 'unknown'),
    'display_name', COALESCE(NEW.display_name, 'New User'),
    'created_at', NEW.created_at
  );
  
  -- Call the edge function using pg_net
  PERFORM net.http_post(
    url := 'https://vuqmxacjtrhsqvswxmxu.supabase.co/functions/v1/notify-new-signup',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    ),
    body := payload
  );
  
  RETURN NEW;
END;
$$;

-- Create trigger on profiles table (fires after new profile is created)
DROP TRIGGER IF EXISTS on_new_user_signup ON public.profiles;
CREATE TRIGGER on_new_user_signup
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_signup();