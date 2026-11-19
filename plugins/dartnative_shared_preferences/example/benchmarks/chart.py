#!/usr/bin/env python3
"""Draws a chart of the shared_preferences benchmark from the tables in
README.md (the iPhone) and android.md (the Android phone), so the picture
always matches the numbers. A chart shows one row of those tables: the iPhone
on the left and the Android phone on the right, each on a card with two bars,
Flutter's and DartNative's, and the gain between them in large type. The look
is the one of the DartNative repository's benchmarks (benchmarks/json).

Usage:
  python3 chart.py <out.png> "<row>" "<title>" "<line>" "<gain word>"
      [--footer "<text>"]

"<row>" is the first cell of a row ("Write, 1 key", "integer"), found in
the first table of each file whose second and third columns are
"shared_preferences, Flutter (ms)" and "dartnative_shared_preferences (ms)".
The gain is Flutter's value divided by DartNative's, followed by "<gain
word>" ("faster"): under 2 as a percentage ("21%" for 1.21), from 2 up as
a multiple, with one decimal below 10 ("2.4×") and none from 10 up
("218×"). --footer adds text under the cards; a "\\n" in it starts a new line.

The PNG is 1920 x 1080. Google Chrome, run without a window from the path in
CHROME, draws it from a page this script writes. The type is Geist where it
is installed, and the system font otherwise.
"""
import html
import os
import subprocess
import sys
import tempfile

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
HERE = os.path.dirname(os.path.abspath(__file__))
# Each phone: (name shown, system shown, the file of its results).
PHONES = [("iPhone 16 Pro", "iOS 27", "README.md"),
          ("Xiaomi 11 Lite 5G NE", "Android 14", "android.md")]
FLUTTER = "shared_preferences, Flutter (ms)"
DARTNATIVE = "dartnative_shared_preferences (ms)"
# The width of the longer bar, in pixels.
BAR_MAX = 600

PAGE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8"><style>
:root{ --ink:#f2f4f7; --soft:#c3c8d1; --muted:#7f8794; --panel:#161b22; --stroke:#30363d;
  --label:#c9d1d9; --bar:#6e7681; --best:#10b981; --dn:#3b82f6; }
*{box-sizing:border-box;margin:0;padding:0}
html,body{width:1920px;height:1080px;overflow:hidden;color:var(--ink);
  font-family:"Geist",-apple-system,"Segoe UI",Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased;
  background:#0b0d11 radial-gradient(circle 1150px at 960px 520px,rgba(40,46,56,0.35) 200px,rgba(11,13,17,0) 1150px)}
.abs{position:absolute}
.mono{font-family:"Geist Mono",ui-monospace,"SF Mono",Menlo,monospace;font-variant-numeric:tabular-nums}
.title{left:80px;top:100px;font-weight:700;font-size:76px;letter-spacing:-0.035em;line-height:1}
.line{left:80px;top:194px;font-size:34px;color:var(--soft);letter-spacing:-0.01em;white-space:nowrap}
.colhead{top:262px;width:860px;display:flex;align-items:baseline;gap:16px}
.colhead .cname{font-weight:700;font-size:34px;letter-spacing:-0.02em}
.colhead .cos{font-size:24px;color:var(--muted)}
.card{top:310px;width:860px;height:610px;border-radius:24px;background:var(--panel);border:1.5px solid var(--stroke)}
.cunit{right:44px;top:44px;font-size:24px;color:var(--muted)}
.row{left:44px;right:44px;height:100px}
.lab{left:0;top:0;font-size:34px;color:var(--label)}
.lab.dn{color:var(--dn);font-weight:700}
.bar{left:0;top:52px;height:48px;border-radius:10px}
.val{top:52px;font-size:40px;line-height:48px;color:var(--label);white-space:nowrap}
.val.dn{color:var(--ink);font-weight:600}
.gain{left:44px;bottom:40px;display:flex;align-items:baseline;gap:18px}
.gain .x{font-weight:700;font-size:150px;line-height:1;letter-spacing:-0.04em;color:var(--best)}
.gain .w{font-weight:600;font-size:48px;color:var(--best);letter-spacing:-0.02em}
.foot{left:80px;width:1760px;font-size:24px;color:var(--muted)}
</style></head><body>
"""


def tables(path):
    """Every Markdown table of the file: (header row, other rows)."""
    out, rows = [], []
    for l in open(path, encoding="utf-8").read().splitlines() + [""]:
        if l.startswith("|"):
            cells = [c.strip() for c in l.strip().strip("|").split("|")]
            if not set("".join(cells)) <= set("-: "):
                rows.append(cells)
        elif rows:
            out.append((rows[0], rows[1:]))
            rows = []
    return out


def values(path, row):
    """(Flutter's milliseconds, DartNative's) for the row, from the first
    table of the file that compares the two and has it."""
    for header, rows in tables(path):
        if header[1:3] != [FLUTTER, DARTNATIVE]:
            continue
        for r in rows:
            if r[0] == row:
                return float(r[1]), float(r[2])
    sys.exit(f'chart.py: no row "{row}" in a table of {path} headed "{FLUTTER}", "{DARTNATIVE}"')


def shown(ms):
    """Three decimals below 1 ms, as the tables have them, two to 10, one to
    100, none above: the two values shown divide to the gain shown."""
    if ms >= 100:
        return f"{ms:,.0f}"
    if ms >= 10:
        return f"{ms:.1f}"
    return f"{ms:.2f}" if ms >= 1 else f"{ms:.3f}"


def gain_text(g):
    if g < 2:
        return f"{(g - 1) * 100:.0f}%"
    return f"{g:.1f}×" if g < 10 else f"{g:,.0f}×"


def card(x, fv, dv, word):
    """One phone's card at left position x: two bars scaled to the larger value, and the gain."""
    top = max(fv, dv)
    out = [f'<div class="abs card" style="left:{x}px">',
           '<div class="abs cunit">ms for 1,000 calls · lower is better</div>']
    for i, (label, v, ours) in enumerate([("Flutter", fv, False), ("DartNative", dv, True)]):
        w = max(6, BAR_MAX * v / top)
        colour = "var(--best)" if ours else "var(--bar)"
        out.append(f'<div class="abs row" style="top:{58 + 150 * i}px">'
                   f'<div class="abs lab{" dn" if ours else ""}">{label}</div>'
                   f'<div class="abs bar" style="width:{w:.1f}px;background:{colour}"></div>'
                   f'<div class="abs val mono{" dn" if ours else ""}" style="left:{w + 18:.1f}px">{shown(v)}</div></div>')
    out.append(f'<div class="abs gain"><span class="x">{gain_text(fv / dv)}</span>'
               f'<span class="w">{html.escape(word)}</span></div>')
    out.append("</div>")
    return "\n".join(out)


def main():
    args = sys.argv[1:]
    footer = ""
    if "--footer" in args:
        k = args.index("--footer")
        footer = args[k + 1]
        del args[k:k + 2]
    if len(args) != 5:
        sys.exit(__doc__)
    out, row, title, line, word = args
    parts = [PAGE,
             f'<div class="abs title">{html.escape(title)}</div>',
             f'<div class="abs line">{html.escape(line)}</div>']
    for p, (name, system, results) in enumerate(PHONES):
        x = 80 + 900 * p
        parts.append(f'<div class="abs colhead" style="left:{x}px"><span class="cname">{html.escape(name)}</span>'
                     f'<span class="cos">{html.escape(system)}</span></div>')
        fv, dv = values(os.path.join(HERE, results), row)
        parts.append(card(x, fv, dv, word))
    lines = [l for l in footer.replace("\\n", "\n").split("\n") if l.strip()]
    for k, l in enumerate(lines):
        parts.append(f'<div class="abs foot" style="top:{996 - 40 * (len(lines) - 1 - k)}px">{html.escape(l)}</div>')
    parts.append("</body></html>\n")
    with tempfile.TemporaryDirectory() as tmp:
        page = os.path.join(tmp, "chart.html")
        open(page, "w", encoding="utf-8").write("\n".join(parts))
        subprocess.run([CHROME, "--headless", "--hide-scrollbars", "--force-device-scale-factor=1",
                        "--window-size=1920,1080", f"--screenshot={os.path.abspath(out)}",
                        "file://" + page], check=True, capture_output=True)
    print(f"{out}: {row}, 1920x1080")


if __name__ == "__main__":
    main()
