# Cursor Task — Launch-mode feature flag (waitlist → App Store CTA swap)

**Owner:** Anjela (executing in Cursor)
**Specced by:** frontend-developer agent
**Priority:** P0 — without this, day-of-launch CTA swap requires a code deploy under pressure
**Estimated effort:** 1–2 hours

---

## Context for Cursor

Pre-launch (today through 2026-05-26): every CTA on the marketing site captures a waitlist email.

Day-of-launch (2026-05-27): every CTA should instead deep-link to the App Store listing.

Without a feature flag, swapping requires editing source, committing, deploying — all under pressure on launch day, while you're also doing PR, social posts, and customer support. We want a single env-var flip that takes effect immediately on deploy (or, better, takes effect without any deploy by reading from a runtime config).

Two viable approaches; pick simplest (option A).

---

## Locked decisions

- **Launch date / flip moment:** 2026-05-27 (configure `VITE_LAUNCH_MODE=launched` in Vercel/Netlify env at that time)
- **App Store URL placeholder:** `https://apps.apple.com/app/id{APP_STORE_ID}` — fill in real ID when assigned
- **Fallback behavior if `VITE_LAUNCH_MODE` is unset:** treat as `prelaunch` (show waitlist)

---

## Task breakdown

### Step 1 — Add env variable

`.env.example`:
```
VITE_LAUNCH_MODE=prelaunch
VITE_APP_STORE_URL=https://apps.apple.com/app/id0000000000
```

Document in README that valid `VITE_LAUNCH_MODE` values are `prelaunch` and `launched`.

### Step 2 — Create config module

`src/lib/launchConfig.ts`:

```typescript
export type LaunchMode = 'prelaunch' | 'launched'

export const launchMode: LaunchMode =
  (import.meta.env.VITE_LAUNCH_MODE as LaunchMode) === 'launched' ? 'launched' : 'prelaunch'

export const appStoreUrl =
  import.meta.env.VITE_APP_STORE_URL ?? 'https://apps.apple.com/app/your-date-genie'

export const isLaunched = launchMode === 'launched'
```

### Step 3 — Build the polymorphic CTA

`src/components/PrimaryCTA.tsx`:

```tsx
import { isLaunched, appStoreUrl } from '@/lib/launchConfig'
import { WaitlistForm } from './WaitlistForm'
import { Events } from '@/lib/analytics'

export function PrimaryCTA({
  source,
  appStorePlacement,
  className = '',
}: {
  source: string             // for waitlist tracking
  appStorePlacement: string  // for App Store click tracking
  className?: string
}) {
  if (isLaunched) {
    return (
      <a
        href={appStoreUrl}
        onClick={() => Events.appStoreClick(appStorePlacement)}
        className={`inline-flex items-center gap-3 rounded-xl bg-black px-6 py-4 text-white ${className}`}
      >
        <AppleLogo /> Download on App Store
      </a>
    )
  }

  return <WaitlistForm source={source} className={className} />
}

function AppleLogo() {
  return (
    <svg viewBox="0 0 24 24" className="h-6 w-6" fill="currentColor">
      <path d="M17.05 20.28c-.98.95-2.05.86-3.08.43-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.43C2.79 15.5 3.51 7.71 9.05 7.41c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 3.99l.01-.01M12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25"/>
    </svg>
  )
}
```

### Step 4 — Replace existing CTAs across the site

Find every existing CTA button on the marketing site. Likely places:
- Hero section (`src/components/Hero.tsx` or `src/pages/Index.tsx`)
- Pricing section
- Footer signup
- Any "Get Started" / "Try Date Genie" buttons

Replace each with `<PrimaryCTA source="..." appStorePlacement="..." />`.

Naming conventions for the props:
- `source` describes where the user came in via (used by waitlist analytics)
- `appStorePlacement` describes where on the page the button is (used by App Store click analytics)

Example replacements:

```tsx
// Hero
<PrimaryCTA source="landing_hero" appStorePlacement="hero" />

// Pricing
<PrimaryCTA source="landing_pricing" appStorePlacement="pricing" />

// Footer
<PrimaryCTA source="landing_footer" appStorePlacement="footer" />

// Sticky bottom bar (mobile)
<PrimaryCTA source="landing_sticky" appStorePlacement="sticky" />
```

### Step 5 — Add a launch banner component (optional but nice)

Create `src/components/LaunchBanner.tsx`:

```tsx
import { isLaunched } from '@/lib/launchConfig'

export function LaunchBanner() {
  if (!isLaunched) return null

  return (
    <div className="bg-gradient-to-r from-purple-600 to-pink-500 px-4 py-2 text-center text-sm font-medium text-white">
      Now live on the App Store
    </div>
  )
}
```

Mount it at the top of the layout. Once `VITE_LAUNCH_MODE=launched`, this banner appears site-wide automatically.

### Step 6 — Configure deploy environments

In Vercel/Netlify (whichever hosts the site), set environment variables:

**Production environment:**
- Now → 2026-05-26: `VITE_LAUNCH_MODE=prelaunch`
- 2026-05-27 onward: `VITE_LAUNCH_MODE=launched`

**Preview environments:**
- Always: `VITE_LAUNCH_MODE=launched` (so you can test the launched-state CTAs in PR previews)

Anjela's day-of-launch action: change the production env var, redeploy, done.

### Step 7 — Add a testing override (dev convenience)

In `launchConfig.ts`, allow URL override for testing:

```typescript
const urlMode = typeof window !== 'undefined'
  ? new URLSearchParams(window.location.search).get('launchMode')
  : null

export const launchMode: LaunchMode =
  urlMode === 'launched' ? 'launched' :
  urlMode === 'prelaunch' ? 'prelaunch' :
  (import.meta.env.VITE_LAUNCH_MODE as LaunchMode) === 'launched' ? 'launched' : 'prelaunch'
```

Now `?launchMode=launched` lets you preview the post-launch site without changing env vars.

---

## Verification checklist

- [ ] `VITE_LAUNCH_MODE=prelaunch` build → CTAs show waitlist form
- [ ] `VITE_LAUNCH_MODE=launched` build → CTAs show "Download on App Store" linking to App Store URL
- [ ] `?launchMode=launched` URL override flips the CTA without rebuild
- [ ] All existing CTAs across the site have been replaced with `<PrimaryCTA>`
- [ ] Launch banner appears only when `isLaunched` is true
- [ ] Plausible events fire correctly in both modes
- [ ] Deploy environments configured: production = prelaunch (until 5/27), previews = launched
- [ ] Documented in README how to flip on launch day (single env var change + redeploy)

## Out of scope

- iOS app feature flags (separate concern; iOS doesn't have a "launch mode")
- Geographic / time-zone-based auto-flip (manual env var change is fine for one-shot launch)
- A/B testing different launch states (we ship one launched site)

## When you're done

Tell me ("chief-of-staff, launch flag wired") and I'll mark P0 #11 as complete.
