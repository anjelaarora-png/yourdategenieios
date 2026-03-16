/**
 * Detect user's timezone for VPN/location-aware currency.
 * Used when sending preferences to the backend so costs are shown in local currency.
 */
export function getClientTimeZone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || "";
  } catch {
    return "";
  }
}

/**
 * Optional: infer country from locale (e.g. en-IN -> IN). Less reliable than timezone for VPN users.
 */
export function getClientLocaleRegion(): string {
  try {
    const locale = navigator.language || (navigator as { userLanguage?: string }).userLanguage || "";
    const part = locale.split("-")[1];
    return part ? part.toUpperCase() : "";
  } catch {
    return "";
  }
}
