#!/usr/bin/env python3
"""Reads the folder threads.sh wrote and prints, for each app and screen in
it, the processor time its threads used per second of scrolling: the main
thread, RenderThread (the two Android's frame time covers), every other
thread together, and the busiest of those by name; then how many times the
React Native app's other threads used each other app's.

    python3 threads.py <out-dir>
"""
import collections
import os
import re
import sys

APPS = ("dartnative", "kotlin", "legendlist", "flashlist", "flatlist")


def threads(path):
    """{thread id: (name, processor ticks)} from one reading."""
    out = {}
    for line in open(path):
        line = line.strip()
        if ")" not in line:
            continue
        tid, stat = line.split(" ", 1)
        name = stat[stat.index("(") + 1:stat.rindex(")")]
        fields = stat[stat.rindex(")") + 2:].split()
        out[tid] = (name, int(fields[11]) + int(fields[12]))  # utime + stime
    return out


def summary(folder, app, screen):
    run = os.path.join(folder, f"{app}_{screen}_run.txt")
    if not os.path.exists(run):
        return None
    info = dict(kv.split("=") for kv in open(run).read().split())
    seconds = float(info["end"]) - float(info["start"])
    hz = int(info["hz"])
    before = threads(os.path.join(folder, f"{app}_{screen}_before.txt"))
    after = threads(os.path.join(folder, f"{app}_{screen}_after.txt"))
    by = collections.Counter()
    for tid, (name, ticks) in after.items():
        used = ticks - before.get(tid, (name, 0))[1]
        key = "main" if tid == info["pid"] else re.sub(r"[-#:_]*[\d_]+$", "", name)
        by[key] += used * 1000 / hz / seconds
    return by


def main():
    folder = sys.argv[1]
    for screen in ("cards", "chat"):
        other = {}
        for app in APPS:
            by = summary(folder, app, screen)
            if by is None:
                continue
            if not other:
                print(f"\n{screen}: processor time per second of scrolling, ms")
            other[app] = sum(by.values()) - by["main"] - by["RenderThread"]
            busiest = [(k, v) for k, v in by.most_common() if k not in ("main", "RenderThread")][:4]
            print(f"  {app:11s} main {by['main']:4.0f}  RenderThread {by['RenderThread']:4.0f}  "
                  f"other threads {other[app]:4.0f}  ({', '.join(f'{k} {v:.0f}' for k, v in busiest)})")
        rn = other.get("legendlist")
        for app, ms in other.items():
            if rn and app != "legendlist" and ms > 0:
                print(f"  React Native's other threads: {rn / ms:.1f}x {app}'s")


if __name__ == "__main__":
    main()
