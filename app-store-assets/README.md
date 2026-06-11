# YDG App Store Connect — Upload Asset Pack
**Built:** 2026-05-15
**For:** App Store submission Mon May 18, 2026 · Public launch May 27, 2026

This folder has everything Apple wants at upload, organized so you can drag-and-drop into App Store Connect without hunting. Anything marked ✅ is already drafted; anything marked ⬜ needs capture / fill-in.

---

## Master checklist — what App Store Connect asks for

| Asset | Status | Where in this folder |
|---|---|---|
| App icon 1024×1024 PNG (no alpha) | ⬜ confirm export from master | `app-icon/SPEC.md` |
| Screenshots — 6.9" iPhone (1320×2868) × 3–10 | ⬜ capture | `screenshots/6.9-inch/SPEC.md` |
| Screenshots — 6.5" iPhone (1242×2688) × 3–10 | ⬜ legacy fallback, only if rejected | `screenshots/6.5-inch/SPEC.md` |
| Screenshots — iPad 13" (2064×2752) × 3–10 | ⬜ N/A (iPhone-only at v1.0) | `screenshots/ipad-13/SPEC.md` |
| App Preview video — 6.9" iPhone (886×1920, 15–30s) | ⬜ in progress | `app-previews/6.9-inch/SPEC.md` |
| App name (30 chars max) | ✅ "Your Date Genie" | `metadata/name-and-subtitle.md` |
| Subtitle (30 chars max) | ✅ drafted | `metadata/name-and-subtitle.md` |
| Promotional text (170 chars) | ✅ drafted | `metadata/promotional-text.md` |
| Description (4,000 chars) | ✅ drafted | `metadata/description.md` |
| Keywords (100 chars total) | ✅ drafted | `metadata/keywords.md` |
| Support URL | ✅ https://yourdategenie.com/support | `metadata/urls.md` |
| Marketing URL (optional) | ✅ https://yourdategenie.com | `metadata/urls.md` |
| Privacy Policy URL | ✅ live on WordPress | `metadata/urls.md` |
| EULA (Apple standard or custom) | ✅ Apple-EULA bridge for v1.0 | `metadata/eula.md` |
| Privacy Nutrition Label answers | ✅ drafted | `metadata/privacy-nutrition.md` |
| Age rating answers | ✅ drafted (target 17+ for dating category) | `metadata/age-rating.md` |
| Category — Primary / Secondary | ✅ Lifestyle / Entertainment | `metadata/category.md` |
| Copyright string | ✅ © 2026 Your Date Genie LLC | `metadata/copyright.md` |
| Routing for reviewers (demo account + notes) | ⬜ create demo account this weekend | `reviewer-notes/SPEC.md` |

---

## Capture order — do this in this sequence

1. **Verify app icon** (5 min) — confirm 1024×1024 PNG export is at `app-icon/icon-1024.png`. No alpha channel. No transparency.
2. **Capture screenshots on 6.9" device** (60–90 min) — use your iPhone 16 Pro Max (or simulator). Five hero shots per `screenshots/6.9-inch/SPEC.md`. Save as PNG to `screenshots/6.9-inch/01-questionnaire.png` etc.
3. **Record App Preview video** (60–90 min) — follow the storyboard in `app-previews/SCRIPT.md`. Export at 886×1920 H.264 .mov. Save to `app-previews/6.9-inch/preview-final.mov`.
4. **Create reviewer demo account** (20 min) — see `reviewer-notes/SPEC.md`.
5. **Paste metadata** (30 min) — open each `metadata/*.md` file, copy block, paste into matching App Store Connect field.

Total capture/finishing time: ~4 hours. Fits a Saturday morning block.

---

## Rejection vectors I've already mitigated

- ✅ Sign in with Apple parity (§4.8) — code shipped, dashboard configured
- ✅ Paywall §3.1.2 — Privacy + Terms buttons, auto-renewal disclosure
- ✅ StoreKit 2 receipt validation server-side — Edge Function deployed
- ✅ App-EULA bridge for v1.0 (custom Terms ship in v1.0.1)
- ✅ Block + Report user flows (§1.2)
- ✅ App icon size grid complete

## Open rejection vectors

- ⬜ One reviewer demo account that gets past auth on first try
- ⬜ Demo account already has 3 sample date plans saved so the empty state doesn't read as "broken"
- ⬜ "Verify hours/prices" disclaimer copy visible on every plan card (§4.0 user-generated content vs. AI-generated facts)
- ⬜ Privacy Nutrition Label exactly matches what the app actually collects (do not over-disclose, do not under-disclose)

These all sit in `reviewer-notes/SPEC.md` and `metadata/privacy-nutrition.md`.

---

## When you upload to App Store Connect

1. Sign in → My Apps → Your Date Genie → 1.0 Prepare for Submission.
2. Drag screenshots into the 6.9" iPhone slot (Apple auto-scales for smaller iPhones as of 2025+).
3. Drag App Preview .mov into the 6.9" iPhone slot.
4. Upload 1024×1024 icon.
5. Paste each metadata field from this folder.
6. Save. Then go to TestFlight → submit your build → submit for review.
7. Expect 24-hour processing on the App Preview before it shows in the listing.

If anything errors at upload, screenshot the error and send it to me — I'll fix and re-export.

---

## Sources for the 2026 specs in this pack

- [Apple Developer · Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Apple Developer · App Preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications/)
- [Apple Developer · Upload app previews and screenshots](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/)
