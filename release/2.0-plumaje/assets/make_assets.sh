#!/usr/bin/env bash
# Builds the Growth & Marketing images for Lorito 2.0 "Plumaje" from the
# fastlane screenshots and the bundled brand fonts. Requires ImageMagick 7.
# Usage: release/2.0-plumaje/assets/make_assets.sh   (from the repo root)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
OUT="$ROOT/release/2.0-plumaje/assets"
SHOTS="$ROOT/fastlane/screenshots/ru"
FONTS="$ROOT/Packages/LoritoKit/Sources/DesignSystem/Resources/Fonts"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Plumaje tokens (design/brand/tokens.json)
INK="#0F1A14"; INK_RAISED="#1C2A22"; PAPEL="#F3F4EF"; LORO="#0E7C47"; LIMA="#CBEF6B"; CHILE="#E5482A"
UNBOUNDED="$FONTS/Unbounded-ExtraBold.ttf"

# phone <screenshot> <height> <out>: scale, round the corners, add a soft shadow.
phone() {
  local src="$1" h="$2" out="$3"
  magick "$src" -resize "x$h" "$TMP/p.png"
  local w; w=$(magick identify -format "%w" "$TMP/p.png")
  local r=$(( h / 16 ))
  magick -size "${w}x${h}" xc:none -fill white -draw "roundrectangle 0,0,$((w-1)),$((h-1)),$r,$r" "$TMP/mask.png"
  magick "$TMP/p.png" "$TMP/mask.png" -alpha off -compose CopyOpacity -composite "$TMP/r.png"
  magick "$TMP/r.png" \( +clone -background black -shadow 40x40+0+30 \) +swap -background none -layers merge +repage "$out"
}

IP="$SHOTS/Lorito iPhone"
phone "$IP-05Recall.png" 1300 "$TMP/recall_l.png"
phone "$IP-05Study.png"  1300 "$TMP/study_l.png"
phone "$IP-04Today.png"  1300 "$TMP/today_l.png"
phone "$IP-07Progress.png" 1300 "$TMP/progress_l.png"
phone "$IP-05Recall.png" 1000 "$TMP/recall_m.png"
phone "$IP-04Today.png"  1000 "$TMP/today_m.png"
phone "$IP-07Progress.png" 1000 "$TMP/progress_m.png"
phone "$IP-05Study.png"  1000 "$TMP/study_m.png"
phone "$IP-05Recall.png" 1500 "$TMP/recall_xl.png"
phone "$IP-07Progress.png" 1500 "$TMP/progress_xl.png"

# 1. Asset Library — product page header, 21:9, 3840x1646 (short phrase allowed).
magick -size 3840x1646 "xc:$INK" \
  -font "$UNBOUNDED" -fill "$INK_RAISED" -pointsize 1500 -gravity center -annotate +250-60 "¿" \
  -gravity west -fill "$LIMA" -pointsize 118 -annotate +460-130 "Сначала вспомни —" \
  -fill "$PAPEL" -annotate +460+20 "потом смотри" \
  -font "$FONTS/InstrumentSerif-Italic.ttf" -fill "$LIMA" -pointsize 96 -annotate +460+210 "el problema, la mano, el agua" \
  \( "$TMP/recall_l.png" \) -gravity east -geometry +1120+60 -composite \
  \( "$TMP/study_l.png" \) -gravity east -geometry +460+60 -composite \
  -alpha off "$OUT/asset-library-header-21x9-3840x1646.png"

# 2. Asset Library — search result, 3:2, 1920x1280: the real interface, no text.
magick -size 1920x1280 "xc:$PAPEL" \
  \( "$TMP/today_m.png" -resize x1100 \) -gravity center -geometry -600+20 -composite \
  \( "$TMP/recall_m.png" -resize x1150 \) -gravity center -geometry +0+0 -composite \
  \( "$TMP/progress_m.png" -resize x1100 \) -gravity center -geometry +600+20 -composite \
  -alpha off "$OUT/asset-library-search-3x2-1920x1280.png"

# 3. In-app event "Lorito 2.0" — card 16:9 1920x1080 + details 9:16 1080x1920. No text or logos.
magick -size 1920x1080 "xc:$INK" \
  -fill "$LORO" -draw "circle 1500,180 1500,620" -fill "$LIMA" -draw "circle 300,980 300,1180" \
  \( "$TMP/today_m.png" -resize x900 \) -gravity center -geometry -480+60 -composite \
  \( "$TMP/study_m.png" -resize x900 \) -gravity center -geometry +480+60 -composite \
  \( "$TMP/recall_m.png" -resize x980 \) -gravity center -geometry +0+40 -composite \
  -alpha off "$OUT/event-2-0-card-16x9-1920x1080.png"
magick -size 1080x1920 "xc:$INK" \
  -fill "$LORO" -draw "circle 900,300 900,760" -fill "$LIMA" -draw "circle 160,1700 160,1900" \
  \( "$TMP/recall_xl.png" \) -gravity center -geometry +0+60 -composite \
  -alpha off "$OUT/event-2-0-details-9x16-1080x1920.png"

# 4. In-app event "7 дней подряд" — streak challenge on Chile. No text or logos.
magick -size 1920x1080 "xc:$CHILE" \
  -fill "$INK" -draw "circle 1650,950 1650,1450" -fill "$LIMA" -draw "circle 260,160 260,420" \
  \( "$TMP/progress_m.png" -resize x980 \) -gravity center -geometry +0+40 -composite \
  -alpha off "$OUT/event-streak-card-16x9-1920x1080.png"
magick -size 1080x1920 "xc:$CHILE" \
  -fill "$INK" -draw "circle 900,1750 900,2200" -fill "$LIMA" -draw "circle 160,240 160,480" \
  \( "$TMP/progress_xl.png" \) -gravity center -geometry +0+40 -composite \
  -alpha off "$OUT/event-streak-details-9x16-1080x1920.png"

for f in "$OUT"/*.png; do
  printf '%-48s %s\n' "$(basename "$f")" "$(magick identify -format '%wx%h %[channels]' "$f")"
done
