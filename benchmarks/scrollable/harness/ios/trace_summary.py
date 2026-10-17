#!/usr/bin/env python3
"""Reads a trace recorded by trace.sh and prints, for the flings it holds:

- the typical frame time inside the flings: the median of the Hitches
  instrument's reading of the app's update for each frame, the time the
  app took to prepare it, which the results compare;
- the hitches inside the flings (Hitches instrument: a frame shown later
  than its deadline), their count and their time, and the frames the app
  showed a second (its screen updates inside the flings over their time);
- the share of the flings' time the panel spent at each refresh rate
  (Display instrument, vsync intervals of the built-in display);
- the app's CPU time inside the flings, main thread and all threads, as a
  share of the flings' time (Time Profiler samples at 1 ms);
- the app's memory: its footprint at rest 10 s after the last fling, as
  the app's own census measured it (BENCH_MEMORY, the file next to the
  trace), and the highest footprint Activity Monitor sampled before the
  census began.

A fling runs from the start of the finger's travel to the end of the
deceleration. Its times come from the file the app's own driver writes
(autoscroll/BenchAutoScroll.m; trace.sh puts it next to the trace as
<app>_<screen>_flings.txt), placed on the trace's time line through the
"sync" signpost the driver makes at the end of the run: the device's log
daemon may leave a process's signposts out of the first tens of seconds
of a recording, and the mark at the end of the run is the one every trace
has. A trace with no such file falls back to its "fling" signposts, and a
trace of hand swipes falls back to UIKit's own
`Scroll_DraggingAndDeceleration` intervals.

Usage:
  python3 trace_summary.py <trace> [--json]

Needs the xctrace of the Xcode that built the apps. The exports are cached
next to the trace, and made again for a newer trace.
"""
import collections
import json
import os
import re
import statistics
import subprocess
import sys
import xml.etree.ElementTree as ET

XCTRACE = ["xcrun", "xctrace", "export"]


def export(trace, schema):
    """Exports one table of the trace to XML, once; xctrace can crash while
    exporting a large table, so a failed export is tried again."""
    out = f"{trace}.{schema}.xml"
    for attempt in range(3):
        # An export older than the trace belongs to an earlier trace
        # recorded at the same path.
        if os.path.exists(out) and os.path.getsize(out) > 0 and os.path.getmtime(out) >= os.path.getmtime(trace):
            return out
        if os.path.exists(out):
            os.remove(out)
        try:
            subprocess.run(XCTRACE + ["--input", trace, "--xpath",
                                      f'/trace-toc/run[@number="1"]/data/table[@schema="{schema}"]',
                                      "--output", out], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            if attempt == 2:
                raise
    return out


def rows(path):
    """Yields each row as a dict of column mnemonic to element, with the
    export's id/ref references resolved."""
    root = ET.parse(path).getroot()
    schema = root.find(".//schema")
    if schema is None:
        return
    cols = [c.find("mnemonic").text for c in schema.findall("col")]
    ids = {}

    def val(el):
        if el.get("id"):
            ids[el.get("id")] = el
        if el.get("ref"):
            el = ids[el.get("ref")]
        for child in list(el):
            val(child)
        return el

    for row in root.iter("row"):
        yield dict(zip(cols, [val(c) for c in row]))


def flings(trace):
    """The driver's fling intervals, in trace time (nanoseconds). The driver
    writes each fling's start and end to a file, on the device's monotonic
    clock, with a sync reading that its "sync" signpost at the end of the
    run also carries; the signpost's trace time minus that reading puts
    every fling on the trace's time line. Only this one mark has to be in
    the trace: the device's log daemon may leave a process's signposts out
    of the first tens of seconds of a recording, so the early flings can be
    missing, but the mark at the end of the run comes later than that. A
    trace with no file beside it falls back to the fling signposts it
    holds, and a trace of an app that was not driven falls back to UIKit's
    own scroll intervals."""
    sync_trace, pairs, begin = None, [], None
    for r in rows(export(trace, "os-signpost")):
        if r["subsystem"].get("fmt") != "com.dartnative.benchmarks.scrollable":
            continue
        name, kind, t = r["name"].get("fmt"), r["event-type"].get("fmt"), int(r["time"].text)
        if name == "sync":
            # The export writes the reading with digit-group separators.
            sync_trace = (t, int(re.sub(r"\D", "", r["message"].get("fmt") or r["message"].text or "0")))
        elif name == "fling":
            if kind == "Begin":
                begin = t
            elif kind == "End" and begin is not None:
                pairs.append((begin, t))
                begin = None
    times = trace[:-len(".trace")] + "_flings.txt" if trace.endswith(".trace") else trace + "_flings.txt"
    if sync_trace and os.path.exists(times):
        sync_device = None
        ours = []
        for line in open(times):
            parts = line.split()
            if parts[:1] == ["sync"]:
                sync_device = int(parts[1])
            elif parts[:1] == ["fling"]:
                ours.append((float(parts[2]), float(parts[3])))
        if sync_device == sync_trace[1] and ours:
            # Trace time of a device clock reading: the sync mark's trace
            # time, minus how long before the sync mark the reading was
            # taken.
            at = lambda seconds: sync_trace[0] - (sync_device - int(seconds * 1e6)) * 1000
            return [(at(a), at(b)) for a, b in ours]
    if pairs:
        return pairs
    uikit = []
    for r in rows(export(trace, "os-signpost-interval")):
        if r["name"].get("fmt") != "Scroll_DraggingAndDeceleration":
            continue
        start = int(r["start"].text)
        uikit.append((start, start + int(r["duration"].text)))
    return uikit


def inside(t, intervals):
    return any(a <= t <= b for a, b in intervals)


def hitches(trace, intervals):
    span = sum(b - a for a, b in intervals) or 1
    found = [h for h in rows(export(trace, "hitches")) if inside(int(h["start"].text), intervals)]
    updates = [int(u["duration"].text) / 1e6 for u in rows(export(trace, "hitches-updates"))
               if inside(int(u["start"].text), intervals)]
    return {"count": len(found),
            "ms": round(sum(int(h["duration"].text) for h in found) / 1e6, 1),
            "frames_per_second": round(len(updates) / (span / 1e9), 1),
            "update_median_ms": round(statistics.median(updates), 2) if updates else None}


def refresh_shares(trace, intervals):
    times = sorted(int(r["timestamp"].text) for r in rows(export(trace, "display-vsyncs-interval"))
                   if r["display-name"].get("fmt") == "Built-In Display")
    total = collections.Counter()
    for a, b in zip(times, times[1:]):
        if inside(a, intervals) and b - a > 0:
            total[round(1e9 / (b - a))] += b - a
    span = sum(total.values()) or 1
    return {f"{hz} Hz": round(100 * ns / span, 1) for hz, ns in total.most_common(4)}


def cpu_shares(trace, intervals):
    main = other = 0
    for r in rows(export(trace, "time-profile")):
        t = int(r["time"].text)
        if not inside(t, intervals):
            continue
        weight = int(r["weight"].text)
        if r["thread"].get("fmt", "").startswith("Main Thread"):
            main += weight
        else:
            other += weight
    span = sum(b - a for a, b in intervals) or 1
    return {"main_thread_pct": round(100 * main / span, 1),
            "all_threads_pct": round(100 * (main + other) / span, 1),
            "main_thread_ms_per_fling": round(main / 1e6 / max(1, len(intervals)), 1)}


def census_time(trace):
    """When the driver's memory census began (its "census" signpost event),
    or None: the census allocates memory, so the samples after it show the
    census, not the app."""
    try:
        path = export(trace, "os-signpost")
    except subprocess.CalledProcessError:
        return None
    for r in rows(path):
        if r.get("name") is not None and r["name"].get("fmt") == "census":
            return int(r["time"].text)
    return None


def memory(trace):
    """The traced process's footprint: at rest, as the app's own census
    measured it 10 s after the last fling (the file trace.sh copies next to
    the trace), else the last Activity Monitor sample before the census;
    and the highest sample before the census."""
    try:
        path = export(trace, "sysmon-process")
    except subprocess.CalledProcessError:
        return None
    cutoff = census_time(trace)
    samples = [r for r in rows(path) if "memory-physical-footprint" in r
               and (cutoff is None or int(r["time"].text) <= cutoff)]
    if not samples:
        return None
    last = samples[-1]["memory-physical-footprint"]
    peak = max(samples, key=lambda r: int(r["memory-physical-footprint"].text))["memory-physical-footprint"]
    result = {"footprint": last.get("fmt"), "footprint_peak": peak.get("fmt"),
              "footprint_bytes": int(last.text), "footprint_peak_bytes": int(peak.text)}
    census = trace[:-len(".trace")] + "_memory.txt" if trace.endswith(".trace") else None
    if census and os.path.exists(census):
        with open(census) as f:
            first = f.readline().split()
        if len(first) >= 3 and first[0] == "footprint":
            mib = float(first[1])
            result["footprint"] = f"{mib:.1f} MiB"
            result["footprint_bytes"] = int(mib * 1048576)
    return result


def diagnostic(read, trace, intervals):
    """Reads a table that explains the results rather than one that is
    compared. If its export fails (the time profile of a long run is the
    largest table, and `xctrace export` can crash on it), the summary says
    so and keeps the rest."""
    try:
        return read(trace, intervals)
    except subprocess.CalledProcessError as e:
        return {"error": f"export failed ({e.returncode})"}


def main():
    trace = sys.argv[1]
    intervals = flings(trace)
    result = {
        "trace": os.path.basename(trace),
        "flings": len(intervals),
        "fling_seconds": round(sum(b - a for a, b in intervals) / 1e9, 1),
        "hitches": hitches(trace, intervals),
        "refresh": diagnostic(refresh_shares, trace, intervals),
        "cpu": diagnostic(cpu_shares, trace, intervals),
        "memory": memory(trace),
    }
    if "--json" in sys.argv:
        print(json.dumps(result, indent=2))
    else:
        for k, v in result.items():
            print(f"{k:14s} {v}")


if __name__ == "__main__":
    main()
