"""Prints a RESULTS.md table from batch folders, one row per app: the
typical frame time (p50), blank space (from the recorded run's blank.json
or holes.json, when there is one), the memory at rest after the scroll and
its peak during it, each the median over the batch's runs. The memory
comes from the sampled runs when the app has them, both numbers from the
same runs; otherwise the memory at rest comes from the timed runs and
there is no peak. A column that no app of the screen has is left out.
With --all, the table also has the 90th, 95th and 99th percentile frame
times and the share of frames Android counts as late, which RESULTS.md
does not compare (METHODOLOGY.md says why).

  python3 table.py [--all] <results-dir> <screen> [app ...]

<results-dir> holds the folders run.sh wrote, named <screen>_<app>, the
recorded runs, named rec_<screen>_<app>, and the sampled runs, named
peak_<screen>_<app>.
"""
import json
import os
import subprocess
import sys

NAMES = {
    "dartnative": "DartNative",
    "kotlin": "Kotlin",
    "legendlist": "Legend List",
    "legendlist-recycle": "Legend List, recycling",
    "flashlist": "FlashList",
    "flatlist": "FlatList",
}
HERE = os.path.dirname(os.path.abspath(__file__))


def medians(folder):
    if not os.path.isdir(folder):
        return lambda k: None
    out = subprocess.check_output([sys.executable, os.path.join(HERE, "summarize.py"), folder])
    s = json.loads(out)[0]
    return lambda k: (s[k]["median"] if isinstance(s[k], dict) else s[k]) if k in s else None


def blank(folder):
    for name in ("blank.json", "holes.json"):
        path = os.path.join(folder, name)
        if os.path.exists(path) and os.path.getsize(path) > 0:
            return json.load(open(path))["mean_blank_pct"]
    return None


def main():
    args = sys.argv[1:]
    every = "--all" in args
    args = [a for a in args if a != "--all"]
    results, screen = args[0], args[1]
    apps = args[2:] or list(NAMES)
    rows = []
    for app in apps:
        folder = os.path.join(results, f"{screen}_{app}")
        if not os.path.isdir(folder):
            continue
        g = medians(folder)
        b = blank(os.path.join(results, f"rec_{screen}_{app}"))
        sampled = medians(os.path.join(results, f"peak_{screen}_{app}"))
        peak = sampled("peak_pss_mb")
        rest = sampled("pss_mb") if peak is not None else g("pss_mb")
        rows.append((NAMES.get(app, app), g, b, rest, peak))

    columns = []  # (header, cell for one row)
    if every:
        columns.append(("Frame time p50 / p90 / p95 / p99, ms (lower is better)",
                        lambda g, b, r, p: f"{g('p50_ms'):.0f} / {g('p90_ms'):.0f} / {g('p95_ms'):.0f} / {g('p99_ms'):.0f}"))
        columns.append(("Frames past their deadline (lower is better)",
                        lambda g, b, r, p: f"{g('janky_pct'):.2f} %"))
    else:
        columns.append(("Frame time p50, ms (lower is better)", lambda g, b, r, p: f"{g('p50_ms'):.0f}"))
    if any(b is not None for _, _, b, _, _ in rows):
        columns.append(("Blank space, mean (lower is better)",
                        lambda g, b, r, p: "not recorded" if b is None else f"{b:.2f} %"))
    columns.append(("Memory at rest, PSS MB (lower is better)", lambda g, b, r, p: f"{r:.0f}"))
    if any(p is not None for _, _, _, _, p in rows):
        columns.append(("Memory peak, PSS MB (lower is better)",
                        lambda g, b, r, p: "not sampled" if p is None else f"{p:.0f}"))

    print("| App | " + " | ".join(h for h, _ in columns) + " |")
    print("| --- | " + " | ".join("---:" for _ in columns) + " |")
    for name, g, b, r, p in rows:
        print(f"| {name} | " + " | ".join(cell(g, b, r, p) for _, cell in columns) + " |")


if __name__ == "__main__":
    main()
