# API keys & third-party integrations

Single reference for **where each integration is configured** and **what breaks if it’s missing**.

| Integration | API key needed? | Where to configure | Used for |
|-------------|-----------------|-------------------|----------|
| **OpenAI** | Yes | Supabase secret `OPENAI_API_KEY` | Date plans, gifts, love-note rewrite |
| **Google Places** | Yes | iOS `Secrets.xcconfig` + Supabase secret + web `.env` | Autocomplete, geocoding, server venue verification |
| **Last.fm** | Yes | Supabase secret `LASTFM_API_KEY` | Playlist generation only |
| **OpenTable / Resy** | No | N/A (URLs + deep links) | Reservation links on stops; detected in AI output + `places.ts` |
| **Sign in with Apple** | No (Apple Developer + Supabase Auth) | Xcode entitlements + Supabase Apple provider | Login |
| **Google login** | No (Supabase Auth OAuth) | Supabase Google provider + redirect URL | Login |

---

## 1. OpenAI (server-side only)

**Never** put `OPENAI_API_KEY` in the iOS app, web bundle, or git.

| Edge function | Feature |
|---------------|---------|
| `generate-date-plan` | AI date itineraries |
| `generate-more-gifts` | Gift Finder suggestions |
| `rewrite-love-note` | Love Notes “make it poetic” |

```bash
supabase secrets set OPENAI_API_KEY=sk-... --project-ref jhpwacmsocjmzhimtbxj
supabase functions deploy generate-date-plan generate-more-gifts rewrite-love-note
```

iOS calls these via `SupabaseService` → `functions/v1/...` with the user’s JWT.

---

## 2. Google Places & Geocoding

One Google Cloud API key can serve all three surfaces. Enable **Places API** and **Geocoding API**.

### iOS app (client)

- File: `ios/Secrets.xcconfig` (copy from `Secrets.xcconfig.example`)
- Variable: `GOOGLE_PLACES_API_KEY`
- Read at runtime: `Config.swift` → `GooglePlacesService` (autocomplete, place details, route geocoding)

### Supabase (server)

- Secret: `GOOGLE_PLACES_API_KEY`
- Used in `generate-date-plan` → `places.ts` (`validateAllStops`, `geocodeAddress`)
- Without it: plans still generate, but stops are **unverified** (no Places cross-check)

```bash
supabase secrets set GOOGLE_PLACES_API_KEY=... --project-ref jhpwacmsocjmzhimtbxj
```

### Web app (Vite)

- Root `.env`: `VITE_GOOGLE_MAPS_API_KEY=...`
- Used in `src/components/ui/PlacesAutocompleteInput.tsx`

---

## 3. Last.fm (playlists only)

| Edge function | iOS entry point |
|---------------|-----------------|
| `generate-playlist` | `PlaylistWidgetView`, `SavedPlaylistsView` → `SupabaseService.generatePlaylist` |

```bash
supabase secrets set LASTFM_API_KEY=... --project-ref jhpwacmsocjmzhimtbxj
supabase functions deploy generate-playlist
```

Get a key: [last.fm/api/account/create](https://www.last.fm/api/account/create)

If missing, the app shows: *“Add LASTFM_API_KEY in Supabase → Edge Functions → Secrets.”*

See also: `docs/PLAYLIST_DEPLOY_STEPS.md`

---

## 4. OpenTable & Resy (no API keys)

There is **no** OpenTable or Resy developer API in this stack.

How reservations work:

1. **AI** (`generate-date-plan/prompt.ts`) may include `bookingUrl` on restaurant stops.
2. **Server** (`places.ts`) detects `opentable.com` / `resy.com` on venue websites → sets `reservationPlatforms`.
3. **iOS** (`ReservationWidgetView.swift`, `OpenTableReservationSafari`) opens booking URLs with platform-aware labels and iOS referrer params.

Nothing to add to `Secrets.xcconfig` or Supabase secrets for OpenTable/Resy.

---

## 5. Sign in with Apple

### iOS (code — already wired)

- `SocialAuthService` → `SupabaseService.signInWithApple`
- `AuthenticationView` — native `SignInWithAppleButton`
- Entitlement: `ios/YourDateGenie/YourDateGenie.entitlements` → `com.apple.developer.applesignin`

### Apple Developer (manual)

1. App ID → Sign in with Apple enabled
2. Services ID + key (.p8) if using web redirect (optional for native-only)

### Supabase Dashboard (manual)

**Authentication → Providers → Apple** — enable and paste Team ID, Key ID, private key, Services ID.

---

## 6. Google login

Uses **Supabase Auth PKCE OAuth** (no Google SDK in the app).

### iOS (code — already wired)

- `SocialAuthService.signInWithGoogle()` → `SupabaseService.signInWithGoogle()`
- Redirect: `yourdategenie://auth-callback` (see `Info.plist` URL scheme + `AppDelegate`)

### Supabase Dashboard (manual)

1. **Authentication → Providers → Google** — enable, paste OAuth client ID/secret from Google Cloud Console
2. **Authentication → URL configuration → Redirect URLs** — add:
   - `yourdategenie://auth-callback`
   - Your Supabase project callback URL (`https://<project>.supabase.co/auth/v1/callback`)

### Google Cloud Console

OAuth 2.0 client for **Web application** (Supabase callback) — not the Places API key.

---

## 7. Other Supabase secrets

See `supabase/secrets.example` for the full list (Resend, Twilio, Apple bundle ID for StoreKit, etc.).

---

## Quick verification

### iOS (`Config.validateConfiguration()`)

On launch, missing keys log as:

- `SUPABASE_URL` / `SUPABASE_ANON_KEY` — `ios/Secrets.xcconfig`
- `GOOGLE_PLACES_API_KEY` — same file

### Supabase

Dashboard → Edge Functions → Logs:

- `OPENAI_API_KEY is not configured` → set OpenAI secret
- `LASTFM_API_KEY not configured` → set Last.fm secret
- `[Validation] Cannot verify venues - missing API key` → set `GOOGLE_PLACES_API_KEY`

### Deploy checklist

```bash
supabase functions deploy generate-date-plan generate-more-gifts rewrite-love-note generate-playlist \
  validate-receipt delete-account submit-report send-welcome-email send-date-plan-email \
  notify-new-signup import-eventbrite-event send-date-plan-sms

# Apple webhook only — no JWT at gateway:
supabase functions deploy apple-notifications-v2 --no-verify-jwt
```

---

## Summary table

| Where you're running | File / location |
|----------------------|-----------------|
| **iOS** | `ios/Secrets.xcconfig` → `SUPABASE_*`, `GOOGLE_PLACES_API_KEY` |
| **Web** | Root `.env` → `VITE_*`, `VITE_GOOGLE_MAPS_API_KEY` |
| **Supabase Edge Functions** | Dashboard secrets or `supabase secrets set` — see `supabase/secrets.example` |
| **Apple / Google login** | Supabase Auth providers + Apple Developer portal (no app secrets) |
| **OpenTable / Resy** | No keys — booking URLs only |
