import { Resend } from "https://esm.sh/resend@2.0.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const resend = new Resend(Deno.env.get("RESEND_API_KEY"));

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface WelcomeEmailRequest {
  email: string;
  display_name: string;
  first_name: string;
}

function validatePayload(payload: unknown): payload is WelcomeEmailRequest {
  if (!payload || typeof payload !== "object") return false;
  const p = payload as Record<string, unknown>;
  return (
    typeof p.email === "string" && p.email.length > 0 && p.email.length <= 254 &&
    (p.display_name === undefined || p.display_name === null || 
      (typeof p.display_name === "string" && p.display_name.length <= 200)) &&
    (p.first_name === undefined || p.first_name === null || 
      (typeof p.first_name === "string" && p.first_name.length <= 100))
  );
}

function escapeHtml(text: string): string {
  const htmlEscapes: Record<string, string> = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  };
  return text.replace(/[&<>"']/g, (char) => htmlEscapes[char] || char);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Authentication check
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      console.error("Missing or invalid authorization header");
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    );

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);

    if (userError || !user) {
      console.error("Invalid token:", userError);
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    console.log(`Authenticated user ${user.id} requesting welcome email`);

    const payload = await req.json();
    
    if (!validatePayload(payload)) {
      console.error("Invalid payload format");
      return new Response(
        JSON.stringify({ error: "Invalid payload format" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const { email, display_name, first_name } = payload;
    const greeting = first_name || display_name || "there";

    console.log("Sending welcome email to:", email);

    // Send luxurious welcome email to the new user
    const welcomeEmailResponse = await resend.emails.send({
      from: "Your Date Genie <onboarding@resend.dev>",
      to: [email],
      subject: `Welcome to the magic ✨`,
      html: `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>Welcome to Your Date Genie</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Tangerine:wght@400;700&display=swap');
  </style>
</head>
<body style="margin: 0; padding: 0; background-color: #4A0E0E; font-family: 'Times New Roman', Times, Georgia, serif; -webkit-font-smoothing: antialiased;">
  <div style="width: 100%; background-color: #4A0E0E; padding: 40px 0;">
    <table cellpadding="0" cellspacing="0" border="0" width="100%">
      <tr>
        <td align="center">
          <div style="max-width: 600px; margin: 0 auto; background: linear-gradient(180deg, #4A0E0E 0%, #2D0808 100%); border-radius: 24px; overflow: hidden; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);">
            <!-- Header -->
            <div style="text-align: center; padding: 48px 40px 32px; background: linear-gradient(180deg, rgba(199, 166, 119, 0.15) 0%, transparent 100%);">
              <img src="https://jhpwacmsocjmzhimtbxj.supabase.co/storage/v1/object/public/assets/logo.png" 
                   alt="Your Date Genie" 
                   style="width: 80px; height: 80px; margin-bottom: 16px;">
              <h1 style="font-family: 'Tangerine', cursive; font-size: 52px; font-weight: 700; color: #C7A677; letter-spacing: 2px; margin: 0; line-height: 1.1;">
                ✨ Your Date Genie ✨
              </h1>
              <p style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 13px; font-weight: 400; color: #B8A090; letter-spacing: 3px; text-transform: uppercase; margin: 8px 0 0;">Crafting Unforgettable Moments</p>
              <div style="width: 80px; height: 1px; background: linear-gradient(90deg, transparent, #C7A677, transparent); margin: 28px auto;"></div>
            </div>
            
            <!-- Content -->
            <div style="padding: 0 48px 48px; text-align: center;">
              <p style="font-family: 'Tangerine', cursive; font-size: 36px; font-weight: 400; color: #C7A677; margin: 0 0 8px;">Dear ${escapeHtml(greeting)},</p>
              <h2 style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 36px; font-weight: 600; color: #FFF8F0; margin: 0 0 24px; line-height: 1.2; font-style: italic;">Your Genie Is Ready</h2>
              
              <p style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 16px; font-weight: 400; color: #E8D5C4; line-height: 1.9; margin: 0 0 40px;">
                Welcome to an exclusive world where every date becomes an 
                unforgettable experience. Your personal Date Genie is now at your 
                service, ready to craft magical moments tailored just for you.
              </p>
              
              <!-- Features -->
              <table cellpadding="0" cellspacing="0" border="0" width="100%" style="margin: 0 0 40px;">
                <tr>
                  <td>
                    <div style="display: block; text-align: left; margin-bottom: 16px; padding: 20px 24px; background: rgba(199, 166, 119, 0.05); border-radius: 16px; border: 1px solid rgba(199, 166, 119, 0.1);">
                      <span style="font-size: 24px; margin-right: 12px;">🎯</span>
                      <span style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 18px; font-weight: 600; color: #FFF8F0;">Personalized Date Plans</span>
                      <p style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 13px; font-weight: 400; color: #B8A090; margin: 8px 0 0 36px; line-height: 1.5;">AI-crafted experiences based on your unique preferences</p>
                    </div>
                  </td>
                </tr>
                <tr>
                  <td>
                    <div style="display: block; text-align: left; margin-bottom: 16px; padding: 20px 24px; background: rgba(199, 166, 119, 0.05); border-radius: 16px; border: 1px solid rgba(199, 166, 119, 0.1);">
                      <span style="font-size: 24px; margin-right: 12px;">🗺️</span>
                      <span style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 18px; font-weight: 600; color: #FFF8F0;">Curated Routes</span>
                      <p style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 13px; font-weight: 400; color: #B8A090; margin: 8px 0 0 36px; line-height: 1.5;">Seamlessly planned itineraries with perfect venues</p>
                    </div>
                  </td>
                </tr>
                <tr>
                  <td>
                    <div style="display: block; text-align: left; margin-bottom: 16px; padding: 20px 24px; background: rgba(199, 166, 119, 0.05); border-radius: 16px; border: 1px solid rgba(199, 166, 119, 0.1);">
                      <span style="font-size: 24px; margin-right: 12px;">🎁</span>
                      <span style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 18px; font-weight: 600; color: #FFF8F0;">Thoughtful Gift Suggestions</span>
                      <p style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 13px; font-weight: 400; color: #B8A090; margin: 8px 0 0 36px; line-height: 1.5;">Perfectly matched presents that speak from the heart</p>
                    </div>
                  </td>
                </tr>
                <tr>
                  <td>
                    <div style="display: block; text-align: left; padding: 20px 24px; background: rgba(199, 166, 119, 0.05); border-radius: 16px; border: 1px solid rgba(199, 166, 119, 0.1);">
                      <span style="font-size: 24px; margin-right: 12px;">📸</span>
                      <span style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 18px; font-weight: 600; color: #FFF8F0;">Memory Capture</span>
                      <p style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 13px; font-weight: 400; color: #B8A090; margin: 8px 0 0 36px; line-height: 1.5;">Beautiful journals to preserve your cherished moments</p>
                    </div>
                  </td>
                </tr>
              </table>
              
              <!-- CTA Section -->
              <div style="text-align: center; padding: 32px; background: linear-gradient(180deg, rgba(199, 166, 119, 0.08) 0%, rgba(199, 166, 119, 0.02) 100%); border-radius: 20px; margin: 0 0 32px;">
                <h3 style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 22px; font-weight: 500; color: #FFF8F0; margin: 0 0 16px; font-style: italic;">Ready to Create Magic?</h3>
                <a href="yourdategenie://home" style="display: inline-block; padding: 18px 48px; background: linear-gradient(135deg, #C7A677 0%, #D4B88A 50%, #C7A677 100%); color: #4A0E0E; text-decoration: none; font-family: 'Times New Roman', Times, Georgia, serif; font-size: 14px; font-weight: 600; letter-spacing: 1.5px; text-transform: uppercase; border-radius: 50px; box-shadow: 0 8px 24px rgba(199, 166, 119, 0.3);">
                  Start Planning Magic
                </a>
              </div>
              
              <!-- Sign-off -->
              <div style="text-align: center; margin-top: 32px;">
                <p style="font-family: 'Tangerine', cursive; font-size: 28px; color: #C7A677; margin: 0 0 8px;">Here's to unforgettable moments,</p>
                <p style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 14px; font-weight: 400; color: #A08070; margin: 0; font-style: italic;">The Your Date Genie Team</p>
              </div>
            </div>
            
            <!-- Footer -->
            <div style="padding: 32px 48px; text-align: center; border-top: 1px solid rgba(199, 166, 119, 0.1);">
              <div style="color: #C7A677; font-size: 24px; margin: 16px 0;">❧</div>
              <p style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 12px; color: #8A6A5A; margin: 0 0 8px;">
                Crafted with love for unforgettable moments
              </p>
              <p style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 12px; color: #8A6A5A; margin: 0;">
                <a href="https://yourdategenie.com" style="color: #C7A677; text-decoration: none;">yourdategenie.com</a>
              </p>
              <p style="font-family: 'Times New Roman', Times, Georgia, serif; font-size: 11px; color: #8A6A5A; margin: 16px 0 0;">
                © ${new Date().getFullYear()} Your Date Genie. All rights reserved.
              </p>
            </div>
          </div>
        </td>
      </tr>
    </table>
  </div>
</body>
</html>
      `,
    });

    console.log("Welcome email sent successfully:", welcomeEmailResponse);

    return new Response(JSON.stringify({ success: true, emailResponse: welcomeEmailResponse }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: unknown) {
    console.error("Error sending welcome email:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: "Failed to send welcome email", details: errorMessage }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
});
