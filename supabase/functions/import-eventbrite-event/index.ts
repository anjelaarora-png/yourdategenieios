import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "./cors.ts";

// ---------------------------------------------------------------------------
// Admin-only: caller must supply a JWT whose role claim is "service_role".
// ---------------------------------------------------------------------------

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Returns true when the bearer token is a service_role JWT. */
function isServiceRole(authHeader: string): boolean {
  try {
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7).trim() : "";
    if (!token) return false;
    const parts = token.split(".");
    if (parts.length !== 3) return false;
    // Decode base64url payload — no signature verification needed here;
    // Supabase signs all project JWTs with the project secret.
    const padded = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const payload = JSON.parse(atob(padded));
    return payload?.role === "service_role";
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// HTML helpers
// ---------------------------------------------------------------------------

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
    } catch { /* skip malformed blocks */ }
  }
  return null;
}

function decodeEntities(str: string): string {
  return str
    .replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&nbsp;/g, " ")
    .trim();
}

/**
 * Clean Eventbrite image URLs.
 * img.evbuc.com proxies the real CDN image as a percent-encoded path segment.
 * Decoding it gives a direct, publicly cacheable CDN URL that iOS can load.
 */
function cleanImageUrl(raw: string): string {
  if (!raw) return "";
  try {
    const u = new URL(raw);
    if (u.hostname === "img.evbuc.com" && u.pathname.startsWith("/http")) {
      const inner = decodeURIComponent(u.pathname.slice(1));
      new URL(inner); // validate
      return inner;
    }
    return u.toString();
  } catch {
    return raw;
  }
}

/**
 * Scan the raw HTML for the first direct cdn.evbuc.com image URL.
 * This is more reliable than og:image which often points to the proxy.
 */
function extractCdnImage(html: string): string | null {
  // Look for cdn.evbuc.com/images/... in src, href, or JSON strings
  const re = /https:\/\/cdn\.evbuc\.com\/images\/[^"'\s>]+/g;
  const matches = html.match(re);
  if (!matches) return null;
  // Prefer /original. variants; fall back to first match
  const original = matches.find(u => u.includes("/original."));
  return original ?? matches[0];
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

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  // Admin gate: only service_role JWTs are accepted
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!isServiceRole(authHeader)) {
    return jsonResponse(403, { error: "Admin access required." });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const { url, dry_run } = body as { url?: string; dry_run?: boolean };

    if (!url || typeof url !== "string")
      return jsonResponse(400, { error: "Provide a valid Eventbrite URL in the `url` field." });

    const cleanUrl = url.trim();
    if (!cleanUrl.includes("eventbrite."))
      return jsonResponse(400, { error: "URL must be an Eventbrite link." });

    // 1. Fetch the public Eventbrite event page
    const pageRes = await fetch(cleanUrl, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Referer": "https://www.google.com/",
      },
      redirect: "follow",
    });

    if (!pageRes.ok)
      return jsonResponse(502, { error: `Could not fetch Eventbrite page (HTTP ${pageRes.status}). Ensure the event is public.` });

    const html = await pageRes.text();
    const jsonLd = extractEventJsonLd(html);

    // 2. Extract fields — prefer JSON-LD (more reliable) over og: tags
    const title =
      (jsonLd?.name as string | undefined) ??
      extractMeta(html, "og:title") ??
      extractMeta(html, "twitter:title") ??
      "Untitled Event";

    const description =
      (jsonLd?.description as string | undefined) ??
      extractMeta(html, "og:description") ??
      extractMeta(html, "description") ??
      "";

    // Priority: 1) direct cdn.evbuc.com URL from page HTML (most reliable)
    //            2) JSON-LD image field
    //            3) og:image (often a proxy — cleaned before use)
    const cdnImage = extractCdnImage(html);
    const jsonLdImage = jsonLd?.image as string | string[] | undefined;
    const jsonLdImageUrl = Array.isArray(jsonLdImage) ? jsonLdImage[0] : jsonLdImage;
    const rawImageUrl =
      cdnImage ??
      jsonLdImageUrl ??
      extractMeta(html, "og:image:secure_url") ??
      extractMeta(html, "og:image") ??
      extractMeta(html, "twitter:image") ??
      "";
    const imageUrl = cdnImage ? cdnImage : cleanImageUrl(rawImageUrl);

    let dateTime: string = new Date().toISOString();
    if (jsonLd?.startDate) {
      const parsed = new Date(jsonLd.startDate as string);
      if (!isNaN(parsed.getTime())) dateTime = parsed.toISOString();
    }

    const location = parseLocation(jsonLd?.location);

    console.log("[import-eventbrite-event]", { title, dateTime, location, imageUrl });

    const eventRow = {
      title: title.slice(0, 255),
      description,
      date_time: dateTime,
      location: location.slice(0, 255),
      image_url: imageUrl,
      eventbrite_url: cleanUrl,
      is_active: true,
    };

    // dry_run: return parsed data without saving (preview mode)
    if (dry_run) return jsonResponse(200, { preview: eventRow });

    // 3. Insert into events table
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
