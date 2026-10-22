#!/usr/bin/env python3
"""Measures hot reload on the iOS simulator: the time from saving a source file
to the new colour on the simulator's screen.

Usage, from the benchmark's folder:

    python3 tool/measure.py dartnative|flutter
        [--app small|medium] [--route editor|terminal]
        [--device <simulator id>] [--sessions 3] [--reloads 10] [--warmups 3]
        [--gap 3] [--dn <path to dn>] [--flutter <path to flutter>]

    python3 tool/summarize.py      # the tables, from every session in results/

--app picks the screen: small (one file) or medium (nine files, the edit in
one of them). --route picks how a reload starts:
  editor     the app runs under the tool's daemon (`run --machine`), and each
             save is followed by `app.restart` with `debounce: true`, the
             request VS Code sends when a Dart file is saved;
  terminal   the app runs under `run`, and each save is followed by the reload
             that `r` starts in the terminal, sent as SIGUSR1 to the tool.
--device defaults to the one booted simulator. --dn and --flutter default to
the dn and flutter on PATH.

Before the first session:
  dartnative    run `dn pub get` in dartnative/
  flutter       run `flutter pub get` in flutter/

Each session:
  1. Starts the app in debug on the simulator, as the route says.
  2. Waits for the app's first frame and starts the simulator's own screen
     recording (`xcrun simctl io recordVideo`).
  3. Makes the warm-up reloads, then the measured ones, --gap seconds apart.
     Each one writes a new value of the colour constant into its file (the
     small app's cardColor, the medium app's rowColor), starts the reload
     the route says, and waits until the app reports the new colour (each
     app sends the colour it has just drawn to a small listener here, on
     port 48765). A reload the app never reports within 20 seconds ends the
     session with an error, and no numbers are kept from it.
  4. Stops the recording and finds, for each reload, the first frame of the
     recording that shows the new colour (tool/pixels.py). The time of that
     frame on this Mac's clock, minus the time the file was written, is the
     result: save to screen.

Results go to results/<framework>-<app>-<route>-<date>-<time>.json, with the
recording beside it. The source file is put back as it was at the end of
every session.

Needs Python 3, Xcode and ffmpeg (for ffprobe and ffmpeg). Run it on an
otherwise idle Mac.
"""

import argparse
import json
import os
import platform
import re
import shutil
import signal
import socketserver
import statistics
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

import pixels

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PORT = 48765
# The colours each reload writes, in turn; two reloads in a row never write the
# same one, and none is close to another.
COLOURS = ['E24A4A', '4AE27A', '4A90E2', 'E2C44A', '9B4AE2']
RELOAD_TIMEOUT = 20


def dart_colour(name):
    return dict(line=rf'^const {name} = Color\(0x([0-9A-Fa-f]{{8}})\);$',
                write=f'const {name} = Color(0xFF{{hex}});')


# For each framework and app: the folder the tool runs in, the file each reload
# edits, the Dart entry point, and the colour line in that file.
APPS = {
    ('dartnative', 'small'): dict(dir='dartnative', src='lib/main.dart', target=None,
                                  **dart_colour('cardColor')),
    ('dartnative', 'medium'): dict(dir='dartnative', src='lib/medium/contact_row.dart',
                                   target='lib/medium/main.dart', **dart_colour('rowColor')),
    ('flutter', 'small'): dict(dir='flutter', src='lib/main.dart', target=None,
                               **dart_colour('cardColor')),
    ('flutter', 'medium'): dict(dir='flutter', src='lib/medium/contact_row.dart',
                                target='lib/medium/main.dart', **dart_colour('rowColor')),
}

# The Dart tools' own report of each reload.
RELOADED = re.compile(r'Reloaded (\d+) of (\d+) libraries in ([\d,.]+) ?ms'
                      r' \(compile: (\d+) ms, reload: (\d+) ms, reassemble: (\d+) ms\)')


def rgb_hex(text):
    """The last six hex digits, lower case: the colour without its alpha."""
    return text.strip().lstrip('#').lower()[-6:]


class Shown:
    """What the app reports: (time.perf_counter() on arrival, colour)."""

    def __init__(self):
        self.items = []
        self.cv = threading.Condition()

    def add(self, colour):
        with self.cv:
            self.items.append((time.perf_counter(), colour))
            self.cv.notify_all()

    def wait_for(self, colour, after, timeout):
        """The arrival time of the first report of colour after `after`, or None."""
        deadline = time.perf_counter() + timeout
        with self.cv:
            while True:
                for t, c in self.items:
                    if c == colour and t > after:
                        return t
                left = deadline - time.perf_counter()
                if left <= 0:
                    return None
                self.cv.wait(left)


SHOWN = Shown()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        query = parse_qs(urlparse(self.path).query)
        SHOWN.add(rgb_hex(query.get('colour', [''])[0]))
        self.send_response(204)
        self.end_headers()

    def log_message(self, *args):
        pass


class Listener(ThreadingHTTPServer):
    allow_reuse_address = True

    def server_bind(self):
        # Skips the host name lookup HTTPServer makes here; it is never used and
        # can take seconds.
        socketserver.TCPServer.server_bind(self)
        self.server_name, self.server_port = self.server_address[:2]


class Output:
    """Reads a process's output into a log file and keeps the lines."""

    def __init__(self, proc, log_path):
        self.lines = []
        self.closed = False
        self.cv = threading.Condition()
        self.log = open(log_path, 'w', encoding='utf-8')
        threading.Thread(target=self._read, args=(proc,), daemon=True).start()

    def _read(self, proc):
        for raw in proc.stdout:
            line = raw.decode('utf-8', 'replace').rstrip('\n')
            self.log.write(line + '\n')
            self.log.flush()
            with self.cv:
                self.lines.append(line)
                self.cv.notify_all()
        with self.cv:
            self.closed = True
            self.cv.notify_all()

    def wait_for(self, test, start=0, timeout=600):
        """The first line from index `start` on for which test(line) is true,
        as (index, value), or (None, None) after the timeout or once the
        process has ended."""
        deadline = time.monotonic() + timeout
        with self.cv:
            i = start
            while True:
                while i < len(self.lines):
                    value = test(self.lines[i])
                    if value:
                        return i, value
                    i += 1
                left = deadline - time.monotonic()
                if left <= 0 or self.closed:
                    return None, None
                self.cv.wait(left)


def daemon_message(match):
    """A test for Output.wait_for: the first daemon message for which match(message) is true."""
    def test(line):
        if not line.startswith('[{'):
            return None
        try:
            for message in json.loads(line):
                if match(message):
                    return message
        except ValueError:
            pass
        return None
    return test


def booted_simulator():
    out = subprocess.run(['xcrun', 'simctl', 'list', 'devices', 'booted', '-j'],
                         capture_output=True, text=True, check=True).stdout
    booted = [d for ds in json.loads(out)['devices'].values() for d in ds
              if d.get('state') == 'Booted']
    if len(booted) != 1:
        sys.exit(f'{len(booted)} simulators are booted; pass --device <simulator id>')
    return booted[0]['udid']


def first_line(cmd, **kw):
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=120, **kw)
        return (out.stdout or out.stderr).strip().splitlines()[0]
    except Exception as e:  # noqa: BLE001 - recorded as text, never fatal
        return f'unknown ({e})'


def environment(framework, device, tool):
    """The versions this session ran with, recorded beside its numbers."""
    sim = json.loads(subprocess.run(['xcrun', 'simctl', 'list', 'devices', '-j'],
                                    capture_output=True, text=True).stdout)
    name, runtime = device, ''
    for rt, ds in sim['devices'].items():
        for d in ds:
            if d['udid'] == device:
                name, runtime = d['name'], rt.split('.')[-1]
    env = dict(simulator=name, simulator_runtime=runtime,
               xcode=' '.join(subprocess.run(['xcodebuild', '-version'], capture_output=True,
                                             text=True).stdout.split()),
               mac=first_line(['sysctl', '-n', 'hw.model']),
               chip=first_line(['sysctl', '-n', 'machdep.cpu.brand_string']),
               macos=platform.mac_ver()[0])
    env['tool'] = shutil.which(tool) or tool
    env['tool_version'] = subprocess.run([tool, '--version'], capture_output=True,
                                         text=True).stdout.strip()
    return env


def session(args, device, tool, number):
    framework, app_name, route = args.framework, args.app, args.route
    app = APPS[(framework, app_name)]
    app_dir = os.path.join(ROOT, app['dir'])
    src_path = os.path.join(app_dir, app['src'])
    stamp = time.strftime('%Y%m%d-%H%M%S')
    base = os.path.join(args.out, f'{framework}-{app_name}-{route}-{stamp}')
    original = open(src_path, encoding='utf-8').read()
    line = re.compile(app['line'], re.M)
    m = line.search(original)
    if not m:
        sys.exit(f'no colour line in {src_path}')
    initial = rgb_hex(m.group(1))
    target = ['-t', app['target']] if app['target'] else []
    procs = []
    recorder = None
    app_id = None
    tool_pid = None
    session_start = time.perf_counter()
    print(f'[{framework} {app_name} {route}] session {number}: starting the app', flush=True)
    try:
        if route == 'editor':
            run = subprocess.Popen([tool, 'run', '--machine', '-d', device] + target,
                                   cwd=app_dir, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, start_new_session=True)
            procs.append(run)
            out = Output(run, base + '.tool.log')
            _, start = out.wait_for(daemon_message(lambda m: m.get('event') == 'app.start'),
                                    timeout=1200)
            _, started = out.wait_for(daemon_message(lambda m: m.get('event') == 'app.started'),
                                      timeout=1200)
            if not (start and started):
                sys.exit(f'[{framework}] the app did not start; see {base}.tool.log')
            app_id = start['params']['appId']
        else:
            pid_file = base + '.pid'
            run = subprocess.Popen([tool, 'run', '-d', device, '--pid-file', pid_file] + target,
                                   cwd=app_dir, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, start_new_session=True)
            procs.append(run)
            out = Output(run, base + '.tool.log')
        if SHOWN.wait_for(initial, session_start, 1200) is None:
            sys.exit(f'[{framework}] the app never reported its first frame; see {base}.tool.log')
        if route == 'terminal':
            _, ready = out.wait_for(lambda s: 'hot reload' in s.lower(), timeout=120)
            for _ in range(100):
                if os.path.exists(pid_file) and open(pid_file).read().strip():
                    break
                time.sleep(0.2)
            tool_pid = int(open(pid_file).read().strip())

        recorder = subprocess.Popen(['xcrun', 'simctl', 'io', device, 'recordVideo',
                                     '--codec=h264', '--force', base + '.mov'],
                                    stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True)
        video_start = None
        for text in recorder.stdout:
            if 'Recording started' in text:
                video_start = time.time()
                break
        if video_start is None:
            sys.exit(f'[{framework}] the screen recording did not start')
        time.sleep(5)  # the app idle on its screen before the first reload

        samples = []
        total = args.warmups + args.reloads
        for k in range(total):
            colour = COLOURS[k % len(COLOURS)]
            text = line.sub(app['write'].format(hex=colour), original, count=1)
            mark = len(out.lines)
            t0 = time.perf_counter()
            wall0 = time.time()
            with open(src_path, 'w', encoding='utf-8') as f:
                f.write(text)
            if route == 'editor':
                request = [dict(id=k + 1, method='app.restart',
                                params=dict(appId=app_id, fullRestart=False, pause=False,
                                            reason='save', debounce=True))]
                run.stdin.write((json.dumps(request) + '\n').encode())
                run.stdin.flush()
            else:
                os.kill(tool_pid, signal.SIGUSR1)
            t1 = SHOWN.wait_for(rgb_hex(colour), t0, RELOAD_TIMEOUT)
            if t1 is None:
                sys.exit(f'[{framework} {app_name} {route}] reload {k + 1}: the app never '
                         f'reported #{colour}; see {base}.tool.log')
            sample = dict(i=k + 1, warmup=k < args.warmups, colour=colour.lower(),
                          wall_save=wall0, app_reported_ms=round((t1 - t0) * 1000, 1))
            if route == 'editor':
                _, reply = out.wait_for(daemon_message(
                    lambda m: m.get('id') == k + 1 and ('result' in m or 'error' in m)),
                    start=mark, timeout=30)
                if not reply or reply.get('error') or reply['result'].get('code') != 0:
                    sys.exit(f'[{framework}] reload {k + 1} failed: {reply}')
            _, r = out.wait_for(lambda s: RELOADED.search(s), start=mark, timeout=10)
            if r:
                sample.update(libraries=int(r.group(1)), libraries_total=int(r.group(2)),
                              tool_ms=float(r.group(3).replace(',', '')),
                              compile_ms=int(r.group(4)), reload_ms=int(r.group(5)),
                              reassemble_ms=int(r.group(6)))
            samples.append(sample)
            print(f"[{framework} {app_name} {route}] "
                  f"{'warm-up' if sample['warmup'] else 'reload '} {k + 1:2d} #{colour}: "
                  f"reported by the app after {sample['app_reported_ms']:6.1f} ms", flush=True)
            time.sleep(args.gap)

        recorder.send_signal(signal.SIGINT)
        recorder.wait(timeout=60)
        recorder = None
        found = pixels.on_screen(base + '.mov', video_start, samples)
        for sample in samples:
            sample['save_to_screen_ms'] = found.get(sample['i'])
        measured = [s for s in samples if not s['warmup']]
        missing = [s['i'] for s in measured if s['save_to_screen_ms'] is None]
        if missing:
            print(f'[{framework}] the recording does not show the colour of reload(s) {missing}; '
                  'they are left out', flush=True)
        values = [s['save_to_screen_ms'] for s in measured if s['save_to_screen_ms'] is not None]
        result = dict(framework=framework, app=app_name, route=route, device=device,
                      edited_file=app['src'], video=os.path.basename(base + '.mov'),
                      video_start_wall=video_start, warmups=args.warmups, gap_s=args.gap,
                      environment=environment(framework, device, tool), samples=samples)
        with open(base + '.json', 'w', encoding='utf-8') as f:
            json.dump(result, f, indent=2)
        if values:
            print(f'[{framework} {app_name} {route}] session {number}: save to screen, median '
                  f'{statistics.median(values):.1f} ms over {len(values)} reloads', flush=True)
        print(f'[{framework} {app_name} {route}] {base}.json', flush=True)
    finally:
        with open(src_path, 'w', encoding='utf-8') as f:
            f.write(original)
        if recorder:
            recorder.send_signal(signal.SIGINT)
            recorder.wait(timeout=60)
        stop(procs, app_id)
        if route == 'terminal' and os.path.exists(base + '.pid'):
            os.remove(base + '.pid')


def stop(procs, app_id):
    for p in procs:
        if p.poll() is not None:
            continue
        try:
            if app_id:
                p.stdin.write((json.dumps([dict(id=9999, method='app.stop',
                                                params=dict(appId=app_id))]) + '\n').encode())
                p.stdin.flush()
                time.sleep(3)
                p.stdin.close()
                p.wait(timeout=15)
            else:
                p.stdin.write(b'q')
                p.stdin.flush()
                p.wait(timeout=15)
        except Exception:  # noqa: BLE001 - stopped below
            pass
        if p.poll() is None:
            try:
                os.killpg(p.pid, signal.SIGINT)
                p.wait(timeout=15)
            except Exception:  # noqa: BLE001
                p.kill()


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('framework', choices=['dartnative', 'flutter'])
    ap.add_argument('--app', choices=['small', 'medium'], default='small')
    ap.add_argument('--route', choices=['editor', 'terminal'], default='editor',
                    help='how a reload starts: from the editor or from the terminal')
    ap.add_argument('--device', help='the simulator id; default: the one booted simulator')
    ap.add_argument('--sessions', type=int, default=3)
    ap.add_argument('--reloads', type=int, default=10, help='measured reloads per session')
    ap.add_argument('--warmups', type=int, default=3, help='reloads before the measured ones')
    ap.add_argument('--gap', type=float, default=3.0, help='seconds between reloads')
    ap.add_argument('--dn', default='dn', help='the dn to run the DartNative app with')
    ap.add_argument('--flutter', default='flutter', help='the flutter to run the Flutter app with')
    ap.add_argument('--out', default=os.path.join(ROOT, 'results'))
    args = ap.parse_args()
    args.out = os.path.abspath(args.out)

    for needed in ('ffmpeg', 'ffprobe', 'xcrun'):
        if not shutil.which(needed):
            sys.exit(f'{needed} is not on PATH')
    device = args.device or booted_simulator()
    tool = {'dartnative': args.dn, 'flutter': args.flutter}[args.framework]
    os.makedirs(args.out, exist_ok=True)
    listener = Listener(('127.0.0.1', PORT), Handler)
    threading.Thread(target=listener.serve_forever, daemon=True).start()
    try:
        for n in range(1, args.sessions + 1):
            session(args, device, tool, n)
            time.sleep(5)
    finally:
        listener.shutdown()


if __name__ == '__main__':
    main()
