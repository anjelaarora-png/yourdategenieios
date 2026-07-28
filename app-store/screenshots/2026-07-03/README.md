# App Store assets — 2026-07-03

Fresh capture from **cream-card / gold extras** build on branch `cursor/cream-card-rose-home-polish`.

Generated 2026-07-03.

---

## iPhone 6.5" — Screenshots (1284 × 2778 px)

**Upload folder:** `iphone-6.5/` → App Store Connect **6.5" Display** slot.

Upload **01–10** in order (main marketing set):

| # | File | Headline |
|---|------|----------|
| 1 | `01_plan_tonight.png` | Plan tonight's date. |
| 2 | `02_built_around_you.png` | Built around you two. |
| 3 | `03_wishes_granted.png` | Wishes granted. |
| 4 | `04_three_acts.png` | Pasta. Art. Late-night gelato. |
| 5 | `05_send_in_one_tap.png` | Send it in one tap. |
| 6 | `06_never_run_out.png` | Never run out of date ideas. |
| 7 | `07_one_tap_away.png` | One tap away. |
| 8 | `08_genie_at_work.png` | The Genie is thinking. |
| 9 | `09_every_romantic_detail.png` | Every romantic detail. |
| 10 | `10_plan_together.png` | Plan together. |

Optional extras (same folder): `11_memory_gallery.png`, `12_playlist.png`, `13_gift_finder.png`, `14_see_every_stop.png`.

**New in this bundle:** `14_see_every_stop.png` — full itinerary / plan detail view (swap in for slot 4 if you want zero duplicate captures; slot 4 currently reuses the home-plan screen).

**Also included:** `iphone-6.9/` (1290×2796) if you prefer the primary 6.9" slot instead.

---

## iPhone — App previews (886 × 1920 px, 15–30s)

**Upload from:** `app-previews/fixed/` (stereo AAC 256 kbps, H.264 High L4.0)

| # | File | Content |
|---|------|---------|
| 1 | `01_planning_flow.mov` | Home → questionnaire → generating → plan options → tonight's plan |
| 2 | `02_share_the_night.mov` | Plan ready → share with partner |
| 3 | `03_beyond_the_plan.mov` | Convo extras → Dates library → Home |

---

## iPad 13" — Screenshots (2064 × 2752 px)

**Upload folder:** `ipad-13/` → App Store Connect **13" Display** slot.

Upload **01–10** in order:

| # | File | Headline |
|---|------|----------|
| 1 | `01_plan_tonight.png` | Plan tonight's date. |
| 2 | `02_built_around_you.png` | Built around you two. |
| 3 | `03_wishes_granted.png` | Wishes granted. |
| 4 | `04_three_acts.png` | Pasta. Art. Late-night gelato. |
| 5 | `05_send_in_one_tap.png` | Send it in one tap. |
| 6 | `06_never_run_out.png` | Never run out of date ideas. |
| 7 | `07_one_tap_away.png` | One tap away. |
| 8 | `08_genie_at_work.png` | The Genie is thinking. |
| 9 | `09_every_romantic_detail.png` | Every romantic detail. |
| 10 | `10_plan_together.png` | Plan together. |

Optional extras: `ipad-13/extras/11–13`.

**2026-07-04 fix:** Slot **10** now uses raw capture `cap_04b_plan_options.png` (`planOptionsB` scene) so it no longer duplicates slot **3** (`cap_04_plan_options.png`). Re-upload **`03_wishes_granted.png`**, **`04_three_acts.png`**, and **`10_plan_together.png`** if those slots were already live in App Store Connect. Composites for those three files were regenerated **2026-07-04** after a fresh iPad `planOptionsB` capture; main set **01–10** now maps to **10 distinct** `cap_*` sources.

---

## iPad 13" — App previews (1200 × 1600 px, 15–30s)

**Upload from:** `app-previews-ipad/fixed/`

| # | File | Content |
|---|------|---------|
| 1 | `01_planning_flow.mov` | Home → questionnaire → generating → plan options → tonight's plan |
| 2 | `02_share_the_night.mov` | Plan ready → share with partner |
| 3 | `03_beyond_the_plan.mov` | Convo extras → Dates library → Home |

---

## Regenerate

```bash
cd app-store/screenshots
./generate_dated_bundle.sh 2026-07-03

# App previews (after build + captures)
./record_app_previews.sh 2026-07-03/app-previews
./fix_app_previews.sh 2026-07-03/app-previews 2026-07-03/app-previews/fixed
./record_ipad_previews.sh 2026-07-03/app-previews-ipad
```

Raw simulator captures live in `_ios_screenshots/` and `_ios_screenshots/ipad/`.
