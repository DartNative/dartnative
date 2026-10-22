#!/usr/bin/env python3
"""Draws the hot reload chart from the results tables in README.md, so the
picture always matches the numbers: the small app on the left and the medium
app on the right, each on a card with four bars, DartNative's and Flutter's
reload from the editor and from the terminal (the median time from saving the
file to the new colour on the simulator's screen), and, in large type, how
many times faster DartNative's reload is on each route.

Usage, from this folder:

  python3 chart.py README.md charts/save_to_screen.png [--footer "<text>"]

Each card's table is the first Markdown table after the heading that starts
with "Small app" or "Medium app". Its rows are named by the App column
(DartNative, Flutter) and the Reload column ("from the editor", "from the
terminal"); the values are the third column. --footer adds text under the
cards; a "\\n" in it starts a new line.

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
TITLE = "Hot reload"
LINE = "From saving the file to the change on the iOS simulator's screen."
CARDS = [("Small app", "one file"), ("Medium app", "one file changed of nine")]
ROUTES = ["from the editor", "from the terminal"]
# The width of the longest bar, in pixels.
BAR_MAX = 520

PAGE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8"><style>
:root{ --ink:#f2f4f7; --soft:#c3c8d1; --muted:#7f8794; --panel:#161b22; --stroke:#30363d;
  --label:#c9d1d9; --bar:#6e7681; --best:#10b981; }
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
.cunit{right:44px;top:40px;font-size:24px;color:var(--muted)}
.row{left:44px;right:44px;height:84px}
.lab{left:0;top:0;font-size:28px;color:var(--label);white-space:nowrap}
.lab .route{color:var(--muted)}
.lab.dn{color:var(--ink);font-weight:700}
.bar{left:0;top:40px;height:40px;border-radius:9px}
.val{top:40px;font-size:34px;line-height:40px;color:var(--label);white-space:nowrap}
.val.dn{color:var(--ink);font-weight:600}
.gain{left:44px;display:flex;align-items:baseline;gap:14px}
.gain .x{font-weight:700;font-size:56px;line-height:1;letter-spacing:-0.03em;color:var(--best)}
.gain .w{font-weight:600;font-size:28px;color:var(--best);letter-spacing:-0.01em}
.foot{left:80px;width:1760px;font-size:24px;color:var(--muted)}
</style></head><body>
"""


def read_table(path, heading):
    """(header row, other rows) of the first Markdown table after the heading
    that starts with `heading`."""
    lines = open(path, encoding="utf-8").read().splitlines()
    i = next(k for k, l in enumerate(lines)
             if l.startswith("#") and l.strip().lstrip("#").strip().startswith(heading))
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


def number(cell):
    m = re.search(r"-?\d+(?:\.\d+)?", cell)
    return float(m.group()), m.group()


def gain_text(g):
    return f"{g:.1f}×" if g < 10 else f"{g:.0f}×"


def card(x, values):
    """One app's card at left position x: DartNative's and Flutter's bars for
    each route, scaled to the largest, and DartNative's gain on each route."""
    top = max(v for v, _ in values.values())
    out = [f'<div class="abs card" style="left:{x}px">',
           '<div class="abs cunit">ms · lower is better</div>']
    i = 0
    for route in ROUTES:
        for name in ("DartNative", "Flutter"):
            v, shown = values[(name, route)]
            ours = name == "DartNative"
            w = max(6, BAR_MAX * v / top)
            out.append(f'<div class="abs row" style="top:{40 + 96 * i}px">'
                       f'<div class="abs lab{" dn" if ours else ""}">{name} '
                       f'<span class="route">{html.escape(route)}</span></div>'
                       f'<div class="abs bar" style="width:{w:.1f}px;background:var({"--best" if ours else "--bar"})"></div>'
                       f'<div class="abs val mono{" dn" if ours else ""}" style="left:{w + 16:.1f}px">{shown}</div></div>')
            i += 1
    for k, route in enumerate(ROUTES):
        g = values[("Flutter", route)][0] / values[("DartNative", route)][0]
        out.append(f'<div class="abs gain" style="bottom:{34 + 70 * (len(ROUTES) - 1 - k)}px">'
                   f'<span class="x">{gain_text(g)}</span>'
                   f'<span class="w">faster than Flutter, {html.escape(route)}</span></div>')
    out.append("</div>")
    return "\n".join(out)


def main():
    args = sys.argv[1:]
    footer = ""
    if "--footer" in args:
        k = args.index("--footer")
        footer = args[k + 1]
        del args[k:k + 2]
    if len(args) != 2:
        sys.exit(__doc__)
    path, out = args
    parts = [PAGE,
             f'<div class="abs title">{html.escape(TITLE)}</div>',
             f'<div class="abs line">{html.escape(LINE)}</div>']
    for p, (heading, note) in enumerate(CARDS):
        x = 80 + 900 * p
        _, rows = read_table(path, heading)
        values = {(r[0], r[1]): number(r[2]) for r in rows}
        parts.append(f'<div class="abs colhead" style="left:{x}px"><span class="cname">{html.escape(heading)}</span>'
                     f'<span class="cos">{html.escape(note)}</span></div>')
        parts.append(card(x, values))
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
    print(f"{out}: two apps, 1920x1080")


if __name__ == "__main__":
    main()
