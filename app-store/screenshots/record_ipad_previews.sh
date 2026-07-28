#!/usr/bin/env bash
# Record 3 iPad 13" app previews → 1200×1600 .mov with stereo AAC
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${1:-$ROOT/app-store/screenshots/ipad-app-previews}"
DEVICE="iPad Pro 13-inch (M5)"
BUNDLE="com.yourdategenie.app"
PREVIEW_W=1200
PREVIEW_H=1600

mkdir -p "$OUT_DIR"

APP_PATH="$(find "$HOME/Library/Developer/Xcode/DerivedData" -name 'YourDateGenie.app' -path '*Debug-iphonesimulator*' ! -path '*Index.noindex*' -print -quit)"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Build the app first: cd ios && xcodebuild -scheme YourDateGenie -destination 'platform=iOS Simulator,name=${DEVICE}' build" >&2
  exit 1
fi

if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
  :
else
echo "Building for $DEVICE..."
cd "$ROOT/ios"
xcodebuild \
  -scheme YourDateGenie \
  -destination "platform=iOS Simulator,name=${DEVICE}" \
  -configuration Debug \
  -quiet \
  build

APP_PATH="$(xcodebuild \
  -scheme YourDateGenie \
  -destination "platform=iOS Simulator,name=${DEVICE}" \
  -configuration Debug \
  -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/ BUILT_PRODUCTS_DIR / {print $2; exit}')/YourDateGenie.app"
fi
if [[ ! -d "$APP_PATH" ]]; then
  echo "Could not find built app at $APP_PATH" >&2
  exit 1
fi
command -v ffmpeg >/dev/null || { echo "brew install ffmpeg" >&2; exit 1; }

UDID="$(xcrun simctl list devices available -j \
  | python3 -c "import json,sys; d=json.load(sys.stdin); name=sys.argv[1]; print(next(u['udid'] for devs in d['devices'].values() for u in devs if u.get('name')==name and u.get('isAvailable')))" \
  "$DEVICE")"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl install "$UDID" "$APP_PATH" 2>/dev/null || true
SIM="$UDID"

launch_scene() {
  xcrun simctl terminate "$SIM" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$SIM" "$BUNDLE" -AppStoreScreenshots "-scene=${1}" >/dev/null
  sleep 4
}

record_preview() {
  local name=$1
  shift
  local -a steps=("$@")
  local raw="$OUT_DIR/.${name}_raw.mov"
  local out="$OUT_DIR/${name}.mov"

  echo "Recording ${name}…"
  rm -f "$raw" "$out"

  xcrun simctl io "$SIM" recordVideo --codec=h264 --force "$raw" &
  local rec_pid=$!
  sleep 0.8

  for step in "${steps[@]}"; do
    scene="${step%%:*}"
    seconds="${step##*:}"
    launch_scene "$scene"
    sleep "$seconds"
  done

  kill -INT "$rec_pid" 2>/dev/null || true
  wait "$rec_pid" 2>/dev/null || true
  sleep 0.5

  ffmpeg -y -loglevel error -i "$raw" \
    -f lavfi -i "anullsrc=r=48000:cl=2" \
    -vf "scale=${PREVIEW_W}:${PREVIEW_H}:force_original_aspect_ratio=decrease,pad=${PREVIEW_W}:${PREVIEW_H}:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,fps=30" \
    -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p \
    -b:v 10M -maxrate 12M -bufsize 24M \
    -c:a aac -b:a 256k -ar 48000 -ac 2 \
    -shortest -t 29 -movflags +faststart \
    "$out"
  rm -f "$raw"
  echo "  ✓ ${name}.mov (${PREVIEW_W}×${PREVIEW_H})"
}

record_preview "01_planning_flow" "home:3" "questionnaire:5" "generating:4" "planOptions:8" "homePlan:4"
record_preview "02_share_the_night" "homePlan:5" "partnerShare:10" "homePlan:5"
record_preview "03_beyond_the_plan" "convo:7" "dates:7" "home:6"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/fix_app_previews.sh" "$OUT_DIR" "$OUT_DIR/fixed" "$PREVIEW_W" "$PREVIEW_H"

echo "Upload .mov files from: $OUT_DIR/fixed/"
