#!/bin/bash
# Measures blank rows under a real finger: the UI-test runner flicks the
# list with real touches (ScrollRunnerUITests testFlicks) while the app,
# launched in the driver's watch mode, counts blank rows in every frame the
# list moves (BENCH_WATCH, autoscroll/BenchAutoScroll.m). A list that
# prepares its rows on another thread can keep up with the driver's own
# flings and still fall behind a finger's; this run shows that. Nothing is
# timed here: XCTest's accessibility snapshots around each gesture make a
# UITableView build every row.
#
# Usage:
#   DEVELOPMENT_TEAM=<team id> ./flick.sh <app> <screen> <device-udid> <out-dir>
#
#   app, screen, SWIPES, DIRECTION: as in trace.sh
#   SPEED=<points/s> the finger's speed at release (4,000 by default)
#   PAUSE=<s> seconds between flicks (2.5 by default, which lets the list
#   settle; 0.3 is a finger that keeps flicking while the list moves)
#
# Writes <out-dir>/<app>_<screen>_flick_blank.txt: the driver's count (the
# mean, the worst frame, the frames more than half blank, the blank time
# per second the list moved).
set -euo pipefail

APP=${1:?app}; SCREEN=${2:?screen}; UDID=${3:?device udid}; OUT=${4:?out-dir}
HERE="$(cd "$(dirname "$0")" && pwd)"
: "${DEVELOPMENT_TEAM:?set DEVELOPMENT_TEAM to your Apple team id}"
. "$HERE/../apps.sh"
BUNDLE=$(app_id "$APP" "$SCREEN") || exit 1

[ "$SCREEN" = chat ] && DIRECTION=${DIRECTION:-down}
cd "$HERE"
[ -d ScrollRunner.xcodeproj ] || xcodegen generate --quiet
mkdir -p "$OUT"
RESULT="$OUT/${APP}_${SCREEN}_flick.xcresult"
rm -rf "$RESULT"

TEST_RUNNER_BENCH_BUNDLE="$BUNDLE" \
TEST_RUNNER_BENCH_SWIPES="${SWIPES:-25}" \
TEST_RUNNER_BENCH_DIRECTION="${DIRECTION:-up}" \
TEST_RUNNER_BENCH_SPEED="${SPEED:-4000}" \
TEST_RUNNER_BENCH_PAUSE="${PAUSE:-2.5}" \
xcodebuild test \
  -project ScrollRunner.xcodeproj -scheme ScrollRunner \
  -destination "id=$UDID" \
  -only-testing:ScrollRunnerUITests/ScrollBenchmarkTests/testFlicks \
  -allowProvisioningUpdates \
  -resultBundlePath "$RESULT" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" 2>&1 | grep -E "Test Case|error|failed|passed" | tail -5

rm -f "$OUT/${APP}_${SCREEN}_flick_blank.txt"
xcrun devicectl device copy from --device "$UDID" --domain-type appDataContainer --domain-identifier "$BUNDLE" \
  --source Documents/bench_blank.txt --destination "$OUT/${APP}_${SCREEN}_flick_blank.txt" >/dev/null 2>&1 \
  || { echo "no blank count (the driver never found the list, or the app was not built with it)"; exit 1; }
cat "$OUT/${APP}_${SCREEN}_flick_blank.txt"
