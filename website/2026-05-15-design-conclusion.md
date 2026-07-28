# Your Date Genie — Website Design Conclusion
**Built:** 2026-05-15
**Status:** Awaiting Anjela's approval before we touch Elementor

This is the locked design spec for yourdategenie.com. Two pages get redesigned today: **Home** and **Waitlist**. Everything else (About, FAQs, Contact, Pricing, Our Story) stays untouched pre-launch. We do those in v1.1 post-launch.

---

## Brand system (applies to both pages)

### Typography
- **Display / Headlines:** Cormorant Garamond, weight 400 italic + 600 regular
  - Hero headlines: 56–72px desktop / 40–48px mobile
  - Section headlines: 36–44px / 28–32px mobile
- **Body / Ledes:** Cormorant Garamond Light **300**, 19px / line-height 1.55 (ledes at 21px)
- **UI (forms, nav, footer columns, phone mocks, pop-out tags):** Plus Jakarta Sans
- **Eyebrows / All-caps labels / Buttons:** Cinzel, tracked, weight 500–600
- **Italic emphasis:** Cormorant italic weight 400 in **champagne** color

### Color palette
- **Background:** Cream `#F5EDE0`
- **Ink (primary text):** Deep maroon `#5B1A2B`
- **Accent / Italic emphasis:** Champagne `#C9A961`
- **Soft highlight:** Dusty rose `#E8C9B8`
- **Pure white:** Used sparingly inside phone mocks only

### Motion
- 0.05–0.50s staggered entrance delays on chip / detail elements
- 4-second slow float loop on the constellation pop-out chips
- All hover effects: ≤200ms ease-out, subtle scale (1.02–1.05), no bounce
- Reduced motion media query honored

---

## Page 1 — HOME (replaces "HOME new")

The story arc from top to bottom: founder hello → product magic → social proof → CTA. **Eight sections.**

### Section 1 — Hero (founder photo + name + blurb at top)
- **Background:** Full-bleed cream `#F5EDE0`
- **Layout:** Two-column on desktop (founder photo left 40%, copy right 60%); stacked on mobile
- **Founder photo:** Soft-edged polaroid frame, 320×400px, tilted 2° left
- **Eyebrow:** Cinzel uppercase tracked — "FROM THE FOUNDER"
- **Headline:** Cormorant 56px — "Hi, I'm Anjela."
- **Sub:** Cormorant Light 300, 21px — "I built Your Date Genie because the answer to 'what are we doing tonight' shouldn't take an hour. We're starting in New York."
- **CTA button:** Cinzel uppercase — "JOIN THE WAITLIST" → `/waitlist` (or `/be-the-first`)

### Section 2 — The magic moment (iPhone mockup)
- **Background:** Cream with a faint champagne radial behind the phone
- **Layout:** Single centered phone mock at 320×640px
- **Phone shows:** Date plan card — "Tonight, something good · Bar Penny & a slow walk home · Wine · Quiet · Walkable"
- **Constellation pop-out** (4 chips around bezel, on hover or scroll-trigger):
  - Top-left · 🍷 — Cinzel tag "MOOD" / italic value "Cozy & slow"
  - Top-right · ⚠ — Cinzel tag "ALLERGY" / italic value "No shellfish"
  - Bottom-left · ♪ — Cinzel tag "LOVES" / italic value "Live jazz"
  - Bottom-right · $ — Cinzel tag "BUDGET" / italic value "$80–120"
- **Headline above phone:** Cormorant italic 44px — "Tonight, something good."

### Section 3 — How it works (3 polaroids)
- **Background:** Cream with thin champagne hairline divider above
- **Eyebrow:** "HOW IT WORKS"
- **3 polaroids** in tilted scattered row:
  1. "TELL US THE VIBE" — photo of couple choosing, tilted -3°
  2. "WE CRAFT THE NIGHT" — photo of date plan on screen, tilted +1°
  3. "YOU JUST SHOW UP" — photo of couple at bar, tilted -2°
- Each polaroid 240×280px, Cormorant italic caption below

### Section 4 — What you both love (mood/preferences detail)
- **Background:** Soft dusty rose `#E8C9B8`
- **Headline:** Cormorant 44px — "What you both love."
- **Body:** Cormorant Light 300 lede — "We capture every detail — your mood, your dietary needs, your favorite activities, your budget — and turn them into one night you'll remember."
- **Below:** Row of 4 detail cards in Plus Jakarta Sans (mood emojis 15px, mood circles 28px)

### Section 5 — Journey timeline
- **Background:** Cream
- **Eyebrow:** "THE WHOLE NIGHT, PLANNED"
- **Timeline element:** Vertical line on left, 3–4 timestamp blocks
  - 7 PM · Bar Penny · Cormorant italic — "Quiet, candlelit, two seats at the bar"
  - 8:30 PM · Slow walk · "Down Hudson, two stops for photos"
  - 9:30 PM · Hudson River bench · "Bring the leftover wine"
- **Final block:** "And the rest is yours." in Cormorant italic, champagne color

### Section 6 — Social proof
- **Background:** Cream
- **Eyebrow:** "AS FEATURED IN"
- **Logo row:** Vogue · Cup of Jo · TechCrunch (use placeholder until press hits)
- **Below:** Cormorant italic 28px — "3,412 couples ahead of you. Invites sent weekly."

### Section 7 — Final CTA (waitlist)
- **Background:** Champagne `#C9A961` with cream text
- **Headline:** Cormorant 56px — "Romance, Reimagined."
- **Sub:** "Be the first to know when we open the doors."
- **Email input + CTA button:** Cinzel uppercase — "JOIN THE WAITLIST"
- **Below:** Cinzel small caps — "FREE FOR THE FIRST 1,000."

### Section 8 — Footer
- **Background:** Deep maroon `#5B1A2B`, cream text
- **Columns:** About · Press · Privacy · Terms · Contact
- **Social:** IG @yourdategenie · TikTok @yourdategenie
- **Copyright:** © 2026 Your Date Genie LLC · New Jersey

---

## Page 2 — WAITLIST (replaces "BE THE FIRST")

The conversion page. No header navigation, no footer. Just sign up.

### Section 1 — Hero waitlist form
- **Background:** Full-bleed cream
- **Layout:** Centered, 480px max-width column
- **Eyebrow:** Cinzel uppercase — "JOIN THE WAITLIST"
- **Headline:** Cormorant italic 64px — "Romance, Reimagined."
- **Sub:** Cormorant Light 300, 21px — "An AI date planner for couples who want every night to count. Launching in New York, May 27."
- **Form fields (Plus Jakarta Sans):**
  - Email (required)
  - City (optional, dropdown: NYC / LA / Chicago / Other)
  - Relationship status (optional: In a relationship / Married / Dating / It's complicated)
- **CTA button:** Cinzel uppercase — "I'M IN" — champagne background, maroon text
- **Below button:** Cinzel small — "FREE FOR THE FIRST 1,000 · NO SPAM · UNSUBSCRIBE ANYTIME"

### Section 2 — Social proof strip
- **Background:** Cream with champagne hairline above
- **Single line, centered:** Cormorant italic — "3,412 couples ahead of you · Featured in Vogue, Cup of Jo, TechCrunch"

### Section 3 — Founder note (small, below the fold)
- **Background:** Cream
- **Layout:** Two-column, founder photo small (200×200 polaroid tilted -2°) left, blurb right
- **Headline:** Cormorant 32px — "Why I'm building this."
- **Blurb:** 2–3 sentences from Anjela, ending with "— Anjela, NYC" in Cinzel small caps

### Section 4 — Footer (slim)
- **Background:** Cream, single line
- **Text:** "© 2026 Your Date Genie LLC · Privacy · Terms" in Cinzel small caps, centered

---

## Mapping to Elementor — how we'll build this

I'll use Elementor's standard widget library (no premium add-ons assumed). Each section above maps to:

- **Section** widget (Elementor's container)
- Inside: **Inner Section** for multi-column layouts, or **Spacer** + content widgets
- **Heading** widget for all headlines (typography overridden per spec)
- **Text Editor** widget for body paragraphs (use the custom font CSS)
- **Image** widget for founder photos / polaroids (apply transform: rotate via CSS class)
- **Button** widget for all CTAs (typography overridden)
- **Spacer** widget for vertical rhythm
- **Custom CSS** widget block for Cormorant Garamond Light import + utility classes

Custom CSS one-time setup at the top of HOME and WAITLIST pages:

```css
@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,600;1,300;1,400&family=Plus+Jakarta+Sans:wght@400;500;600&family=Cinzel:wght@400;500;600&display=swap');

.ydg-body { font-family: 'Cormorant Garamond', serif; font-weight: 300; font-size: 19px; line-height: 1.55; color: #5B1A2B; }
.ydg-lede { font-family: 'Cormorant Garamond', serif; font-weight: 300; font-size: 21px; line-height: 1.55; color: #5B1A2B; }
.ydg-display { font-family: 'Cormorant Garamond', serif; font-weight: 400; font-style: italic; color: #5B1A2B; }
.ydg-ui { font-family: 'Plus Jakarta Sans', sans-serif; }
.ydg-eyebrow { font-family: 'Cinzel', serif; font-weight: 500; text-transform: uppercase; letter-spacing: 0.15em; font-size: 12px; color: #5B1A2B; }
.ydg-cta { font-family: 'Cinzel', serif; font-weight: 600; text-transform: uppercase; letter-spacing: 0.1em; }
.ydg-italic-accent { font-style: italic; color: #C9A961; }
.polaroid-tilt-left { transform: rotate(-2deg); }
.polaroid-tilt-right { transform: rotate(2deg); }
```

---

## What you need to do to approve

Read this. Three responses possible:

- **"Approved."** I duplicate HOME new and BE THE FIRST in wp-admin, open the duplicates in Elementor, and we start building section by section with you watching.
- **"Approved with changes — X, Y, Z."** Note the changes inline above and we restart.
- **"Stop, I want the actual rendered design first."** We wait for the Claude Design usage cap to reset (~19 hours from now → midday tomorrow) and re-pull the live HTML.

If you approve, also drag your **Elementor tab into this Chrome window** so I can drive it. Right now I only see Claude Design + wp-admin Pages list in my window.
