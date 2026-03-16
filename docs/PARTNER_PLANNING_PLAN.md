# Partner Planning Feature — Implementation Plan (iOS)

Single source of truth: typography/style, requirements, optimized user flow, and implementation checklist.

---

## Part 1 — Typography & style (match nav exactly)

- **Section headers:** `Font.tangerine(34, weight: .bold)` + `.italic()`, `Color.luxuryGold` (e.g. "Quick Magic" in `HomeTabView`).
- **Subheaders / subtitles:** `Font.bodySans(13, weight: .regular)`, `Color.luxuryCreamMuted`.
- **Body text:** `Font.bodySans(15)` or `Font.bodySans(16)`; colors from `AppTheme.swift`.
- **Button text:** Primary CTA: `Font.bodySans(16, weight: .semibold)`; secondary: `Font.bodySans(14, weight: .semibold)`.
- **Captions:** `Font.bodySans(13, weight: .regular)` / `Font.caption()`.
- **Icons:** SF Symbols, `Color.luxuryGold` (e.g. `.font(.system(size: 22))`).
- **Cards:** `LuxuryFeatureTile` / `.luxuryCard()`; gold border via `LuxuryCardModifier`.
- **Animations:** `withAnimation(.spring(response: 0.4))` or `AppAnimation.spring`.
- **Do not use Cormorant;** use only Tangerine, Times/Header, bodySans from `AppTheme`.

---

## Part 2 — Optimized user flow (integrated)

### Entry
- One **Invite Partner** card on Home (below Quick Magic) → opens **Plan Together** sheet.

### Plan Together sheet — state-driven, one sheet

| State | Sheet content |
|-------|----------------|
| **No partner session** | CTAs (Plan My Next Date, Reuse Last Plan, Pick up where you left off) + divider "or invite your partner" + invite form. |
| **Invite sent, partner not joined** | Same CTAs + **inline Waiting** block (gold ring, "Waiting for your partner...", "Magic is brewing", Send a Reminder, **Fill my preferences**) + form collapsed or "Edit invite". |
| **Partner joined, you haven’t filled** | Prominent "Plan My Next Date" + "Partner is ready." |
| **Both filled** | Auto → Magical Loading → Date Plan Result ("Made for [A] & [B]"). |

### CTAs (exact nav wording)
- **Plan My Next Date** — primary gold gradient, sparkles icon. If no partner session: solo questionnaire. If partner session active: your questionnaire then merge when partner submits.
- **Reuse Last Plan** — secondary gold outline, arrow.clockwise icon. Load most recent from `coordinator.generatedPlans` or `savedPlans` → Date Plan Result.
- **Pick up where you left off** — secondary gold outline, bookmark.fill icon. Resume from `QuestionnaireProgressStore`.

### Invite path
- Form: Partner name (person.fill), email (envelope.fill), optional message (message.fill).
- **Send Magical Invite** → Share sheet (`UIActivityViewController`) with pre-filled message + join link (session id in URL). User sends via iMessage/WhatsApp/email.
- After send: show **inline Waiting** on same sheet (no full-screen). **Send a Reminder** = share sheet again. **Fill my preferences** = start questionnaire now so merge can run when partner submits.

### Partner joins
- Partner opens link → "Join [Inviter name]'s date plan" → fill questionnaire → on submit, inviter sees "Partner is done — generating your plan" → merge + generate → Result with "Made for [A] & [B]" and "Both of you will love this because...".

---

## Part 3 — Requirements by section (original 8 sections, aligned to flow)

### Section 1 — Invite Partner card on Home
- Add section below Quick Magic; heading styled like "Quick Magic" (Tangerine 34, gold).
- Card: same style as nav cards (e.g. `LuxuryFeatureTile`); left gold `heart.fill`, title "Invite Partner", subtitle "Plan magical dates together", gold border. Tap → open Plan Together sheet.

### Section 2 — Plan Together sheet
- Full-screen sheet; background `Color.luxuryMaroon`; animated gold sparkles.
- Header: gold sparkle icon, title "Plan Together", subtitle "Two hearts, one perfect date."

### Section 3 — Three CTAs (nav wording)
- **Plan My Next Date** — primary gold gradient, sparkles icon.
- **Reuse Last Plan** — secondary outline, arrow.clockwise (show if `LastQuestionnaireStore.hasLastData` or `hasCompletedPreferences`).
- **Pick up where you left off** — secondary outline, bookmark.fill (show if `QuestionnaireProgressStore.hasValidProgress`).
- Gold divider + text "or invite your partner" between CTAs and invite form.

### Section 4 — Partner invite form
- Inputs: match `LuxuryTextField` (SignUpView); gold border focus animation; icons person.fill, envelope.fill, message.fill (all gold).
- **Send Magical Invite** — primary CTA style. On tap: generate session id, build join URL, present share sheet; persist invite state; show inline Waiting block on same sheet.
- Caption below button in caption style.

### Section 5 — Waiting for Partner (inline)
- Inline on sheet (not full-screen): animated gold spinning ring, floating sparkles, "Waiting for your partner...", "Magic is brewing", partner avatar placeholder (gold border), **Send a Reminder** (share sheet again), **Fill my preferences** (start questionnaire).

### Section 6 — Combined questionnaire
- Both partners fill separately (inviter can use "Fill my preferences" while waiting). Merge preferences in `PartnerSessionManager` (union arrays, sensible rules for single-choice). Status copy: "Your partner is filling out their preferences..." in body style.

### Section 7 — Combined date plan generation
- `DatePlanGeneratorService`: add partner generation (merge two `QuestionnaireData` into one prompt or merged struct; call existing `generateDatePlan(from:)`). Result: "Made for [Partner 1] & [Partner 2]" badge (gold), "Both of you will love this because..." section in card style.

### Section 8 — Technical
- **PartnerSessionManager.swift** (Managers/): UserDefaults for invite status, partner session state, merged questionnaire; shareable session id / join URL.
- **NavigationCoordinator:** `ActiveSheet.partnerPlanning`; `showPartnerPlanning()`; handle Reuse (most recent plan) and Pick up (QuestionnaireProgressStore) from sheet.
- **MainAppView:** present `PartnerPlanningSheetView` for `.partnerPlanning`.
- All colors from `AppTheme`; gold icons `Color.luxuryGold`; animations `withAnimation(.spring(response: 0.4))`; iOS 17+; do not remove/rename existing views or variables.

---

## Part 4 — Implementation checklist

Execute in this order so each step is testable.

- [ ] **1. PartnerSessionManager** — Create `Managers/PartnerSessionManager.swift`. UserDefaults keys for invite (name, email, message, sentAt), session id, partner state (pending/joined/filled). Methods: `createSession()`, `getJoinURL()`, `saveInvite(...)`, `partnerState`, `setPartnerJoined()`, `setPartnerFilled()`, `mergedQuestionnaireData()` (merge logic stub).
- [ ] **2. NavigationCoordinator** — Add `ActiveSheet.partnerPlanning`; add `showPartnerPlanning()`. In Reuse path use `generatedPlans.last` or latest from `savedPlans` per product; in Pick up path call existing resume flow.
- [ ] **3. MainAppView** — In `sheetContent(for:)` add case `.partnerPlanning` → `PartnerPlanningSheetView()`.
- [ ] **4. Home — Invite Partner section** — In `HomeTabView`, add section below Quick Magic: heading "Invite" / "Partner", one card (heart.fill, "Invite Partner", "Plan magical dates together"), tap calls `coordinator.showPartnerPlanning()`.
- [ ] **5. PartnerPlanningSheetView — shell** — New view: `Color.luxuryMaroon`, sparkles background, header "Plan Together" / "Two hearts, one perfect date.", state from `PartnerSessionManager` (or local @State backed by it).
- [ ] **6. Sheet — CTAs** — Add three buttons (Plan My Next Date primary; Reuse Last Plan, Pick up where you left off secondary) with same styling as `HomeTabView` heroSection; conditional visibility for Reuse/Pick up; wire actions to coordinator and PartnerSessionManager.
- [ ] **7. Sheet — divider and invite form** — Gold divider + "or invite your partner"; form (name, email, message) with LuxuryTextField-style and gold icons; "Send Magical Invite" button; on send generate session id, build URL, present share sheet, save invite, switch state to show inline Waiting.
- [ ] **8. Sheet — inline Waiting block** — When invite sent and partner not joined: show inline Waiting (spinning ring, copy, avatar placeholder, Send a Reminder, Fill my preferences). Send a Reminder → share sheet again. Fill my preferences → start questionnaire (coordinator) in partner mode so result can merge later.
- [ ] **9. State-driven sheet content** — Drive sheet body by PartnerSessionManager state: no session → CTAs + form; invite sent → CTAs + Waiting (+ collapsed form); partner joined → emphasize Plan My Next Date + "Partner is ready."
- [ ] **10. Questionnaire partner mode** — Optional: partner-mode flag in coordinator so questionnaire completion writes to PartnerSessionManager (e.g. "inviter filled" / "partner filled"); when both filled trigger merge + generation.
- [ ] **11. DatePlanGeneratorService — partner generation** — Add `generateDatePlan(partnerA:partnerB:)` or merge two `QuestionnaireData` into one and call `generateDatePlan(from:)`; extend `buildPrompt` for "Partner A prefers X, Partner B Y; balance both."
- [ ] **12. Result — partner badge and copy** — On DatePlanResultView (or partner result view), when plan is from partner flow: show "Made for [A] & [B]" badge (gold), "Both of you will love this because..." section in nav card style.
- [ ] **13. Join link / partner entry** — Implement partner entry: when app opens via join URL (universal link or web), read session id, show "Join [Name]'s date plan" → questionnaire → on complete call PartnerSessionManager to mark partner filled and trigger merge/generate for inviter (or store partner data for merge when inviter next opens).

---

## File list

| File | Action |
|------|--------|
| `ios/YourDateGenie/Managers/PartnerSessionManager.swift` | Create |
| `ios/YourDateGenie/Navigation/NavigationCoordinator.swift` | Add enum case + method |
| `ios/YourDateGenie/Navigation/MainAppView.swift` | Add sheet case |
| `ios/YourDateGenie/Navigation/HomeTabView.swift` | Add Invite Partner section |
| `ios/YourDateGenie/Views/PartnerPlanning/PartnerPlanningSheetView.swift` | Create (or under Views/) |
| `ios/YourDateGenie/Managers/DatePlanGeneratorService.swift` | Add partner merge + generation |
| `ios/YourDateGenie/Views/DatePlan/DatePlanResultView.swift` | Add partner badge + "Both of you will love..." |

Optional: `WaitingForPartnerView` as a subview inside the sheet; partner join flow view (when app opens from link).

Use `docs/partner-planning-optimized-flow.md` for copy and flow detail; this plan is the implementation source of truth.
