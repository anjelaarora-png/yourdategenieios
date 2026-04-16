import { Resend } from "https://esm.sh/resend@2.0.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const resend = new Resend(Deno.env.get("RESEND_API_KEY"));

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Admin email from environment variable with fallback
const ADMIN_EMAIL = Deno.env.get("ADMIN_NOTIFICATION_EMAIL") || "Anjela.arora@yourdategenie.com";

interface SignupNotification {
  user_id: string;
  email: string;
  display_name: string;
  created_at: string;
}

// Input validation
function validatePayload(payload: unknown): payload is SignupNotification {
  if (!payload || typeof payload !== "object") return false;
  const p = payload as Record<string, unknown>;
  return (
    typeof p.user_id === "string" && p.user_id.length > 0 && p.user_id.length <= 100 &&
    typeof p.email === "string" && p.email.length > 0 && p.email.length <= 254 &&
    (p.display_name === undefined || p.display_name === null || 
      (typeof p.display_name === "string" && p.display_name.length <= 200)) &&
    typeof p.created_at === "string"
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
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Authentication check - require valid JWT token
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
    const { data: claimsData, error: claimsError } = await supabaseClient.auth.getClaims(token);

    if (claimsError || !claimsData?.claims) {
      console.error("Invalid token:", claimsError);
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const userId = claimsData.claims.sub;
    console.log(`Authenticated user ${userId} sending signup notification`);

    const payload = await req.json();
    
    // Validate input
    if (!validatePayload(payload)) {
      console.error("Invalid payload format");
      return new Response(
        JSON.stringify({ error: "Invalid payload format" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Validate that the user_id in the payload matches the authenticated user
    if (payload.user_id !== userId) {
      console.error(`user_id mismatch: payload=${payload.user_id} jwt=${userId}`);
      return new Response(
        JSON.stringify({ error: "Forbidden: user_id does not match authenticated user" }),
        { status: 403, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    console.log("New signup notification received for user:", userId);

    const { user_id, email, display_name, created_at } = payload;
    const signupDate = new Date(created_at).toLocaleString("en-US", {
      dateStyle: "medium",
      timeStyle: "short",
    });

    const emailResponse = await resend.emails.send({
      from: "Your Date Genie <onboarding@resend.dev>",
      to: [ADMIN_EMAIL],
      subject: `🎉 New User Signup: ${escapeHtml(display_name || email).substring(0, 50)}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h1 style="color: #8B5CF6;">New User Signed Up! 🎉</h1>
          
          <div style="background: linear-gradient(135deg, #fef3c7, #fcd34d); padding: 20px; border-radius: 12px; margin: 20px 0;">
            <h2 style="margin: 0 0 10px 0; color: #78350f;">User Details</h2>
            <p style="margin: 5px 0;"><strong>Display Name:</strong> ${escapeHtml(display_name || "Not set")}</p>
            <p style="margin: 5px 0;"><strong>Email:</strong> ${escapeHtml(email)}</p>
            <p style="margin: 5px 0;"><strong>User ID:</strong> ${escapeHtml(user_id)}</p>
            <p style="margin: 5px 0;"><strong>Signed Up:</strong> ${escapeHtml(signupDate)}</p>
          </div>
          
          <p style="color: #666;">
            A new user has joined Your Date Genie! Head to your 
            <a href="https://yourdategenie.lovable.app/admin" style="color: #8B5CF6;">Admin Dashboard</a> 
            to see all users.
          </p>
          
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="color: #999; font-size: 12px;">
            This is an automated notification from Your Date Genie.
          </p>
        </div>
      `,
    });

    console.log("Signup notification email sent:", emailResponse);

    return new Response(JSON.stringify({ success: true, emailResponse }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: unknown) {
    console.error("Error sending signup notification:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: "Failed to send notification" }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
});