# App Store Rejection Recovery — Manual Checklist

**Rejection dates:** July 9, 2026 (build 9) · **July 29, 2026 (build 10)**  
**Devices:** iPad Air 11-inch (M3) / iPadOS 26.5.2  
**Submission ID (Jul 29):** ec3359fb-30bc-496d-8438-456bf8cc0ec6

Apple rejected build 10 for: (1) SIWA requiring name after auth, (2) subscription purchase error, (3) IAPs not submitted with the app, (4) §1.2 UGC precautions + screen recording.

**Code fixes ship in the next binary (build 11+).** Complete every checkbox below in App Store Connect before / with resubmit.

---

## 1. Paid Apps Agreement (blocks all IAP)

- [ ] App Store Connect → **Business** (or Agreements, Tax, and Banking)
- [ ] **Paid Apps Agreement** status = **Active**
- [ ] If you just signed it: wait up to 24 hours, then re-check product availability in Sandbox

---

## 2. Create / finish subscription products

App Store Connect → Your Date Genie (`com.yourdategenie.app`) → **Monetization → Subscriptions**

### Group

- [ ] Group named **Premium** (exact name optional; products must match IDs below)

### Products (exact product IDs — must match code)


| Product ID                          | Reference name  | Duration | Price       | Intro offer      |
| ----------------------------------- | --------------- | -------- | ----------- | ---------------- |
| `com.yourdategenie.premium.monthly` | Premium Monthly | 1 month  | **$14.99**  | Free, **7 days** |
| `com.yourdategenie.premium.annual`  | Premium Annual  | 1 year   | **$119.99** | Free, **7 days** |


For **each** product:

- [ ] US English localization: display name + description
- [ ] Introductory offer: Free / 7 days / one period
- [ ] Review screenshot uploaded (paywall showing plan name, price, trial, Privacy, Terms, Restore) — use `app-store/iap-review-screenshots/`
- [ ] Status shows **Ready to Submit**

### App Store Server Notifications V2

- [ ] Production URL: `https://jhpwacmsocjmzhimtbxj.supabase.co/functions/v1/apple-notifications-v2`
- [ ] Sandbox URL: same
- [ ] Version: **2**
- [ ] Send Test Notification → confirm Supabase function logs

---

## 3. Demo account + Sandbox tester

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

## 4. §1.2 screen recording (required for Jul 29 reply)

Capture on a **physical device** and attach in **App Review Information → Notes** (and/or Resolution Center):

1. Auth screen — Terms & Privacy checkbox before sign-in
2. Plan Together waiting screen → **Report a Concern** → submit success
3. **Block & Unlink Partner** → confirm → unpaired

- [ ] Recording captured and uploaded / linked in App Review Notes

---

## 5. Attach IAPs to the new version + submit

- [ ] Archive + upload **new binary** from Xcode (build **11+**)
- [ ] Version page → **In-App Purchases and Subscriptions** → add **both** products
- [ ] Confirm both still **Ready to Submit**
- [ ] Paste updated `launch-day-artifacts/reviewer-notes.md` into App Review Notes (fill passwords)
- [ ] Submit for Review
- [ ] Reply in Resolution Center (template below)

### Resolution Center reply (copy/paste)

```
Thank you for the feedback on submission ec3359fb-30bc-496d-8438-456bf8cc0ec6.

Guideline 4 (Sign in with Apple):
We removed the post-SIWA name collection screen. After Sign in with Apple,
the app no longer requires name or email — Authentication Services identity
is used as-is. Name may be edited later in Settings if the user chooses.

Guideline 2.1(b) — IAP:
Both auto-renewable subscriptions are submitted with this build and attached
to the version:
- com.yourdategenie.premium.monthly ($14.99/mo, 7-day free trial)
- com.yourdategenie.premium.annual ($119.99/yr, 7-day free trial)
The Paid Apps Agreement is Active. Products were tested in Sandbox on iPad.

Guideline 1.2 — UGC:
This build requires Terms & Privacy agreement before register/login (zero
tolerance for objectionable content/abusive users), filters partner free-text,
and provides Report + Block & Unlink on the Plan Together waiting screen
(instant unlink; developer notified; reports acted on within 24 hours).
A screen recording demonstrating EULA, Report, and Block is attached in
App Review Information Notes.

Demo account (email/password — core flow):
Email: appstore.review@yourdategenie.com
Password: [YOUR REVIEWER PASSWORD]

Sandbox Apple ID for IAP testing: [YOUR SANDBOX EMAIL / PASSWORD]
```

---

## 6. Pre-submit smoke (iPad + iPhone)


| Test                                                              | Pass |
| ----------------------------------------------------------------- | ---- |
| Auth shows Terms checkbox; email demo login → Home + plan         | [ ]  |
| Sign in with Apple → **no** name/email form after Apple sheet     | [ ]  |
| Paywall shows $14.99 / $119.99 (no orange load error)             | [ ]  |
| Sandbox purchase / trial starts                                   | [ ]  |
| Restore shows success or "No active subscription found…"          | [ ]  |
| Privacy + Terms links open                                        | [ ]  |
| Plan Together → Report a Concern → success (24h copy)             | [ ]  |
| Plan Together → Block & Unlink → session cleared                  | [ ]  |
| Objectionable invite message rejected by filter                   | [ ]  |


