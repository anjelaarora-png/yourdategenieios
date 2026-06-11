# Your Date Genie — App Store Connect Screenshots

**Status:** 6 marketing-style screenshots ready to upload, iPhone 6.9" (1320 × 2868 px), Apple-spec-compliant.
**Generated:** 2026-05-20 (T-7 to submission)

---

## The 6 screenshots

| # | File | Headline | Subtitle | Screen shown |
|---|------|----------|----------|--------------|
| 1 | `01_plan_tonight.png` | Plan tonight's date. | Your night, curated before you ask. | Magazine-cover reveal: issue number, ornament, italic 4-line hero title ("Pasta, Art & Late-Night Gelato."), 3-stop program list with brass hairlines, "Tailored to nut-free" callback |
| 2 | `02_built_around_you.png` | Built around you two. | Mood, budget, allergies, interests — we plan around all of it. | Setup wizard with four sectioned controls: mood chips, budget slider with tick marks, allergy/dietary chips, interest chips |
| 3 | `03_wishes_granted.png` | Wishes granted. | A tailored itinerary in seconds. | Magic generation orb with status items |
| 4 | `04_three_acts.png` | Pasta. Art. Late-night gelato. | Every detail mapped, beat by beat. | Itinerary view — 3-stop date card stack |
| 5 | `05_send_in_one_tap.png` | Send it in one tap. | Share the plan, lock the reservation, show up. | Shared confirmation with envelope + heart seal |
| 6 | `06_never_run_out.png` | Never run out of date ideas. | Your personal genie, in your pocket. | Library grid of saved date ideas |

The mock screens inside the device frames are **placeholder UIs that match the brand and narrative**. You can swap them for real captures later (see "Swap with real captures" below) — the marketing layer (background, headline, subtitle, brass divider, device frame) stays.

---

## Files in this folder

```
app-store/screenshots/
├── README.md                      ← this file
├── iphone-6.9/                    ← upload these 6 to App Store Connect
│   ├── 01_plan_tonight.png
│   ├── 02_built_around_you.png
│   ├── 03_wishes_granted.png
│   ├── 04_three_acts.png
│   ├── 05_send_in_one_tap.png
│   └── 06_never_run_out.png
└── generate_screenshots.py        ← regenerate any time, edit copy or colors in here
```

---

## Apple spec — what you're uploading

| Field | Value |
|---|---|
| Device size | iPhone 6.9" display |
| Resolution | 1320 × 2868 px portrait |
| Format | PNG, sRGB, no alpha channel |
| File size | All under 250 KB (Apple max is 8 MB) |
| Count | 6 (Apple allows 2–10 per device size) |
| Localization | English (U.S.) — your only locale at launch |

**Important inheritance rule:** if you upload screenshots **only** for the 6.9" size, App Store Connect automatically scales and reuses them for older iPhone display sizes (6.7", 6.5", 5.5"). You do **not** need to produce separate sets for older devices.

---

## App Store Connect — exact upload steps

1. Sign in at **appstoreconnect.apple.com** → My Apps → **Your Date Genie**.
2. Make sure you're on the **iOS 1.0 Prepare for Submission** page (not a previously-shipped version).
3. Scroll to **App Previews and Screenshots**.
4. From the device-size dropdown at the top of that section, select **iPhone 6.9" Display**.
5. Drag all 6 PNGs from `app-store/screenshots/iphone-6.9/` into the upload area **in numerical order (01 → 06)**. The first one becomes your hero shot above the fold on the App Store, so the order matters.
6. After upload, drag-rearrange to confirm the order if anything shuffled.
7. Save. App Store Connect will validate dimensions/format on upload and reject anything off-spec — you should see all 6 green-checked.
8. iPad section: leave empty (you're iPhone-only at launch).
9. App Previews section: leave empty for now (you opted out of preview video for v1.0).

---

## Swap with real captures later

Once your TestFlight build is stable and you want real screen content instead of mocks, capture native screenshots from the iPhone 16 Pro Max Simulator at exact resolution:

### From Xcode Simulator

```bash
# 1. Boot iPhone 16 Pro Max simulator
xcrun simctl boot "iPhone 16 Pro Max"
open -a Simulator

# 2. Build + run YDG to the simulator from Xcode

# 3. Navigate to each screen you want to capture, then run:
xcrun simctl io booted screenshot ~/Desktop/ydg-screen-01.png
# Repeat for each screen — files come out at exact 1320 × 2868 px
```

### Then re-render the marketing layer

Open `generate_screenshots.py`. Each `screen_*` function (e.g. `screen_home`, `screen_setup`) draws a mock screen. Replace any one of them with:

```python
def screen_home(canvas, draw, args):
    from PIL import Image
    real = Image.open("/path/to/ydg-screen-01.png").convert("RGB")
    # Resize to match the device frame inner dimensions
    real = real.resize(canvas.size, Image.LANCZOS)
    canvas.paste(real, (0, 0))
```

Re-run `python3 generate_screenshots.py` — your marketing copy + brass frame + brand gradient stays, but the screen inside is now your real app.

### From a physical iPhone on TestFlight

Take screenshots on your iPhone (Side button + Volume Up). They'll be the **native device resolution** of whichever iPhone you have:

| Your phone | Capture size | Need to do |
|---|---|---|
| iPhone 16 Pro Max / 15 Pro Max | 1290 × 2796 | Resize to 1320 × 2868 (close — minor scale) |
| iPhone 16 Pro / 15 Pro | 1179 × 2556 | Don't use for 6.9" slot — too small |
| iPhone 14 Pro Max / 13 Pro Max | 1284 × 2778 | Resize to 1320 × 2868 |
| iPhone 16 / 15 / 14 | 1170 × 2532 | Too small for 6.9" slot |

**Best path:** capture in the Simulator at iPhone 16 Pro Max — you get exact 1320 × 2868 with zero resizing.

---

## Editing the copy

All headlines and subtitles live in the `screens` list at the bottom of `generate_screenshots.py`:

```python
screens = [
    ("01_plan_tonight.png", "Plan tonight's date.", "Tell us the vibe. We handle the rest.", ...),
    ...
]
```

Change the strings, re-run the script, re-upload. Each PNG regenerates in under 2 seconds.

---

## What's intentionally NOT in v1.0

- **iPad screenshots** — you're iPhone-only at launch. Add in v1.1 if you ship iPad.
- **App Preview video** — biggest known conversion lift (~15–25%), but skipped to protect timeline. Can be added post-launch as a metadata-only update (no Apple resubmission needed). Plan to add by mid-June.
- **Localized screenshots** — English U.S. only for v1.0.
- **Dark mode variants** — your brand is already dark (wine), so this is a non-issue.

---

## Post-launch upgrade plan (after May 27)

1. Capture real screens from production iPhone build, swap into the script.
2. Record one 20-second App Preview video (script: pick a city → vibe chips → magic orb → reveal itinerary → share envelope). Capture via Simulator (`xcrun simctl io booted recordVideo`), trim to 15–30s in QuickTime, upload.
3. A/B-test screenshot order via App Store Connect's experiments after you hit 1,000 installs.

---

*Brand tokens, fonts, and visual system pulled from `website/claude-design-bundle/project/colors_and_type.css` so these screenshots match the website and the real app exactly.*
