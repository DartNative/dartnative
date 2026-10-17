#!/bin/bash
# Scrolls one app with Legend List's own autoscroll script and records what
# Android measured: the frame statistics of `dumpsys gfxinfo` and the memory
# of `dumpsys meminfo`. Optionally records the screen instead, for the
# blank-space count (blank_area.py), or reads the app's memory once a second
# through the scroll and once more after it, for its peak and its rest; a
# recorded or a sampled run is never a timed run, because the recorder, and
# the reading, use the device.
#
# Usage:
#   ANDROID_SERIAL=<device> ./run.sh <app> <screen> <runs> <out-dir> [--record | --peak]
#
#   app     dartnative | kotlin | legendlist | flashlist | flatlist
#   screen  cards | chat
#
# Every app opens on the screen it was built for: the DartNative app with
# `--dart-define=BENCH_SCREEN=chat`, the Kotlin app with `-PbenchScreen=chat`,
# each React Native one with `react_native/setup.sh android <screen> <list>`.
# The Chat screen opens at its newest message, at the bottom, and is
# scrolled up through its history.
#
# Each batch starts with one warm-up run that is not recorded, so the 20
# avatars are in each app's disk cache; every measured run then starts from a
# stopped app.
set -euo pipefail

APP=${1:?app}; SCREEN=${2:?screen}; RUNS=${3:?runs}; OUT=${4:?out-dir}; MODE=${5:-}
HERE="$(cd "$(dirname "$0")" && pwd)"
LEGEND_DIR=${LEGEND_DIR:-"$HERE/../../react_native/.work/legend-list"}
AUTOSCROLL="$LEGEND_DIR/example/autoscroll.sh"
SCROLL_MS=${SCROLL_MS:-20000}
SPEED=${SPEED:-1}
# The Cards screen is the benchmark's advanced mode in every app: twice the
# text per card and a horizontal list of ten images inside each. In the
# React Native app it is one of the routes this benchmark adds
# (react_native/advanced).
# DIRECTION=both scrolls down for SCROLL_MS, then back up for as long, with
# the same gesture reversed (autoscroll_up.sh), inside one measured run;
# DIRECTION=up scrolls up only, the Chat screen's default.
if [ "$SCREEN" = chat ]; then DIRECTION=${DIRECTION:-up}; else DIRECTION=${DIRECTION:-down}; fi
AUTOSCROLL_UP="$HERE/autoscroll_up.sh"
: "${ANDROID_SERIAL:?set ANDROID_SERIAL to the device id from adb devices}"
export ANDROID_SERIAL

[ -x "$AUTOSCROLL" ] || chmod +x "$AUTOSCROLL"

# Each screen of each app is an app of its own, opened straight on that
# screen (../apps.sh): it is launched by its package, with nothing to open.
. "$HERE/../apps.sh"
PKG=$(app_id "$APP" "$SCREEN") || exit 1
launch() { adb shell am start -W -n "$PKG/$(app_activity "$APP")" >/dev/null; }

mkdir -p "$OUT"
{
  echo "app=$APP screen=$SCREEN runs=$RUNS mode=${MODE:-timed} scroll_ms=$SCROLL_MS speed=$SPEED direction=$DIRECTION"
  echo "device=$(adb shell getprop ro.product.model | tr -d '\r') android=$(adb shell getprop ro.build.version.release | tr -d '\r')"
  echo "package=$PKG version=$(adb shell dumpsys package "$PKG" | grep -m1 versionName | tr -d ' \r')"
  echo "autoscroll=$(shasum -a 256 "$AUTOSCROLL" | cut -c1-16) (Legend List's example/autoscroll.sh)"
} > "$OUT/run_info.txt"

# One `dumpsys meminfo -s` reading a second, until stopped: the app computes
# its own total on a binder thread, which is why a sampled run is not timed.
sample_memory() { # $1 = file
  while :; do
    adb shell dumpsys meminfo -s "$PKG" | grep -m1 "TOTAL PSS" | tr -d '\r'
    sleep 1
  done > "$1"
}

one_run() { # $1 = label
  adb shell am force-stop "$PKG"
  sleep 1
  launch
  sleep 5
  adb shell dumpsys gfxinfo "$PKG" reset >/dev/null
  local rec_pid="" sampler=""
  if [ "$MODE" = "--record" ] && [ "$1" != "warmup" ]; then
    adb shell screenrecord --bit-rate 20000000 "/sdcard/bench_$1.mp4" &
    rec_pid=$!
    sleep 1
  elif [ "$MODE" = "--peak" ] && [ "$1" != "warmup" ]; then
    sample_memory "$OUT/$1_peak.txt" &
    sampler=$!
  fi
  if [ "$DIRECTION" = up ]; then
    "$AUTOSCROLL_UP" "$SPEED" "$SCROLL_MS" >/dev/null
  else
    "$AUTOSCROLL" "$SPEED" "$SCROLL_MS" >/dev/null
  fi
  if [ "$DIRECTION" = both ]; then
    sleep 1
    "$AUTOSCROLL_UP" "$SPEED" "$SCROLL_MS" >/dev/null
  fi
  sleep 2
  if [ -n "$rec_pid" ]; then
    adb shell pkill -INT screenrecord || true
    wait "$rec_pid" 2>/dev/null || true
    sleep 2
    adb pull "/sdcard/bench_$1.mp4" "$OUT/$1.mp4" >/dev/null
    adb shell rm "/sdcard/bench_$1.mp4"
  elif [ -n "$sampler" ]; then
    kill "$sampler" 2>/dev/null || true
    wait "$sampler" 2>/dev/null || true
    adb shell dumpsys meminfo "$PKG" > "$OUT/$1_meminfo.txt"
  elif [ "$1" != "warmup" ]; then
    adb shell dumpsys gfxinfo "$PKG" > "$OUT/$1_gfxinfo.txt"
    adb shell dumpsys meminfo "$PKG" > "$OUT/$1_meminfo.txt"
  fi
}

one_run warmup
for i in $(seq 1 "$RUNS"); do
  one_run "run$i"
  echo "$APP $SCREEN run $i of $RUNS done"
done
adb shell am force-stop "$PKG"
