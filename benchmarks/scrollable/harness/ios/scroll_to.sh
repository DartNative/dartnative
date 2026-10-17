#!/bin/bash
# The scroll-to test on the iPhone: where each list lands when told to
# scroll far, past items it has never measured.
#
# Usage:
#   DEVELOPMENT_TEAM=<team id> ./scroll_to.sh <app> <device-udid> <out-dir> [chat|cards]
#
#   app  dartnative | uikit | legendlist | flashlist | flatlist
#
# Chat (the default; the DartNative and UIKit apps built for that screen):
# the app opens on its thread, at the newest message, and the Scroll button
# in its bar is tapped once for each of the apps' target messages, going up
# the history: 996, 600, 598, 300 and 0 (the oldest). Cards: the app opens
# on the Cards screen (the benchmark's advanced mode) and the button is
# tapped once for each of the apps' target cards, going down the list:
# 1, 400, 402, 700 and 950. Each target is asked to rest with its top at
# the top of the list. Once the screen stops moving, the UI test
# (testScrollTo) reads where the target's top rests. The first scroll lands
# among rows every list has already measured, so it calibrates that place;
# every later landing is reported as its distance from it, in points. A
# positive distance means the target is lower than asked and the item
# before it shows above it; a negative one means it is higher and its top
# is cut off. A target not on screen at all is a miss.
# <app>_<screen>_scroll.json and a screenshot of each landing go to
# <out-dir>.
set -euo pipefail

APP=${1:?app}; UDID=${2:?device udid}; OUT=${3:?out-dir}; SCREEN=${4:-chat}; MODE=scroll
HERE="$(cd "$(dirname "$0")" && pwd)"
: "${DEVELOPMENT_TEAM:?set DEVELOPMENT_TEAM to your Apple team id}"

case "$SCREEN" in
  chat) TARGETS="996 600 598 300 0" ;;
  cards) TARGETS="1 400 402 700 950" ;;
  *) echo "unknown screen: $SCREEN"; exit 1 ;;
esac
# Each screen of each app is an app of its own, opened straight on that
# screen (../apps.sh).
. "$HERE/../apps.sh"
BUNDLE=$(app_id "$APP" "$SCREEN") || exit 1

if [ "$SCREEN" = chat ]; then
  SPEC=$(python3 - "$HERE/../../assets/chat.json" $TARGETS <<'PY'
import json, sys
messages = json.load(open(sys.argv[1]))
print(";".join(f"{messages[int(n)]['timestampLabel']}|{messages[int(n)]['senderName']}" for n in sys.argv[2:]))
PY
)
else
  SPEC=$(for n in $TARGETS; do printf 'Item #%s;' "$n"; done); SPEC=${SPEC%;}
fi

cd "$HERE"
[ -d ScrollRunner.xcodeproj ] || xcodegen generate --quiet
mkdir -p "$OUT"
RESULT="$OUT/${APP}_${SCREEN}_${MODE}.xcresult"
rm -rf "$RESULT" "$OUT/${APP}_${SCREEN}_${MODE}"
TEST_RUNNER_BENCH_BUNDLE="$BUNDLE" \
TEST_RUNNER_BENCH_SCROLL_TARGETS="$SPEC" \
xcodebuild test \
  -project ScrollRunner.xcodeproj -scheme ScrollRunner \
  -destination "id=$UDID" \
  -only-testing:ScrollRunnerUITests/ScrollBenchmarkTests/testScrollTo \
  -allowProvisioningUpdates \
  -resultBundlePath "$RESULT" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" | grep -E "TEST (SUCC|FAIL)|error:" || true

xcrun xcresulttool export attachments --path "$RESULT" --output-path "$OUT/${APP}_${SCREEN}_${MODE}" >/dev/null
python3 - "$OUT/${APP}_${SCREEN}_${MODE}" "$OUT/${APP}_${SCREEN}_${MODE}.json" "$APP" "$SCREEN" $TARGETS <<'PY'
import json, os, sys
folder, out, app, screen = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
targets = [int(n) for n in sys.argv[5:]]
item = "message" if screen == "chat" else "card"
manifest = json.load(open(os.path.join(folder, "manifest.json")))
files = [a for t in manifest for a in t.get("attachments", [])]
report = next(a for a in files if a.get("suggestedHumanReadableName", "").startswith("scroll-results"))
rows = [line.split("\t") for line in open(os.path.join(folder, report["exportedFileName"])).read().splitlines()]
calibration = None if rows[0][2] == "none" else float(rows[0][2])
landings = []
for (n, _, top, settled), target in zip(rows, targets):
    top = None if top == "none" else float(top)
    error = None if top is None or calibration is None or n == "0" else round(top - calibration, 1)
    landings.append({item: target, "top_pt": top, "error_pt": error,
                     "settled_s": None if settled == "none" else float(settled)})
    print(f"  scroll to {item} {target}: top at {top} pt, error {error} pt, settled in {landings[-1]['settled_s']} s")
json.dump({"app": app, "screen": screen, "landings": landings}, open(out, "w"), indent=2)
PY
