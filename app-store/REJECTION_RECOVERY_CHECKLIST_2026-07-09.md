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

## 4. §1.2 screen recording (required — physical device)

Capture on a **physical iPhone or iPad** (Control Center → Screen Recording). Upload the file in **App Store Connect → App Review Information → Notes** (and attach / link in Resolution Center reply).

### Shot list (≈60–90 seconds)

1. **EULA before login** — Log out (or delete & reinstall). On the auth screen, show the Terms & Privacy checkbox with “no tolerance for objectionable content…”, tap **Terms** so the page opens, return, check the box, then Sign In / Sign Up. Do **not** proceed until the checkbox is checked.
2. **Report** — Sign in with the demo account → open **Plan Together** (Partner Planning). If needed, send a quick invite to a test email so you land on the **waiting** screen → tap **Report a Concern** → pick a category → write a short description → **Submit Report** → show the success alert (“within 24 hours”).
3. **Block** — On the same waiting screen, tap **Block & Unlink Partner** → confirm → show the session cleared / unpaired state immediately.

Optional (nice to have in the same clip): Settings → Support & safety → **Report a Concern** (second entry point).

- [ ] Recording captured on a physical device
- [ ] File attached / linked in App Review Information → Notes
- [ ] Resolution Center reply pasted (template below)
---

## 5. Attach IAPs to the new version + submit

- [ ] Archive + upload **new binary** from Xcode (build **11+**)
- [ ] Version page → **In-App Purchases and Subscriptions** → add **both** products
- [ ] Confirm both still **Ready to Submit**
- [ ] Paste updated `launch-day-artifacts/reviewer-notes.md` into App Review Notes (fill passwords)
- [ ] Submit for Review
- [ ] Reply in Resolution Center (template below)

### Resolution Center reply — Guideline 1.2 (copy/paste)

```
Thank you for the feedback regarding Guideline 1.2 (User-Generated Content).

Your Date Genie includes Partner Planning (Couple Plan), which is our only
user-to-user surface. This build implements all required precautions:

1. Filtering — Partner invite messages and notes are filtered for
   objectionable language before they can be shared.
2. Flagging — Users can Report a Concern from Plan Together (waiting
   screen) or Settings → Support & safety. Reports are stored and emailed
   to hello@yourdategenie.com.
3. Blocking — Block & Unlink Partner removes the session from the user’s
   feed immediately, prevents future invites from that user, and notifies
   the developer.
4. EULA — Terms of Use / Privacy Policy agreement is required before
   register or login, stating there is no tolerance for objectionable
   content or abusive users. Live Terms: https://yourdategenie.com/terms
5. 24-hour action — We review and act on reports within 24 hours
   (remove content and eject the offending user when warranted).

A screen recording on a physical device demonstrating (a) the EULA before
login, (b) Report a Concern, and (c) Block & Unlink Partner is attached in
App Review Information → Notes.

How to verify quickly:
• Auth screen → check Terms checkbox → open Terms link
• Plan Together waiting screen → Report a Concern → submit
• Same screen → Block & Unlink Partner → confirm (session clears)

Demo account:
Email: appstore.review@yourdategenie.com
Password: [YOUR REVIEWER PASSWORD]

Support: hello@yourdategenie.com
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


