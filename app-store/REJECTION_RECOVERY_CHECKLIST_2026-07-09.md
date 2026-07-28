# App Store Rejection Recovery — Manual Checklist

**Rejection date:** July 9, 2026 · **Build reviewed:** 1.0 (9) · **Device:** iPad Air 11-inch (M3)

Apple rejected for: (1) Sign in with Apple error, (2) IAPs not submitted with the app, (3) subscription screen error (empty products).

Code hardening for Sign in with Apple + paywall UX ships in the next binary. **You must complete every checkbox below in App Store Connect and Supabase before resubmitting.**

---

## 1. Paid Apps Agreement (blocks all IAP)

- [x] App Store Connect → **Business** (or Agreements, Tax, and Banking)
- [x] **Paid Apps Agreement** status = **Active**
- [x] If you just signed it: wait up to 24 hours, then re-check product availability in Sandbox

---

## 2. Create subscription products

App Store Connect → Your Date Genie (`com.yourdategenie.app`) → **Monetization → Subscriptions**

### Group

- [ ] Create group named **Premium** (exact name optional; products must match IDs below)

### Products (exact product IDs — must match code)


| Product ID                          | Reference name  | Duration | Price      | Intro offer      |
| ----------------------------------- | --------------- | -------- | ---------- | ---------------- |
| `com.yourdategenie.premium.monthly` | Premium Monthly | 1 month  | **$14.99** | Free, **7 days** |
| `com.yourdategenie.premium.annual`  | Premium Annual  | 1 year   | **$119.99** | Free, **7 days** |


For **each** product:

- [ ] US English localization: display name + description
- [ ] Introductory offer: Free / 7 days / one period
- [ ] Review screenshot uploaded (paywall showing plan name, price, trial, Privacy, Terms, Restore)
- [ ] Status shows **Ready to Submit**

### App Store Server Notifications V2

- [ ] Production URL: `https://jhpwacmsocjmzhimtbxj.supabase.co/functions/v1/apple-notifications-v2`
- [ ] Sandbox URL: same
- [ ] Version: **2**
- [ ] Send Test Notification → confirm Supabase function logs

---

## 3. Supabase — Sign in with Apple provider

Dashboard → project `jhpwacmsocjmzhimtbxj` → **Authentication → Providers → Apple**

- [ ] Provider **Enabled**
- [ ] **Team ID** pasted (Apple Developer → Membership)
- [ ] **Key ID** + full **.p8** private key (Apple Developer → Keys → Sign in with Apple)
- [ ] **Client IDs / Services ID** filled if the form requires it (native iOS still needs the key)
- [ ] Apple Developer → Identifiers → App ID `com.yourdategenie.app` → **Sign in with Apple** capability enabled
- [ ] Xcode entitlements include `com.apple.developer.applesignin` (already in repo)

### Verify

- [ ] Fresh install on **iPad** → Sign in with Apple → no "Sign In Error" alert
- [ ] Supabase → Authentication → Users → new user with Apple provider
- [ ] If it fails: Authentication → Logs → look for `bad_jwt`, nonce, or invalid claim errors

---

## 4. Demo account + Sandbox tester

```bash
export SUPABASE_SERVICE_ROLE_KEY="..."
export REVIEWER_PASSWORD="..."   # store in 1Password
./scripts/create_app_store_reviewer.sh
```

- [ ] Email login works: `appstore.review@yourdategenie.com`
- [ ] Premium/trialing row present (no paywall on demo account)
- [ ] Create a **Sandbox Apple ID** in App Store Connect → Users and Access → Sandbox
- [ ] Paste demo + Sandbox credentials into App Review Information (see `APP_STORE_REVIEW_ACCOUNT.md` and `launch-day-artifacts/reviewer-notes.md`)

---

## 5. Attach IAPs to the new version + submit

- [ ] Archive + upload **new binary** from Xcode (Apple required a new binary)
- [ ] Version page → **In-App Purchases and Subscriptions** → add **both** products
- [ ] Confirm both still **Ready to Submit**
- [ ] Submit for Review
- [ ] Reply in Resolution Center (template below)

### Resolution Center reply (copy/paste)

```
IAP: Both auto-renewable subscriptions (com.yourdategenie.premium.monthly and
com.yourdategenie.premium.annual) are now submitted for review with this build,
including App Review screenshots. The Paid Apps Agreement is Active.

Subscriptions screen: The error was caused by IAP products not yet being available
in App Store Connect. Products are now configured and tested in Sandbox on iPad.

Sign in with Apple: We verified the Supabase Apple provider configuration and tested
Sign in with Apple on iPad. Demo account for the core flow (email/password — do not
use Sign in with Apple for this account):

Email: appstore.review@yourdategenie.com
Password: [YOUR REVIEWER PASSWORD]

Sandbox Apple ID for IAP testing: [YOUR SANDBOX EMAIL / PASSWORD]
```

---

## 6. Pre-submit smoke (iPad + iPhone)


| Test                                                     | Pass |
| -------------------------------------------------------- | ---- |
| Email demo login → Home + plan generate                  | [ ]  |
| Sign in with Apple completes, no error alert             | [ ]  |
| Paywall shows $14.99 / $119.99 (no orange load error)    | [ ]  |
| Sandbox purchase / trial starts                          | [ ]  |
| Restore shows success or "No active subscription found…" | [ ]  |
| Privacy + Terms links open                               | [ ]  |


