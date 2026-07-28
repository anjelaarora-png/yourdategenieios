#!/usr/bin/env bash
# Build fresh iPhone + iPad App Store screenshot packs into app-store/screenshots/YYYY-MM-DD/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPTS="$ROOT/app-store/screenshots"
DATE="${1:-$(date +%Y-%m-%d)}"
BUNDLE="$SCRIPTS/$DATE"

echo "=== Your Date Genie screenshot bundle: $DATE ==="
echo "Output: $BUNDLE"
echo ""

mkdir -p "$BUNDLE"/{iphone-6.9,iphone-6.5,ipad-13,how-to-use}

# One build for both device captures
echo "→ Building app (Debug, iPhone 17 Pro Max)..."
cd "$ROOT/ios"
xcodebuild \
  -scheme YourDateGenie \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.2" \
  -configuration Debug \
  -quiet \
  build

echo ""
echo "→ Capturing iPhone simulator screens..."
SKIP_BUILD=1 "$SCRIPTS/capture_screenshots.sh"

echo ""
echo "→ Capturing iPad Pro 13\" simulator screens..."
SKIP_BUILD=1 "$SCRIPTS/capture_ipad_screenshots.sh"

echo ""
echo "→ Compositing iPhone marketing screenshots..."
export YDG_SCREENSHOT_BUNDLE="$BUNDLE"
python3 "$SCRIPTS/generate_screenshots.py"

echo ""
echo "→ Compositing iPad marketing screenshots..."
python3 "$SCRIPTS/generate_ipad_assets.py"

# README for this bundle
cat > "$BUNDLE/README.md" <<EOF
# App Store assets — $DATE

Generated $(date '+%Y-%m-%d %H:%M %Z').

## iPhone (upload to **6.9" Display** slot)

| Folder | Size | Files |
|--------|------|-------|
| \`iphone-6.9/\` | 1290×2796 | 01–10 main + \`extras/11–13\` (memories, playlist, gift finder) |
| \`iphone-6.5/\` | 1284×2778 | Same set — alternate 6.5" slot if needed |

## iPad 13" (upload to **13" Display** slot)

| Folder | Size | Files |
|--------|------|-------|
| \`ipad-13/\` | 2064×2752 | 01–10 main + \`extras/11–13\` |

## How-to-use (optional)

\`how-to-use/\` — 3 tutorial cards at 1290×2796 (not App Store slots).

## Regenerate

\`\`\`bash
cd app-store/screenshots
./generate_dated_bundle.sh $DATE
\`\`\`
EOF

if [[ -f "$SCRIPTS/promotional-text.txt" ]]; then
  cp "$SCRIPTS/promotional-text.txt" "$BUNDLE/promotional-text.txt" 2>/dev/null || true
fi

echo ""
echo "=== Done ==="
echo "iPhone: $BUNDLE/iphone-6.9/ ($(ls "$BUNDLE/iphone-6.9"/*.png 2>/dev/null | wc -l | tr -d ' ') files + extras)"
echo "iPad:   $BUNDLE/ipad-13/ ($(ls "$BUNDLE/ipad-13"/*.png 2>/dev/null | wc -l | tr -d ' ') files + extras)"
echo "See $BUNDLE/README.md"
