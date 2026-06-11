# Cursor Task — Generate complete AppIcon size grid

**Owner:** Designer (slicing) + Anjela (Cursor) for Contents.json
**Specced by:** ios-developer agent
**Priority:** P0 — Apple requires the full size grid
**Estimated effort:** 30 min designer + 10 min Cursor

---

## Context for Cursor

`ios/YourDateGenie/Assets.xcassets/AppIcon.appiconset/` currently contains only the 1024×1024 universal "marketing" icon. Apple requires a full size grid covering iPhone, iPad, Spotlight, Settings, and Notifications variants. App Store Connect validation will reject builds missing required sizes.

Anjela has the 1024×1024 master ready (confirmed 2026-04-29). Designer slices it into the size grid; Cursor updates `Contents.json` to declare all the sizes.

---

## Goal

`AppIcon.appiconset/` contains all required PNG files at correct sizes, and `Contents.json` declares them all so Xcode knows which file maps to which idiom + scale.

---

## Required sizes (full Apple grid for universal app)

| Filename | Size (px) | Idiom | Purpose |
|---|---|---|---|
| `Icon-20.png` | 20×20 | universal | Notification (1x — legacy, generally include) |
| `Icon-20@2x.png` | 40×40 | iphone, ipad | Notification (2x) |
| `Icon-20@3x.png` | 60×60 | iphone | Notification (3x) |
| `Icon-29.png` | 29×29 | universal | Settings (1x) |
| `Icon-29@2x.png` | 58×58 | iphone, ipad | Settings (2x) |
| `Icon-29@3x.png` | 87×87 | iphone | Settings (3x) |
| `Icon-40.png` | 40×40 | universal | Spotlight (1x) |
| `Icon-40@2x.png` | 80×80 | iphone, ipad | Spotlight (2x) |
| `Icon-40@3x.png` | 120×120 | iphone | Spotlight (3x) |
| `Icon-60@2x.png` | 120×120 | iphone | App icon (2x) |
| `Icon-60@3x.png` | 180×180 | iphone | App icon (3x) |
| `Icon-76.png` | 76×76 | ipad | App icon (1x — legacy) |
| `Icon-76@2x.png` | 152×152 | ipad | App icon (2x) |
| `Icon-83.5@2x.png` | 167×167 | ipad | App icon (2x, iPad Pro) |
| `Icon-1024.png` | 1024×1024 | ios-marketing | App Store |

(Some duplicate-size files share image content but exist under different names so Xcode's asset catalog knows the idiom — e.g. `Icon-40.png` and `Icon-20@2x.png` are both 40×40 but have different roles.)

---

## Task breakdown

### Step 1 — Designer slices the 1024×1024 master

Designer exports each size as a PNG with:
- No alpha channel (Apple requires opaque)
- No rounded corners (Apple applies the rounding)
- sRGB color space
- Filename matching the table above

Designer drops all PNGs into `ios/YourDateGenie/Assets.xcassets/AppIcon.appiconset/` directory.

### Step 2 — Cursor updates `Contents.json`

Replace the current `Contents.json` with the full declaration. Use this template:

```json
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20",
      "filename" : "Icon-20@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20",
      "filename" : "Icon-20@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29",
      "filename" : "Icon-29@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29",
      "filename" : "Icon-29@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40",
      "filename" : "Icon-40@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40",
      "filename" : "Icon-40@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60",
      "filename" : "Icon-60@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60",
      "filename" : "Icon-60@3x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20",
      "filename" : "Icon-20.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20",
      "filename" : "Icon-20@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29",
      "filename" : "Icon-29.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29",
      "filename" : "Icon-29@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40",
      "filename" : "Icon-40.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40",
      "filename" : "Icon-40@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76",
      "filename" : "Icon-76.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76",
      "filename" : "Icon-76@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5",
      "filename" : "Icon-83.5@2x.png"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024",
      "filename" : "Icon-1024.png"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

If the existing icon is currently named `AppIcon.png`, rename it to `Icon-1024.png` to match the new manifest (or update the manifest to match the existing name — pick one and be consistent).

### Step 3 — Verify in Xcode

Open `Assets.xcassets` in Xcode. Click `AppIcon`. Every slot should show a populated icon — no empty grey boxes. Any missing slot = missing PNG file.

---

## Verification checklist

- [ ] All 15 PNGs listed above are in `AppIcon.appiconset/`
- [ ] Each PNG has the exact pixel dimensions in its filename (open in Preview / `sips -g pixelWidth -g pixelHeight Icon-60@3x.png` should print 180 × 180)
- [ ] None of the PNGs have alpha (run `sips -g hasAlpha Icon-1024.png` — should print "no")
- [ ] `Contents.json` validates as JSON
- [ ] Xcode's asset catalog UI shows every slot filled
- [ ] `xcodebuild -scheme YourDateGenie build` completes without warnings about missing icons
- [ ] Archive uploaded to App Store Connect → no "missing required icon" validation error

## Out of scope

- Designing the icon itself (Anjela has the 1024×1024 master)
- Watch / CarPlay / Mac Catalyst icons (we're iPhone + iPad only at launch)

## When you're done

Tell me ("chief-of-staff, app icon grid done") and I'll mark P0 #3 as complete.
