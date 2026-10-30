#!/usr/bin/env bash
# Records the App Store app preview (app-store-presence) from a simulator:
# runs AppPreviewUITests while `simctl io recordVideo` captures the screen, cuts the
# recording at the test's [preview] marks, adds a Russian caption per scene and
# encodes to Apple's spec (H.264 High ≤4.0, 30 fps, ~11 Mbps, silent stereo AAC 256k,
# 15–30 s).
#
# Usage: tools/record_app_preview.sh <simulator-udid> <iphone|ipad> [out.mp4]
#   iphone → 886×1920 portrait, ipad → 1600×1200 landscape.
#   default out: fastlane/marketing/media/preview-<kind>.mp4
#   REUSE=<work dir of an earlier run> re-cuts its raw.mov/offsets.txt without recording.
# Captions are drawn with ImageMagick (ffmpeg builds often lack drawtext).
set -euo pipefail
cd "$(dirname "$0")/.."

UDID="$1"; KIND="$2"; OUT="${3:-fastlane/marketing/media/preview-$KIND.mp4}"
WORK="${REUSE:-$(mktemp -d)}"
FONT="Packages/LoritoKit/Sources/DesignSystem/Resources/Fonts/Unbounded-Bold.ttf"
case "$KIND" in
  iphone) W=886; H=1920; CAP=46 ;;
  ipad)   W=1600; H=1200; CAP=40 ;;
  *) echo "kind must be iphone or ipad" >&2; exit 2 ;;
esac

# Scene → caption, and the seconds kept from each mark.
SCENES=(today recall rule mistakes conjugation progress exams)
declare -A CAPTION=(
  [today]="План на день"
  [recall]="Сначала вспомни"
  [rule]="Правило по-русски"
  [mistakes]="Ошибки русскоязычных"
  [conjugation]="100 глаголов, 14 времён"
  [progress]="Серия и прогресс"
  [exams]="DELE A2 и CCSE"
)
declare -A KEEP=([today]=2.6 [recall]=2.6 [rule]=3.2 [mistakes]=2.6 [conjugation]=2.6 [progress]=2.6 [exams]=4.0)

if [ -z "${REUSE:-}" ]; then
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

echo "building for testing…"
xcodebuild -project Lorito.xcodeproj -scheme Lorito -destination "platform=iOS Simulator,id=$UDID" \
  build-for-testing -derivedDataPath "$WORK/dd" > "$WORK/build.log" 2>&1

xcrun simctl io "$UDID" recordVideo --codec h264 --force "$WORK/raw.mov" > "$WORK/rec.log" 2>&1 &
REC=$!
# The first frame is written when simctl reports the start, not when it is launched.
for _ in $(seq 1 200); do grep -q "Recording started" "$WORK/rec.log" && break; sleep 0.05; done
REC_START=$(python3 -c 'import time; print(time.time())')

TEST_RUNNER_LORITO_PREVIEW=1 xcodebuild -project Lorito.xcodeproj -scheme Lorito \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$WORK/dd" \
  test-without-building -only-testing:LoritoUITests/AppPreviewUITests > "$WORK/test.log" 2>&1 || {
    kill -INT $REC; wait $REC || true
    grep -E "error:|failed" "$WORK/test.log" | head >&2; echo "test failed; log: $WORK/test.log" >&2; exit 1; }
kill -INT $REC; wait $REC || true

# Marks → offsets into the recording.
grep -oE '\[preview\] [a-z]+ [0-9.]+' "$WORK/test.log" | awk '{print $2, $3}' | sort -u -k2n > "$WORK/marks.txt"
python3 - "$WORK/marks.txt" "$REC_START" > "$WORK/offsets.txt" <<'PY'
import sys
start = float(sys.argv[2])
for line in open(sys.argv[1]):
    name, t = line.split()
    print(name, round(float(t) - start, 3))
PY
cat "$WORK/offsets.txt"

fi

# Rotate a portrait capture of a landscape iPad run; then fit into W×H.
RW=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$WORK/raw.mov")
RH=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$WORK/raw.mov")
ROT=""
if [ "$KIND" = ipad ] && [ "$RW" -lt "$RH" ]; then ROT="transpose=2,"; fi
FIT="scale=${W}:${H}:force_original_aspect_ratio=increase,crop=${W}:${H}"

# simctl writes a frame only when the screen changes: make the timeline constant-rate
# (static stretches repeat their frame) before cutting, or a cut would start on the
# next screen.
ffmpeg -loglevel error -y -i "$WORK/raw.mov" -an -vf "${ROT}${FIT},fps=30" -c:v libx264 -crf 10 -preset veryfast \
  -pix_fmt yuv420p "$WORK/cfr.mp4"

i=0; LIST="$WORK/list.txt"; : > "$LIST"
for s in "${SCENES[@]}"; do
  t=$(awk -v n="$s" '$1==n {print $2}' "$WORK/offsets.txt")
  [ -n "$t" ] || { echo "missing mark $s" >&2; exit 1; }
  BAND=$((CAP * 24 / 10))
  magick -size "${W}x${BAND}" xc:'#0F1A14D1' -font "$FONT" -pointsize "$CAP" -fill '#F3F4EF' \
    -gravity center -annotate +0+0 "${CAPTION[$s]}" "$WORK/cap$i.png"
  ffmpeg -loglevel error -y -ss "$t" -t "${KEEP[$s]}" -i "$WORK/cfr.mp4" -i "$WORK/cap$i.png" -an \
    -filter_complex "[0:v][1:v]overlay=0:H*0.035,format=yuv420p" \
    -c:v libx264 -profile:v high -level:v 4.0 -b:v 11M -maxrate 12M -bufsize 24M "$WORK/seg$i.mp4"
  echo "file '$WORK/seg$i.mp4'" >> "$LIST"; i=$((i+1))
done

mkdir -p "$(dirname "$OUT")"
ffmpeg -loglevel error -y -f concat -safe 0 -i "$LIST" -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
  -map 0:v:0 -map 1:a:0 -c:v libx264 -profile:v high -level:v 4.0 -pix_fmt yuv420p -r 30 \
  -b:v 11M -maxrate 12M -bufsize 24M -c:a aac -b:a 256k -shortest -movflags +faststart "$OUT"
ffprobe -v error -show_entries stream=codec_name,width,height,avg_frame_rate,channels,sample_rate:format=duration -of compact "$OUT"
echo "wrote $OUT (work dir $WORK)"
