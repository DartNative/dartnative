#!/usr/bin/env python3
"""Pools every session in results/ by app, framework and route, and prints the
README's tables: save to screen (median and p90 of the measured reloads), the
Dart tools' own report of each reload, and what each session ran on.

Usage, from the benchmark's folder:

    python3 tool/summarize.py [results folder]

p90 is the nearest-rank 90th percentile: the value 90% of the reloads did not
exceed.
"""

import glob
import json
import os
import statistics
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROWS = [('dartnative', 'editor'), ('dartnative', 'terminal'), ('flutter', 'editor'),
        ('flutter', 'terminal')]
NAMES = {'dartnative': 'DartNative', 'flutter': 'Flutter'}
ROUTES = {'editor': 'from the editor', 'terminal': 'from the terminal'}
APPS = {'small': 'Small app', 'medium': 'Medium app'}


def p90(values):
    s = sorted(values)
    return s[max(1, -(-len(s) * 90 // 100)) - 1]


def fmt(v):
    return f'{v:.0f}' if v >= 100 else f'{v:.1f}'.rstrip('0').rstrip('.')


def measured(sessions):
    return [s for r in sessions for s in r['samples'] if not s['warmup']]


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'results')
    groups = {}
    for path in sorted(glob.glob(os.path.join(folder, '*.json'))):
        res = json.load(open(path))
        if res['framework'] not in NAMES:
            continue
        groups.setdefault((res['app'], res['framework'], res['route']), []).append(res)
    if not groups:
        sys.exit(f'no sessions in {folder}')

    for app, title in APPS.items():
        rows = [(fw, route) for fw, route in ROWS if (app, fw, route) in groups]
        if not rows:
            continue
        print(f'{title}\n')
        print('| App | Reload | Save to screen, median ms (lower is better) '
              '| p90, ms (lower is better) | Reloads |')
        print('| --- | --- | ---: | ---: | ---: |')
        for fw, route in rows:
            values = [s['save_to_screen_ms'] for s in measured(groups[(app, fw, route)])
                      if s.get('save_to_screen_ms') is not None]
            print(f'| {NAMES[fw]} | {ROUTES[route]} | {fmt(statistics.median(values))} '
                  f'| {fmt(p90(values))} | {len(values)} |')
        print()
        print('| App | Reload | Libraries reloaded | Compile, ms | Reload, ms | Reassemble, ms '
              '| The tool\'s total, ms |')
        print('| --- | --- | --- | ---: | ---: | ---: | ---: |')
        for fw, route in rows:
            m = [s for s in measured(groups[(app, fw, route)]) if 'tool_ms' in s]
            if not m:
                continue
            libs = sorted({(s['libraries'], s['libraries_total']) for s in m})
            cells = [statistics.median([s[k] for s in m])
                     for k in ('compile_ms', 'reload_ms', 'reassemble_ms', 'tool_ms')]
            print(f"| {NAMES[fw]} | {ROUTES[route]} | {', '.join(f'{a} of {b}' for a, b in libs)} | "
                  + ' | '.join(fmt(c) for c in cells) + ' |')
        print()

    for (app, fw, route), sessions in sorted(groups.items()):
        print(f'{NAMES[fw]}, {APPS[app].lower()}, {ROUTES[route]}:')
        for r in sessions:
            m = [s for s in r['samples'] if not s['warmup']]
            values = [s['save_to_screen_ms'] for s in m if s.get('save_to_screen_ms') is not None]
            gaps = [s['save_to_screen_ms'] - s['app_reported_ms'] for s in m
                    if s.get('save_to_screen_ms') is not None]
            print(f"  {r['video'][:-4]}: median {fmt(statistics.median(values))} ms, "
                  f'from {fmt(min(values))} to {fmt(max(values))} ms, {len(values)} of {len(m)} '
                  f'reloads found; screen after the app\'s report: median '
                  f'{statistics.median(gaps):+.1f} ms, from {min(gaps):+.1f} to {max(gaps):+.1f}')
        env = sessions[-1]['environment']
        print('    ' + '; '.join(f'{k}: {v}'.replace('\n', ' / ') for k, v in env.items()))


if __name__ == '__main__':
    main()
