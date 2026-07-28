#!/usr/bin/env bash
# Capture fresh simulator screenshots for App Store marketing composites.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAP_DIR="$ROOT/_ios_screenshots"
DEVICE="${SCREENSHOT_DEVICE:-iPhone 17 Pro Max}"
BUNDLE="com.yourdategenie.app"

mkdir -p "$CAP_DIR"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "Building YourDateGenie for $DEVICE..."
  cd "$ROOT/ios"
  xcodebuild \
    -scheme YourDateGenie \
    -destination "platform=iOS Simulator,name=${DEVICE}" \
    -configuration Debug \
    -quiet \
    build
else
  echo "Skipping build (SKIP_BUILD=1)"
  cd "$ROOT/ios"
fi

APP_PATH="$(find "$HOME/Library/Developer/Xcode/DerivedData" -name 'YourDateGenie.app' -path '*Debug-iphonesimulator*' ! -path '*Index.noindex*' -print -quit)"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Could not find built YourDateGenie.app" >&2
  exit 1
fi

echo "Installing on simulator..."
xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator >/dev/null 2>&1 || true
xcrun simctl install booted "$APP_PATH"

declare -a SCENES=(
  "home:cap_01_home"
  "homePlan:cap_02_home_plan"
  "questionnaire:cap_03_questionnaire"
  "planOptions:cap_04_plan_options"
  "planDetail:cap_05_plan_detail"
  "partnerShare:cap_06_partner_share"
  "dates:cap_07_dates"
  "convo:cap_08_convo"
  "generating:cap_09_generating"
  "memories:cap_10_memories"
  "playlist:cap_11_playlist"
  "giftFinder:cap_12_gift_finder"
)

for entry in "${SCENES[@]}"; do
  scene="${entry%%:*}"
  file="${entry##*:}"
  out="$CAP_DIR/${file}.png"
  echo "Capturing $scene → $(basename "$out")"
  xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch booted "$BUNDLE" -AppStoreScreenshots "-scene=${scene}" >/dev/null
  sleep 5
  if [[ "$scene" == "memories" ]]; then
    sleep 5
  fi
  xcrun simctl io booted screenshot "$out"
done

echo ""
echo "Captures written to $CAP_DIR"
python3 - <<'PY'
from PIL import Image
import os
cap = os.environ.get("CAP_DIR", "/Users/anjelaarora/Downloads/yourdategenie-main/_ios_screenshots")
for name in sorted(os.listdir(cap)):
    if name.startswith("cap_") and name.endswith(".png"):
        im = Image.open(os.path.join(cap, name))
        print(f"  {name}: {im.size[0]}x{im.size[1]}")
PY
