#!/usr/bin/env python3
"""Measures blank space in a screen recording of a list.

A card that has not been drawn yet leaves the list's own background visible:
#445566 in Legend List's example, and the same colour in the DartNative app.
No card, avatar or text uses that colour, so the share of the list area that
shows it, frame by frame, is the share of the list the user saw empty.

Usage:
  python3 blank_area.py <video.mp4> --top <px> --bottom <px> [--tolerance 10]
                        [--colour 445566]

--top and --bottom bound the list area in the recording's pixels: below the
navigation bar, above the system navigation bar. The 100-point header box at
the top of the list sits on the same background with margins around it, so
the frames before the first scroll are reported separately (`start_frames`),
and so is every frame with the header box itself on screen (`header_frames`,
found by the box's own colour, #456AAA; pass `--header-colour none` on a
screen without one), since a run that scrolls back up ends at the top.

Needs ffmpeg; the counting uses the Python standard library only.
"""
import argparse
import json
import subprocess

DEFAULT_COLOUR = "445566"


def channel_table(value, tolerance):
    return bytes(1 if abs(v - value) <= tolerance else 0 for v in range(256))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("video")
    ap.add_argument("--top", type=int, required=True)
    ap.add_argument("--bottom", type=int, required=True)
    ap.add_argument("--tolerance", type=int, default=10)
    ap.add_argument("--skip-seconds", type=float, default=1.5,
                    help="frames before the first swipe, reported apart")
    ap.add_argument("--colour", default=DEFAULT_COLOUR,
                    help="the list's background, six hex digits")
    ap.add_argument("--header-colour", default="456AAA",
                    help="the header box's colour, six hex digits, or none")
    ap.add_argument("--halves", action="store_true",
                    help="also report the first and the second half of the "
                         "scrolled frames apart (a run that scrolls down, then up)")
    args = ap.parse_args()
    target = tuple(int(args.colour[i:i + 2], 16) for i in (0, 2, 4))

    probe = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_entries", "stream=width,height", "-of", "json", args.video]))
    width = probe["streams"][0]["width"]
    height = args.bottom - args.top
    frame_size = width * height * 3

    tables = [channel_table(v, args.tolerance) for v in target]
    header = None
    if args.header_colour.lower() != "none":
        header = [channel_table(int(args.header_colour[i:i + 2], 16), args.tolerance)
                  for i in (0, 2, 4)]
    proc = subprocess.Popen([
        "ffmpeg", "-v", "error", "-i", args.video,
        "-vf", f"crop={width}:{height}:0:{args.top}",
        "-fps_mode", "passthrough", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        stdout=subprocess.PIPE)
    pts = subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_entries", "frame=pts_time", "-of", "csv=p=0", args.video]).split()
    times = [float(t) for t in pts]

    fractions = []
    index = 0
    while True:
        frame = proc.stdout.read(frame_size)
        if len(frame) < frame_size:
            break
        r = int.from_bytes(frame[0::3].translate(tables[0]), "big")
        g = int.from_bytes(frame[1::3].translate(tables[1]), "big")
        b = int.from_bytes(frame[2::3].translate(tables[2]), "big")
        blank = (r & g & b).bit_count()
        shows_header = False
        if header:
            hr = int.from_bytes(frame[0::3].translate(header[0]), "big")
            hg = int.from_bytes(frame[1::3].translate(header[1]), "big")
            hb = int.from_bytes(frame[2::3].translate(header[2]), "big")
            # A few hundred pixels: the box's edge entering the screen.
            shows_header = (hr & hg & hb).bit_count() > 400
        t = times[index] if index < len(times) else None
        fractions.append((t, blank / (width * height), shows_header))
        index += 1
    proc.wait()

    t0 = fractions[0][0] if fractions and fractions[0][0] is not None else 0
    start = [f for t, f, _ in fractions if t is not None and t - t0 < args.skip_seconds]
    later = [(t, f, h) for t, f, h in fractions if t is None or t - t0 >= args.skip_seconds]
    header_frames = sum(1 for _, _, h in later if h)
    scrolled = [f for _, f, h in later if not h]

    def pct(values, q):
        return round(100 * values[min(len(values) - 1, int(q * len(values)))], 3) if values else None

    def stats(values):
        ordered = sorted(values)
        return {
            "frames": len(ordered),
            "mean_blank_pct": round(100 * sum(ordered) / len(ordered), 3) if ordered else None,
            "p95_blank_pct": pct(ordered, 0.95),
            "max_blank_pct": pct(ordered, 1.0),
            "frames_over_1pct": sum(1 for f in ordered if f > 0.01),
            "frames_over_5pct": sum(1 for f in ordered if f > 0.05),
        }

    report = {"video": args.video, "start_frames": len(start),
              "header_frames": header_frames, **stats(scrolled)}
    if args.halves:
        half = len(scrolled) // 2
        report["first_half"] = stats(scrolled[:half])
        report["second_half"] = stats(scrolled[half:])
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
