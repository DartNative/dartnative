#!/bin/sh
# Renders banner.html into ../dartnative-banner-phones.png, the README's
# banner: 1280 x 600 at twice the scale (2560 x 1200). Needs Google Chrome.
# Run from anywhere: sh docs/assets/banner/render.sh
set -e
DIR=$(cd "$(dirname "$0")" && pwd)
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
PROFILE=$(mktemp -d)
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --no-first-run \
  --user-data-dir="$PROFILE" --force-device-scale-factor=2 \
  --window-size=1280,600 --virtual-time-budget=4000 \
  --screenshot="$DIR/../dartnative-banner-phones.png" "file://$DIR/banner.html"
rm -rf "$PROFILE"
echo "wrote $DIR/../dartnative-banner-phones.png"
