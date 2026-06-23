export type JwtPayload = {
  role?: string;
  sub?: string;
};

/** Decode JWT payload (Supabase gateway may already verify when verify_jwt=true). */
export function decodeJwtPayload(authHeader: string | null): JwtPayload | null {
  if (!authHeader?.startsWith("Bearer ")) return null;
  try {
    const parts = authHeader.slice(7).split(".");
    if (parts.length !== 3) return null;
    const padded = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const pad = padded.length % 4 === 0 ? "" : "=".repeat(4 - (padded.length % 4));
    return JSON.parse(atob(padded + pad)) as JwtPayload;
  } catch {
    return null;
  }
}

export function requireAuthenticatedUser(authHeader: string | null): { sub: string } | null {
  const payload = decodeJwtPayload(authHeader);
  if (payload?.role !== "authenticated" || !payload.sub) return null;
  return { sub: payload.sub };
}
