#!/bin/bash
# Renders the Plumaje marketing art (app-store-presence) from design/marketing/*.html
# into fastlane/marketing/media/ as flattened sRGB PNGs (no alpha).
# Usage: tools/render_marketing.sh [CAPTURES_DIR]   (default fastlane/screenshots_raw/ru;
#        files named "Lorito iPhone-<scene>.png")
set -euo pipefail
cd "$(dirname "$0")/.."
CAP="$(cd "${1:-fastlane/screenshots_raw/ru}" && pwd)"
SRC="$PWD/design/marketing"
OUT="fastlane/marketing/media"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
mkdir -p "$OUT"
# name  width  height
while read -r name w h; do
  [ -z "$name" ] && continue
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=4000 --window-size="$w,$h" \
    --screenshot="$TMP/$name.png" "file://$SRC/$name.html?cap=$(python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "$CAP")" >/dev/null 2>&1
  magick "$TMP/$name.png" -crop "${w}x${h}+0+0" +repage -background '#0F1A14' -alpha remove -alpha off \
    -colorspace sRGB "PNG24:$OUT/$name.png"
  echo "$OUT/$name.png $(magick identify -format '%wx%h %[channels]' "$OUT/$name.png")"
done <<LIST
${ONLY:-header-ru 3840 1646
search-ru 3840 2560
event-card 3840 2160
event-details 2160 3840
featuring-4320x1080 4320 1080
today-3524x2160 3524 2160}
LIST
rm -rf "$TMP"
