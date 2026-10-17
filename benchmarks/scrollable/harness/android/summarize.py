#!/usr/bin/env python3
"""Reads the `dumpsys gfxinfo` and `dumpsys meminfo` files that run.sh wrote,
and the memory readings of a sampled run, and prints, per batch folder, the
median and the range over the runs.

Usage: python3 summarize.py <batch-dir> [<batch-dir> ...]

Every number comes from Android's own counters for the app's window: the
same counters for any app, whatever draws it.
"""
import json
import re
import statistics
import sys
from pathlib import Path

GFX_FIELDS = {
    "frames": r"Total frames rendered: (\d+)",
    "janky_pct": r"Janky frames: \d+ \(([\d.]+)%\)",
    "janky_legacy_pct": r"Janky frames \(legacy\): \d+ \(([\d.]+)%\)",
    "p50_ms": r"^50th percentile: (\d+)ms",
    "p90_ms": r"^90th percentile: (\d+)ms",
    "p95_ms": r"^95th percentile: (\d+)ms",
    "p99_ms": r"^99th percentile: (\d+)ms",
    "missed_vsync": r"Number Missed Vsync: (\d+)",
    "slow_ui_thread": r"Number Slow UI thread: (\d+)",
    "slow_draw": r"Number Slow issue draw commands: (\d+)",
    "deadline_missed": r"Number Frame deadline missed: (\d+)",
    "high_input_latency": r"Number High input latency: (\d+)",
    "gpu_p50_ms": r"^50th gpu percentile: (\d+)ms",
    "gpu_p99_ms": r"^99th gpu percentile: (\d+)ms",
}


def parse_gfx(text):
    # Only the first block: the app's own process stats.
    out = {}
    for key, pattern in GFX_FIELDS.items():
        m = re.search(pattern, text, re.MULTILINE)
        out[key] = float(m.group(1)) if m else None
    return out


def parse_mem(text):
    m = re.search(r"TOTAL PSS:\s+(\d+)", text) or re.search(r"^\s*TOTAL\s+(\d+)", text, re.MULTILINE)
    return {"pss_mb": round(int(m.group(1)) / 1024, 1)} if m else {"pss_mb": None}


def parse_peak(text):
    # The readings of a sampled run (`run.sh --peak`), one a second through
    # the scroll: the highest is the run's peak; its rest is the meminfo
    # taken after the scroll, as in a timed run.
    values = [int(v) for v in re.findall(r"TOTAL PSS:\s+(\d+)", text)]
    return {"peak_pss_mb": round(max(values) / 1024, 1)} if values else {}


def summarize(batch):
    # One row per run: a timed run has gfxinfo and meminfo, a sampled run
    # its readings and the meminfo taken after the scroll.
    rows = {}
    parsers = {"gfxinfo": parse_gfx, "meminfo": parse_mem, "peak": parse_peak}
    for path in sorted(batch.glob("run*_*.txt")):
        label, kind = path.stem.rsplit("_", 1)
        if kind in parsers:
            rows.setdefault(label, {}).update(parsers[kind](path.read_text()))
    runs = list(rows.values())
    if not runs:
        return None
    summary = {"batch": batch.name, "runs": len(runs)}
    for key in dict.fromkeys(k for r in runs for k in r):
        values = [r[key] for r in runs if r.get(key) is not None]
        if values:
            summary[key] = {
                "median": statistics.median(values),
                "min": min(values),
                "max": max(values),
            }
    return summary


if __name__ == "__main__":
    results = [s for s in (summarize(Path(p)) for p in sys.argv[1:]) if s]
    print(json.dumps(results, indent=2))
