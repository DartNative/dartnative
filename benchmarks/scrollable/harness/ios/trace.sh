#!/bin/bash
# Records one run of an app on a connected iPhone under Instruments (the
# os_signpost, Hitches, Display, Time Profiler and Activity Monitor
# instruments) and saves the trace. The app flings its own list: it is
# launched with BENCH_AUTOSCROLL, and the driver built into every app
# (autoscroll/BenchAutoScroll.m) makes 25 flings by default, one every
# 2.5 s, the same in every app. Nothing but the app runs on the phone while
# it scrolls. trace_summary.py then reads the trace inside the flings: the
# hitches and the frames shown, the share of the time the panel spent at
# each refresh rate, the app's CPU time (main thread and all threads) and
# its memory.
#
# Usage:
#   ./trace.sh <app> <screen> <device-udid> <out-dir>
#
#   app     dartnative | uikit | legendlist | flashlist | flatlist
#   screen  cards | chat | empty (nothing to scroll: no flings, only the
#           memory census)
#   SWIPES=<n> (environment) the number of flings, 25 by default
#   DIRECTION=both flings back down as many times afterwards; the Chat
#   screen is flung down, through its history
#   SPEED=<points/s> the finger's speed at release (4,000 by default, the
#   driver's own)
#   UNIFORM=<s> one steady scroll at SPEED for that many seconds instead of
#   the flings (one interval, read like a single fling)
#
# The recording launches the app itself (xctrace --launch, with the
# settings in its environment), so the trace holds the app from its first
# frame. The flings' times come from the driver's own file and are placed
# on the trace's time line through the one mark the driver makes at the
# end of the run (the device's log daemon may leave a process's signposts
# out of the first tens of seconds of a recording). Use the xctrace of the
# Xcode that built the apps (DEVELOPER_DIR): a newer Xcode's xctrace may
# not find the phone's processes.
set -euo pipefail

APP=${1:?app}; SCREEN=${2:?screen}; UDID=${3:?device udid}; OUT=${4:?out-dir}
HERE="$(cd "$(dirname "$0")" && pwd)"

# Each screen of each app is an app of its own, opened straight on that
# screen (../apps.sh).
. "$HERE/../apps.sh"
BUNDLE=$(app_id "$APP" "$SCREEN") || exit 1

[ "$SCREEN" = chat ] && DIRECTION=${DIRECTION:-down}
DIRECTION=${DIRECTION:-up}; SWIPES=${SWIPES:-25}
mkdir -p "$OUT"
TRACE="$OUT/${APP}_${SCREEN}.trace"
rm -rf "$TRACE"

# The recording's length: the app's launch and its list's first screen (8 s
# by default; SETTLE=<s> for an app that takes longer to show its list),
# one fling every 2.5 s with the last slowing to a stop, then the app at
# rest for the memory reading and the driver's census ten seconds after the
# last fling, plus the seconds the recording takes to launch the app.
SETTLE=${SETTLE:-8}
FLINGS=$SWIPES; [ "$DIRECTION" = both ] && FLINGS=$((2 * SWIPES))
LIMIT=$((SETTLE + FLINGS * 5 / 2 + 20))
[ -n "${UNIFORM:-}" ] && { SWIPES=1; LIMIT=$((SETTLE + ${UNIFORM%.*} + 20)); }
# The Empty screen has nothing to fling: the driver looks for a list for
# ten seconds from its first look and writes the census ten seconds after
# giving up, half a minute after the launch.
[ "$SCREEN" = empty ] && LIMIT=34

RECORD=(xcrun xctrace record --device "$UDID" --instrument os_signpost --instrument Hitches --instrument Display
  --instrument "Time Profiler" --instrument "Activity Monitor" --time-limit "${LIMIT}s" --output "$TRACE"
  --env "BENCH_AUTOSCROLL=$SWIPES" --env "BENCH_DIRECTION=$DIRECTION" ${SPEED:+--env "BENCH_SPEED=$SPEED"} ${UNIFORM:+--env "BENCH_UNIFORM=$UNIFORM"} --env BENCH_MEMORY=1 --launch -- "$BUNDLE")

# xctrace leaves its raw recording in the temporary folder, up to several
# GB a trace; the one this run makes is removed once the trace is saved.
TMP="${TMPDIR:-/tmp}"
KTRACES=$(ls "$TMP"/instruments*.ktrace 2>/dev/null || true)
"${RECORD[@]}" 2>&1 | grep -E "Recording|saved|rror|ailed" || true
for f in "$TMP"/instruments*.ktrace; do
  [ -e "$f" ] && ! grep -qxF "$f" <<<"$KTRACES" && rm -f "$f"
done
# Copy the two files the driver wrote into the app's documents: the
# flings' times, which trace_summary.py places on the trace's time line
# through the driver's sync mark, and what the app's memory was made of at
# the end of the run (BENCH_MEMORY).
rm -f "$OUT/${APP}_${SCREEN}_flings.txt" "$OUT/${APP}_${SCREEN}_memory.txt"
xcrun devicectl device copy from --device "$UDID" --domain-type appDataContainer --domain-identifier "$BUNDLE" \
  --source Documents/bench_flings.txt --destination "$OUT/${APP}_${SCREEN}_flings.txt" >/dev/null 2>&1 \
  || echo "no fling times (the run ended before the driver wrote them)"
xcrun devicectl device copy from --device "$UDID" --domain-type appDataContainer --domain-identifier "$BUNDLE" \
  --source Documents/bench_memory.txt --destination "$OUT/${APP}_${SCREEN}_memory.txt" >/dev/null 2>&1 \
  || echo "no memory census (the run ended before the driver wrote it)"
echo "trace: $TRACE"
