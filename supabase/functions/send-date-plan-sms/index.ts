import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface SMSRequest {
  phoneNumber: string;
  plan: {
    title: string;
    tagline: string;
    totalDuration: string;
    estimatedCost: string;
    stops: Array<{
      order: number;
      emoji: string;
      name: string;
      timeSlot: string;
      address?: string;
    }>;
  };
  scheduledDate?: string;
  startTime?: string;
}

// Validation functions
function validatePhoneNumber(phone: string): boolean {
  // E.164 format validation - allows 7-15 digits with optional + prefix
  const cleaned = phone.replace(/[\s()\-]/g, "");
  const phoneRegex = /^\+?[1-9]\d{6,14}$/;
  return phoneRegex.test(cleaned);
}

function validatePlanData(plan: SMSRequest["plan"]): string | null {
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
    if (stop.address && stop.address.length > 500) {
      return "Invalid stop address (max 500 characters)";
    }
  }
  return null;
}

function sanitizeText(text: string): string {
  // Remove any potentially harmful characters for SMS
  return text.replace(/[<>]/g, "").trim();
}

function formatPlanForSMS(plan: SMSRequest["plan"], scheduledDate?: string, startTime?: string): string {
  let message = `🌹 ${sanitizeText(plan.title)}\n`;
  message += `"${sanitizeText(plan.tagline)}"\n\n`;
  
  if (scheduledDate) {
    message += `📅 ${sanitizeText(scheduledDate)}`;
    if (startTime) {
      message += ` at ${sanitizeText(startTime)}`;
    }
    message += `\n\n`;
  }
  
  message += `⏱ ${sanitizeText(plan.totalDuration)} | 💰 ${sanitizeText(plan.estimatedCost)}\n\n`;
  message += `📍 ITINERARY:\n`;
  
  plan.stops.forEach((stop) => {
    message += `${stop.order}. ${sanitizeText(stop.emoji)} ${sanitizeText(stop.name)}\n`;
    message += `   ${sanitizeText(stop.timeSlot)}\n`;
    if (stop.address) {
      message += `   📍 ${sanitizeText(stop.address)}\n`;
    }
  });
  
  message += `\n✨ Created with Your Date Genie`;
  
  return message;
}

const handler = async (req: Request): Promise<Response> => {
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
    console.log(`Authenticated user ${userId} requesting SMS send`);

    const { phoneNumber, plan, scheduledDate, startTime }: SMSRequest = await req.json();

    // Input validation
    if (!phoneNumber || !plan) {
      return new Response(
        JSON.stringify({ error: "Phone number and plan are required" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    if (!validatePhoneNumber(phoneNumber)) {
      console.error("Invalid phone number format:", phoneNumber);
      return new Response(
        JSON.stringify({ error: "Invalid phone number format" }),
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

    const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID");
    const authToken = Deno.env.get("TWILIO_AUTH_TOKEN");
    const twilioPhoneNumber = Deno.env.get("TWILIO_PHONE_NUMBER");

    if (!accountSid || !authToken || !twilioPhoneNumber) {
      console.error("Missing Twilio credentials");
      return new Response(
        JSON.stringify({ error: "SMS service not configured" }),
        { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const messageBody = formatPlanForSMS(plan, scheduledDate, startTime);
    
    // Format phone number - ensure it has country code
    let formattedPhone = phoneNumber.replace(/\D/g, "");
    if (!formattedPhone.startsWith("1") && formattedPhone.length === 10) {
      formattedPhone = "1" + formattedPhone; // Add US country code if missing
    }
    formattedPhone = "+" + formattedPhone;

    console.log(`Sending SMS to ${formattedPhone} for user ${userId}`);

    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;
    
    const response = await fetch(twilioUrl, {
      method: "POST",
      headers: {
        "Authorization": "Basic " + btoa(`${accountSid}:${authToken}`),
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        To: formattedPhone,
        From: twilioPhoneNumber,
        Body: messageBody,
      }),
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("Twilio error:", result);
      return new Response(
        JSON.stringify({ error: result.message || "Failed to send SMS" }),
        { status: response.status, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    console.log(`SMS sent successfully for user ${userId}:`, result.sid);

    return new Response(
      JSON.stringify({ success: true, messageId: result.sid }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (error: unknown) {
    console.error("Error in send-date-plan-sms function:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: "Failed to send SMS" }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
};

serve(handler);