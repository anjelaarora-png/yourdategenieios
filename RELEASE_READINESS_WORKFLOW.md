# Release-Readiness Workflow — Your Date Genie

**Last refresh:** 2026-04-29 (chief-of-staff re-audit)
**Original audit:** 2026-04-28
**iOS submission target:** 2026-05-18 (19 days)
**Public launch target:** 2026-05-27 (28 days)
**Overall status:** 🟡 **AT RISK** — clearable with focused execution; **11 P0 blockers** across iOS, backend, and web (one of yesterday's 12 was a false positive — see #6).

**What changed since 2026-04-28:**
- ✅ P0 #6 (broken migration) **INVALIDATED** — `user_id` column DOES exist on `date_plans` (added in `20260327120000_unified_user_storage_date_plans_prefs.sql:10`). The 4/25 migration will deploy fine. Removing from blocker list.
- ✅ Decisions confirmed by Anjela 4/29: Supabase project ID is `jhpwacmsocjmzhimtbxj`, support email is `hello@yourdategenie.com`, Privacy Policy URL is reusable at `/privacy-policy`.
- ⚠️ Terms of Service path **CHANGED**: existing `Terms.tsx` is template-grade and must be re-drafted. Custom Terms drafted at `legal/terms-of-service-draft.md` (lawyer review pending).
- ✅ OpenAI proxy decision: APPROVED. Cursor brief at `tasks/cursor/01-move-openai-server-side.md`.
- ⏳ Codebase deltas since audit: **NONE.** Last commit on main is `03a6921` ("4-25-26 updates"). No P0 fixes have landed in the repo yet. If work has been done in branches/Cursor it hasn't been pushed.

---

## Executive summary (read this first)

Anjela — the cross-team audit (iOS + backend + web + social) found **12 P0 blockers** that would prevent a clean ship. The good news: none of them are foundational. Total estimated engineering effort to clear them is roughly **20–25 hours**. That fits comfortably inside the 20-day submission window if discipline holds.

The single most urgent item is **rotating the Supabase anon key** — it is currently hardcoded in the iOS binary and effectively public. Do that today.

The single biggest gap relative to plan is the **Firebase waitlist** — the Firestore SDK isn't installed in the web app at all, so there is no live waitlist capture today. This blocks every social/marketing push you have planned in the next 4 weeks.

Below: status snapshot, P0 list, week-by-week sequence, owners, and the open questions I need answered to lock in dates.

---

## 🚦 Status snapshot

| Surface | Status | Key issues |
|---|---|---|
| **iOS app** | 🟡 At risk | All 4 known blockers still present. New finding: hardcoded Supabase anon key in `Config.swift`. OpenAI key sent client-side. |
| **Backend / data** | 🟡 At risk | Latest migration will fail to deploy (references non-existent `user_id` column). No StoreKit server-side validation. No Firebase waitlist code. |
| **Web app** | 🟡 At risk | No waitlist form. No analytics. SEO/structured data missing. No App Store CTA swap mechanism. |
| **Social media** | 🟡 Unknown | Handles confirmed (`@yourdategenie` IG + TikTok). Public audit blocked by egress; you'll fill in numbers. |
| **App Store Connect deliverables** | 🔴 Not ready | Screenshots, subtitle, keywords, description, privacy nutrition label, age rating, support URL, EULA URL — all missing. |

---

## 🔴 P0 BLOCKERS (must fix to ship)

| # | Blocker | Surface | File | Owner agent | Est. |
|---|---|---|---|---|---|
| 1 | Hardcoded Supabase anon JWT in binary; rotate key | iOS | `ios/YourDateGenie/Config.swift:54` | backend-developer | 30m + key rotation |
| 2 | `UIRequiredDeviceCapabilities = armv7` → must be `arm64` | iOS | `ios/Info.plist:81` | software-developer | 2m |
| 3 | AppIcon.appiconset only has 1024×1024; needs full size set | iOS | `ios/YourDateGenie/Assets.xcassets/AppIcon.appiconset/Contents.json` | ui-ux-designer | 30m |
| 4 | Paywall missing visible Privacy + Terms links (Apple §3.1.2) | iOS | `ios/YourDateGenie/Views/Subscription/PaywallView.swift` | frontend-developer (iOS) + ui-ux-designer | 20m |
| 5 | OpenAI key sent client-side; move to Edge Function proxy | iOS + backend | `ios/.../DatePlanGeneratorService.swift:~569` | backend-developer | 2–4h |
| 6 | ~~Migration indexes non-existent `user_id` column~~ | ~~Backend~~ | ~~`supabase/migrations/20260425120000_save_plan_date_requirement.sql`~~ | — | **INVALIDATED 4/29** — column exists in earlier migration |
| 7 | No server-side StoreKit 2 receipt validation — premium status is client-trusted | Backend | new Edge Function needed | backend-developer | 4–5h |
| 8 | `subscriptions` table missing from schema (required for §3.1.2 + web premium gating) | Backend | new migration | backend-developer | 1h |
| 9 | No Firebase Firestore waitlist capture in web app (SDK not installed) | Web | new component + Firebase init | frontend-developer + backend-developer | 4–6h |
| 10 | No analytics wired (Plausible/PostHog) — launch-day conversion unmeasurable | Web | new instrumentation | frontend-developer | 2–3h |
| 11 | App Store CTA swap mechanism missing (CTAs hardcoded to `/signup`) | Web | landing components + env var | frontend-developer | 1–2h |
| 12 | All App Store Connect deliverables missing (screenshots, subtitle, keywords, description, privacy nutrition labels, age rating, support URL, EULA URL) | Marketing/Design | App Store Connect | ui-ux-designer + marketing | 6–8h |

**Total P0 effort (revised 4/29):** ~22–32 hours of engineering remains across 11 blockers. Achievable in 11 working days if Anjela keeps focus and Cursor work starts Mon 5/4 latest.

**Go/No-Go gates for App Store submission (5/18):**
- 🔴 NO-GO if any of {#1 key rotation, #2 arm64, #3 AppIcon, #4 paywall §3.1.2, #7 receipt validation, #8 subscriptions table} are open
- 🟡 SHIP-WITH-RISK if {#5 OpenAI proxy} is open (cost vector, not Apple-rejecting)
- 🟢 NICE-TO-HAVE for App Store: {#9 waitlist, #10 analytics, #11 CTA swap} — these block marketing, not Apple
- 🔴 NO-GO if {#12 ASC deliverables} aren't all uploaded by 5/17 EOD

**Go/No-Go gates for Public Launch (5/27):**
- 🔴 NO-GO if any P0 unresolved
- 🔴 NO-GO if Terms of Service hasn't been lawyer-reviewed
- 🔴 NO-GO if waitlist hasn't captured ≥250 emails (signals organic demand for paid push)
- 🟡 SHIP-WITH-RISK if no APNs/push set up (retention hit but not launch-blocking)

---

## 🟡 P1 — Should fix before launch

- Audit Info.plist for missing privacy strings: `NSPhotoLibraryUsageDescription` (read), `NSCameraUsageDescription`, `NSContactsUsageDescription`. Confirm what's actually used in code.
- `LSApplicationQueriesSchemes` empty — declare `maps`, `googlemaps`, `opentable`.
- `NSUserTrackingUsageDescription` if Meta/TikTok pixel attribution is wired.
- Per-user rate limit on `/generate-date-plan` Edge Function (OpenAI cost protection).
- APNs / push notification setup for retention (welcome push, date-day reminders).
- Email template QA — brand colors, deliverability test, DKIM/SPF.
- Dashboard empty/loading states for first-time users (`src/pages/Dashboard.tsx`).
- Image optimization on landing (`loading="lazy"`, modern formats).
- Favicon currently pointing to external GCS URL — move to `public/`.
- Error boundary + user-friendly errors for Firebase/Supabase outages.
- ResetPassword flow finish (success state, redirect, rate-limit).
- UTM parameter capture on landing → carry into signup metadata.

## 🟢 P2 — Post-launch hardening

- Pre-permission rationale screens for location/notifications (iOS).
- Apple App Site Association for universal links.
- RLS perf fix: replace `couple_id IN (SELECT...)` subquery with materialized view.
- Sentry + observability across iOS + Edge Functions.
- Confirm Supabase PITR backups enabled.
- Data residency / GDPR review if EU launch in scope.
- A11y contrast audit on cream/maroon/gold combinations.
- 404 page improvements.

---

## 📅 Week-by-week sequence to launch

### Week 1 — 4/28 → 5/3 (THIS WEEK) · Theme: "Stop the bleeding & open the funnel"

**Outcome:** Security hardened, waitlist capturing emails, all P0 work has owners and dates.

**Day-by-day:**

- **Mon 4/28** — ✅ audit complete; ⏳ no fixes landed in repo yet.
- **Tue 4/29 (today)** — chief-of-staff re-audit (this doc). Decisions confirmed: Supabase project, support email, OpenAI proxy approval, Terms Path B. **Cursor task #1 ready for Anjela to execute** (`tasks/cursor/01-move-openai-server-side.md`). Action items: kick off arm64 fix (#2 — 2 min), AppIcon size set (#3 — 30 min), paywall link bar (#4 — 20 min). These three alone clear ~52 min of P0 today.
- **Wed 4/30** — frontend-developer + backend-developer: install Firebase SDK in web app, build waitlist form component, wire to Firestore `waitlist_signups` collection with security rules (#9). Deploy. Update IG + TikTok bios with the live URL.
- **Thu 5/1** — frontend-developer: install Plausible or PostHog, instrument landing + signup events (#10). Add App Store CTA swap env var (#11). Build a `LAUNCH_MODE` feature flag.
- **Fri 5/2** — backend-developer: stand up Supabase Edge Function for OpenAI proxy, kill client-side OpenAI calls (#5). Add `subscriptions` table migration (#8). Anjela executes Cursor task #1 — anon key rotation + remove hardcoded fallback (#1) — 30 min + 5 min testing on TestFlight build.
- **Sat 5/3** — backend-developer: stand up Edge Function `/functions/v1/validate-receipt` (#7). Test against StoreKit sandbox.
- **Sun 5/3 — weekly review** with chief-of-staff: P0 status, % complete, slip risks.

**By end of week:** all critical security work done, waitlist live capturing emails, paywall compliant.

---

### Week 2 — 5/4 → 5/10 · Theme: "App Store Connect prep + content batch"

**Outcome:** Every App Store Connect field has a draft. Two weeks of content shot.

**Engineering:**
- Finish OpenAI proxy + StoreKit receipt validation if any spillover from Week 1.
- Sweep all P1 Info.plist privacy strings (`NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`, `NSContactsUsageDescription`, `NSUserTrackingUsageDescription` if needed, `LSApplicationQueriesSchemes`).
- Add per-user rate limiting to OpenAI proxy.
- Finish ResetPassword flow + UTM capture.
- Dashboard empty/loading states.

**App Store Connect (#12):**
- ui-ux-designer: design 5 screenshots × 3 iPhone sizes (6.7", 6.1", 5.8") + 5 iPad sizes. Story arc: promise → magic moment → differentiator → social proof → CTA.
- marketing agent: write App Name (locked), Subtitle (≤30 chars), Keywords (100-char field), Description (~3500 chars).
- ui-ux-designer: optional 30-second preview video script + storyboard.
- accounting agent: Apple Small Business Program enrollment (15% commission vs 30%).
- chief-of-staff: confirm Support URL (e.g. `support@yourdategenie.com`) and EULA URL on the website.
- accounting + frontend-developer: privacy nutrition label completed in App Store Connect.

**Social (per social-media-manager 30-day plan):**
- Batch-shoot 8–12 short videos (mix of 6 content pillars).
- Outreach to 5–10 micro-creators (5K–50K followers) in committed-relationship/lifestyle niche.
- Post 4 IG + 5 TikTok this week. Cadence locked.

**Friday 5/8 — TestFlight build #2** with all P0 + most P1 fixes; route to internal testers.

---

### Week 3 — 5/11 → 5/17 · Theme: "Submission readiness + waitlist push"

**Outcome:** Build is feature-frozen Friday 5/15; submission ready Monday 5/18.

**Engineering:**
- Feature freeze 5/15. Only blocker fixes after.
- TestFlight #3 with App Icons + paywall + all privacy strings + receipt validation. Test on real device with sandbox StoreKit.
- Fix any TestFlight feedback.
- Confirm Supabase PITR enabled.

**Marketing/Social:**
- Daily countdown content (IG Stories sticker + post). "10 days until..."
- Send creator kits to recruited micro-creators.
- Repost user wishes / waitlist testimonials.
- BTS content peak: app build, design decisions, "what couples told us."
- Pre-write launch-day content for 5/27.

**Operations:**
- accounting agent: confirm chart of accounts, Mercury/Brex card setup, books up to date through April.
- finance agent: lock launch-week burn forecast and ad-test budget gate.
- chief-of-staff: lock the launch-day plan (hour by hour for 5/27).

---

### Week 4 — 5/18 → 5/27 · Theme: "Submit, wait, launch"

**Mon 5/18 — SUBMIT TO APP STORE.** Aim for end-of-day. Apple review typically 24–48 hours but plan for 7-day worst case.

**Tue 5/19 → Sun 5/24 — review purgatory:**
- Daily content cadence continues (countdown).
- Influencer kits final push.
- Press list (if any) gets advance notice + embargoed link.
- chief-of-staff: prep launch-day comms, hour-by-hour social calendar, DM blitz lists.
- backend-developer: load-test the OpenAI proxy + Supabase under simulated launch traffic.
- Set up Sentry / alerting (P2 normally, but worth it for launch week).
- Have an iOS hotfix branch + TestFlight ready in case Apple rejects on a fixable issue.

**Mon 5/25 → Wed 5/27 — launch:**
- 5/25: confirm app is "Ready for Sale," set release date to 5/27 in App Store Connect, pre-warm App Store URL (test it works in private browse).
- 5/26: switch web app `LAUNCH_MODE` env to live; CTAs swap from waitlist to App Store badge. Email the entire waitlist with "we're live tomorrow."
- **5/27 LAUNCH DAY:**
  - 8am ET: app live in App Store. Anjela posts launch reel on IG + TikTok.
  - 10am ET: email blast to waitlist with App Store link + UTM.
  - 12pm ET: second IG post + TikTok. Threads + X launch posts.
  - 6pm ET: third IG + TikTok post. UGC reposting begins.
  - All day: chief-of-staff DMs everyone who commented on countdown content.

---

## 👥 Owners & accountability

Each P0 above has an **owner agent**. Anjela's role is **decisions + final approval**, not execution.

| Agent | What they own this month |
|---|---|
| **chief-of-staff** | Daily standup, weekly review, calendar protection, decision routing, launch-day hour-by-hour plan |
| **strategy** | Final go/no-go on launch date if anything slips. Trade-off calls. |
| **finance** | Apple Small Business Program enrollment confirmation. Launch-week burn forecast. Paid-ad gate. |
| **accounting** | Chart of accounts, Mercury/Brex setup, books current. App Store revenue reconciliation prep. |
| **software-developer** | Architecture review on OpenAI proxy + receipt validation. iOS-side Info.plist fixes. |
| **backend-developer** | Items #1, #5, #6, #7, #8 on the P0 list. Migrations. Rate limiting. |
| **frontend-developer** | Items #9, #10, #11. Dashboard polish. ResetPassword flow. UTM capture. |
| **ui-ux-designer** | Items #3, #4. Screenshot suite. Paywall §3.1.2 visual. |
| **marketing** | App Store metadata copy. Launch-day messaging. Email-to-waitlist copy. |
| **social-media-manager** | 30-day content calendar. Creator outreach. Daily countdown. UGC capture pipeline. |

---

## 📲 Social audit — fill-in form (from social-media-manager)

I couldn't pull IG/TikTok data directly (egress block), so this is yours to complete in 10 minutes from your phone:

### Instagram (`@yourdategenie`)
- Followers: ____
- Posts in last 30 days: ____
- Bio link currently points to: ____ (target: live waitlist URL by Wed 4/30)
- Profile image is on-brand (maroon/gold/cream or founder face)? Y / N
- Highlights/pinned content set up? Y / N — if Y, list themes:
- Top 3 posts by saves/comments — note the formats:

### TikTok (`@yourdategenie`)
- Followers: ____
- Videos in last 30 days: ____
- Bio link currently points to: ____
- Hook quality on top 3 videos — first 2 seconds compelling? Y / N
- Avg completion rate (rough): ____%
- Trending sound participation in last 7 days: ____ (target: 2+/week)

### Other platforms
- Threads `@yourdategenie`? Y / N — followers: ____
- X / Twitter? Handle: ____ — followers: ____
- Pinterest? Y / N
- LinkedIn (Anjela personal)? Y / N — connections/followers: ____
- YouTube? Y / N

### Tools
- Bio link tool (Linktree/Beacons/direct): ____
- Scheduler (Later/Buffer/Metricool/native/none): ____
- Analytics dashboard: ____

Drop these numbers in chat and `social-media-manager` will run the 30-day plan against actuals.

---

## ❓ Open questions I need from you (in priority order)

These block work this week. Easier to answer in batch.

1. ✅ **Supabase project URL/ID** — Anjela 4/29: `jhpwacmsocjmzhimtbxj` confirmed. Cursor briefed.
2. ✅ **OpenAI proxy approval** — Anjela 4/29: APPROVED. Cursor task ready.
3. ✅ **Privacy Policy URL** — `/privacy-policy` confirmed reusable. ⚠️ **Terms URL still PENDING** — existing `Terms.tsx` is template-grade (Path B chosen 4/29 — custom draft at `legal/terms-of-service-draft.md` needs lawyer review before going live).
4. ✅ **Support email** — `hello@yourdategenie.com` confirmed.
5. ⏳ **Meta/TikTok ad attribution at launch?** — Anjela 4/29: needs plain-language re-explanation. *Plain version: "If you plan to run Meta or TikTok paid ads at any point in your first 90 days post-launch, iOS requires us to ask the user 'Allow Your Date Genie to track your activity across other companies' apps and websites?' the first time they open the app. This is what unlocks attribution — knowing which ad drove which install. If you say yes here, I add a one-line `NSUserTrackingUsageDescription` to Info.plist. If no, we ship without it and lose the ability to A/B test paid ads at launch."*
6. ⏳ **Subscription pricing + free trial** — memory has $4.99/mo, $49.99/yr, 7-day trial. Confirm these are still locked.
7. ⏳ **App icon design** — do you have the 1024×1024 marketing icon ready, or does ui-ux-designer need to produce it from existing AppIcon.png?
8. ⏳ **Photo library / Camera / Contacts usage** — confirm if any iOS view lets users select photos, take photos, or read contacts. Determines which Info.plist privacy strings are mandatory.
9. ✅ **Migration #6** — INVALIDATED. False positive in 4/28 audit; column exists. No action.
10. ⏳ **TestFlight invite list** — who should be added as internal testers for next build?
11. 🆕 **Legal entity status** — is "Your Date Genie, Inc." actually incorporated, or sole prop / LLC / DBA? Changes the boilerplate in Terms + Privacy Policy.
12. 🆕 **`legal@` and `privacy@` email aliases** — do these exist, or should we consolidate everything on `hello@`?

---

## 🧭 How to use this doc

- **Daily:** `chief-of-staff, daily brief` — I'll pull from this doc and tell you the day's 3 priorities.
- **Weekly (Friday):** `chief-of-staff, weekly review` — what shipped, what slipped, what changes for next week.
- **Anytime:** `chief-of-staff, status on [iOS / web / backend / social]` — surface-specific health check.
- This doc is the source of truth. Every check-in updates it. When status changes, the agent will re-mark items 🟢 / 🟡 / 🔴.

---

*Generated 2026-04-28 by chief-of-staff with input from frontend-developer, backend-developer, software-developer, ui-ux-designer, marketing, and social-media-manager agents. Update as work completes.*
