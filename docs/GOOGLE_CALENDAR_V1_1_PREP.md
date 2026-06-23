# Google Calendar — v1.1 Enablement Runbook

> **⏸️ PAUSED — circle back when ready (2026-06-23)**  
> OAuth **sensitive-scope verification is not submitted yet** — blocked on **demo video** (required for production; not needed for test users only).  
> **When you return:** (1) record 2–4 min unlisted YouTube per shot list in §2 below, (2) paste Additional info (~1000 chars — see chat), (3) submit verification in OAuth consent screen.  
> **Done:** Privacy policy updated for Google Calendar + Limited Use (2026-06-23).  
> **Until then:** keep consent screen in **Testing**, use **Test users** only, ship v1 with Apple Calendar for everyone — Google Calendar works only for test Gmail accounts.

**Status:** Google Calendar is **enabled in code** (`Config.isGoogleCalendarEnabled = true`). OAuth sensitive-scope verification may still be required for users outside your Google Cloud test-user list.
**Why:** The Google Calendar scopes we need (`calendar.readonly`, `calendar.events`) are **sensitive scopes**. Exposing them to real users before Google completes sensitive-scope verification risks both Google OAuth review enforcement and Apple App Store review problems. Base Google **sign-in** (auth-only) is unaffected and stays on in v1.

This document is the precise "do this to turn it on" runbook for v1.1. Do **not** flip the flag until every CONSOLE and PRIVACY/LEGAL step below is complete.

---

## 1. The exact code flip

There is a single source-of-truth flag.

- **File:** `ios/YourDateGenie/Config.swift`
- **Symbol:** `Config.isGoogleCalendarEnabled`
- **Current value:** `true`
- **To enable:** change it to `true` (one-line change).

```swift
// ios/YourDateGenie/Config.swift
static let isGoogleCalendarEnabled = false   // ← change to true for v1.1
```

That single flag controls all three behaviors below. No other code change is required to re-enable the feature.

### What the flag drives (already wired, do NOT re-edit)

1. **Provider picker re-appears** — `ios/YourDateGenie/Views/PartnerPlanning/PartnerPlanningSheetView.swift`, in `dateTimeTabContent`:

   ```swift
   if Config.isGoogleCalendarEnabled {
       calendarProviderPicker
   }
   ```

   When `true`, the Apple/Google segmented control (`calendarProviderPicker`) and the switch handler (`switchCalendarProvider(to:)`) become visible again. The "Your calendar" row subtitle (`calendarSync.provider.displayName`) will then reflect the chosen provider ("Apple Calendar" / "Google Calendar"). When `false`, the picker is hidden, the row always reads **"Apple Calendar"**, and the step behaves exactly as EventKit-only.

2. **Stored preference is honored again** — `ios/YourDateGenie/Managers/CalendarSyncManager.swift`, `init()`: when `false`, the manager force-sets `provider = .apple` regardless of any stored `calendarProvider` value in `UserDefaults`. When `true`, it restores the stored provider as before.

3. **`selectGoogleCalendar()` activates** — same file: when `false`, it is a no-op that stays on `.apple` and requests **no** Google calendar scopes. When `true`, it calls `GoogleCalendarService.connect()` (incremental scope request) and switches to `.google` only if scopes are granted.

> Net effect in v1: no Google calendar scope is ever requested during normal usage. The only scope interaction lives behind this flag.

### Verify after flipping

```bash
xcodebuild -project "ios/YourDateGenie.xcodeproj" -scheme "YourDateGenie" \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath ~/ydg_build_dd build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```

Expect `** BUILD SUCCEEDED **`.

---

## 2. Google Cloud Console steps (DO BEFORE flipping the flag)

Project: the existing Google Cloud project that owns our iOS OAuth client.

1. **Enable the API:** APIs & Services → Library → **Google Calendar API** → Enable.
2. **Add scopes to the OAuth consent screen:** APIs & Services → OAuth consent screen → Edit app → Scopes → Add:
   - `https://www.googleapis.com/auth/calendar.readonly` (powers freeBusy)
   - `https://www.googleapis.com/auth/calendar.events` (powers event insert)

   These are exactly the scopes declared in `GoogleCalendarService.calendarScopes`.
3. **Confirm the OAuth client:** No new client is needed. We reuse the **existing iOS OAuth client** (type "iOS"). The app reads `GIDClientID` from Info.plist (set via `GOOGLE_IOS_CLIENT_ID` in `Secrets.xcconfig`); the reversed client ID is registered as a URL scheme. Calendar access is added to that same client via **incremental authorization** — no client/config change.

### Sensitive-scope verification (the long pole)

`calendar.readonly` and `calendar.events` are **sensitive** (the broader `calendar` family can even be *restricted*; the two we use are sensitive, not restricted). Verification is required before the consent screen can serve these scopes to users outside your test list.

- **Timeline:** realistically **multiple weeks**, sometimes longer. Plan for it well ahead of the v1.1 ship date — do not block a release date on Google's queue.
- **Possible CASA security assessment:** Google may route the app through a **third-party CASA (Cloud Application Security Assessment)** Tier 2 review, which adds time and may carry a cost via the assessor. This is more likely for restricted scopes but can apply to sensitive scopes depending on Google's risk evaluation.
- **Artifacts Google asks for (prepare these in advance):**
  - **Scope justification** — a written explanation of why each scope is needed and how data is used (freeBusy to find mutually-free evenings; events to write the date plan). Keep it minimal-use and specific.
  - **Demo video** — a screen recording showing the OAuth consent flow and exactly how each granted scope is used in-app (connect Google → grant calendar scopes → free-evenings result → event written to calendar).
  - **Privacy policy URL** — public, must describe Google user-data usage (see §3).
  - **Homepage/app homepage URL** — public, on a domain you own and that is verified in Search Console for the same Google account.
  - **Authorized domain verification** in the consent screen.

### Test-users path (use this for pre-verification testing)

Before verification completes you can fully test the path without exposing it to the public:

- OAuth consent screen → **Test users** → add the Google accounts that will test (founder + testers).
- While in "Testing" publishing status, only those test users can grant the sensitive scopes. This is the supported way to QA the v1.1 flow before the flag is flipped for everyone.
- You can keep `isGoogleCalendarEnabled = false` in the shipped build and flip it locally (or in a TestFlight build) to exercise the flow with test users.

---

## 3. Privacy / Legal

**Privacy policy:** ✅ Updated live (2026-06-23) — Google Calendar usage + Limited Use for verification. Confirm the URL on the OAuth consent screen matches the published page (e.g. `https://yourdategenie.com/privacy-policy`).

Still to do before public Google Calendar (non–test users):

- **App Store privacy nutrition label:** Re-evaluate App Privacy in App Store Connect when Google Calendar ships broadly — calendar/event data used for app functionality; declare that it stays on-device / is not sent to your servers if accurate.

---

## 4. iOS specifics (how it actually works in our code)

- **Incremental authorization:** `GoogleCalendarService.authorize(interactive:)` reuses the existing GoogleSignIn session. If the user already signed in with Google, it calls `user.addScopes(calendarScopes, presenting:)` to request only the *additional* calendar scopes; if not signed in, it does `signIn(... additionalScopes: calendarScopes)`. `connect()` wraps this for the opt-in toggle and returns `true` only when the scopes are actually granted.
- **Per-device, per-partner:** Each partner authorizes their **own** Google Calendar on their **own** device. There is no cross-account calendar reading.
- **No server-side token storage (still true in v1.1):** We never persist Google access/refresh tokens server-side. Tokens live only in the GoogleSignIn SDK keychain on-device; `freshAccessToken(for:)` refreshes them on demand.
- **Free/busy exchange model is unchanged:** Mutual availability is computed by each side uploading its own free slots (see `PartnerSessionManager.syncAndComputeFreeEvenings`); we do not read a remote partner's calendar directly. Switching a side's backend from EventKit to Google changes only how *that* device computes its own free blocks (`GoogleCalendarService.findFreeEvenings` via the freeBusy endpoint).
- **Routing:** All calendar operations go through `CalendarSyncManager.shared`, which routes to `CalendarService` (Apple) or `GoogleCalendarService` (Google) based on `provider`. Call sites don't change between v1 and v1.1.

---

## 5. Test plan (run with a Google test user before flipping for all)

1. **Connect Google:** From the planning calendar step, tap Google in the picker → consent screen appears → grant calendar scopes → provider switches to `.google`, "Your calendar" reads "Google Calendar".
2. **Grant path:** With scopes granted, `findFreeEvenings` returns free evenings derived from real busy blocks.
3. **Deny path:** Tap Google → on consent, deny/uncheck the calendar scopes → `connect()` returns false → provider reverts to `.apple` ("Apple Calendar"), no false "connected" state.
4. **Cancel path:** Tap Google → dismiss/cancel the Google sheet → treated as cancelled → reverts to `.apple`, no error spam.
5. **freeBusy correctness:** Create known busy events in the test calendar in the evening window; confirm those evenings are excluded and only genuinely-free evenings are offered.
6. **Event insert with reminders:** Confirm a date plan from the Google path → event appears in the primary Google Calendar with correct title, time zone, location, and the two popup reminders (1440 min + 120 min).
7. **Token expiry / 401:** Force an expired/invalid token (or revoke access mid-session) → API returns 401/403 → surfaces the "access expired, please reconnect" message (`GoogleCalendarError.unauthorized`) rather than silently failing.
8. **Revert-to-Apple on denial / revocation:** After revoking access in the Google Account settings, returning to the step should not claim Google access; switching back to Apple must work and re-scan via EventKit.
9. **Stale preference safety (regression):** Ship with the flag false after a build where it was true; confirm `CalendarSyncManager.init()` forces `.apple` even if `UserDefaults` still holds `calendarProvider = google`.

---

## 6. v2 consideration (out of scope now)

The v1.1 model is strictly **client-side, per-device, no server token storage**. If we ever need **cross-device server-side Google Calendar access** (e.g., reading a partner's calendar without their device present, or background sync), that is a **separate backend OAuth build**: server-side OAuth flow, secure refresh-token storage, token rotation, and an additional layer of Google verification/security review. It is explicitly **out of scope** for v1.1 and should be planned as its own project.
