# Date Genie — App Store Submission Compliance Check
**Date:** 2026-06-04 · Mapped against the **common rejection reasons** those TikTok checklists cover (Apple App Review Guidelines), grounded in your code audit.
**Legend:** ✅ met · 🟡 verify / partial · 🔴 will get you rejected — fix before submit

---

## 🔴 Hard blockers (auto-reject — fix first)

| # | Requirement | Our status | Action |
|---|---|---|---|
| 1 | **`PrivacyInfo.xcprivacy` manifest** (required-reason APIs) | 🔴 **Missing** (audit P0 #2) | Add the manifest declaring data types + API reasons. This is THE thing the videos warn about — submitting without it = instant rejection. |
| 2 | **Functional Terms/EULA link for auto-renewing subscriptions** | 🔴 Terms still a placeholder | Apple requires a working Terms (or Apple's standard EULA) **+** Privacy link in BOTH the binary and the App Store metadata for subscriptions. Use Apple's standard EULA now; ship custom later. |

## 🟡 Likely-rejection items (verify before submit)

| # | Requirement | Our status | Action |
|---|---|---|---|
| 3 | **Sign in with Apple** | 🟡 Unconfirmed | If you offer Google/any third-party login, Apple **requires** Sign in with Apple alongside it (Guideline 4.8). Confirm it's implemented. |
| 4 | **Reviewer demo account / guest access** | 🟡 | If the app needs login to see value, give Apple working demo credentials in Review Notes (or allow browsing without login). Missing this is a top-5 rejection. |
| 5 | **Restore Purchases button** | 🟡 | StoreKit apps must offer a visible "Restore Purchases." Confirm it exists on the paywall. |
| 6 | **Privacy Nutrition Labels** accurate in App Store Connect | 🟡 | Fill them to match what you actually collect (must align with the manifest in #1). |
| 7 | **Crash-free on a real device** | 🟡 | Audit found 23 force-unwrapped `URL(string:)!` (a bad URL crashes the app) + zero tests. Do a full TestFlight pass on your iPhone before submit. |
| 8 | **Age rating** set correctly in ASC | 🟡 | Set during submission; confirm it matches content. |

## ✅ Already handled (the videos' other big ones — you're good)

| Requirement | Status |
|---|---|
| **Account deletion in-app** (required since 2022) | ✅ `delete-account` hard-deletes + cascades |
| **In-App Purchase via StoreKit** (no outside payment links) | ✅ StoreKit 2 + server-side receipt validation |
| **Permission usage strings** (camera/location/etc.) | ✅ Present and well-written (audit) |
| **Privacy Policy live + linked** | ✅ Live on yourdategenie.com — just confirm the link works in-app + in metadata |
| **App Tracking Transparency / IDFA** | ✅ Organic-first, no tracking SDK → no ATT prompt needed (confirm no ad SDK slipped in) |
| **Real native functionality (not a web wrapper)** | ✅ Full native app |
| **Screenshots / metadata ready** | ✅ 6 iPhone 6.9" screenshots delivered; support email hello@ |

---

## Net: what these videos would catch on YOUR app
You're **already past most** common rejection reasons (account deletion, StoreKit, privacy policy, ATT) — better shape than the videos assume. **Five things stand between you and a clean submit:**

1. 🔴 Add `PrivacyInfo.xcprivacy`
2. 🔴 Working Terms/EULA + Privacy link for the subscription
3. 🟡 Confirm Sign in with Apple (if any third-party login)
4. 🟡 Reviewer demo account in Review Notes
5. 🟡 Restore Purchases button + Nutrition Labels filled

Items 1, 5, 6, 7 are already on your **🚀 Ship the App** track. Items **2, 3, 4** are NEW — they should be added so the ship track is truly rejection-proof.

> ⚠️ Caveat: the two TikToks may name a reason or two I couldn't hear. If you can tell me the items they list (or send the audio/a summary), I'll diff them against this and close any remaining gap.
