import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "./cors.ts";

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function extractMeta(html: string, key: string): string | null {
  const regexes = [
    new RegExp(`<meta[^>]+property=["']${key}["'][^>]+content=["']([^"']+)["']`, "i"),
    new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+property=["']${key}["']`, "i"),
    new RegExp(`<meta[^>]+name=["']${key}["'][^>]+content=["']([^"']+)["']`, "i"),
    new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+name=["']${key}["']`, "i"),
  ];
  for (const re of regexes) {
    const m = html.match(re);
    if (m) return decodeEntities(m[1]);
  }
  return null;
}

function extractEventJsonLd(html: string): Record<string, unknown> | null {
  const scriptRe = /<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let m: RegExpExecArray | null;
  while ((m = scriptRe.exec(html)) !== null) {
    try {
      const parsed = JSON.parse(m[1]);
      const items: unknown[] = Array.isArray(parsed) ? parsed : [parsed];
      for (const item of items) {
        if (item && typeof item === "object" && (item as Record<string, unknown>)["@type"] === "Event") {
          return item as Record<string, unknown>;
        }
      }
    } catch { /* skip */ }
  }
  return null;
}

function decodeEntities(str: string): string {
  return str.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&nbsp;/g, " ").trim();
}

function parseLocation(loc: unknown): string {
  if (!loc) return "";
  if (typeof loc === "string") return loc;
  const l = loc as Record<string, unknown>;
  const parts: string[] = [];
  if (typeof l.name === "string" && l.name) parts.push(l.name);
  const addr = l.address as Record<string, unknown> | undefined;
  if (addr) {
    if (typeof addr.streetAddress === "string" && addr.streetAddress) parts.push(addr.streetAddress);
    if (typeof addr.addressLocality === "string" && addr.addressLocality) parts.push(addr.addressLocality);
    if (typeof addr.addressRegion === "string" && addr.addressRegion) parts.push(addr.addressRegion);
  }
  return parts.join(", ");
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  // Verify that the caller is an authenticated admin user before processing.
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse(401, { error: "Unauthorized" });
  }

  const { createClient } = await import("https://esm.sh/@supabase/supabase-js@2");
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  const token = authHeader.slice(7);
  const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);
  if (authError || !user) {
    return jsonResponse(401, { error: "Unauthorized" });
  }

  // Check user_roles table for admin role
  const { data: roleRow } = await supabaseAdmin
    .from("user_roles")
    .select("role")
    .eq("user_id", user.id)
    .maybeSingle();

  const isAdmin =
    roleRow?.role === "admin" ||
    (user.app_metadata as Record<string, unknown>)?.role === "admin";

  if (!isAdmin) {
    return jsonResponse(403, { error: "Admin access required" });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const { url, dry_run } = body as { url?: string; dry_run?: boolean };

    if (!url || typeof url !== "string")
      return jsonResponse(400, { error: "Provide a valid Eventbrite URL in the `url` field." });
    if (!url.includes("eventbrite."))
      return jsonResponse(400, { error: "URL must be an Eventbrite link." });

    const pageRes = await fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        Accept: "text/html,application/xhtml+xml",
        "Accept-Language": "en-US,en;q=0.9",
      },
      redirect: "follow",
    });

    if (!pageRes.ok)
      return jsonResponse(502, { error: `Could not fetch Eventbrite page (HTTP ${pageRes.status}). Ensure the event is public.` });

    const html = await pageRes.text();
    const jsonLd = extractEventJsonLd(html);

    const title = extractMeta(html, "og:title") ?? extractMeta(html, "twitter:title") ?? (jsonLd?.name as string | undefined) ?? "Untitled Event";
    const description = extractMeta(html, "og:description") ?? extractMeta(html, "description") ?? (jsonLd?.description as string | undefined) ?? "";
    const imageUrl = extractMeta(html, "og:image:secure_url") ?? extractMeta(html, "og:image") ?? extractMeta(html, "twitter:image") ?? "";

    let dateTime: string = new Date().toISOString();
    if (jsonLd?.startDate) {
      const parsed = new Date(jsonLd.startDate as string);
      if (!isNaN(parsed.getTime())) dateTime = parsed.toISOString();
    }

    const location = parseLocation(jsonLd?.location);
    console.log("[import-eventbrite-event] Parsed:", { title, dateTime, location, imageUrl });

    const eventRow = {
      title: title.slice(0, 255),
      description,
      date_time: dateTime,
      location: location.slice(0, 255),
      image_url: imageUrl,
      eventbrite_url: url,
      is_active: true,
    };

    // dry_run=true -> return parsed preview without writing to DB (used by iOS import form)
    if (dry_run) return jsonResponse(200, { preview: eventRow });

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data, error } = await supabase.from("events").insert(eventRow).select().single();
    if (error) throw new Error(error.message);

    return jsonResponse(200, { success: true, event: data });
  } catch (err) {
    console.error("[import-eventbrite-event] Error:", err);
    return jsonResponse(500, { error: (err as Error).message ?? "Unexpected error." });
  }
});
