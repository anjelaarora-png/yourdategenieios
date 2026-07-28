# Your Date Genie — Automation & Scheduled Task Plan
*Generated 2026-04-29 · Anchored to iOS launch 2026-05-27*

This is the working list of recurring and one-time tasks that can be put on a schedule (run automatically or on-demand) to take load off the founder during the 30-day launch sprint and beyond. Each item lists the cadence, what it does, why it earns its place on a solo founder's calendar, and what's needed to enable it.

**Legend:**
- ✅ I can schedule this today using only what I already have
- 🔌 Needs a connector (Gmail, Notion, Reddit, App Store Connect, Firebase, Supabase, etc.)
- 👤 Founder action required at run time — automation just nudges/preps

---

## 1. Daily — Launch sprint (now → 2026-05-27)

### 1.1 Morning launch standup brief (8:00 AM)
- **What:** Generate a one-page brief: days to submission (2026-05-18), days to public launch (2026-05-27), top 3 P0 blockers still open, anything that slipped overnight, top 3 things to ship today.
- **Why:** Solo founders lose the plot fastest in week 3 of a launch. A daily anchor keeps the sprint honest.
- **Status:** ✅ Schedulable now. Pulls from `LAUNCH_MASTER_PLAN.md` and memory.

### 1.2 TestFlight feedback sweep (9:00 AM)
- **What:** Pull new TestFlight feedback + crash reports, summarize top issues, flag anything that affects App Store submission readiness.
- **Why:** Bugs that surface in TestFlight need ~48hrs to fix-and-resubmit before May 18 cutoff.
- **Status:** 🔌 Needs App Store Connect connector. Workaround: founder pastes feedback dump into chat → automation summarizes.

### 1.3 Support inbox triage (10:00 AM, weekdays)
- **What:** Scan `hello@yourdategenie.com` for new threads, classify (bug / billing / press / general / spam), draft replies for "general" tier.
- **Why:** Press and beta-tester DMs hide in a Gmail inbox during launch. Missing one matters.
- **Status:** 🔌 Needs Gmail connector.

### 1.4 Social mentions sweep (11:00 AM)
- **What:** Search IG, TikTok, X, Reddit for `@yourdategenie`, `"Your Date Genie"`, `"date genie"`. Flag anything that needs a reply within 24hrs.
- **Why:** Pre-launch buzz and post-launch reviews live and die on response time.
- **Status:** 🔌 Best with a social-listening connector. Lite version: web search → I summarize.

### 1.5 Reddit engagement queue (4:00 PM, weekdays)
- **What:** Pull 3–5 fresh posts from r/dating, r/relationships, r/datingoverthirty, r/marriage, r/CityName_subs where a thoughtful (non-spammy) comment mentioning date planning would land. Draft comment per post.
- **Why:** Reddit is your stated organic channel. Drafted-but-not-posted comments lower friction enormously. 👤 You still post — Reddit penalizes bot-posted content.
- **Status:** ✅ Schedulable with web search. 🔌 Better with a Reddit connector.

### 1.6 Content post nudge (5:00 PM)
- **What:** Reminder + link to today's TikTok/IG content theme. If no content shipped today, list 3 quick prompts pulled from yesterday's Reddit threads or trending date-planning queries.
- **Why:** Posting cadence is the variable that decides whether organic-first works.
- **Status:** ✅ Schedulable now. Founder posts.

### 1.7 Waitlist + signups counter (6:00 PM)
- **What:** Pull yesterday's Firebase waitlist signups + Supabase auth signups. Compare to 7-day rolling average. Call out spikes/dips.
- **Why:** Marketing spend and content effort should track to signal in this number.
- **Status:** 🔌 Needs Firebase + Supabase connectors. Lite version: founder dumps numbers daily.

---

## 2. Weekly — Launch sprint cadence

### 2.1 Monday launch readiness review (9:00 AM Mon)
- **What:** Walk through the LAUNCH_MASTER_PLAN.md checklist; report % complete; surface anything slipping; recommend resequencing.
- **Why:** A weekly hard-look prevents the soft slip-and-pray pattern that kills 30-day launches.
- **Status:** ✅ Schedulable now.

### 2.2 KPI snapshot + investor-style update (5:00 PM Fri)
- **What:** Generate a 1-page weekly report — installs, signups, conversion to trial, churn, MRR, top 3 wins, top 3 blockers, ask of the week.
- **Why:** Forces founder to write the narrative weekly even with no investors yet. Doubles as future fundraising material.
- **Status:** 🔌 Best with App Store Connect + Supabase. Manual today.

### 2.3 Content performance autopsy (Sun evening)
- **What:** Pull top-performing IG/TikTok posts of the week, identify pattern (hook, format, hour, length), feed those patterns into next week's content plan.
- **Why:** Organic only compounds when you actually study what worked.
- **Status:** 🔌 Needs IG/TikTok connectors. Lite version: founder pastes analytics screenshots.

### 2.4 ASO keyword check (Wed)
- **What:** Run keyword position checks for "date ideas", "date planner", "date night", "couples", "AI date" across iOS App Store. Compare vs prior week.
- **Why:** ASO is the highest-leverage organic acquisition channel after launch. Movement here matters.
- **Status:** 🔌 Needs an ASO tool connector or manual founder check pre-launch.

### 2.5 Competitor pricing/feature scan (Thu)
- **What:** Pull Tinder, Bumble, Hinge, Match, Plenty of Fish, smaller indie date-planning apps. Note any pricing changes, new features, marketing campaigns.
- **Why:** Your $14.99/mo position sits between Tinder Gold and Bumble Premium — moves there matter for repositioning.
- **Status:** ✅ Schedulable with web search.

### 2.6 Burn-rate check (Fri)
- **What:** Reconcile this week's spend across team, ads, events, tools against $5K/mo budget. Project month-end. Flag if pacing >100%.
- **Why:** A $5K/mo budget can disappear in week 2 if uncontrolled.
- **Status:** 👤 Founder logs spend; automation does math + flags.

### 2.7 Backup nudge (Sun)
- **What:** Reminder to confirm Supabase + Firebase weekly backups ran successfully.
- **Why:** Pre-launch is exactly when irrecoverable data loss bites hardest.
- **Status:** ✅ Schedulable now.

---

## 3. Monthly — Cadence after launch

### 3.1 Subscription / StoreKit reconciliation (1st of month)
- **What:** Pull StoreKit transactions, reconcile against Supabase entitlements, flag mismatches (refund chargebacks, expired-but-still-flagged-premium users).
- **Why:** $14.99/mo subscriptions create entitlement drift. Caught early it's painless; caught late it's a refund storm.
- **Status:** 🔌 Needs App Store Connect + Supabase.

### 3.2 Press & PR scan (1st of month)
- **What:** Pull recent coverage of "AI dating", "date planning apps", "couples tech" in TechCrunch, The Information, Product Hunt, Lifehacker. Identify reporters writing in this beat.
- **Why:** Cold pitching works only when it's targeted at active beat reporters.
- **Status:** ✅ Schedulable with web search.

### 3.3 LLC compliance + tax-prep check (15th of month)
- **What:** Reminder to confirm Your Date Genie LLC state filing, sales tax registration if applicable, quarterly estimated taxes if month is Mar/Jun/Sep/Dec.
- **Why:** LLC penalties are silent and stack.
- **Status:** ✅ Schedulable now (calendar reminders).

### 3.4 Privacy Policy & Terms review (15th of month)
- **What:** Diff current Privacy Policy and Terms against any new app features shipped in last 30 days. Flag if disclosure update needed.
- **Why:** Apple rejects updates that ship undisclosed data collection.
- **Status:** ✅ Schedulable now (I diff against feature changelog).

### 3.5 Cohort retention + LTV report (last day of month)
- **What:** Pull D1/D7/D30 retention, trial-to-paid conversion %, average LTV vs CAC. Compare to prior month.
- **Why:** Retention is the only number that decides whether YDG is a business or a project.
- **Status:** 🔌 Needs Supabase + StoreKit.

---

## 4. One-time — Launch countdown milestones

### 4.1 T-14 days — Submission readiness checkpoint (fire 2026-05-04)
- **What:** Hard checklist: Info.plist `arm64` ✓, full AppIcon set ✓, paywall complies w/ §3.1.2 ✓, Privacy URL live ✓, Terms URL live ✓, support email reachable ✓, screenshots + metadata final ✓.
- **Status:** ✅ Schedulable now (one-time fire).

### 4.2 T-9 days — App Store submit go/no-go (fire 2026-05-18)
- **What:** Final go/no-go review pulling from blockers list, TestFlight crash rate, last 48hrs of feedback. Submit or abort with reason.
- **Status:** ✅ Schedulable now.

### 4.3 T-1 day — Launch eve prep (fire 2026-05-26)
- **What:** Day-of run-of-show: announcement post drafts (IG, TikTok, X, LinkedIn, Reddit r/SideProject + r/iosapps), waitlist email, press release send list, founder mental-prep checklist.
- **Status:** ✅ Schedulable now.

### 4.4 Launch day execution (fire 2026-05-27, 6:00 AM)
- **What:** Execute run-of-show: post announcements at planned times, monitor App Store live status, watch waitlist conversion, handle inbound press.
- **Status:** ✅/🔌 hybrid. Some posting is founder-driven; monitoring is automatable.

### 4.5 T+7 days — Launch retrospective (fire 2026-06-03)
- **What:** Pull launch-week numbers (downloads, reviews, retention D1/D7, MRR, viral coefficient). Compare to plan. Decide what carries into June, what gets cut.
- **Status:** ✅ Schedulable now.

### 4.6 Android port kickoff (fire 2026-06-15)
- **What:** Capacitor port checklist, Play Console setup, Android-specific QA list. Targets ~2026-07-15 Play Store submission.
- **Status:** ✅ Schedulable now.

---

## 5. Event-series support (Q3 2026 city events)

### 5.1 Event leadtime task generator (T-30, T-14, T-7, T-1)
- **What:** Per-event countdown that fires task lists at standard leadtimes — venue confirmed, RSVP page live, waiver collected, partner emails sent, day-of run-of-show.
- **Why:** Running a 2–3 city series solo means standardized checklists are non-negotiable.
- **Status:** ✅ Schedulable per-event once dates set.

### 5.2 RSVP signup digest (daily during event windows)
- **What:** Daily summary of new RSVPs, dietary/access notes, capacity vs cap, partners cc'd.
- **Status:** 🔌 Depends on RSVP tool (Eventbrite, Lu.ma, Partiful).

---

## 6. Founder operating system (always-on)

### 6.1 Inbox zero nudge (5:00 PM daily)
- **What:** Count of unread + threads >24hrs without reply. Nothing else.
- **Why:** A nudge is enough; long inbox digests just create more inbox.
- **Status:** 🔌 Needs Gmail connector.

### 6.2 Calendar load preview (Sun evening)
- **What:** Next-week calendar walkthrough — overcommitments, missing prep blocks for events, double-bookings.
- **Status:** ✅ Available with Google Calendar already connected.

### 6.3 "What did I ship this week" log (Fri 4:00 PM)
- **What:** Auto-generated brag doc — 3-bullet list of the week's wins. Stored to a running log.
- **Why:** Solo founders forget. The log is fuel during the week-3 trough.
- **Status:** ✅ Schedulable now.

### 6.4 30-day countdown daily ping (now → 2026-05-27)
- **What:** Single line each morning: "T-N days. {biggest task today}."
- **Status:** ✅ Schedulable now.

---

## 7. Recommended phase-1 setup (highest ROI to start with)

If we start with five scheduled tasks today, I'd pick — in this order:

1. **30-day countdown daily ping** (1.0 — single line, max signal, zero overhead)
2. **Morning launch standup brief** (1.1 — anchor the sprint)
3. **Reddit engagement queue** (1.5 — your stated channel, drafted-not-posted)
4. **Monday launch readiness review** (2.1 — keep the plan honest)
5. **T-9 days submit go/no-go** (4.2 — one-time, hard date)

These are all schedulable with what's already wired up. Connector-dependent tasks (1.2, 1.3, 1.7, 2.2, 2.3, 2.4, 3.1, 3.5, 6.1) come online as connectors get added.

---

## Open questions for founder

- Do you want morning briefs delivered to chat, email, or both?
- Reddit drafts: post yourself, or run them past me first each time?
- Are events confirmed for cities/dates yet? (Need to slot 5.1.)
- Which connectors do you want to prioritize wiring up — Gmail, App Store Connect, or Firebase first?
