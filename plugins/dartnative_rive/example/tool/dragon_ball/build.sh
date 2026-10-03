#!/bin/sh
# build.sh [trace.svg]: writes example/assets/rive/marketplace/dragon_ball.riv,
# the Dragon Ball screen's file, from the traced SVG (goku_vegeta.svg beside
# this script when none is named). The SVG traces an image generated with
# Craiyon: https://www.craiyon.com/fr/image/ngkUyMYoSyKO_gBOI_zQ6Q. The file
# embeds dragonball_sound_4s.mp3, beside it in assets/rive/marketplace/: the
# sound dragonball_sound.mp3 from its fourth second on, cut once with
#   ffmpeg -ss 4 -i dragonball_sound.mp3 -map 0:a -map_metadata -1 \
#     -af afade=t=in:d=0.02 -c:a libmp3lame -b:a 128k dragonball_sound_4s.mp3
#
# Rive's own tools make a .riv in its editor. This writes the runtime format
# directly instead (rivwriter.py), from the SVG's paths (svgparse.py), with
# the few things that move added by build_anime.py. It needs Python 3 and
# Chrome, which draws the SVG once so stones.py can find the stones in it.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
SVG=${1:-$HERE/goku_vegeta.svg}
SVG=$(cd "$(dirname "$SVG")" && pwd)/$(basename "$SVG")
OUT=$HERE/../../assets/rive/marketplace/dragon_ball.riv
SOUND=$HERE/../../assets/rive/marketplace/dragonball_sound_4s.mp3
CHROME=${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
printf '<html><body style="margin:0;background:#ff00ff"><img src="file://%s" width="1024" height="1024"></body></html>' "$SVG" > "$TMP/trace.html"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --window-size=1024,1024 \
  --screenshot="$TMP/trace.png" "file://$TMP/trace.html" >/dev/null 2>&1
python3 "$HERE/build_anime.py" "$SVG" "$TMP/trace.png" "$OUT" "$SOUND"
