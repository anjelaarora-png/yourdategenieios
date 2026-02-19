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

    // Send welcome email to the new user
    const welcomeEmailResponse = await resend.emails.send({
      from: "Your Date Genie <onboarding@resend.dev>",
      to: [email],
      subject: `Welcome to Your Date Genie, ${escapeHtml(greeting)}! 💕`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0; background-color: #fef7f0; font-family: 'Georgia', serif;">
          <div style="max-width: 600px; margin: 0 auto; padding: 40px 20px;">
            <!-- Header -->
            <div style="text-align: center; margin-bottom: 40px;">
              <h1 style="color: #8B5CF6; font-size: 32px; margin: 0; font-weight: normal;">
                ✨ Your Date Genie ✨
              </h1>
              <p style="color: #a78bfa; font-size: 14px; margin-top: 8px; letter-spacing: 2px;">
                STOP PLANNING. START DATING.
              </p>
            </div>
            
            <!-- Welcome Message -->
            <div style="background: linear-gradient(135deg, #8B5CF6 0%, #a78bfa 100%); padding: 40px; border-radius: 16px; margin-bottom: 30px; text-align: center;">
              <h2 style="color: #ffffff; font-size: 28px; margin: 0 0 16px 0; font-weight: normal;">
                Welcome, ${escapeHtml(greeting)}! 💕
              </h2>
              <p style="color: #e9d5ff; font-size: 18px; margin: 0; line-height: 1.6;">
                Your romantic adventure begins now!
              </p>
            </div>
            
            <!-- Content -->
            <div style="background: #ffffff; padding: 32px; border-radius: 16px; margin-bottom: 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
              <h3 style="color: #7c3aed; font-size: 20px; margin: 0 0 20px 0;">
                🧞‍♂️ What Your Genie Can Do:
              </h3>
              
              <div style="margin-bottom: 20px; padding-left: 16px; border-left: 3px solid #e9d5ff;">
                <p style="color: #4b5563; margin: 0 0 8px 0; font-weight: bold;">🌹 Romantic Date Plans</p>
                <p style="color: #6b7280; margin: 0; font-size: 14px;">Complete itineraries tailored to your preferences</p>
              </div>
              
              <div style="margin-bottom: 20px; padding-left: 16px; border-left: 3px solid #e9d5ff;">
                <p style="color: #4b5563; margin: 0 0 8px 0; font-weight: bold;">💝 Thoughtful Gift Ideas</p>
                <p style="color: #6b7280; margin: 0; font-size: 14px;">Personalized suggestions that show you care</p>
              </div>
              
              <div style="margin-bottom: 20px; padding-left: 16px; border-left: 3px solid #e9d5ff;">
                <p style="color: #4b5563; margin: 0 0 8px 0; font-weight: bold;">💬 Conversation Starters</p>
                <p style="color: #6b7280; margin: 0; font-size: 14px;">Break the ice and deepen your connection</p>
              </div>
              
              <div style="padding-left: 16px; border-left: 3px solid #e9d5ff;">
                <p style="color: #4b5563; margin: 0 0 8px 0; font-weight: bold;">🧘‍♀️ Solo Self-Care Dates</p>
                <p style="color: #6b7280; margin: 0; font-size: 14px;">Because you deserve to treat yourself too</p>
              </div>
            </div>
            
            <!-- CTA Button -->
            <div style="text-align: center; margin-bottom: 30px;">
              <a href="https://yourdategenie.lovable.app/dashboard" 
                 style="display: inline-block; background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%); color: #78350f; padding: 16px 40px; border-radius: 50px; text-decoration: none; font-size: 18px; font-weight: bold; box-shadow: 0 4px 14px rgba(245, 158, 11, 0.4);">
                Plan Your First Date ✨
              </a>
            </div>
            
            <!-- Footer -->
            <div style="text-align: center; padding-top: 20px; border-top: 1px solid #e5e7eb;">
              <p style="color: #9ca3af; font-size: 14px; margin: 0 0 8px 0;">
                Questions? Just reply to this email!
              </p>
              <p style="color: #d1d5db; font-size: 12px; margin: 0;">
                © ${new Date().getFullYear()} Your Date Genie. Made with 💕
              </p>
            </div>
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
