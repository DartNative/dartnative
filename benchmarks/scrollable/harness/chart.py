#!/usr/bin/env python3
"""Draws a results chart from the tables in RESULTS.md, so the picture can
never drift from the numbers: one measure, the iPhone on the left and the
Android phone on the right, a card each with a bar for every app.

Usage:
  python3 chart.py <results.md> <out.png> "<measure>" "<title>" "<line>" --screen <name> [--screen <name>]
      [--footer "<text>"] [--name "<row>=<label>"]...

A phone's table is the first Markdown table after the heading "<phone's
heading>, <screen>" ("iPhone 16 Pro, Cards", "Android phone, Chat"; PHONES
below). The measure is the column whose header starts with it: "Typical
frame time" reads "Typical frame time, ms (lower is better)", and the
header's text between the comma and the parenthesis is the unit. Each
card scales to its own largest value; the best value (the lowest, unless
the header says "higher is better") is drawn in green, DartNative's bar
in blue when it is not the best, the others in grey.

A column with no number in it is a card of words, for what is seen rather
than measured (in a recording): "none" gets a green check mark, anything
else a grey cross. Such a column can be given two screens (--screen Cards
--screen Chat): the card is titled "Cards and Chat", and the chart stops
with an error if the two tables do not read the same.

<line> is the sentence under the title. --footer "<text>" writes the text
under the cards; a "\\n" starts a new line, and the words between ** and **
are drawn bold. --name "<row>=<label>" shows the table's row under another
name (the Legend List row as "React Native"); the table keeps its own.

The PNG is 1920 x 1080, drawn by Chrome headless from a page this script
writes; the type is Geist where it is installed, the system's otherwise.
"""
import html
import os
import re
import subprocess
import sys
import tempfile

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# (name, system, the heading its tables follow, before ", <screen>")
PHONES = [("iPhone 16 Pro", "iOS 26", "iPhone 16 Pro"),
          ("Xiaomi 11 Lite 5G NE", "Android 14", "Android phone")]
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
.legend{right:80px;top:124px;display:flex;gap:30px;font-size:22px;color:var(--label)}
.legend span{display:flex;align-items:center;gap:10px}
.legend i{display:block;width:20px;height:20px;border-radius:5px}
.colhead{top:262px;width:860px;display:flex;align-items:baseline;gap:16px}
.colhead .cname{font-weight:700;font-size:34px;letter-spacing:-0.02em}
.colhead .cos{font-size:24px;color:var(--muted)}
.card{top:310px;width:860px;height:610px;border-radius:24px;background:var(--panel);border:1.5px solid var(--stroke)}
.ctitle{left:44px;top:34px;font-weight:700;font-size:42px;letter-spacing:-0.02em}
.cunit{right:44px;top:48px;font-size:24px;color:var(--muted)}
.row{left:44px;right:44px;height:100px}
.lab{left:0;top:0;font-size:34px;color:var(--label)}
.lab.dn{color:var(--dn);font-weight:700}
.bar{left:0;top:52px;height:48px;border-radius:10px}
.val{top:52px;font-size:40px;line-height:48px;color:var(--label);white-space:nowrap}
.val.best{color:var(--ink);font-weight:600}
.mark{left:0;top:52px;width:48px;height:48px}
.mark path{fill:none;stroke-width:3.2;stroke-linecap:round;stroke-linejoin:round}
.word{left:66px;top:52px;font-size:36px;line-height:48px;color:var(--label)}
.foot{left:80px;width:1760px;font-size:24px;color:var(--muted)}
.foot b{color:var(--soft);font-weight:600}
</style></head><body>
"""


def read_table(path, heading):
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


def column(path, heading, measure):
    """(unit, lower is better, [(app, cell)]) for the measure's column in the heading's table."""
    header, rows = read_table(path, heading)
    c = next((k for k, name in enumerate(header) if name.lower().startswith(measure.lower())), None)
    if c is None:
        sys.exit(f'chart.py: no column "{measure}" in the table after "{heading}"')
    m = re.match(r"[^,]*,\s*([^(]*?)\s*(\(|$)", header[c])
    lower = "higher is better" not in header[c].lower()
    return (m.group(1) if m else ""), lower, [(r[0], r[c] if c < len(r) else "") for r in rows]


def number(cell):
    """The cell's first number, as written ("0.50" stays "0.50")."""
    m = re.search(r"-?\d+(?:[.,]\d+)?", cell)
    return (float(m.group().replace(",", ".")), m.group()) if m else (None, cell)


def text(s):
    """Escaped text; the words between ** and ** in bold."""
    parts = re.split(r"\*\*(.+?)\*\*", s)
    return "".join(f"<b>{html.escape(p)}</b>" if k % 2 else html.escape(p) for k, p in enumerate(parts))


def card(x, title, unit, lower, rows, names):
    out = [f'<div class="abs card" style="left:{x}px">', f'<div class="abs ctitle">{html.escape(title)}</div>']
    values = [number(cell)[0] for _, cell in rows]
    words = all(v is None for v in values)
    if not words:
        out.append(f'<div class="abs cunit">{html.escape(unit)} · {"lower" if lower else "higher"} is better</div>')
        best, top = (min if lower else max)(values), max(values)
    for i, (app, cell) in enumerate(rows):
        ours = app.lower().startswith("dartnative")
        out.append(f'<div class="abs row" style="top:{128 + 156 * i}px">'
                   f'<div class="abs lab{" dn" if ours else ""}">{html.escape(names.get(app, app))}</div>')
        if words:
            ok = cell.strip().lower() == "none"
            d = "M4 12.5 L9.5 18 L20 6" if ok else "M6 6 L18 18 M18 6 L6 18"
            out.append(f'<svg class="abs mark" viewBox="0 0 24 24"><path d="{d}" stroke="{"#10b981" if ok else "#6e7681"}"/></svg>'
                       f'<div class="abs word">{html.escape(cell)}</div></div>')
            continue
        v, shown = number(cell)
        w = max(4, BAR_MAX * v / top)
        colour = "var(--best)" if v == best else "var(--dn)" if ours else "var(--bar)"
        out.append(f'<div class="abs bar" style="width:{w:.1f}px;background:{colour}"></div>'
                   f'<div class="abs val mono{" best" if v == best else ""}" style="left:{w + 18:.1f}px">{shown}</div></div>')
    out.append("</div>")
    return "\n".join(out)


def main():
    args = sys.argv[1:]

    def take(flag):
        found = []
        while flag in args:
            k = args.index(flag)
            found.append(args[k + 1])
            del args[k:k + 2]
        return found

    screens = take("--screen")
    footer = (take("--footer") or [""])[0]
    names = dict(n.split("=", 1) for n in take("--name"))
    names = {k.strip(): v.strip() for k, v in names.items()}
    path, out, measure, title, line = args[:5]
    if not screens:
        sys.exit("chart.py: give the screen with --screen")

    parts = [PAGE,
             f'<div class="abs title">{html.escape(title)}</div>',
             f'<div class="abs line">{html.escape(line)}</div>',
             '<div class="abs legend"><span><i style="background:var(--dn)"></i>DartNative</span>'
             '<span><i style="background:var(--best)"></i>best</span>'
             '<span><i style="background:var(--bar)"></i>the others</span></div>']
    for p, (name, system, heading) in enumerate(PHONES):
        x = 80 + 900 * p
        parts.append(f'<div class="abs colhead" style="left:{x}px"><span class="cname">{html.escape(name)}</span>'
                     f'<span class="cos">{html.escape(system)}</span></div>')
        read = [column(path, f"{heading}, {s}", measure) for s in screens]
        unit, lower, rows = read[0]
        if any(r != rows for _, _, r in read[1:]):
            sys.exit(f'chart.py: "{measure}" differs between {" and ".join(screens)} on the {name}')
        parts.append(card(x, " and ".join(screens), unit, lower, rows, names))
    lines = [l for l in footer.replace("\\n", "\n").split("\n") if l.strip()]
    for k, l in enumerate(lines):
        parts.append(f'<div class="abs foot" style="top:{996 - 40 * (len(lines) - 1 - k)}px">{text(l)}</div>')
    parts.append("</body></html>\n")

    with tempfile.TemporaryDirectory() as tmp:
        page = os.path.join(tmp, "chart.html")
        open(page, "w", encoding="utf-8").write("\n".join(parts))
        subprocess.run([CHROME, "--headless", "--hide-scrollbars", "--force-device-scale-factor=1",
                        "--window-size=1920,1080", f"--screenshot={os.path.abspath(out)}",
                        "file://" + page], check=True, capture_output=True)
    print(f"{out}: {measure}, {' and '.join(screens)}, 1920x1080")


if __name__ == "__main__":
    main()
