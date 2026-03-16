# Partner Planning — Optimized User Flow

**Implementation plan and checklist:** see [PARTNER_PLANNING_PLAN.md](PARTNER_PLANNING_PLAN.md).

## Goals
- One clear primary path: "Plan together" (with or without partner on another device).
- Minimal taps and no dead ends.
- Same CTA wording as home nav: "Plan My Next Date", "Reuse Last Plan", "Pick up where you left off".

---

## 1. Entry: One card on Home

- **Invite Partner** card (below Quick Magic) → opens **Plan Together** sheet.
- One entry point; all partner options live in the sheet.

---

## 2. Plan Together sheet — Two clear paths

### Path A: "Plan now" (same device or reuse/resume)

**Top of sheet (always visible):**
- Primary: **Plan My Next Date** — gold gradient, sparkles icon.
- Secondary (conditional, same as nav): **Reuse Last Plan** (if `LastQuestionnaireStore.hasLastData` or `hasCompletedPreferences`).
- Secondary (conditional): **Pick up where you left off** (if `QuestionnaireProgressStore.hasValidProgress`).

**Behavior:**
- **Plan My Next Date**  
  - If **no active partner session**: start questionnaire as today (solo). On completion, optionally show "Invite partner to get a plan that fits you both" with a small link to the invite form (same sheet, scroll to form).  
  - If **partner session active** (invite sent and partner joined): start questionnaire; when you finish, show "Waiting for partner's preferences" or, if partner already submitted, merge and generate immediately.
- **Reuse Last Plan** → Load most recent plan from coordinator → Date Plan Result. One tap.
- **Pick up where you left off** → Resume questionnaire from `QuestionnaireProgressStore` → then generate as usual. One tap.

No extra "Are you planning solo or with partner?" question; the sheet supports both.

---

### Path B: "Invite partner" (partner on another device)

**Below a gold divider:** label **"or invite your partner"**.

- Form: Partner name, Partner email, Optional message.
- **Send Magical Invite** → Share sheet with pre-filled message + join link (e.g. `https://yourdategenie.com/partner/join?session=XXX` or universal link).
- User sends via iMessage / WhatsApp / Email.
- After send: **stay on same sheet** but switch to a **Waiting for Partner** block (inline, no full-screen transition unless you prefer):
  - Animated gold ring + "Waiting for your partner..."
  - Subtitle: "Magic is brewing"
  - Partner avatar placeholder (gold border).
  - **Send a Reminder** → again opens share sheet with same link/message (or copies link to clipboard).
  - **Fill my preferences** (optional CTA): Start your questionnaire now so when partner joins and fills, you're already done and merge can run immediately. Reduces perceived wait.

When partner opens link:
- They land in app (or web fallback) and see "Join [Inviter name]'s date plan".
- They tap Join → fill questionnaire (same steps as solo).
- When partner submits: inviter's app (if open or on next open) shows "Partner is done — generating your plan" → merge + generate → Date Plan Result with "Made for [A] & [B]" and "Both of you will love this because...".

---

## 3. State-driven sheet (optimization)

- **No partner session:** Sheet = CTAs (Plan My Next Date, Reuse, Pick up) + divider + invite form.
- **Invite sent, partner not joined:** Sheet = same CTAs (so they can still Reuse/Pick up) + **inline Waiting** block (spinning ring, "Send a Reminder", "Fill my preferences") + collapsed or hidden form (or "Edit invite" to change message/link).
- **Partner joined, you haven’t filled:** Sheet = prominent "Plan My Next Date" (your turn) + short line "Partner is ready."
- **Both filled:** Auto-transition to Magical Loading → Date Plan Result (no extra tap).

This keeps one sheet, content changes by state; user always sees the next obvious action.

---

## 4. Reduced steps summary

| Goal | Before (generic) | After (optimized) |
|------|-------------------|-------------------|
| Plan with partner remotely | Open sheet → maybe tap Plan? → then invite? → then wait | Open sheet → Invite (form + Send) → optionally "Fill my preferences" while waiting → partner joins and fills → auto merge |
| Plan together, both here | Unclear | Tap "Plan My Next Date" → fill; if partner session exists, partner fills on their device via same link, or they use same device and you pass the phone |
| Reuse / Resume | Same | One tap each; no change |
| After sending invite | Go to full-screen Waiting, then ??? | Inline Waiting + "Fill my preferences" so wait time is useful |

---

## 5. Copy and placement (match nav)

- Section title on home: **Invite** / **Partner** (Tangerine, gold).
- Sheet title: **Plan Together**; subtitle: **Two hearts, one perfect date.**
- CTAs: **Plan My Next Date** | **Reuse Last Plan** | **Pick up where you left off** (exact nav strings).
- Divider text: **or invite your partner**
- Button: **Send Magical Invite**

Use this flow in the implementation so the partner feature feels like one coherent path with minimal decisions.
