"""Reads a Perfetto trace made by trace.sh: how long the app's frames took
and what the long ones were doing.

  python3 trace_frames.py <trace> <package> [--budget-ms 11.1]

Needs the `perfetto` package (pip install perfetto).
"""
import argparse
import re
from collections import Counter

from perfetto.trace_processor import TraceProcessor

ap = argparse.ArgumentParser()
ap.add_argument("trace")
ap.add_argument("package")
ap.add_argument("--budget-ms", type=float, default=11.1)
args = ap.parse_args()

tp = TraceProcessor(trace=args.trace)
upid = [r.upid for r in tp.query(f"select upid from process where name = '{args.package}'")]
if not upid:
    raise SystemExit(f"no process named {args.package} in the trace")
upid = upid[0]
main = [r.utid for r in tp.query(f"select utid from thread where upid = {upid} and is_main_thread = 1")][0]
track = [r.id for r in tp.query(f"select id from thread_track where utid = {main}")][0]


def pct(sorted_values, p):
    return sorted_values[min(len(sorted_values) - 1, int(p * len(sorted_values)))]


# Frames from SurfaceFlinger's frame timeline, when the trace has it, then
# the main thread's doFrame sections.
frames = [(r.ts, r.dur, r.jank_type) for r in tp.query(f"""
select ts, dur, jank_type from actual_frame_timeline_slice where upid = {upid} and layer_name is not null order by ts""")]
if frames:
    durs = sorted(d / 1e6 for _, d, _ in frames)
    print(f"frames (SurfaceFlinger timeline): {len(durs)}  ms p50 {pct(durs, .5):.1f}  p90 {pct(durs, .9):.1f}  p99 {pct(durs, .99):.1f}  max {durs[-1]:.1f}")
    print("  jank types:", dict(Counter(j for _, _, j in frames).most_common(6)))

do = [(r.id, r.ts, r.dur) for r in tp.query(f"""
select id, ts, dur from slice where track_id = {track} and name like 'Choreographer#doFrame%' order by ts""")]
ddurs = sorted(d / 1e6 for _, _, d in do)
if ddurs:
    print(f"doFrame on the main thread: {len(ddurs)}  ms p50 {pct(ddurs, .5):.1f}  p90 {pct(ddurs, .9):.1f}  p99 {pct(ddurs, .99):.1f}  max {ddurs[-1]:.1f}")

# Main-thread busy stretches: what held the thread longer than the budget.
running = [(r.ts, r.dur) for r in tp.query(f"select ts, dur from thread_state where utid = {main} and state = 'Running' order by ts")]
stretches = []
for ts, dur in running:
    if stretches and ts - stretches[-1][1] < 300_000:
        stretches[-1][1] = max(stretches[-1][1], ts + dur)
    else:
        stretches.append([ts, ts + dur])
top = [(r.ts, r.ts + r.dur, r.name) for r in tp.query(f"select ts, dur, name from slice where track_id = {track} and depth = 0")]
long = [(a, b) for a, b in stretches if (b - a) / 1e6 > args.budget_ms]
print(f"\nmain thread busy for more than {args.budget_ms} ms at a stretch: {len(long)} times")
for a, b in sorted(long, key=lambda x: x[0] - x[1])[:10]:
    names = Counter()
    for s, e, n in top:
        if s < b and e > a:
            key = re.sub(r"[ #]-?\d.*$", "", n)
            names[key] += (min(e, b) - max(s, a)) / 1e6
    parts = ", ".join(f"{n} {ms:.1f}" for n, ms in names.most_common(5))
    print(f"  {(b - a) / 1e6:6.1f} ms: {parts}")

busy = sum(b - a for a, b in stretches) / 1e6
print(f"\nmain thread busy {busy:.0f} ms over the recording")
