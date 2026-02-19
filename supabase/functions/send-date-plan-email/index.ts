import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface DatePlanStop {
  order: number;
  name: string;
  venueType: string;
  timeSlot: string;
  duration: string;
  description: string;
  whyItFits: string;
  romanticTip: string;
  emoji: string;
  travelTimeFromPrevious?: string;
  validated?: boolean;
  address?: string;
}

interface GenieSecretTouch {
  title: string;
  description: string;
  emoji: string;
}

interface DatePlan {
  title: string;
  tagline: string;
  totalDuration: string;
  estimatedCost: string;
  stops: DatePlanStop[];
  genieSecretTouch: GenieSecretTouch;
  packingList: string[];
  weatherNote: string;
}

interface EmailRequest {
  email: string;
  plan: DatePlan;
  scheduledDate?: string;
  startTime?: string;
}

// Validation functions
function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email) && email.length <= 254;
}

function validatePlanData(plan: DatePlan): string | null {
  if (!plan.title || plan.title.length > 200) {
    return "Invalid plan title (max 200 characters)";
  }
  if (!plan.tagline || plan.tagline.length > 500) {
    return "Invalid plan tagline (max 500 characters)";
  }
  if (!Array.isArray(plan.stops) || plan.stops.length === 0 || plan.stops.length > 10) {
    return "Plan must have 1-10 stops";
  }
  for (const stop of plan.stops) {
    if (!stop.name || stop.name.length > 200) {
      return "Invalid stop name (max 200 characters)";
    }
    if (stop.description && stop.description.length > 1000) {
      return "Stop description too long (max 1000 characters)";
    }
  }
  return null;
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

function formatDate(dateStr?: string): string {
  if (!dateStr) return "TBD";
  try {
    return new Date(dateStr).toLocaleDateString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  } catch {
    return escapeHtml(dateStr);
  }
}

function generateEmailHTML(plan: DatePlan, scheduledDate?: string, startTime?: string): string {
  const stopsHTML = plan.stops.map(stop => `
    <tr>
      <td style="padding: 16px 0; border-bottom: 1px solid #e5e5e5;">
        <table width="100%" cellpadding="0" cellspacing="0">
          <tr>
            <td style="font-size: 20px; padding-right: 12px; vertical-align: top;">${escapeHtml(stop.emoji)}</td>
            <td style="width: 100%;">
              <h3 style="margin: 0 0 4px 0; font-size: 16px; color: #1a1a1a;">
                ${stop.order}. ${escapeHtml(stop.name)}
                ${stop.validated ? '<span style="color: #22c55e; font-size: 12px;"> ✓ Verified</span>' : ''}
              </h3>
              <p style="margin: 0 0 8px 0; font-size: 13px; color: #666;">
                🕐 ${escapeHtml(stop.timeSlot)} (${escapeHtml(stop.duration)}) • ${escapeHtml(stop.venueType)}
              </p>
              ${stop.address ? `<p style="margin: 0 0 8px 0; font-size: 13px; color: #888;">📍 ${escapeHtml(stop.address)}</p>` : ''}
              <p style="margin: 0 0 8px 0; font-size: 14px; color: #333; line-height: 1.5;">${escapeHtml(stop.description)}</p>
              <p style="margin: 0; font-size: 13px; color: #666; font-style: italic;">💡 ${escapeHtml(stop.romanticTip)}</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  `).join('');

  const packingListHTML = plan.packingList.length > 0 ? `
    <tr>
      <td style="padding: 24px 0;">
        <h2 style="margin: 0 0 12px 0; font-size: 18px; color: #1a1a1a;">🎒 What to Bring</h2>
        <ul style="margin: 0; padding-left: 20px; color: #333;">
          ${plan.packingList.slice(0, 20).map(item => `<li style="margin-bottom: 6px;">${escapeHtml(item.substring(0, 100))}</li>`).join('')}
        </ul>
      </td>
    </tr>
  ` : '';

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Date Plan - ${escapeHtml(plan.title)}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
          <!-- Header -->
          <tr>
            <td style="background: linear-gradient(135deg, #d4af37 0%, #f4e4bc 100%); padding: 32px; text-align: center;">
              <h1 style="margin: 0; font-size: 28px; color: #1a1a1a;">✨ ${escapeHtml(plan.title)}</h1>
              <p style="margin: 8px 0 0 0; font-size: 16px; color: #333; font-style: italic;">${escapeHtml(plan.tagline)}</p>
            </td>
          </tr>
          
          <!-- Quick Info -->
          <tr>
            <td style="padding: 24px; background-color: #fafafa; border-bottom: 1px solid #e5e5e5;">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="text-align: center; width: 33%;">
                    <p style="margin: 0; font-size: 13px; color: #666;">📅 Date</p>
                    <p style="margin: 4px 0 0 0; font-size: 14px; color: #1a1a1a; font-weight: 600;">${formatDate(scheduledDate)}</p>
                    ${startTime ? `<p style="margin: 2px 0 0 0; font-size: 13px; color: #666;">at ${escapeHtml(startTime)}</p>` : ''}
                  </td>
                  <td style="text-align: center; width: 33%;">
                    <p style="margin: 0; font-size: 13px; color: #666;">⏱️ Duration</p>
                    <p style="margin: 4px 0 0 0; font-size: 14px; color: #1a1a1a; font-weight: 600;">${escapeHtml(plan.totalDuration)}</p>
                  </td>
                  <td style="text-align: center; width: 33%;">
                    <p style="margin: 0; font-size: 13px; color: #666;">💰 Budget</p>
                    <p style="margin: 4px 0 0 0; font-size: 14px; color: #1a1a1a; font-weight: 600;">${escapeHtml(plan.estimatedCost)}</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          
          <!-- Itinerary -->
          <tr>
            <td style="padding: 24px;">
              <h2 style="margin: 0 0 16px 0; font-size: 20px; color: #1a1a1a;">Your Itinerary</h2>
              <table width="100%" cellpadding="0" cellspacing="0">
                ${stopsHTML}
              </table>
            </td>
          </tr>
          
          <!-- Genie's Secret Touch -->
          <tr>
            <td style="padding: 24px; background-color: #fffbeb;">
              <h2 style="margin: 0 0 12px 0; font-size: 18px; color: #1a1a1a;">✨ Genie's Secret Touch</h2>
              <p style="margin: 0 0 8px 0; font-size: 16px; color: #333; font-weight: 600;">
                ${escapeHtml(plan.genieSecretTouch.emoji)} ${escapeHtml(plan.genieSecretTouch.title)}
              </p>
              <p style="margin: 0; font-size: 14px; color: #555; line-height: 1.5;">
                ${escapeHtml(plan.genieSecretTouch.description)}
              </p>
            </td>
          </tr>
          
          <!-- Packing List -->
          ${packingListHTML}
          
          <!-- Weather Note -->
          ${plan.weatherNote ? `
          <tr>
            <td style="padding: 16px 24px; background-color: #f0f9ff; border-top: 1px solid #e5e5e5;">
              <p style="margin: 0; font-size: 14px; color: #0369a1;">
                🌤️ ${escapeHtml(plan.weatherNote)}
              </p>
            </td>
          </tr>
          ` : ''}
          
          <!-- Footer -->
          <tr>
            <td style="padding: 24px; text-align: center; background-color: #1a1a1a;">
              <p style="margin: 0; font-size: 14px; color: #d4af37;">
                Created with Your Date Genie ✨
              </p>
              <p style="margin: 8px 0 0 0; font-size: 12px; color: #888;">
                Have a magical date!
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `;
}

const handler = async (req: Request): Promise<Response> => {
  // Handle CORS preflight requests
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
    const { data: claimsData, error: claimsError } = await supabaseClient.auth.getClaims(token);

    if (claimsError || !claimsData?.claims) {
      console.error("Invalid token:", claimsError);
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const userId = claimsData.claims.sub;
    console.log(`Authenticated user ${userId} requesting email send`);

    const { email, plan, scheduledDate, startTime }: EmailRequest = await req.json();

    // Input validation
    if (!email || !plan) {
      return new Response(
        JSON.stringify({ error: "Email and plan are required" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    if (!validateEmail(email)) {
      console.error("Invalid email format:", email);
      return new Response(
        JSON.stringify({ error: "Invalid email address format" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const planError = validatePlanData(plan);
    if (planError) {
      console.error("Plan validation error:", planError);
      return new Response(
        JSON.stringify({ error: planError }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    console.log(`Sending date plan email to: ${email} for user ${userId}`);

    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
    if (!RESEND_API_KEY) {
      console.error("RESEND_API_KEY is not configured");
      return new Response(
        JSON.stringify({ error: "Email service not configured" }),
        { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Your Date Genie <onboarding@resend.dev>",
        to: [email],
        subject: `✨ Your Date Plan: ${plan.title.substring(0, 50)}`,
        html: generateEmailHTML(plan, scheduledDate, startTime),
      }),
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("Resend API error:", result);
      return new Response(
        JSON.stringify({ error: "Failed to send email" }),
        { status: response.status, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    console.log(`Email sent successfully for user ${userId}:`, result);

    return new Response(JSON.stringify({ success: true, ...result }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: unknown) {
    console.error("Error sending email:", error);
    return new Response(
      JSON.stringify({ error: "Failed to send email" }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
};

serve(handler);