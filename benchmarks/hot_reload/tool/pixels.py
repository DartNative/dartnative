#!/usr/bin/env python3
"""Finds each reload's new colour in a session's screen recording.

Usage, from the benchmark's folder (measure.py also runs it after every
session):

    python3 tool/pixels.py results/<framework>-<date>-<time>.json

The simulator's own recording (`xcrun simctl io recordVideo`) holds a frame for
every change of the screen, each with its time from the start of the
recording. For each reload this finds the first frame, after the file was
written, in which a thin vertical strip through the cards shows the new
colour, and puts that frame on this Mac's clock: the moment measure.py saw
the simulator print "Recording started", plus the frame's time. Save to screen
is that time minus the moment the file was written.

The strip is 4 pixels wide at 62% of the screen's width, clear of the cards'
labels, from 15% to 90% of its height: below the bar and across many cards.
A frame shows the colour when at least half as many of the strip's pixels
match it (each channel within 28 of the colour, for the video's compression)
as in the frame that matches best.

The same placement on the clock applies to every framework. Each app also
reports the colour it has drawn, after its frame; the screen should change a
little after that report, never before, and the script prints the difference
as a check.

Needs ffmpeg and ffprobe on PATH.
"""

import json
import os
import statistics
import subprocess
import sys

STRIP_X, STRIP_WIDTH = 0.62, 4
STRIP_TOP, STRIP_BOTTOM = 0.15, 0.90
TOLERANCE = 28


def rgb(hex6):
    return tuple(int(hex6[i:i + 2], 16) for i in (0, 2, 4))


def frames(video):
    """(frame times in seconds, the strip of each frame as RGB bytes, bytes per strip)."""
    size = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0',
                           '-show_entries', 'stream=width,height', '-of', 'csv=p=0', video],
                          capture_output=True, text=True, check=True).stdout.strip()
    w, h = (int(v) for v in size.split(',')[:2])
    times = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0',
                            '-show_entries', 'frame=best_effort_timestamp_time',
                            '-of', 'csv=p=0', video],
                           capture_output=True, text=True, check=True).stdout.split()
    times = [float(t.strip(',')) for t in times if t.strip(',')]
    x, y = int(w * STRIP_X), int(h * STRIP_TOP)
    sh = int(h * STRIP_BOTTOM) - y
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', video, '-fps_mode', 'passthrough',
                          '-vf', f'crop={STRIP_WIDTH}:{sh}:{x}:{y}', '-f', 'rawvideo',
                          '-pix_fmt', 'rgb24', '-'], capture_output=True, check=True).stdout
    per = STRIP_WIDTH * sh * 3
    n = min(len(raw) // per, len(times))
    return times[:n], [raw[i * per:(i + 1) * per] for i in range(n)], per


def share(strip, colour):
    """The share of the strip's pixels that show the colour."""
    r, g, b = colour
    hits = 0
    for p in range(0, len(strip), 3):
        if abs(strip[p] - r) <= TOLERANCE and abs(strip[p + 1] - g) <= TOLERANCE \
                and abs(strip[p + 2] - b) <= TOLERANCE:
            hits += 1
    return hits / (len(strip) // 3)


def on_screen(video, video_start, samples, report=print):
    """{reload number: save to screen in ms} for the reloads found in the video."""
    times, strips, _ = frames(video)
    found = {}
    for k, s in enumerate(samples):
        save = s['wall_save'] - video_start
        end = samples[k + 1]['wall_save'] - video_start if k + 1 < len(samples) else times[-1] + 1
        window = [i for i in range(len(times)) if save - 0.5 <= times[i] < end]
        if not window:
            report(f"reload {s['i']}: no frames near the save")
            continue
        colour = rgb(s['colour'])
        shares = {i: share(strips[i], colour) for i in window}
        peak = max(shares.values())
        before = [i for i in window if times[i] < save]
        if peak < 0.2:
            report(f"reload {s['i']}: #{s['colour']} is not in the recording")
            continue
        if before and shares[before[-1]] >= 0.5 * peak:
            report(f"reload {s['i']}: #{s['colour']} was on screen before the save")
            continue
        first = next((i for i in window if times[i] >= save and shares[i] >= 0.5 * peak), None)
        if first is None:
            report(f"reload {s['i']}: #{s['colour']} is not on screen after the save")
            continue
        found[s['i']] = round((times[first] - save) * 1000, 1)
    return found


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    path = sys.argv[1]
    res = json.load(open(path))
    video = os.path.join(os.path.dirname(path), res['video'])
    found = on_screen(video, res['video_start_wall'], res['samples'])
    gaps = []
    for s in res['samples']:
        ms = found.get(s['i'])
        if ms is None:
            continue
        tag = 'warm-up' if s['warmup'] else 'reload'
        print(f"{tag:7s} {s['i']:2d} #{s['colour']}: save to screen {ms:7.1f} ms, "
              f"reported by the app {s['app_reported_ms']:7.1f} ms, "
              f"screen after the report {ms - s['app_reported_ms']:+6.1f} ms")
        if not s['warmup']:
            gaps.append(ms - s['app_reported_ms'])
    if gaps:
        print(f'screen after the report: median {statistics.median(gaps):+.1f} ms, '
              f'from {min(gaps):+.1f} to {max(gaps):+.1f} ms')


if __name__ == '__main__':
    main()
