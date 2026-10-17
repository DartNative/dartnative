#!/bin/bash
# Measures blank space on the iPhone: the share of the list's visible area
# that no drawn view covers, frame by frame during the flings. The driver
# counts it (BENCH_BLANK, autoscroll/BenchAutoScroll.m) in a run of its
# own, because the count costs the main thread about a millisecond a
# frame: a blank run is never a timed run, just as a recorded run never is
# on Android.
#
# Usage:
#   ./blank.sh <app> <screen> <device-udid> <out-dir>
#
#   app, screen, SWIPES, DIRECTION, SPEED, UNIFORM, SETTLE: as in trace.sh
#   BLANK=2: the driver also writes the list's view tree for the first
#   frames that are more than a tenth blank, to check the count against
#
# Writes <out-dir>/<app>_<screen>_blank.txt: the mean over the frames and
# the worst frame.
set -euo pipefail

APP=${1:?app}; SCREEN=${2:?screen}; UDID=${3:?device udid}; OUT=${4:?out-dir}
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../apps.sh"
BUNDLE=$(app_id "$APP" "$SCREEN") || exit 1

[ "$SCREEN" = chat ] && DIRECTION=${DIRECTION:-down}
DIRECTION=${DIRECTION:-up}; SWIPES=${SWIPES:-25}; SETTLE=${SETTLE:-8}
mkdir -p "$OUT"

ENV=$(printf '{"BENCH_AUTOSCROLL":"%s","BENCH_DIRECTION":"%s","BENCH_BLANK":"%s"%s%s}' "$SWIPES" "$DIRECTION" "${BLANK:-1}" "${SPEED:+,\"BENCH_SPEED\":\"$SPEED\"}" "${UNIFORM:+,\"BENCH_UNIFORM\":\"$UNIFORM\"}")
xcrun devicectl device process launch --terminate-existing --environment-variables "$ENV" \
  --json-output "$OUT/blank_launch.json" --device "$UDID" "$BUNDLE" >/dev/null

# Wait for the launch and the first screen, the flings, and the last fling
# to slow to a stop.
FLINGS=$SWIPES; [ "$DIRECTION" = both ] && FLINGS=$((2 * SWIPES))
WAIT=$((SETTLE + FLINGS * 5 / 2 + 6)); [ -n "${UNIFORM:-}" ] && WAIT=$((SETTLE + ${UNIFORM%.*} + 6))
sleep $WAIT
rm -f "$OUT/${APP}_${SCREEN}_blank.txt"
xcrun devicectl device copy from --device "$UDID" --domain-type appDataContainer --domain-identifier "$BUNDLE" \
  --source Documents/bench_blank.txt --destination "$OUT/${APP}_${SCREEN}_blank.txt" >/dev/null 2>&1 \
  || { echo "no blank count (the run ended before the driver wrote it)"; exit 1; }
cat "$OUT/${APP}_${SCREEN}_blank.txt"
