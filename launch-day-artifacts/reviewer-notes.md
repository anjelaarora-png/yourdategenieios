# App Review Notes — Your Date Genie v1.0

Thank you for reviewing Your Date Genie. Below is everything you need to test the full app, including premium features, in under five minutes.

## Demo account

Email: apple-review@yourdategenie.com
Password: [INSERT PASSWORD BEFORE SUBMITTING]

This account has an active premium subscription pre-applied, so all paid features (Memories, Partner Planning, unlimited date plan generation) are unlocked on sign-in. No payment is required to test.

## Happy-path test (60 seconds)

1. Open the app — you land on the questionnaire.
2. Pick a city (try New York, NY), a vibe (try Romantic), and a date type (try Date Night).
3. Answer the 4 quick prompts (cuisine preference, budget, vibe, time of day).
4. Tap Generate. The plan generates in 8–12 seconds.
5. Review the 3-stop itinerary with venues, transit notes, and a story arc.
6. Tap Save. The plan appears in Memories (premium feature).

## Premium features to test

| Feature | Where | What it does |
|---|---|---|
| Memories | Bottom tab → Memories | Save and revisit any generated date plan; pre-populated with 2 sample plans for demo account |
| Partner Planning | Profile → Partner | Link a partner via email; co-plan together; demo account has a sandbox partner already linked |
| Unlimited Generate | Anywhere | Generate as many date plans as needed; free tier is capped at 2/day |

## Subscription compliance (Guideline §3.1.2)

The paywall is reached via Profile → Upgrade or by tapping any premium feature on the free tier. The paywall screen displays:

- Title of subscription (Your Date Genie Premium)
- Length (monthly or annual)
- Price per period ($14.99/mo or $99.99/yr — $8.33/mo equivalent for annual)
- 7-day free trial disclosure with auto-renewal language
- Restore Purchases button
- Privacy Policy link (opens https://yourdategenie.com/privacy)
- Terms of Use link (opens https://yourdategenie.com/terms)
- Apple Standard EULA reference

Auto-renewal disclosure is the exact Apple-required wording: "Payment will be charged to your iTunes Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period."

## Sign in with Apple (Guideline §4.8)

Sign in with Apple is offered as the first authentication option on the welcome screen. It has equal prominence to email sign-up and creates a complete account without requiring additional data collection. We also support email/password and Google Sign-In.

## Block + Report (Guideline §1.2)

The Partner Planning feature allows users to block and report partners. Reports route to hello@yourdategenie.com and are reviewed within 24 hours. Blocked users cannot re-link or message. To test:

1. Sign in with the demo account.
2. Profile → Partner → tap the sandbox partner's name.
3. Tap the three-dot menu → Report or Block.

## Known issues (planned for v1.0.1, week of 2026-06-08)

- Premium feature unlocks during the 7-day free trial use a cached entitlement that refreshes on next app open; users report a 30–60 second delay seeing unlocked content on first trial start. Fix is staged and will ship in v1.0.1 alongside Custom Terms of Use.
- Minor UI polish on the dark-mode paywall — copy is legible but contrast can be improved.
- Custom Terms of Use page currently uses Apple's Standard EULA. Custom Terms ship in v1.0.1.

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

— Anjela Arora, Founder
