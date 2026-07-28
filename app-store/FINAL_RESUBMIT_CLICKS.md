# Final clicks — clear the July 9 rejection

**Binary ready in repo:** version **1.0 (10)**  
Code + IAP screenshots + review notes are done. Only these console steps remain.

---

## A. App Store Connect — finish IAPs (15–30 min)

1. Monetization → Subscriptions → **Premium**
2. Confirm **both** products exist:
   - `com.yourdategenie.premium.monthly` → **$14.99**, 7-day free trial  
   - `com.yourdategenie.premium.annual` → **$119.99**, 7-day free trial  
3. Each product → localization (US English):
   - Monthly display name: `Premium Monthly`  
     Description: `Unlimited AI date plans with full Premium access.`
   - Annual display name: `Premium Annual`  
     Description: `Full Premium access for a year — best value.`
4. Each product → **Review Information** → App Review Screenshot:
   - Annual → `app-store/iap-review-screenshots/annual-premium.png` (1290×2796)  
   - Monthly → `app-store/iap-review-screenshots/monthly-premium.png`
5. Both must show **Ready to Submit**

### Server Notifications (if blank)
Production + Sandbox:  
`https://jhpwacmsocjmzhimtbxj.supabase.co/functions/v1/apple-notifications-v2`  
Version **2** → Send Test Notification

---

## B. Supabase — Sign in with Apple (10–20 min)

**Critical (most likely cause of the Apple review rejection):**  
Xcode Bundle ID is **`com.yourdategenie.app`** (not `com.yourdategenie.yourdategenie`).

1. Dashboard → `jhpwacmsocjmzhimtbxj` → Authentication → Providers → **Apple** → Enable  
2. Paste **Team ID**, **Key ID**, **.p8** from Apple Developer → Keys (Sign in with Apple)  
3. **Client IDs** field must include exactly:  
   `com.yourdategenie.app`  
   (If you currently have `com.yourdategenie.yourdategenie`, replace it or add `com.yourdategenie.app` as a comma-separated entry. Native iOS identity tokens use the Bundle ID as the audience.)  
4. Apple Developer → App ID `com.yourdategenie.app` → Sign in with Apple **ON**  
5. **Test on iPad** (fresh install): Sign in with Apple → no error → user appears in Auth → Users  

If it fails: Authentication → Logs (look for jwt / nonce / provider / audience errors).

---

## C. Demo + Sandbox credentials (10 min)

```bash
export SUPABASE_SERVICE_ROLE_KEY="..."
export REVIEWER_PASSWORD="..."   # 1Password
./scripts/create_app_store_reviewer.sh
```

- Confirm `appstore.review@yourdategenie.com` logs in and has Premium  
- Create Sandbox Apple ID in ASC → Users and Access → Sandbox  
- Paste both into App Review Information (templates in `app-store/APP_STORE_REVIEW_ACCOUNT.md`)

---

## D. Archive + upload build 1.0 (10) (20–40 min)

1. Xcode → open `ios/YourDateGenie.xcodeproj`  
2. Confirm version **1.0** / build **10**  
3. Product → Archive → Distribute App → App Store Connect  
4. In ASC version page:
   - Select the new build  
   - **In-App Purchases and Subscriptions** → add **both** products  
5. Paste reviewer notes from `launch-day-artifacts/reviewer-notes.md`  
6. Submit for Review  

### Smoke before Submit (iPad)
- [ ] Demo email login works  
- [ ] Sign in with Apple works  
- [ ] Paywall shows $14.99 / $119.99 (no load error)  
- [ ] Sandbox trial / restore works  

---

## E. Resolution Center reply (copy/paste)

```
IAP: Both auto-renewable subscriptions (com.yourdategenie.premium.monthly and
com.yourdategenie.premium.annual) are now submitted for review with build 1.0 (10),
including App Review screenshots. The Paid Apps Agreement is Active.

Subscriptions screen: The earlier error was caused by IAP products not yet being
available in App Store Connect. Products are now configured and tested in Sandbox
on iPad.

Sign in with Apple: We verified the Supabase Apple provider configuration and tested
Sign in with Apple on iPad. Demo account for the core flow (email/password — do not
use Sign in with Apple for this account):

Email: appstore.review@yourdategenie.com
Password: [YOUR REVIEWER PASSWORD]

Sandbox Apple ID for IAP testing: [YOUR SANDBOX EMAIL / PASSWORD]
```

---

**I cannot complete A–E from here** (needs your Apple / Supabase logins + Xcode archive). Everything else in the repo for this rejection is ready.
