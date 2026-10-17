#!/bin/bash
# Records a Perfetto trace of one app while Legend List's autoscroll runs
# on it: the scheduler, the frame pipeline (gfx, view, input), the app's
# own trace sections and SurfaceFlinger's frame timeline. The trace opens in
# ui.perfetto.dev; `trace_frames.py` reads the long frames out of it.
#
#   ./trace.sh <app> <screen> <out.perfetto-trace> [scroll_ms]
#
# <app> and <screen> as in run.sh, which also describes ANDROID_SERIAL and
# LEGEND_DIR; as there, the Chat screen is scrolled up through its history
# (DIRECTION=up, its default).
set -euo pipefail

APP="${1:?app}"
SCREEN="${2:?screen}"
OUT="${3:?out.perfetto-trace}"
SCROLL_MS="${4:-${SCROLL_MS:-10000}}"
HERE="$(cd "$(dirname "$0")" && pwd)"
LEGEND_DIR=${LEGEND_DIR:-"$HERE/../../react_native/.work/legend-list"}
AUTOSCROLL="$LEGEND_DIR/example/autoscroll.sh"
if [ "$SCREEN" = chat ]; then DIRECTION=${DIRECTION:-up}; else DIRECTION=${DIRECTION:-down}; fi
[ "$DIRECTION" = up ] && AUTOSCROLL="$HERE/autoscroll_up.sh"
: "${ANDROID_SERIAL:?set ANDROID_SERIAL to the device id from adb devices}"
export ANDROID_SERIAL

# The same launch as run.sh, so the trace shows the same screen.
# Each screen of each app is an app of its own, opened straight on that
# screen (../apps.sh): it is launched by its package, with nothing to open.
. "$HERE/../apps.sh"
PKG=$(app_id "$APP" "$SCREEN") || exit 1
launch() { adb shell am start -W -n "$PKG/$(app_activity "$APP")" >/dev/null; }

CFG="$(mktemp)"
cat > "$CFG" <<EOF
buffers: { size_kb: 131072 fill_policy: RING_BUFFER }
data_sources: {
  config {
    name: "linux.ftrace"
    ftrace_config {
      ftrace_events: "sched/sched_switch"
      ftrace_events: "sched/sched_wakeup"
      ftrace_events: "sched/sched_waking"
      ftrace_events: "power/cpu_frequency"
      ftrace_events: "power/cpu_idle"
      atrace_categories: "gfx"
      atrace_categories: "view"
      atrace_categories: "input"
      atrace_categories: "sched"
      atrace_categories: "freq"
      atrace_categories: "dalvik"
      atrace_categories: "binder_driver"
      atrace_apps: "*"
    }
  }
}
data_sources: {
  config {
    name: "linux.process_stats"
    process_stats_config { scan_all_processes_on_start: true }
  }
}
data_sources: { config { name: "android.surfaceflinger.frametimeline" } }
duration_ms: $((SCROLL_MS + 5000))
EOF

adb shell am force-stop "$PKG" || true
launch
sleep 5
DEVICE_OUT=/data/misc/perfetto-traces/bench.perfetto-trace
adb shell perfetto -c - --txt -o "$DEVICE_OUT" < "$CFG" >/dev/null 2>&1 &
PERFETTO=$!
sleep 2
bash "$AUTOSCROLL" 1 "$SCROLL_MS" >/dev/null 2>&1 || true
wait $PERFETTO
adb pull "$DEVICE_OUT" "$OUT" >/dev/null
adb shell am force-stop "$PKG"
rm -f "$CFG"
echo "trace: $OUT ($(du -h "$OUT" | cut -f1))"
