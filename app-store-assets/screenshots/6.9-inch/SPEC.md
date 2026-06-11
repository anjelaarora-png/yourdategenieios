# Screenshots — 6.9" iPhone (REQUIRED)
**Resolution:** 1320 × 2868 px (portrait)
**Format:** PNG, RGB color space, no alpha / no transparency
**Max file size:** 10 MB per image
**Count:** 3 minimum, 10 maximum (recommend 5 for v1.0)
**Device:** iPhone 16 Pro Max / 17 Pro Max (or matching simulator)

As of 2025, Apple **only requires the 6.9" set**. Apple auto-scales these to all smaller iPhone displays. You don't need to capture 6.7", 6.5", 5.5", etc. separately unless reviewer specifically asks.

---

## The 5 hero shots — capture in this order

### 01-hero-questionnaire.png
- **Screen:** Start questionnaire, vibe selector visible
- **Caption (overlay text):** "Tell us the vibe."
- **What's on screen:** Tonight / Date Night / Weekend toggle at top; vibe cards "Romantic," "Adventurous," "Cozy" mid-screen; warm cream background; gold accents.

### 02-questionnaire-budget.png
- **Screen:** Budget slider step
- **Caption:** "Set the budget."
- **What's on screen:** Slider with $, $$, $$$ tick marks; "We'll keep your plan inside the budget."

### 03-loading-generating.png
- **Screen:** Mid-generation animation (the "Genie is thinking" loader)
- **Caption:** "60 seconds. One perfect plan."
- **What's on screen:** Sparkle animation, "Crafting your date…" copy, soft gradient.

### 04-date-plan-result.png
- **Screen:** Full date plan timeline (the hero asset of the app)
- **Caption:** "Romance, Reimagined."
- **What's on screen:** Three time-blocks (e.g., 7 PM Bar Penny → 8:30 PM slow walk → 9:30 PM Hudson River bench); maps icon; reservation CTA; save heart icon.

### 05-memories-saved.png
- **Screen:** Memories tab with 3 saved plans
- **Caption:** "Every great date, saved."
- **What's on screen:** Three plan cards in scroll; partner avatar on each; date stamps.

---

## Caption typography (do this in Figma or Canva, then composite over screenshot)

- **Font:** Cinzel (headlines), Inter (body) — same as brand
- **Color:** Deep maroon `#5B1A2B` on cream `#F5EDE0`
- **Position:** Top 18% of frame, centered, never overlaps phone status bar
- **Weight:** Cinzel 600 for the caption, all-caps slightly tracked

The phone bezel + status bar must stay visible (App Store policy expects the actual app UI, not pure marketing art).

---

## Capture method options

**Best:** iPhone 16 Pro Max physical device → Screenshot button → AirDrop to Mac → PNG to this folder.

**Backup:** Xcode Simulator → iPhone 16 Pro Max → File → New Screenshot → PNG to this folder.

**Style overlay:** Open each PNG in Canva at 1320×2868 canvas → drop screenshot at full bleed → add caption text in Cinzel → export PNG with "no transparency, no compression."

---

## Validation before upload

For each file, confirm:
- [ ] Filename is exactly as above
- [ ] Pixel dimensions are exactly 1320 × 2868 (check in Preview → Tools → Show Inspector)
- [ ] Color space is RGB (not P3 wide gamut — App Store Connect rejects P3)
- [ ] No alpha channel (run `sips -s format png --deleteColorManagementProperties [file]` if unsure)
- [ ] File size under 10 MB
- [ ] No personally identifiable info in the visible UI (no real partner name, no real phone number)

If any one fails, the upload errors out and you have to redo the whole batch. Validate before uploading.
