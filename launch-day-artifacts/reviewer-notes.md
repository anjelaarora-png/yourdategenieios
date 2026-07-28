# App Review Notes — Your Date Genie v1.0

Thank you for reviewing Your Date Genie. Below is everything you need to test the full app, including premium features, in under five minutes.

**Please use the email/password demo account below for the core flow.** Sign in with Apple creates a separate account and is available for testing on the welcome screen (it is the first authentication option, above email).

## Demo account

Email: appstore.review@yourdategenie.com
Password: [INSERT PASSWORD BEFORE SUBMITTING]

This account has an active premium subscription pre-applied, so all paid features (Memories, Partner Planning, unlimited date plan generation) are unlocked on sign-in. No payment is required to test the core product with this account.

## Sandbox Apple ID (In-App Purchases)

Use this Sandbox tester to exercise StoreKit purchase / restore on the paywall:

Sandbox Apple ID: [INSERT SANDBOX EMAIL]
Sandbox password: [INSERT SANDBOX PASSWORD]

Auto-renewable subscriptions submitted with this build:
- `com.yourdategenie.premium.monthly` — $14.99/month, 7-day free trial
- `com.yourdategenie.premium.annual` — $119.99/year, 7-day free trial

## Happy-path test (60 seconds)

1. Open the app — Sign in with the demo email/password above (not Sign in with Apple for this account).
2. On Home, tap Plan my date. Pick a city (try New York, NY), a vibe (try Romantic), and a date type (try Date Night).
3. Answer the quick prompts (cuisine preference, budget, vibe, time of day).
4. Tap Generate. The plan generates in about 30–60 seconds.
5. Review the itinerary with venues, transit notes, and extras.
6. Tap Save. The plan appears in Memories (premium feature).

## Premium features to test

| Feature | Where | What it does |
|---|---|---|
| Memories | Bottom tab → Memories | Save and revisit any generated date plan |
| Partner Planning | Profile → Partner | Link a partner via email; co-plan together |
| Unlimited Generate | Anywhere | Generate as many date plans as needed; free tier is capped |

## Subscription compliance (Guideline 3.1.2)

The paywall is reached via Profile → Settings → View plans, or by tapping a premium feature on the free tier. The paywall screen displays:

- Title of subscription (Your Date Genie Premium)
- Length (monthly or annual)
- Price per period ($14.99/mo or $119.99/yr)
- 7-day free trial disclosure with auto-renewal language
- Restore Purchases button
- Privacy Policy link (opens https://yourdategenie.com/privacy-policy)
- Terms of Use link (opens https://yourdategenie.com/terms)

Auto-renewal disclosure: Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Manage in Settings → Subscriptions.

## Sign in with Apple (Guideline 4.8)

Sign in with Apple is the first authentication option on the welcome screen (above email/password and Google). It uses the native Sign in with Apple button and creates a complete account without requiring additional data collection. We also support email/password and Google Sign-In.

**For this review:** please use the demo email/password account for the happy path. Sign in with Apple may be tested separately; it creates a new account (not the seeded demo account).

## Block + Report (Guideline 1.2)

The Partner Planning feature allows users to block and report partners. Reports route to hello@yourdategenie.com and are reviewed within 24 hours. Blocked users cannot re-link or message. To test:

1. Sign in with the demo account.
2. Profile → Partner → tap the sandbox partner's name.
3. Tap the three-dot menu → Report or Block.

## Disclaimers (in-app)

All venue hours, prices, and availability are sourced from Google Places at the time of plan generation. In-app copy reads: "Verify hours and prices with the venue before you go — things change fast." This appears below every venue card.

## Support and contact

Support URL: https://yourdategenie.com/support
Support email: hello@yourdategenie.com
Founder: Anjela Arora, Your Date Genie LLC (NJ)
Direct line for review questions: hello@yourdategenie.com (replies within 4 hours business days)

## Privacy summary

- We collect: email, partner email (if linked), generated date plans, city of use
- We do not collect: contacts, photos, location beyond city selection, IDFA
- All data lives in Supabase (US region); deletion request via Profile → Settings → Delete Account or hello@yourdategenie.com
- Privacy Nutrition Labels in App Store Connect match this scope

Thanks again — we appreciate the time. Happy to answer anything at hello@yourdategenie.com.
