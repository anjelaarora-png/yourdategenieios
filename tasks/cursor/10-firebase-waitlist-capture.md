# Cursor Task — Wire pre-launch waitlist to Firebase Firestore

**Owner:** Anjela (executing in Cursor)
**Specced by:** frontend-developer agent
**Priority:** P0 — needed for IG/TikTok bio link + launch-day SMS
**Estimated effort:** 4–6 hours

---

## Context for Cursor

The pre-launch marketing funnel (IG bio, TikTok bio, paid Reddit posts, in-person event QR codes) needs ONE place to capture an email/phone before the app launches. Per founder decision (2026-04-29), waitlist lives in Firebase Firestore project `xcode-490005` (NOT Supabase). Reason: keeps marketing data separate from product data; Supabase project stays clean for authenticated app users only.

The web app currently has no Firebase SDK installed. Landing-page CTAs hardcode `/signup`, which requires full account creation — too much friction for a pre-launch waitlist.

---

## Locked decisions

- **Firebase project:** `xcode-490005`
- **Firestore collection:** `waitlist`
- **Document shape:** `{ email: string, phone?: string, source: string, createdAt: Timestamp, ipHash?: string, userAgent?: string, partnerEmail?: string }`
- **Sources we expect to see:** `landing_hero`, `landing_footer`, `instagram_bio`, `tiktok_bio`, `reddit_*` (per subreddit), `event_*` (per event)
- **Confirmation:** Show "You're on the list" inline + send confirmation email via Firestore-triggered Cloud Function (out of scope here; can use Firebase extension)

---

## Task breakdown

### Step 1 — Install Firebase SDK in web app

```bash
cd <web-app-root>   # whichever directory holds package.json for the marketing site
npm install firebase
```

### Step 2 — Create Firebase config module

`src/lib/firebase.ts`:

```typescript
import { initializeApp, getApps, getApp } from 'firebase/app'
import { getFirestore } from 'firebase/firestore'

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: 'xcode-490005',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
}

const app = getApps().length ? getApp() : initializeApp(firebaseConfig)
export const db = getFirestore(app)
```

### Step 3 — Add env vars

`.env.local` and `.env.example`:

```
VITE_FIREBASE_API_KEY=
VITE_FIREBASE_AUTH_DOMAIN=xcode-490005.firebaseapp.com
VITE_FIREBASE_STORAGE_BUCKET=xcode-490005.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=
VITE_FIREBASE_APP_ID=
```

Anjela populates from Firebase console → Project settings → General → Your apps → Web app config.

### Step 4 — Build the waitlist hook

`src/hooks/useWaitlist.ts`:

```typescript
import { useState } from 'react'
import { collection, addDoc, serverTimestamp, query, where, getDocs } from 'firebase/firestore'
import { db } from '@/lib/firebase'

export type WaitlistEntry = {
  email: string
  phone?: string
  source: string
  partnerEmail?: string
}

export function useWaitlist() {
  const [status, setStatus] = useState<'idle' | 'submitting' | 'success' | 'error' | 'duplicate'>('idle')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  async function submit(entry: WaitlistEntry) {
    setStatus('submitting')
    setErrorMessage(null)

    try {
      // De-dupe check
      const existing = await getDocs(
        query(collection(db, 'waitlist'), where('email', '==', entry.email.toLowerCase()))
      )
      if (!existing.empty) {
        setStatus('duplicate')
        return
      }

      await addDoc(collection(db, 'waitlist'), {
        ...entry,
        email: entry.email.toLowerCase(),
        createdAt: serverTimestamp(),
        userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : undefined,
      })
      setStatus('success')
    } catch (err: any) {
      console.error('Waitlist submission error:', err)
      setStatus('error')
      setErrorMessage(err.message ?? 'Something went wrong')
    }
  }

  return { status, errorMessage, submit }
}
```

### Step 5 — Replace landing-page CTA

In whatever component renders the landing-page hero CTA (likely `src/pages/Index.tsx` or `src/components/Hero.tsx`), swap the "Sign up" link for an inline waitlist form:

```tsx
import { useState } from 'react'
import { useWaitlist } from '@/hooks/useWaitlist'

export function WaitlistForm({ source }: { source: string }) {
  const [email, setEmail] = useState('')
  const { status, errorMessage, submit } = useWaitlist()

  if (status === 'success') {
    return (
      <div className="rounded-lg bg-green-50 p-4 text-green-900">
        You're on the list. We'll email you when Date Genie launches.
      </div>
    )
  }

  if (status === 'duplicate') {
    return (
      <div className="rounded-lg bg-blue-50 p-4 text-blue-900">
        You're already on the list — see you at launch.
      </div>
    )
  }

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        submit({ email, source })
      }}
      className="flex gap-2"
    >
      <input
        type="email"
        required
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="you@example.com"
        className="flex-1 rounded-lg border px-4 py-3"
      />
      <button
        type="submit"
        disabled={status === 'submitting'}
        className="rounded-lg bg-purple-600 px-6 py-3 font-medium text-white disabled:opacity-50"
      >
        {status === 'submitting' ? 'Adding…' : 'Join Waitlist'}
      </button>
      {status === 'error' && (
        <p className="text-sm text-red-600">{errorMessage}</p>
      )}
    </form>
  )
}
```

Use it in hero with `<WaitlistForm source="landing_hero" />` and in footer with `<WaitlistForm source="landing_footer" />`.

### Step 6 — Build a dedicated short waitlist page

Create `src/pages/Waitlist.tsx` at route `/waitlist` — a simple, mobile-first page that:
- Single H1: "Get early access to Date Genie"
- One paragraph: "We're launching soon. Drop your email and we'll send you a TestFlight invite the day we go live."
- The waitlist form (source defaults from `?src=` query param, fallback `direct`)
- Optional partner email field (collapsed by default, "Bringing your partner? Add their email")
- Footer: "By joining, you agree to receive launch updates. We'll never share your email."

This page is what goes in IG / TikTok / Reddit bios.

### Step 7 — Publish Firestore security rules

`firestore.rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /waitlist/{doc} {
      // Anyone can write a new entry, but only with required fields
      allow create: if request.resource.data.email is string
                    && request.resource.data.email.matches('.+@.+\\..+')
                    && request.resource.data.source is string
                    && request.resource.data.createdAt == request.time;
      // No reads, updates, or deletes from client
      allow read, update, delete: if false;
    }
  }
}
```

Deploy:
```bash
firebase deploy --only firestore:rules --project xcode-490005
```

### Step 8 — Add basic abuse rate-limiting (App Check)

Enable Firebase App Check with reCAPTCHA v3 provider on the web app. This stops bots from flooding the waitlist:

```typescript
// In firebase.ts, after initializeApp
import { initializeAppCheck, ReCaptchaV3Provider } from 'firebase/app-check'

if (typeof window !== 'undefined') {
  initializeAppCheck(app, {
    provider: new ReCaptchaV3Provider(import.meta.env.VITE_RECAPTCHA_SITE_KEY),
    isTokenAutoRefreshEnabled: true,
  })
}
```

Anjela manual: register reCAPTCHA v3 site at https://www.google.com/recaptcha/admin, paste site key into env, paste secret key into Firebase App Check console.

### Step 9 — Wire up confirmation email

Cleanest path: Firebase Extensions → install "Trigger Email" extension. Configure to read a `mail` collection. Then add a Cloud Function trigger on `waitlist` document creation:

```typescript
// functions/index.ts
import { onDocumentCreated } from 'firebase-functions/v2/firestore'
import { getFirestore } from 'firebase-admin/firestore'

export const sendWaitlistConfirmation = onDocumentCreated('waitlist/{id}', async (event) => {
  const data = event.data?.data()
  if (!data?.email) return

  await getFirestore().collection('mail').add({
    to: data.email,
    message: {
      subject: "You're on the Date Genie waitlist",
      html: `<p>Thanks for signing up! We'll email you as soon as Date Genie launches.</p><p>— The Date Genie team</p>`,
    },
  })
})
```

This is optional for shipping the waitlist — can launch waitlist first and add confirmation email after.

---

## Verification checklist

- [ ] `firebase` package installed in web app
- [ ] `src/lib/firebase.ts` initialized with project `xcode-490005`
- [ ] Submitting the form on landing page creates a doc in Firestore `waitlist` collection
- [ ] Document has correct shape: `email`, `source`, `createdAt`, `userAgent`
- [ ] Re-submitting same email shows the "already on the list" state (duplicate detection works)
- [ ] `/waitlist` route exists and is mobile-friendly
- [ ] Firestore rules deployed — anonymous client cannot read or delete
- [ ] App Check enabled with reCAPTCHA v3
- [ ] (Optional) Confirmation email sends within 60s of signup

## Out of scope

- Migrating waitlist data to Supabase at launch (separate task — at launch we email everyone an App Store / TestFlight link, then archive)
- SMS confirmation (email only for v1)
- Detailed analytics on waitlist (Plausible covers source attribution — task 11)

## When you're done

Tell me ("chief-of-staff, waitlist live") and I'll mark P0 #9 + #12 as complete (the Firestore work also resolves the social media bio link blocker).
