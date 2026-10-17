#!/usr/bin/env python3
"""Prints where, in seconds, the stretch of a screen recording with the
most movement starts: the swipes of a scrolling run, wherever the test's
start-up put them.

  python3 motion_window.py <video> <seconds>

Reads the video at 10 frames a second, small and grey, through ffmpeg, and
sums the change from frame to frame over every window of that length.
"""
import subprocess
import sys

FPS, W, H = 10, 90, 196


def main():
    video, seconds = sys.argv[1], float(sys.argv[2])
    p = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-i", video, "-vf",
                          f"fps={FPS},scale={W}:{H},format=gray", "-f", "rawvideo", "-"],
                         stdout=subprocess.PIPE)
    size = W * H
    prev, diffs = None, []
    while True:
        frame = p.stdout.read(size)
        if len(frame) < size:
            break
        if prev is not None:
            diffs.append(sum(abs(a - b) for a, b in zip(frame, prev)))
        prev = frame
    n = int(seconds * FPS)
    if len(diffs) <= n:
        print(0)
        return
    window = sum(diffs[:n])
    best, best_at = window, 0
    for i in range(1, len(diffs) - n + 1):
        window += diffs[i + n - 1] - diffs[i - 1]
        if window > best:
            best, best_at = window, i
    print(f"{best_at / FPS:.1f}")


if __name__ == "__main__":
    main()
