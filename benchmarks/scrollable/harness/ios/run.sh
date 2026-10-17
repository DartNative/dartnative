#!/bin/bash
# Scrolls one app on a connected iPhone through the UI-test runner and saves
# the result bundle with Apple's scroll metric.
#
# Usage:
#   DEVELOPMENT_TEAM=<team id> ./run.sh <app> <screen> <device-udid> <out-dir>
#
#   app     dartnative | uikit | legendlist | flashlist | flatlist
#   screen  cards | chat
#   The Cards screen is the benchmark's advanced mode in every app (in the
#   React Native app, the routes this benchmark adds, such as
#   cards-advanced); DIRECTION=both swipes back down for as many swipes
#   afterwards. The Chat screen opens at its newest message and is swiped
#   down only, through its history.
#
# The app for that screen must be installed on the iPhone in release mode
# first: DartNative's with `dn run --release` (dartnative/README.md has the
# iOS id), the UIKit one with native/ios/build.sh, each React Native one with
# react_native/setup.sh ios <screen> <list>.
set -euo pipefail

APP=${1:?app}; SCREEN=${2:?screen}; UDID=${3:?device udid}; OUT=${4:?out-dir}
HERE="$(cd "$(dirname "$0")" && pwd)"
: "${DEVELOPMENT_TEAM:?set DEVELOPMENT_TEAM to your Apple team id}"

# Each screen of each app is an app of its own, opened straight on that
# screen (../apps.sh).
. "$HERE/../apps.sh"
BUNDLE=$(app_id "$APP" "$SCREEN") || exit 1

[ "$SCREEN" = chat ] && DIRECTION=${DIRECTION:-down}
cd "$HERE"
[ -d ScrollRunner.xcodeproj ] || xcodegen generate --quiet
mkdir -p "$OUT"
SUFFIX=""; [ "${DIRECTION:-up}" = both ] && SUFFIX="_both"
RESULT="$OUT/${APP}_${SCREEN}${SUFFIX}.xcresult"
rm -rf "$RESULT"

TEST_RUNNER_BENCH_BUNDLE="$BUNDLE" \
TEST_RUNNER_BENCH_SWIPES="${SWIPES:-25}" \
TEST_RUNNER_BENCH_ITERATIONS="${ITERATIONS:-5}" \
TEST_RUNNER_BENCH_DIRECTION="${DIRECTION:-up}" \
xcodebuild test \
  -project ScrollRunner.xcodeproj -scheme ScrollRunner \
  -destination "id=$UDID" \
  -only-testing:ScrollRunnerUITests/ScrollBenchmarkTests/testScroll \
  -allowProvisioningUpdates \
  -resultBundlePath "$RESULT" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" | tail -20

xcrun xcresulttool get test-results metrics --path "$RESULT" > "$OUT/${APP}_${SCREEN}${SUFFIX}_metrics.json"
echo "metrics: $OUT/${APP}_${SCREEN}${SUFFIX}_metrics.json"
