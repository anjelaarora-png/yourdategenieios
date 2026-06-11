# Date Genie — App Store Rejection-Proofing Checklist
**Date:** 2026-06-04 · The common rejection reasons (Apple App Review Guidelines) checked against YDG's current state.
**Legend:** 🟢 met · 🟡 needs a quick action · 🔴 will get you rejected — fix before submit.

| # | Apple requirement (rejection reason) | Guideline | YDG status | Action |
|---|---|---|---|---|
| 1 | **No crashes / bugs / placeholder content** | 2.1 | 🟡 | No tests + 23 force-unwrapped URLs = crash risk. Do the TestFlight device pass; fix the force-unwraps |
| 2 | **Reviewer demo account** (if there's a login) | 2.1 | 🔴 | Create a test login + put it in App Review notes — #1 silent rejection for apps with auth |
| 3 | **PrivacyInfo.xcprivacy manifest** (required-reason APIs) | 5.1.1 | 🔴 | Missing entirely (audit P0). Add it — guaranteed rejection without it |
| 4 | **Privacy Policy** linked in app + listing | 5.1.1 | 🟢 | Live on WordPress — confirm the link works in-app |
| 5 | **Privacy "nutrition" labels** filled in App Store Connect | 5.1.1 | 🟡 | Fill them to match what you actually collect |
| 6 | **Account deletion** in-app (if account creation) | 5.1.1(v) | 🟢 | `delete-account` works + cascades |
| 7 | **Sign in with Apple** (if you offer Google/social login) | 4.8 | 🟡 | You use Google sign-in → you MUST also offer Sign in with Apple (or a privacy-preserving option). **Verify — this is a top rejection** |
| 8 | **In-App Purchase via StoreKit** for the subscription | 3.1.1 | 🟢 | StoreKit 2 + server receipts done |
| 9 | **Restore Purchases** button + clear sub terms on paywall | 3.1.2 | 🟡 | Add a visible "Restore Purchases" + price/renewal/terms text on the paywall |
| 10 | **Terms of Use (EULA)** for the subscription | 3.1.2 | 🔴 | Still a placeholder. Apple requires functional Terms for auto-renewing subs |
| 11 | **Permission purpose strings** (location, photos, etc.) | 5.1.1 | 🟢 | Present + well-written (audit) |
| 12 | **Minimum functionality** (not a thin web wrapper) | 4.2 | 🟢 | Native app, real features |
| 13 | **Accurate screenshots/metadata** | 2.3 | 🟢 | 6 real screenshots ready — ensure they match the build |
| 14 | **App Tracking Transparency** (if you track across apps) | 5.1.2 | 🟢 | Organic-first, no IDFA — nothing to prompt |
| 15 | **UGC safeguards** (if users post content) — report/block/moderate | 1.2 | 🟡 | If partner-planning shares any user content, add report + block. Confirm scope |
| 16 | **Working Support URL** | 1.5 | 🟡 | Confirm a support page/email (hello@) resolves from the listing |

---

## The verdict
Your **🔴 must-fix-before-submit** list is short and known:
1. **PrivacyInfo.xcprivacy** (already P0 on your ship track)
2. **Reviewer demo account** in App Review notes
3. **Sign in with Apple** alongside Google login (verify + add if missing)
4. **Functional Terms of Use** for the subscription
5. A visible **Restore Purchases** + subscription disclosure on the paywall

Everything else is already met or a 🟡 quick confirm. **Items 2, 7, 9, 10 are NOT in your current ship checklist — they're new gaps this video surfaced.** I'm adding them.
