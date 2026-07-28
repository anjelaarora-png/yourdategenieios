# App Store Review — Demo Account

Apple requires working login credentials when the app needs an account to see core value. Use this dedicated reviewer account (not your personal login).

**Full rejection recovery checklist:** [`REJECTION_RECOVERY_CHECKLIST_2026-07-09.md`](./REJECTION_RECOVERY_CHECKLIST_2026-07-09.md)

---

## Quick setup (one command)

From the repo root, with your **Supabase service role key** (Dashboard → Project Settings → API → `service_role` — never commit this):

```bash
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
export REVIEWER_PASSWORD="YDG-Review-2026!"   # pick a strong password; store in 1Password

./scripts/create_app_store_reviewer.sh
```

The script will:

1. Create (or reuse) auth user **`appstore.review@yourdategenie.com`**
2. Confirm the email so no verification step blocks login
3. Seed NYC preferences so **Plan my date** works immediately
4. Insert a **`trialing`** Premium subscription row so reviewers are not blocked by the paywall

Override email if needed:

```bash
REVIEWER_EMAIL="review+apple@yourdategenie.com" ./scripts/create_app_store_reviewer.sh
```

---

## Manual fallback (Supabase Dashboard)

If you prefer the UI:

1. **Authentication → Users → Add user**
   - Email: `appstore.review@yourdategenie.com`
   - Password: (your chosen reviewer password)
   - ✅ Auto Confirm User
2. Copy the new user’s **UUID**
3. **SQL Editor** → run `scripts/seed_app_store_reviewer.sql` after replacing `:user_id` with that UUID

---

## Paste into App Store Connect

**App Store Connect → Your Date Genie → App Review Information**

| Field | Value |
|-------|--------|
| **Sign-in required** | Yes |
| **Username** | `appstore.review@yourdategenie.com` |
| **Password** | *(the password you set in `REVIEWER_PASSWORD`)* |

**Notes for Review** (copy/paste — also in `launch-day-artifacts/reviewer-notes.md`):

```
Demo account (email + password — do not use Sign in with Apple for this account):

Email: appstore.review@yourdategenie.com
Password: [YOUR REVIEWER PASSWORD]

Sandbox Apple ID for IAP testing:
Email: [YOUR SANDBOX APPLE ID]
Password: [YOUR SANDBOX PASSWORD]

How to test the core flow:
1. Launch the app → Sign In with the email credentials above (Sign in with Apple is first on the screen but creates a separate account).
2. On Home, tap "Plan my date" (or the questionnaire entry point).
3. City is pre-filled to New York, NY — tap through the questionnaire (defaults are fine).
4. Wait ~30–60s for AI plan generation; you will see plan options.
5. Open a plan to view the full itinerary, gifts, and conversation starters.
6. Premium features are unlocked on this account (trialing subscription).

Subscriptions submitted with this build:
- com.yourdategenie.premium.monthly ($14.99/mo, 7-day trial)
- com.yourdategenie.premium.annual ($119.99/yr, 7-day trial)
Use the Sandbox Apple ID above to test purchase/restore. The demo account already has Premium without purchasing.

Account deletion: Profile → Settings → Delete Account (required by Apple).

Support: hello@yourdategenie.com
Privacy: https://yourdategenie.com/privacy-policy
Terms: https://yourdategenie.com/terms
```

### Resolution Center reply (after resubmit)

```
IAP: Both auto-renewable subscriptions (com.yourdategenie.premium.monthly and
com.yourdategenie.premium.annual) are now submitted for review with this build,
including App Review screenshots. The Paid Apps Agreement is Active.

Subscriptions screen: The error was caused by IAP products not yet being available
in App Store Connect. Products are now configured and tested in Sandbox on iPad.

Sign in with Apple: We verified the Supabase Apple provider configuration and tested
Sign in with Apple on iPad. Demo account for the core flow (email/password):

Email: appstore.review@yourdategenie.com
Password: [YOUR REVIEWER PASSWORD]

Sandbox Apple ID for IAP testing: [YOUR SANDBOX EMAIL / PASSWORD]
```

---

## Before every submission

- [ ] Log out of your personal account on a test device → sign in with the reviewer credentials → confirm Home loads and one plan generates.
- [ ] Confirm Premium badge / no paywall on generation (subscription row still `trialing` or `active`).
- [ ] Test Sign in with Apple on **iPad** (fresh install).
- [ ] Confirm paywall loads both products in Sandbox (no “couldn't load subscription options” error).
- [ ] Both IAPs attached to the version under review and **Ready to Submit**.
- [ ] Update the password in App Store Connect if you rotated it.
- [ ] Do **not** delete this user between submissions unless you re-run the seed script.

---

## Security notes

- The service role key must stay out of git (use env vars only).
- Use a password unique to this account; rotate after launch if leaked.
- This account is for Apple review only — not a production admin account.
