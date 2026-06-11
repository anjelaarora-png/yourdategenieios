type EventProps = Record<string, string | number | boolean>

declare global {
  interface Window {
    plausible?: (
      event: string,
      options?: { props?: EventProps; callback?: () => void }
    ) => void
  }
}

export function trackEvent(event: string, props?: EventProps) {
  if (typeof window === "undefined" || !window.plausible) return
  window.plausible(event, props ? { props } : undefined)
}

/**
 * Typed event helpers — use these instead of calling trackEvent directly.
 *
 * Waitlist events (waitlistSignup, waitlistFormStarted) are wired up in
 * task 10 (Firebase waitlist capture). App Store click events are wired up
 * once App Store links are added to landing page components.
 */
export const Events = {
  /** Fire after successful waitlist form submission. source = utm_source or "direct". */
  waitlistSignup: (source: string) =>
    trackEvent("Waitlist Signup", { source }),

  /** Fire on focus of the waitlist email input. source = page section identifier. */
  waitlistFormStarted: (source: string) =>
    trackEvent("Waitlist Form Started", { source }),

  /** Fire on any "Download on App Store" click. placement = hero | footer | pricing | floating-cta */
  appStoreClick: (placement: string) =>
    trackEvent("App Store Click", { placement }),

  /** Fire once when the pricing section enters the viewport. */
  pricingViewed: () => trackEvent("Pricing Viewed"),

  /** Fire on clicks to IG, TikTok, or other external social links. */
  externalLinkClick: (destination: string) =>
    trackEvent("External Link Click", { destination }),
} as const
