/** Extract a product/preview image URL from a purchase link (og:image, twitter:image). */

const USER_AGENT =
  "Mozilla/5.0 (compatible; YourDateGenie/1.0; +https://yourdategenie.com)";

function extractMeta(html: string, property: string): string | null {
  const patterns = [
    new RegExp(
      `<meta[^>]+(?:property|name)=["']${property}["'][^>]+content=["']([^"']+)["']`,
      "i",
    ),
    new RegExp(
      `<meta[^>]+content=["']([^"']+)["'][^>]+(?:property|name)=["']${property}["']`,
      "i",
    ),
  ];
  for (const re of patterns) {
    const m = html.match(re);
    if (m?.[1]) return m[1].trim();
  }
  return null;
}

function normalizeImageUrl(raw: string, baseUrl: string): string | null {
  const trimmed = raw.trim();
  if (!trimmed || trimmed.startsWith("data:")) return null;
  try {
    const url = trimmed.startsWith("http") ? new URL(trimmed) : new URL(trimmed, baseUrl);
    if (url.protocol !== "http:" && url.protocol !== "https:") return null;
    return url.toString();
  } catch {
    return null;
  }
}

export async function extractLinkPreviewImage(
  pageUrl: string,
  timeoutMs = 8000,
): Promise<string | null> {
  const trimmed = pageUrl?.trim();
  if (!trimmed || !trimmed.startsWith("http")) return null;

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
    let response: Response;
    try {
      response = await fetch(trimmed, {
        signal: controller.signal,
        redirect: "follow",
        headers: {
          Accept: "text/html,application/xhtml+xml",
          "User-Agent": USER_AGENT,
        },
      });
    } finally {
      clearTimeout(timeoutId);
    }

    if (!response.ok) return null;

    const contentType = response.headers.get("content-type") || "";
    if (!contentType.includes("text/html") && !contentType.includes("application/xhtml")) {
      return null;
    }

    const html = (await response.text()).slice(0, 250_000);
    const candidates = [
      extractMeta(html, "og:image:secure_url"),
      extractMeta(html, "og:image"),
      extractMeta(html, "twitter:image"),
    ];

    for (const candidate of candidates) {
      if (!candidate) continue;
      const normalized = normalizeImageUrl(candidate, response.url || trimmed);
      if (normalized) return normalized;
    }
  } catch (err) {
    console.warn("[linkPreview] Failed to fetch image from", trimmed, err);
  }

  return null;
}

export async function enrichGiftImages<T extends { purchaseUrl?: string; imageUrl?: string }>(
  gifts: T[],
  concurrency = 3,
): Promise<T[]> {
  const result = [...gifts];
  for (let i = 0; i < result.length; i += concurrency) {
    const batch = result.slice(i, i + concurrency);
    await Promise.all(
      batch.map(async (gift) => {
        if (gift.imageUrl?.startsWith("http")) return;
        if (!gift.purchaseUrl?.startsWith("http")) return;
        const imageUrl = await extractLinkPreviewImage(gift.purchaseUrl);
        if (imageUrl) gift.imageUrl = imageUrl;
      }),
    );
  }
  return result;
}
