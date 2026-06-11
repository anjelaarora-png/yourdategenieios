# Cursor Task — Install Plausible analytics on web app

**Owner:** Anjela (executing in Cursor)
**Specced by:** frontend-developer agent
**Priority:** P0 — without analytics, launch-day funnel is unmeasurable
**Estimated effort:** 2–3 hours

---

## Context for Cursor

The web app currently has zero analytics. We can't measure: how many people visit the landing page, what % convert to waitlist, what sources (Reddit / IG / TikTok / direct) drive the most signups, where users drop off. On launch day this is critical — without it we're flying blind.

Plausible is the right choice over GA4 because:
- GDPR-compliant by default → no cookie banner needed (saves ~6 hours of legal/UX work)
- Lightweight (~1KB script vs GA4's ~50KB)
- Simple dashboard Anjela can read without training
- $9/month for the Growth plan; cancellable anytime

PostHog is overkill for v1; GA4 requires cookie banner; mixpanel is too expensive.

---

## Locked decisions

- **Domain to track:** `yourdategenie.com`
- **Plausible plan:** Growth (10k pageviews/mo) — sufficient for pre-launch + first month post-launch
- **Account:** Anjela creates at https://plausible.io (use `hello@yourdategenie.com`)
- **Custom events to track at minimum:**
  - `Waitlist Signup` (props: `source`)
  - `App Store Click` (props: `placement` — hero, footer, pricing)
  - `Pricing Viewed`
  - `Waitlist Form Started` (focus on email field)
  - `External Link Click` (props: `destination` — IG, TikTok)

---

## Task breakdown

### Step 1 — Anjela creates Plausible account + adds site

1. Sign up at https://plausible.io with `hello@yourdategenie.com`
2. Add site: `yourdategenie.com`
3. Pick "Growth — 10k pageviews" plan
4. Note the script snippet Plausible provides (looks like `<script defer data-domain="yourdategenie.com" src="https://plausible.io/js/script.js"></script>`)

### Step 2 — Install the Plausible script

If using Vite/React with no SSR, edit `index.html` (typically at web app root):

```html
<head>
  <!-- ...existing tags... -->
  <script defer data-domain="yourdategenie.com" src="https://plausible.io/js/script.tagged-events.outbound-links.js"></script>
</head>
```

Note: use the `script.tagged-events.outbound-links.js` variant — this enables custom event tracking via CSS class `plausible-event-name=` AND auto-tracks outbound link clicks. No extra setup.

If using Next.js or another SSR framework, use the official `next-plausible` package or equivalent; same effect.

### Step 3 — Create a typed wrapper

`src/lib/analytics.ts`:

```typescript
type EventProps = Record<string, string | number | boolean>

declare global {
  interface Window {
    plausible?: (event: string, options?: { props?: EventProps; callback?: () => void }) => void
  }
}

export function trackEvent(event: string, props?: EventProps) {
  if (typeof window === 'undefined' || !window.plausible) return
  window.plausible(event, props ? { props } : undefined)
}

// Pre-defined events for type safety
export const Events = {
  waitlistSignup: (source: string) => trackEvent('Waitlist Signup', { source }),
  waitlistFormStarted: (source: string) => trackEvent('Waitlist Form Started', { source }),
  appStoreClick: (placement: string) => trackEvent('App Store Click', { placement }),
  pricingViewed: () => trackEvent('Pricing Viewed'),
  externalLinkClick: (destination: string) => trackEvent('External Link Click', { destination }),
} as const
```

### Step 4 — Wire up the events

In the waitlist hook (`useWaitlist.ts`), after successful submit:

```typescript
import { Events } from '@/lib/analytics'

// inside submit(), after addDoc succeeds:
Events.waitlistSignup(entry.source)
```

In the waitlist form component, on email field focus:

```tsx
<input
  type="email"
  onFocus={() => Events.waitlistFormStarted(source)}
  // ...
/>
```

In any "Download on App Store" button:

```tsx
<a
  href="https://apps.apple.com/app/your-date-genie/id..."
  onClick={() => Events.appStoreClick('hero')}
>
  Download on App Store
</a>
```

In the pricing page or pricing section:

```tsx
useEffect(() => {
  Events.pricingViewed()
}, [])
```

### Step 5 — Add UTM parameter handling

Plausible auto-captures UTM params on pageview. To make sure marketing links work, document the convention in `docs/utm-conventions.md`:

```
?utm_source=instagram_bio
?utm_source=tiktok_bio
?utm_source=reddit&utm_campaign=r/dating
?utm_source=event&utm_campaign=poker_night_2026_05
```

### Step 6 — Add a goal funnel in Plausible dashboard

Anjela manual step in Plausible UI:
1. Go to Site Settings → Goals
2. Add goal: "Waitlist Signup" (Custom event)
3. Add goal: "App Store Click" (Custom event)
4. Funnel report: Pageview /waitlist → Waitlist Form Started → Waitlist Signup

This gives a clean funnel chart on launch day.

### Step 7 — Mobile app considerations (out of scope here, but flag)

iOS app analytics is a separate question. Recommended: skip for v1, install RevenueCat for paywall analytics post-launch (it covers subscription funnels for free up to $10k MRR). Plausible doesn't track native apps.

---

## Verification checklist

- [ ] Plausible script loads on `yourdategenie.com` (check Network tab in dev tools)
- [ ] Plausible Realtime dashboard shows your visit when you load the site
- [ ] Submitting the waitlist form fires `Waitlist Signup` event (visible in Plausible Realtime)
- [ ] Clicking an App Store button fires `App Store Click`
- [ ] Goals are configured in Plausible UI
- [ ] No cookie banner is shown (Plausible doesn't need consent under GDPR)
- [ ] Total bundle size impact < 5KB (Plausible script is ~1KB)
- [ ] Tested with `?utm_source=instagram_bio` URL — appears in Plausible Sources tab

## Out of scope

- iOS app analytics (RevenueCat post-launch)
- Server-side event tracking (waitlist confirms via client event for now)
- Heatmaps / session replay (not needed; Plausible doesn't do this)
- Event-to-CRM sync (not needed for v1)

## When you're done

Tell me ("chief-of-staff, plausible live") and I'll mark P0 #10 as complete.
