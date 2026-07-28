#!/usr/bin/env bash
# Re-encode app previews to Apple App Store Connect spec:
# 886×1920, H.264 High L4.0, 10–12 Mbps, 30fps, 15–30s, stereo AAC 256kbps @ 48kHz
set -euo pipefail

SRC_DIR="${1:-$(cd "$(dirname "$0")" && pwd)/app-previews}"
OUT_DIR="${2:-$SRC_DIR/fixed}"
PREVIEW_W="${3:-886}"
PREVIEW_H="${4:-1920}"

mkdir -p "$OUT_DIR"

fix_one() {
  local in=$1
  local base
  base=$(basename "$in" .mp4)
  base=$(basename "$base" .mov)
  local out="$OUT_DIR/${base}.mov"

  echo "Fixing ${base}…"

  # Clamp duration to 15–29s (Apple max 30s; avoid encoder rounding over 30)
  local dur
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")
  if awk -v d="$dur" 'BEGIN { exit !(d < 15) }'; then
    echo "  ✗ ${base} is only ${dur}s (minimum 15s)" >&2
    return 1
  fi
  if awk -v d="$dur" 'BEGIN { exit !(d > 29) }'; then
    dur=29
  fi

  ffmpeg -y -loglevel error -i "$in" \
    -f lavfi -i "anoisesrc=color=pink:duration=${dur}:sample_rate=48000,volume=0.0001" \
    -map 0:v:0 -map 1:a:0 \
    -t "$dur" \
    -vf "scale=${PREVIEW_W}:${PREVIEW_H}:force_original_aspect_ratio=decrease,pad=${PREVIEW_W}:${PREVIEW_H}:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,fps=30" \
    -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p \
    -b:v 10M -maxrate 12M -bufsize 24M \
    -c:a aac -b:a 256k -ar 48000 -ac 2 \
    -shortest \
    -movflags +faststart \
    "$out"

  ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels,bit_rate \
    -select_streams v:0 -show_entries stream=width,height,codec_name \
    -show_entries format=duration -of default=nw=1 "$out" | sed 's/^/  /'
  echo "  ✓ ${out}"
}

shopt -s nullglob
files=("$SRC_DIR"/*.mp4 "$SRC_DIR"/*.mov)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No .mp4 or .mov files in $SRC_DIR" >&2
  exit 1
fi

for f in "${files[@]}"; do
  [[ "$f" == *"/fixed/"* ]] && continue
  [[ "$(basename "$f")" == .* ]] && continue
  fix_one "$f"
done

echo ""
echo "Fixed previews → $OUT_DIR"
echo "Upload the .mov files from the fixed/ folder."
