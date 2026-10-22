#!/usr/bin/env python3
"""Draws a chart of the JSON benchmark from the tables in README.md, so the
picture always matches the numbers. A chart shows one measure: the iPhone on
the left and the Android phone on the right, each on a card with two bars,
Flutter's and DartNative's, and the gain between them in large type.

Usage:
  python3 chart.py <README.md> <out.png> "<measure>" "<payload>" "<flutter row>"
      "<title>" "<line>" "<gain word>" [--footer "<text>"]

A phone's table is the first Markdown table after the heading "<phone's
heading>, <payload>" ("iPhone 16 Pro, Feed", "Android phone, Feed"). The
measure is the first column whose header starts with it (ignoring case); the
header's text between the comma and the parenthesis is the unit. "<flutter
row>" names the table row drawn as Flutter (for example, Flutter as apps
write it); the other bar is the row named DartNative. The gain is Flutter's
value divided by DartNative's, with one decimal below 10 ("3.5×") and none
from 10 up ("26×"), followed by "<gain word>" ("faster", "less"). --footer
adds text under the cards; a "\\n" in it starts a new line.

The PNG is 1920 x 1080. Google Chrome, run without a window from the path in
CHROME, draws it from a page this script writes. The type is Geist where it
is installed, and the system font otherwise.
"""
import html
import os
import re
import subprocess
import sys
import tempfile

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# Each phone: (name shown, system shown, the heading its tables follow, before
# ", <payload>").
PHONES = [("iPhone 16 Pro", "iOS 26", "iPhone 16 Pro"),
          ("Xiaomi 11 Lite 5G NE", "Android 14", "Android phone")]
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


def read_table(path, heading):
    """(header row, other rows) of the first Markdown table after the heading."""
    lines = open(path, encoding="utf-8").read().splitlines()
    i = next(k for k, l in enumerate(lines) if l.startswith("#") and l.strip().lstrip("#").strip() == heading)
    rows = []
    started = False
    for l in lines[i + 1:]:
        if l.startswith("|"):
            started = True
            cells = [c.strip() for c in l.strip().strip("|").split("|")]
            if set("".join(cells)) <= set("-: "):
                continue
            rows.append(cells)
        elif started:
            break
    return rows[0], rows[1:]


def values(path, heading, measure, flutter_row):
    """(unit, Flutter's cell, DartNative's cell) for the measure, from the table after the heading."""
    header, rows = read_table(path, heading)
    c = next((k for k, name in enumerate(header) if name.lower().startswith(measure.lower())), None)
    if c is None:
        sys.exit(f'chart.py: no column "{measure}" in the table after "{heading}"')
    m = re.match(r"[^,]*,\s*([^(]*?)\s*(\(|$)", header[c])
    by_name = {r[0]: r[c] for r in rows}
    if flutter_row not in by_name or "DartNative" not in by_name:
        sys.exit(f'chart.py: "{flutter_row}" or "DartNative" missing after "{heading}"')
    return (m.group(1) if m else ""), by_name[flutter_row], by_name["DartNative"]


def number(cell):
    m = re.search(r"-?\d+(?:\.\d+)?", cell)
    return float(m.group()), m.group()


def gain_text(g):
    return f"{g:.1f}×" if g < 10 else f"{g:.0f}×"


def card(x, unit, flutter, dn, word):
    """One phone's card at left position x: two bars scaled to the larger value, and the gain."""
    (fv, fs), (dv, ds) = number(flutter), number(dn)
    top = max(fv, dv)
    out = [f'<div class="abs card" style="left:{x}px">',
           f'<div class="abs cunit">{html.escape(unit)} · lower is better</div>']
    for i, (label, v, shown, ours) in enumerate([("Flutter", fv, fs, False), ("DartNative", dv, ds, True)]):
        w = max(6, BAR_MAX * v / top)
        colour = "var(--best)" if ours else "var(--bar)"
        out.append(f'<div class="abs row" style="top:{58 + 150 * i}px">'
                   f'<div class="abs lab{" dn" if ours else ""}">{label}</div>'
                   f'<div class="abs bar" style="width:{w:.1f}px;background:{colour}"></div>'
                   f'<div class="abs val mono{" dn" if ours else ""}" style="left:{w + 18:.1f}px">{shown}</div></div>')
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
    path, out, measure, payload, flutter_row, title, line, word = args[:8]
    parts = [PAGE,
             f'<div class="abs title">{html.escape(title)}</div>',
             f'<div class="abs line">{html.escape(line)}</div>']
    for p, (name, system, heading) in enumerate(PHONES):
        x = 80 + 900 * p
        parts.append(f'<div class="abs colhead" style="left:{x}px"><span class="cname">{html.escape(name)}</span>'
                     f'<span class="cos">{html.escape(system)}</span></div>')
        unit, flutter, dn = values(path, f"{heading}, {payload}", measure, flutter_row)
        parts.append(card(x, unit, flutter, dn, word))
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
    print(f"{out}: {measure}, {payload}, 1920x1080")


if __name__ == "__main__":
    main()
