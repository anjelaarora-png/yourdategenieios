#!/usr/bin/env bash
# Capture iPad Pro 13" simulator screenshots for App Store marketing composites.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAP_DIR="$ROOT/_ios_screenshots/ipad"
DEVICE="iPad Pro 13-inch (M5)"
BUNDLE="com.yourdategenie.app"

mkdir -p "$CAP_DIR"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "Building for $DEVICE..."
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
if [[ ! -d "$APP_PATH" ]]; then
  echo "Could not find built app at $APP_PATH" >&2
  exit 1
fi

UDID="$(xcrun simctl list devices available -j \
  | python3 -c "import json,sys; d=json.load(sys.stdin); name=sys.argv[1]; print(next(u['udid'] for devs in d['devices'].values() for u in devs if u.get('name')==name and u.get('isAvailable')))" \
  "$DEVICE")"

xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP_PATH"
SIM="$UDID"

declare -a SCENES=(
  "home:cap_01_home"
  "homePlan:cap_02_home_plan"
  "questionnaire:cap_03_questionnaire"
  "planOptions:cap_04_plan_options"
  "planOptionsB:cap_04b_plan_options"
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
  xcrun simctl terminate "$SIM" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$SIM" "$BUNDLE" -AppStoreScreenshots "-scene=${scene}" >/dev/null
  sleep 5
  if [[ "$scene" == "memories" ]]; then
    sleep 5
  fi
  xcrun simctl io "$SIM" screenshot "$out"
done

python3 - <<PY
from PIL import Image
import os
cap = "$CAP_DIR"
for name in sorted(os.listdir(cap)):
    if name.endswith(".png"):
        im = Image.open(os.path.join(cap, name))
        print(f"  {name}: {im.size[0]}×{im.size[1]}")
PY

echo "iPad captures → $CAP_DIR"
