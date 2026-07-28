#!/usr/bin/env bash
# Record 3 App Store app previews (886×1920, 15–30s, H.264 .mp4)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${1:-$ROOT/app-store/screenshots/app-previews}"
DEVICE="iPhone 17 Pro Max"
BUNDLE="com.yourdategenie.app"
PREVIEW_W=886
PREVIEW_H=1920

mkdir -p "$OUT_DIR"

APP_PATH="$(find "$HOME/Library/Developer/Xcode/DerivedData" -name 'YourDateGenie.app' -path '*Debug-iphonesimulator*' ! -path '*Index.noindex*' -print -quit)"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Build the app first: cd ios && xcodebuild -scheme YourDateGenie -destination 'platform=iOS Simulator,name=${DEVICE}' build" >&2
  exit 1
fi

command -v ffmpeg >/dev/null || { echo "ffmpeg required (brew install ffmpeg)" >&2; exit 1; }

xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator >/dev/null 2>&1 || true
xcrun simctl install booted "$APP_PATH" 2>/dev/null || true

launch_scene() {
  local scene=$1
  xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch booted "$BUNDLE" -AppStoreScreenshots "-scene=${scene}" >/dev/null
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

  xcrun simctl io booted recordVideo --codec=h264 --force "$raw" &
  local rec_pid=$!
  sleep 0.8

  for step in "${steps[@]}"; do
    local scene="${step%%:*}"
    local seconds="${step##*:}"
    launch_scene "$scene"
    sleep "$seconds"
  done

  kill -INT "$rec_pid" 2>/dev/null || true
  wait "$rec_pid" 2>/dev/null || true
  sleep 0.5

  if [[ ! -f "$raw" ]]; then
    echo "  ✗ recording failed for ${name}" >&2
    return 1
  fi

  ffmpeg -y -loglevel error -i "$raw" \
    -f lavfi -i "anullsrc=r=48000:cl=2" \
    -vf "scale=${PREVIEW_W}:${PREVIEW_H}:force_original_aspect_ratio=decrease,pad=${PREVIEW_W}:${PREVIEW_H}:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,fps=30" \
    -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p \
    -b:v 10M -maxrate 12M -bufsize 24M \
    -c:a aac -b:a 256k -ar 48000 -ac 2 \
    -shortest \
    -t 29 \
    -movflags +faststart \
    "$out"

  rm -f "$raw"
  local dur
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out" 2>/dev/null | cut -d. -f1)
  local sz
  sz=$(($(stat -f%z "$out" 2>/dev/null || stat -c%s "$out") / 1024 / 1024))
  echo "  ✓ ${name}.mov  ~${dur}s  ${sz}MB  ${PREVIEW_W}×${PREVIEW_H}  (stereo AAC)"
}

# Preview 1 — full planning flow (~22s)
record_preview "01_planning_flow" \
  "home:3" "questionnaire:5" "generating:4" "planOptions:8" "homePlan:4"

# Preview 2 — share with partner (~18s)
record_preview "02_share_the_night" \
  "homePlan:5" "partnerShare:10" "homePlan:5"

# Preview 3 — extras & saved plans (~20s)
record_preview "03_beyond_the_plan" \
  "convo:7" "dates:7" "home:6"

echo ""
echo "App previews written to: $OUT_DIR"
