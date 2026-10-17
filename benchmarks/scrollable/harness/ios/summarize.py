#!/usr/bin/env python3
"""Prints the measurements of every `*_metrics.json` in a results folder
(written by run.sh from `xcresulttool get test-results metrics`): per
iteration, then the median.

Usage:
  python3 summarize.py <out-dir> [--json]
"""
import glob
import json
import os
import statistics
import sys

WANTED = {
    "Frame Rate": "frame_rate_fps",
    "Number of Hitches": "hitches",
    "Hitch Time Ratio": "hitch_ms_per_s",
    "Duration": "interval_s",
}


def measurements(path):
    out = {}

    def walk(o):
        if isinstance(o, dict):
            name = o.get("displayName")
            if name and isinstance(o.get("measurements"), list):
                for prefix, key in WANTED.items():
                    if name.startswith(prefix):
                        values = [m.get("value", m) if isinstance(m, dict) else m for m in o["measurements"]]
                        out[key] = [float(v) for v in values]
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)

    walk(json.load(open(path)))
    return out


def main():
    folder = sys.argv[1]
    as_json = "--json" in sys.argv
    result = {}
    for path in sorted(glob.glob(os.path.join(folder, "*_metrics.json"))):
        name = os.path.basename(path).replace("_metrics.json", "")
        m = measurements(path)
        result[name] = {k: {"values": v, "median": statistics.median(v)} for k, v in m.items()}
        if not as_json:
            print(f"== {name}")
            for k, v in m.items():
                print(f"  {k:16s} median {statistics.median(v):9.2f}   {[round(x, 2) for x in v]}")
    if as_json:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
