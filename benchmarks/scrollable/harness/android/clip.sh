#!/bin/bash
# Records a short clip of one app scrolling one screen, to show what the
# numbers look like: 10 s of Legend List's own autoscroll after a warm-up
# run, recorded with the phone's own screen recorder, with the bar title
# naming the framework and the list. A clip is a recorded run
# (run.sh --record), never a timed one: the recorder itself uses the device.
#
# Usage:
#   ANDROID_SERIAL=<device> ./clip.sh <app> <screen> <out.mp4>
#
#   app     dartnative | kotlin | legendlist | flashlist | flatlist
#   screen  cards | chat
#
# The DartNative and Kotlin apps open on the screen they were built for, so
# the build for that screen must be installed (see run.sh). The clip is cut
# to the 10 s of scrolling and encoded for sharing: H.264, 60 fps, 720 x 1600.
set -euo pipefail

APP=${1:?app}; SCREEN=${2:?screen}; OUT=${3:?out.mp4}
HERE="$(cd "$(dirname "$0")" && pwd)"
CLIP_S=${CLIP_S:-10}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SCROLL_MS=$((CLIP_S * 1000)) "$HERE/run.sh" "$APP" "$SCREEN" 1 "$TMP" --record | tail -1
# run.sh starts the recorder a second before the scroll, which goes the
# screen's own way: down, or up through the Chat screen's history.
ffmpeg -loglevel error -y -ss 1 -i "$TMP/run1.mp4" -t "$CLIP_S" \
  -vf "scale=720:-2,fps=60" -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
  -movflags +faststart -an "$OUT"
echo "$OUT: $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT") s"
