# Your Date Genie - Luxurious Email Templates

This folder contains the premium email templates for Your Date Genie.

## Brand Identity

- **Deep Burgundy:** `#4A0E0E`
- **Elegant Gold:** `#C7A677`  
- **Soft Cream:** `#FFF8F0`
- **Tone:** Sophisticated, romantic, magical, exclusive

## Templates

### 1. Confirmation Email (`confirmation.html`)

Used when a new user signs up and needs to verify their email address.

**Subject:** `Your magical journey awaits`

### 2. Welcome Email (`welcome.html`)

Sent after the user confirms their email address.

**Subject:** `Welcome to the magic ✨`

### 3. Reset Password Email (`reset-password.html`)

Sent when a user requests to reset their password.

**Subject:** `Reset your password`

## Supabase Configuration

### Step 1: Configure Site URL and Redirect URLs

1. Go to **Supabase Dashboard** → **Authentication** → **URL Configuration**
2. Set **Site URL** to: `yourdategenie://auth-callback`
3. Add to **Redirect URLs**:
   - `yourdategenie://auth-callback`
   - `yourdategenie://home`
   - (Add any web URLs if you have a web app)

### Step 2: Configure Email Templates

1. Go to **Supabase Dashboard** → **Authentication** → **Email Templates**

**Confirm Signup Template:**
2. Select **Confirm signup** template
3. Set **Subject**: `Your magical journey awaits`
4. Copy the contents of `confirmation.html` and paste into the HTML body
5. Make sure the confirmation URL variable `{{ .ConfirmationURL }}` is in the button href

**Reset Password Template:**
6. Select **Reset password** template
7. Set **Subject**: `Reset your password`
8. Copy the contents of `reset-password.html` and paste into the HTML body
9. Make sure the confirmation URL variable `{{ .ConfirmationURL }}` is in the button href

### Step 3: Enable Email Confirmations

1. Go to **Supabase Dashboard** → **Authentication** → **Settings**
2. Under **Email Auth**, ensure:
   - "Enable email confirmations" is **ON**
   - "Enable email provider" is **ON**

### Step 4: Set Up Welcome Email Trigger

The welcome email is sent via the Edge Function `send-welcome-email`. To trigger it automatically after email confirmation, you can:

#### Option A: Call from iOS app after successful auth
The iOS app already handles auth callbacks and can trigger the welcome email endpoint.

#### Option B: Use a Database Trigger (Advanced)
Create a PostgreSQL function and trigger:

```sql
-- Function to send welcome email
CREATE OR REPLACE FUNCTION send_welcome_email_trigger()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if email_confirmed_at was just set (changed from NULL)
  IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
    -- Call the edge function (requires pg_net extension)
    PERFORM net.http_post(
      url := 'https://jhpwacmsocjmzhimtbxj.supabase.co/functions/v1/send-welcome-email',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('request.jwt.claim.sub', true) || '"}'::jsonb,
      body := json_build_object(
        'email', NEW.email,
        'display_name', NEW.raw_user_meta_data->>'name',
        'first_name', split_part(NEW.raw_user_meta_data->>'name', ' ', 1)
      )::jsonb
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER on_email_confirmed
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION send_welcome_email_trigger();
```

## iOS Deep Link Configuration

The iOS app is already configured with:

1. **URL Scheme:** `yourdategenie://`
2. **Auth Callback Handler:** Handles `yourdategenie://auth-callback`
3. **Home Deep Link:** `yourdategenie://home`

When a user clicks the confirmation link in their email:
1. The link redirects to `yourdategenie://auth-callback?...`
2. The iOS app catches this deep link
3. The app processes the auth tokens and logs the user in
4. The welcome email is triggered

## Email Service Provider

These templates use **Resend** for sending emails through the Edge Functions.

Make sure the `RESEND_API_KEY` is set in your Supabase Edge Function secrets:

```bash
supabase secrets set RESEND_API_KEY=your_resend_api_key
```

## Testing

1. Create a new account in the app
2. Check your email for the elegant confirmation email
3. Click "Confirm & Begin Your Journey"
4. Verify you're redirected back to the app
5. Check for the welcome email

## Customization

To modify the templates:
1. Edit the HTML files in this folder
2. Update colors using the brand identity values above
3. Test in multiple email clients (Gmail, Apple Mail, Outlook)
4. Re-paste into Supabase dashboard for the confirmation template
5. Redeploy the edge function for the welcome template
