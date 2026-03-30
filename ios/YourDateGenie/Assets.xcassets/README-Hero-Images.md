# Hero images (loading screen)

Images used as the hero on the "Crafting your date plan" loading screen **must have a transparent background**.

## Required format

- **Format:** PNG
- **Background:** Transparent (no white, gray, or solid color behind the graphic)
- **Content:** Single graphic (e.g. genie lamp, sparkle, key) in your desired color (e.g. gold). The app will show it on a maroon background.

## Assets

- `GenieLampHero.imageset` – Option 1: genie lamp
- `HeroSparkleBurst.imageset` – Option 2: sparkle burst
- `HeroWishKey.imageset` – Option 3: wish key

## How to get transparent background

1. **Export from design tools:** In Figma, Sketch, Illustrator, etc., turn off the background layer and export as PNG, or use "Export with transparency".
2. **Image editors:** In Photoshop, delete or hide the background and save as PNG-24 with transparency. In Preview (macOS), use Tools → Adjust Color and set a color to transparent, or use an app that supports alpha.
3. **AI image generation:** When generating the image, request "transparent background", "no background", or "on transparent" so the asset is saved with alpha channel.

If you add an image that has a gray or white background, the app will still try to remove it at runtime (see `HeroImageWithTransparentBackground` in `MagicalLoadingView.swift`), but for best quality and performance, use a PNG that already has a transparent background.
