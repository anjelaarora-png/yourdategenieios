import { Resend } from "https://esm.sh/resend@2.0.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const resend = new Resend(Deno.env.get("RESEND_API_KEY"));

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://yourdategenie.com",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MODERATION_EMAIL = "hello@yourdategenie.com";

const VALID_CATEGORIES = ["harassment", "inappropriate_content", "spam", "safety", "other"] as const;
type ReportCategory = typeof VALID_CATEGORIES[number];

interface ReportPayload {
  reportedId?: string;
  category: ReportCategory;
  description: string;
}

function isValidCategory(value: unknown): value is ReportCategory {
  return typeof value === "string" && (VALID_CATEGORIES as readonly string[]).includes(value);
}

function validatePayload(payload: unknown): payload is ReportPayload {
  if (!payload || typeof payload !== "object") return false;
  const p = payload as Record<string, unknown>;
  if (!isValidCategory(p.category)) return false;
  if (typeof p.description !== "string" || p.description.trim().length === 0) return false;
  if (p.description.length > 2000) return false;
  if (p.reportedId !== undefined && p.reportedId !== null) {
    if (typeof p.reportedId !== "string" || p.reportedId.length > 100) return false;
  }
  return true;
}

function escapeHtml(text: string): string {
  const map: Record<string, string> = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
  return text.replace(/[&<>"']/g, (c) => map[c] ?? c);
}

function categoryLabel(cat: ReportCategory): string {
  const labels: Record<ReportCategory, string> = {
    harassment: "Harassment",
    inappropriate_content: "Inappropriate content",
    spam: "Spam",
    safety: "Safety concern",
    other: "Other",
  };
  return labels[cat];
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const token = authHeader.replace("Bearer ", "");
    const { data: claimsData, error: claimsError } = await supabaseClient.auth.getClaims(token);

    if (claimsError || !claimsData?.claims) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const reporterId = claimsData.claims.sub as string;

    const payload = await req.json();
    if (!validatePayload(payload)) {
      return new Response(
        JSON.stringify({ error: "Invalid payload. Provide category and description." }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const { reportedId, category, description } = payload;

    // Use service role for the insert so RLS `reporter_id = auth.uid()` is satisfied via the JWT.
    const { data: reportRow, error: insertError } = await supabaseClient
      .from("user_reports")
      .insert({
        reporter_id: reporterId,
        reported_id: reportedId ?? null,
        category,
        description: description.trim(),
        status: "pending",
      })
      .select("id")
      .single();

    if (insertError) {
      console.error("Failed to insert report:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to save report. Please try again." }),
        { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const reportId = reportRow?.id ?? "unknown";

    // Send notification email to moderation inbox
    try {
      await resend.emails.send({
        from: "Your Date Genie Safety <onboarding@resend.dev>",
        to: [MODERATION_EMAIL],
        subject: `[Safety Report] ${categoryLabel(category)} — Report ID ${reportId}`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1 style="color: #8B1A1A;">New Safety Report</h1>

            <div style="background: #fff3cd; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107;">
              <p style="margin: 5px 0;"><strong>Report ID:</strong> ${escapeHtml(reportId)}</p>
              <p style="margin: 5px 0;"><strong>Category:</strong> ${escapeHtml(categoryLabel(category))}</p>
              <p style="margin: 5px 0;"><strong>Reporter ID:</strong> ${escapeHtml(reporterId)}</p>
              ${reportedId ? `<p style="margin: 5px 0;"><strong>Reported User ID:</strong> ${escapeHtml(reportedId)}</p>` : ""}
              <p style="margin: 5px 0;"><strong>Submitted:</strong> ${new Date().toLocaleString("en-US", { dateStyle: "medium", timeStyle: "short" })}</p>
            </div>

            <div style="background: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <h2 style="margin-top: 0; color: #333;">Description</h2>
              <p style="white-space: pre-wrap; color: #555;">${escapeHtml(description.trim())}</p>
            </div>

            <p style="color: #666; font-size: 13px;">
              Please review within 48 hours per your moderation policy.<br>
              View in <a href="https://supabase.com/dashboard" style="color: #8B1A1A;">Supabase Dashboard</a> → Table Editor → user_reports.
            </p>

            <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
            <p style="color: #999; font-size: 12px;">Your Date Genie LLC — automated safety notification</p>
          </div>
        `,
      });
    } catch (emailErr) {
      // Non-fatal: report is already saved; log the email failure but return success.
      console.error("Failed to send moderation email:", emailErr);
    }

    return new Response(JSON.stringify({ success: true, reportId }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: unknown) {
    console.error("submit-report error:", error);
    return new Response(
      JSON.stringify({ error: "An unexpected error occurred." }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
});
