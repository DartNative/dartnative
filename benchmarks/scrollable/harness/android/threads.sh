#!/bin/bash
# Scrolls one app as run.sh does and records each of its threads' processor
# time: every thread's /proc stat, read just before the scroll and just
# after it, and the scroll's start and end. threads.py turns the readings
# into processor time per second of scrolling, the main thread, the thread
# that draws and every other thread.
#
# Usage:
#   ANDROID_SERIAL=<device> ./threads.sh <app> <screen> <out-dir>
#
#   app     dartnative | kotlin | legendlist | flashlist | flatlist
#   screen  cards | chat
#
# One run, from a stopped app; the Cards screen is scrolled down and back
# up, the Chat screen up through its history, 20 s each way.
set -euo pipefail

APP=${1:?app}; SCREEN=${2:?screen}; OUT=${3:?out-dir}
HERE="$(cd "$(dirname "$0")" && pwd)"
LEGEND_DIR=${LEGEND_DIR:-"$HERE/../../react_native/.work/legend-list"}
AUTOSCROLL="$LEGEND_DIR/example/autoscroll.sh"
AUTOSCROLL_UP="$HERE/autoscroll_up.sh"
SCROLL_MS=${SCROLL_MS:-20000}
: "${ANDROID_SERIAL:?set ANDROID_SERIAL to the device id from adb devices}"
export ANDROID_SERIAL

. "$HERE/../apps.sh"
PKG=$(app_id "$APP" "$SCREEN") || exit 1

# Every thread of the process: its id and its /proc stat line.
threads() { # $1 = pid
  adb shell "for t in /proc/$1/task/*; do echo \"\${t##*/} \$(cat \$t/stat 2>/dev/null)\"; done" | tr -d '\r'
}
now() { python3 -c 'import time; print(time.time())'; }

mkdir -p "$OUT"
adb shell am force-stop "$PKG"
sleep 1
adb shell am start -W -n "$PKG/$(app_activity "$APP")" >/dev/null
sleep 5
PID=$(adb shell pidof "$PKG" | tr -d '\r')
threads "$PID" > "$OUT/${APP}_${SCREEN}_before.txt"
START=$(now)
if [ "$SCREEN" = chat ]; then
  "$AUTOSCROLL_UP" 1 "$SCROLL_MS" >/dev/null
else
  "$AUTOSCROLL" 1 "$SCROLL_MS" >/dev/null
  sleep 1
  "$AUTOSCROLL_UP" 1 "$SCROLL_MS" >/dev/null
fi
END=$(now)
threads "$PID" > "$OUT/${APP}_${SCREEN}_after.txt"
echo "pid=$PID start=$START end=$END hz=$(adb shell getconf CLK_TCK | tr -d '\r')" > "$OUT/${APP}_${SCREEN}_run.txt"
adb shell am force-stop "$PKG"
echo "$APP $SCREEN done"
