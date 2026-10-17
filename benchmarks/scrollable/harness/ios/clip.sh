#!/bin/bash
# Records a short clip of one app scrolling one screen on a connected
# iPhone, to show what the numbers look like. The screen is recorded over
# the cable (capture.swift) while the UI test swipes the app; the ten
# seconds with the most movement (the swipes) are then cut out and encoded
# for sharing as H.264, 60 fps, 720 pixels wide. A clip is never a measured
# run, because the recording itself uses the phone.
#
# Usage:
#   DEVELOPMENT_TEAM=<team id> ./clip.sh <app> <screen> <device-udid> <out.mp4>
#
# The app must be installed for that screen, as for run.sh.
set -euo pipefail
APP=${1:?app}; SCREEN=${2:?screen}; UDID=${3:?device udid}; OUT=${4:?out.mp4}
HERE="$(cd "$(dirname "$0")" && pwd)"
CLIP_S=${CLIP_S:-10}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Long enough for the test to build, launch the app and swipe.
swift "$HERE/capture.swift" 90 "$TMP/screen.mov" iPhone > "$TMP/capture.log" 2>&1 &
CAPTURE=$!
sleep 5
SWIPES=14 ITERATIONS=1 "$HERE/run.sh" "$APP" "$SCREEN" "$UDID" "$TMP/run" > "$TMP/run.log" 2>&1 || true
wait "$CAPTURE" || { cat "$TMP/capture.log"; exit 1; }
START=$(python3 "$HERE/motion_window.py" "$TMP/screen.mov" "$CLIP_S")
ffmpeg -loglevel error -y -ss "$START" -i "$TMP/screen.mov" -t "$CLIP_S" \
  -vf "scale=720:-2,fps=60" -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
  -movflags +faststart -an "$OUT"
echo "$OUT: from $START s of the recording, $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT") s"
