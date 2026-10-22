// The measuring code of the JSON benchmark, shared by both apps.
// flutter/lib/bench_core.dart and dartnative/lib/bench_core.dart are copies of
// shared/bench_core.dart: edit only that file, then run `tool/sync_shared.sh`,
// which copies it into both apps and checks with `cmp` that the copies match.
// The two apps differ only in the routes (ways to decode or fetch) they pass in.
//
// Four modes:
//   decode    each route turns the same bytes into Dart objects;
//   fetch     each route downloads a file over HTTPS from GitHub's CDN and
//             decodes it;
//   loopback  the same, from a server inside the app on 127.0.0.1: the network
//             part takes about 0.1 ms, so it measures the HTTP client alone;
//   idle      the calling isolate waits for another isolate's answer and does
//             nothing else, which shows what the app runs on its thread meanwhile.
//
// Before timing, each route's result is checked against
// jsonDecode(utf8.decode(bytes)): same values, same Dart types, same key order,
// same sign of zero. Then the routes run in rounds: each route once per round,
// in a new order every round, with a short pause between calls. The first
// rounds are a warm-up: they get one-time costs (first use of the code, opening
// connections) out of the way, and their samples are dropped. Every kept sample
// is printed and written to a file; the summary gives the median with the 10th
// and 90th percentiles.
//
// Measuring starts only after a pause of [benchSettle], so the work of launch
// (the first frame, the runtime's own start-up tasks) is over. Samples stay in
// memory during a file's rounds and are printed (and written) after them, so
// nothing is printed or written while the rounds run.
//
// Each call should start with the CPU at full speed. A phone sets its CPU's
// speed from the app's recent work: without care, the routes an app runs would
// set the speed its other routes are measured at, and the app whose routes
// finish sooner would be measured on a slower CPU. So after the settle pause
// the calling thread does busy work for [benchBurnIn] (the burn-in), and the
// fastest a fixed slice of that work ran gives the CPU's full speed. Right
// before each call it does busy work for [benchWarm], then keeps going until a
// slice runs within 10% of full speed, for at most [benchWarmMax] in all.
//
// Measures per call:
//   main ms   CPU time of the thread running this isolate, from the call until
//             the objects are back. In both frameworks this is the app's main
//             thread (each run's header names the thread).
//   app ms    CPU time of the whole app, all threads, over the same span.
//   wall ms   real time from the call until the objects are back.
//   sync ms   real time until the call returns (its synchronous part). For a
//             route that works in the background, this is how long the call
//             keeps the calling isolate busy before it hands the work over.
//   after ms  CPU time of the whole app in the pause after the call. Work a
//             route leaves running once its result is back (an isolate ending,
//             another starting) counts against that route.
//   cpu ms    how long the last slice of busy work before the call took. The
//             run's header gives the full-speed figure; a sample close to it
//             started at full speed.
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

/// A way to turn bytes into Dart objects.
class DecodeRoute {
  const DecodeRoute(this.name, this.run, {this.background = false});

  final String name;

  /// Returns the objects, or a Future of them for a background route.
  final Object? Function(Uint8List bytes) run;

  /// Whether the route hands the decoding to a background isolate.
  final bool background;
}

/// A way to fetch a URL and turn its JSON into Dart objects.
class FetchRoute {
  const FetchRoute(this.name, this.run);

  final String name;
  final Future<Object?> Function(Uri url) run;
}

/// Measured rounds per file, after the warm-up rounds. Pass
/// `--dart-define=ROUNDS=3` for a quick check.
const benchRounds = int.fromEnvironment('ROUNDS', defaultValue: 30);

/// Where the standard JSON benchmark files come from: the simdjson-data
/// repository, served by GitHub's CDN. The address names one commit, so every
/// run reads the same bytes.
const benchBase =
    'https://raw.githubusercontent.com/simdjson/simdjson-data/4197c425e857f0ec38e89822fdd0bd9ea21f4daf/jsonexamples';

/// The pause before measuring starts, so the work of launch is over.
const benchSettle = Duration(seconds: 3);

/// How long the calling thread does busy work after the settle pause, to find
/// the CPU's full speed (the burn-in).
const benchBurnIn = Duration(seconds: 3);

/// Before each call the calling thread does busy work for at least
/// [benchWarm], then until the CPU is at full speed, for at most
/// [benchWarmMax] in all.
const benchWarm = Duration(milliseconds: 10);
const benchWarmMax = Duration(milliseconds: 100);
const benchFiles = ['github_events.json', 'twitter.json', 'citm_catalog.json', 'canada.json'];

/// Where the results go besides the console: a file in the app's temporary
/// folder, because an iOS release build prints nothing to the console.
final File benchOut = File('${Directory.systemTemp.path}/json_bench.txt');

void Function(String line) _sink = print;

/// Sends [line] to the log and appends it to [benchOut].
void benchLog(String line) {
  _sink(line);
  benchOut.writeAsStringSync('$line\n', mode: FileMode.append);
}

/// Runs the decode mode: times every route on each of [files] (name → bytes).
Future<void> runDecodeBench(
  String app,
  List<DecodeRoute> routes,
  Map<String, Uint8List> files, {
  int warmup = 3,
  int rounds = benchRounds,
  void Function(String line)? log,
}) async {
  _sink = log ?? print;
  benchOut.writeAsStringSync('');
  await Future<void>.delayed(benchSettle);
  _burnIn();
  _header(app, 'decode', warmup, rounds);
  for (final entry in files.entries) {
    final bytes = entry.value;
    final expected = jsonDecode(utf8.decode(bytes));
    for (final r in routes) {
      final value = await _call(r.run, bytes);
      final d = differ(value, expected, r'$');
      if (d != null) throw StateError('${r.name} differs on ${entry.key}: $d');
    }
    final samples = {for (final r in routes) r.name: <_Sample>[]};
    final lines = <String>[];
    final random = math.Random(1);
    for (var round = 0; round < warmup + rounds; round++) {
      for (final r in routes.toList()..shuffle(random)) {
        final s = await _measure(() => r.run(bytes));
        await _pause(s);
        if (round >= warmup) {
          samples[r.name]!.add(s);
          lines.add('sample,decode,${entry.key},${r.name},${round - warmup},${s.csv}');
        }
      }
    }
    lines.forEach(benchLog);
    _summary('decode', entry.key, routes.map((r) => (r.name, r.background)), samples);
  }
  _done();
}

/// A route with the same code in both apps: dart:io's HttpClient, then Dart's
/// jsonDecode on a background isolate. Its time to the data shows whether the
/// network behaved the same while each app ran.
final FetchRoute dartIoReference = FetchRoute('dart:io HttpClient + Isolate.run(jsonDecode) (reference)', _dartIoFetch);

final HttpClient _io = HttpClient();

Future<Object?> _dartIoFetch(Uri url) async {
  final request = await _io.getUrl(url);
  final response = await request.close();
  final builder = BytesBuilder(copy: false);
  await response.forEach(builder.add);
  if (response.statusCode != 200) throw StateError('status ${response.statusCode}');
  return _decodeInIsolate(builder.takeBytes());
}

Future<Object?> _decodeInIsolate(Uint8List bytes) => Isolate.run(() => jsonDecode(utf8.decode(bytes)));

/// Starts an HTTP server on 127.0.0.1, on an isolate of its own, and returns
/// its base URL. It serves [files] gzipped, as the CDN serves them. Through it
/// the network part takes about 0.1 ms, so a fetch measures the client alone.
Future<String> startLoopbackServer(Map<String, Uint8List> files) async {
  final ready = ReceivePort();
  await Isolate.spawn(_serve, <Object?>[ready.sendPort, files], debugName: 'loopback server');
  final port = await ready.first as int;
  return 'http://127.0.0.1:$port';
}

Future<void> _serve(List<Object?> start) async {
  final bodies = {
    for (final MapEntry(:key, :value) in (start[1]! as Map<String, Uint8List>).entries) key: gzip.encode(value),
  };
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.autoCompress = false;
  (start[0]! as SendPort).send(server.port);
  await for (final request in server) {
    final body = bodies[request.uri.pathSegments.isEmpty ? '' : request.uri.pathSegments.last];
    final response = request.response;
    if (body == null) {
      response.statusCode = HttpStatus.notFound;
    } else {
      response.headers
        ..set(HttpHeaders.contentTypeHeader, 'text/plain; charset=utf-8')
        ..set(HttpHeaders.contentEncodingHeader, 'gzip');
      response.contentLength = body.length;
      response.add(body);
    }
    await response.close();
  }
}

/// Runs the fetch mode over the benchmark files. [files] (name → bytes, from
/// [loadBenchFiles]) give the objects each route must return. With [loopback]
/// the files come from [startLoopbackServer] instead of the CDN.
Future<void> runFetchBench(
  String app,
  List<FetchRoute> routes,
  Map<String, Uint8List> files, {
  int warmup = 3,
  int rounds = benchRounds,
  bool loopback = false,
  void Function(String line)? log,
}) async {
  _sink = log ?? print;
  benchOut.writeAsStringSync('');
  final base = loopback ? await startLoopbackServer(files) : benchBase;
  final mode = loopback ? 'loopback' : 'fetch';
  await Future<void>.delayed(benchSettle);
  _burnIn();
  _header(app, mode, warmup, rounds);
  for (final name in files.keys) {
    final url = Uri.parse('$base/$name');
    final expected = jsonDecode(utf8.decode(files[name]!));
    for (final r in routes) {
      final d = differ(await r.run(url), expected, r'$');
      if (d != null) throw StateError('${r.name} differs on $name: $d');
    }
    final samples = {for (final r in routes) r.name: <_Sample>[]};
    final lines = <String>[];
    final random = math.Random(1);
    for (var round = 0; round < warmup + rounds; round++) {
      for (final r in routes.toList()..shuffle(random)) {
        final s = await _measure(() => r.run(url));
        await _pause(s);
        if (round >= warmup) {
          samples[r.name]!.add(s);
          lines.add('sample,$mode,$name,${r.name},${round - warmup},${s.csv}');
        }
      }
    }
    lines.forEach(benchLog);
    _summary(mode, name, routes.map((r) => (r.name, false)), samples);
  }
  _done();
}

/// How long the idle mode's helper isolate waits before it answers, in ms.
const benchIdleWaits = [1, 10, 30, 100];

/// Runs the idle mode. The calling isolate sends one message to a helper
/// isolate, which answers after a fixed wait (as a request handed to a
/// background isolate would), and does nothing else until the answer comes.
/// The CPU time its thread uses during the wait is what the app itself runs
/// on that thread while it waits.
Future<void> runIdleBench(
  String app, {
  int warmup = 3,
  int rounds = benchRounds,
  void Function(String line)? log,
}) async {
  _sink = log ?? print;
  benchOut.writeAsStringSync('');
  final ready = ReceivePort();
  final isolate = await Isolate.spawn(_answerAfter, ready.sendPort, debugName: 'idle answerer');
  final answerer = await ready.first as SendPort;
  await Future<void>.delayed(benchSettle);
  _burnIn();
  _header(app, 'idle', warmup, rounds);
  for (final ms in benchIdleWaits) {
    final samples = <_Sample>[];
    final lines = <String>[];
    for (var round = 0; round < warmup + rounds; round++) {
      final s = await _measure(() {
        final reply = ReceivePort();
        answerer.send([reply.sendPort, ms]);
        return reply.first.whenComplete(reply.close);
      });
      await _pause(s);
      if (round >= warmup) {
        samples.add(s);
        lines.add('sample,idle,${ms}ms,wait,${round - warmup},${s.csv}');
      }
    }
    lines.forEach(benchLog);
    _summary('idle', '${ms}ms', [('wait', false)], {'wait': samples});
  }
  isolate.kill();
  _done();
}

// The idle mode's helper isolate: for each message it sleeps the given ms,
// then answers.
void _answerAfter(SendPort ready) {
  final port = RawReceivePort();
  port.handler = (Object? message) {
    final m = message! as List<Object?>;
    sleep(Duration(milliseconds: m[1]! as int));
    (m[0]! as SendPort).send(null);
  };
  ready.send(port.sendPort);
}

Future<Object?> _call(Object? Function(Uint8List) run, Uint8List bytes) async {
  final v = run(bytes);
  return v is Future ? await v : v;
}

/// One call's measures, in ms, as described at the top of this file ([ui] is
/// the "main ms" column).
final class _Sample {
  _Sample(this.ui, this.app, this.wall, this.sync, this.cpu, this.appEnd);

  final double ui, app, wall, sync, cpu;

  /// The app's CPU clock when the result came back. [_pause] uses it to set
  /// [after], the app's CPU time in the pause that follows.
  final double appEnd;
  double after = 0;

  String get csv => '${ui.toStringAsFixed(3)},${app.toStringAsFixed(3)},'
      '${wall.toStringAsFixed(3)},${sync.toStringAsFixed(3)},${cpu.toStringAsFixed(3)},${after.toStringAsFixed(3)}';
}

// The pause between calls. The app's CPU time during it is charged to the call
// just before, as its "after ms".
Future<void> _pause(_Sample s) async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
  s.after = _cpuMs(_processClock) - s.appEnd;
}

// The busy work's running value. Keeping it between calls gives the work a
// result that is used, so the compiler cannot drop the work.
int _warmState = 1;

/// The shortest time one slice of busy work took in the burn-in, in ms: the
/// CPU's full speed.
double _fullSpeed = double.infinity;

// Busy work in slices of a fixed size (integer shifts and xors). It runs for at
// least [least], then until a slice runs within 10% of [_fullSpeed], and stops
// once [most] has passed in any case. Returns how long the last slice took.
double _work(Duration least, Duration most) {
  final sw = Stopwatch()..start();
  var x = _warmState;
  var slice = 0.0;
  while (true) {
    final s0 = sw.elapsedMicroseconds;
    for (var i = 0; i < 20000; i++) {
      x ^= (x << 13) & 0xFFFFFFFF;
      x ^= x >> 17;
      x ^= (x << 5) & 0xFFFFFFFF;
    }
    final t = sw.elapsedMicroseconds;
    slice = (t - s0) / 1000;
    if (t >= most.inMicroseconds) break;
    if (t >= least.inMicroseconds && slice <= _fullSpeed * 1.1) break;
  }
  _warmState = x | 1;
  return slice;
}

double _warmUp() => _work(benchWarm, benchWarmMax);

// Finds [_fullSpeed]: runs one slice after another for [benchBurnIn] and keeps
// the fastest.
void _burnIn() {
  final end = Stopwatch()..start();
  while (end.elapsed < benchBurnIn) {
    final slice = _work(Duration.zero, Duration.zero);
    if (slice < _fullSpeed) _fullSpeed = slice;
  }
}

// Brings the CPU to full speed, then times one call.
Future<_Sample> _measure(Object? Function() call) async {
  final cpu = _warmUp();
  final t0 = _cpuMs(_threadClock), p0 = _cpuMs(_processClock);
  final sw = Stopwatch()..start();
  final v = call();
  final sync = sw.elapsedMicroseconds / 1000;
  if (v is Future) await v;
  final wall = sw.elapsedMicroseconds / 1000;
  final p1 = _cpuMs(_processClock);
  return _Sample(_cpuMs(_threadClock) - t0, p1 - p0, wall, sync, cpu, p1);
}

// Prints one line per route: each measure's median, with the 10th and 90th
// percentiles in brackets.
void _summary(String mode, String file, Iterable<(String, bool)> routes, Map<String, List<_Sample>> samples) {
  benchLog('summary,$mode,$file: route, main ms, app ms, wall ms, sync ms, after ms (median [p10-p90])');
  for (final (name, _) in routes) {
    final s = samples[name]!;
    String col(double Function(_Sample) f) {
      final v = s.map(f).toList()..sort();
      double at(double q) => v[((v.length - 1) * q).round()];
      return '${at(0.5).toStringAsFixed(2)} [${at(0.1).toStringAsFixed(2)}-${at(0.9).toStringAsFixed(2)}]';
    }

    benchLog('summary,$mode,$file,$name, ${col((x) => x.ui)}, ${col((x) => x.app)}, '
        '${col((x) => x.wall)}, ${col((x) => x.sync)}, ${col((x) => x.after)}');
  }
}

void _header(String app, String mode, int warmup, int rounds) {
  final power = _powerState();
  benchLog('# $app, $mode, ${Platform.operatingSystem} ${Platform.operatingSystemVersion}, '
      'Dart ${Platform.version.split(' ').first}, ${_threadName()}, ${power.isEmpty ? '' : '$power, '}'
      '$rounds rounds after $warmup, a new order each round from a fixed seed, '
      'CPU at full speed: a slice in ${_fullSpeed.toStringAsFixed(3)} ms');
  benchLog('sample,mode,file,route,round,main_ms,app_ms,wall_ms,sync_ms,cpu_ms,after_ms');
}

void _done() {
  final power = _powerState();
  benchLog('# done${power.isEmpty ? '' : ', at the end: $power'}');
}

// On iOS, reads Low Power Mode and the thermal state from NSProcessInfo, since
// both slow the CPU. A run counts only with Low Power Mode off and the thermal
// state "nominal", at the start and at the end. On Android these are read from
// the computer (adb), so this returns an empty string there.
String _powerState() {
  if (!Platform.isIOS) return '';
  final lib = DynamicLibrary.process();
  final getClass = lib.lookupFunction<Pointer<Void> Function(Pointer<Uint8>), Pointer<Void> Function(Pointer<Uint8>)>(
      'objc_getClass');
  final selector = lib.lookupFunction<Pointer<Void> Function(Pointer<Uint8>), Pointer<Void> Function(Pointer<Uint8>)>(
      'sel_registerName');
  final sendObject = lib.lookupFunction<Pointer<Void> Function(Pointer<Void>, Pointer<Void>),
      Pointer<Void> Function(Pointer<Void>, Pointer<Void>)>('objc_msgSend');
  final sendBool = lib.lookupFunction<Bool Function(Pointer<Void>, Pointer<Void>), bool Function(Pointer<Void>, Pointer<Void>)>(
      'objc_msgSend');
  final sendInt = lib.lookupFunction<IntPtr Function(Pointer<Void>, Pointer<Void>), int Function(Pointer<Void>, Pointer<Void>)>(
      'objc_msgSend');
  final malloc = lib.lookupFunction<Pointer<Void> Function(IntPtr), Pointer<Void> Function(int)>('malloc');
  Pointer<Uint8> cString(String s) {
    final p = malloc(s.length + 1).cast<Uint8>();
    p.asTypedList(s.length + 1)
      ..setAll(0, ascii.encode(s))
      ..[s.length] = 0;
    return p;
  }

  final info = sendObject(getClass(cString('NSProcessInfo')), selector(cString('processInfo')));
  final lowPower = sendBool(info, selector(cString('isLowPowerModeEnabled')));
  final thermal = sendInt(info, selector(cString('thermalState')));
  const states = ['nominal', 'fair', 'serious', 'critical'];
  return 'Low Power Mode ${lowPower ? 'on' : 'off'}, thermal state '
      '${thermal >= 0 && thermal < states.length ? states[thermal] : thermal}';
}

// Describes the thread running this isolate: whether it is the process's main
// thread (pthread_main_np on iOS; on Android, the main thread's id equals the
// process id), and its name (pthread_getname_np; iOS leaves the main thread
// unnamed).
String _threadName() {
  final lib = DynamicLibrary.process();
  final bool main;
  if (Platform.isIOS) {
    main = lib.lookupFunction<Int32 Function(), int Function()>('pthread_main_np')() != 0;
  } else {
    final gettid = lib.lookupFunction<Int32 Function(), int Function()>('gettid');
    main = gettid() == pid;
  }
  final self = lib.lookupFunction<IntPtr Function(), int Function()>('pthread_self');
  final getName = lib.lookupFunction<Int32 Function(IntPtr, Pointer<Uint8>, IntPtr),
      int Function(int, Pointer<Uint8>, int)>('pthread_getname_np');
  final malloc = lib.lookupFunction<Pointer<Void> Function(IntPtr), Pointer<Void> Function(int)>('malloc');
  final buffer = malloc(64).cast<Uint8>();
  var name = '';
  if (getName(self(), buffer, 64) == 0) {
    final bytes = buffer.asTypedList(64);
    final end = bytes.indexOf(0);
    name = utf8.decode(bytes.sublist(0, end < 0 ? 64 : end));
  }
  return '${main ? 'main thread' : 'not the main thread'}${name.isEmpty ? '' : ', $name'}';
}

// CPU time clocks, read with clock_gettime from the C library. The clock ids
// differ between iOS and Android.
final _clockGettime = DynamicLibrary.process()
    .lookupFunction<Int32 Function(Int32, Pointer<Int64>), int Function(int, Pointer<Int64>)>('clock_gettime',
        isLeaf: true);
final _threadClock = Platform.isIOS ? 16 : 3; // CLOCK_THREAD_CPUTIME_ID
final _processClock = Platform.isIOS ? 12 : 2; // CLOCK_PROCESS_CPUTIME_ID
final Pointer<Int64> _ts = _alloc16();

Pointer<Int64> _alloc16() {
  final malloc = DynamicLibrary.process()
      .lookupFunction<Pointer<Void> Function(IntPtr), Pointer<Void> Function(int)>('malloc');
  return malloc(16).cast<Int64>();
}

double _cpuMs(int clock) {
  _clockGettime(clock, _ts);
  return _ts[0] * 1e3 + _ts[1] / 1e6;
}

/// Describes the first place where [a] and [b] differ, or returns null when
/// they hold the same values with the same Dart types (key order and the sign
/// of zero included; NaN matches NaN). [path] names the place in messages.
String? differ(Object? a, Object? b, String path) {
  if (a.runtimeType != b.runtimeType) return '$path: ${a.runtimeType} vs ${b.runtimeType}';
  if (a is Map<String, dynamic>) {
    final m = b! as Map<String, dynamic>;
    final ka = a.keys.toList(), kb = m.keys.toList();
    if (ka.length != kb.length) return '$path: ${ka.length} keys vs ${kb.length}';
    for (var i = 0; i < ka.length; i++) {
      if (ka[i] != kb[i]) return '$path: key $i ${ka[i]} vs ${kb[i]}';
      final d = differ(a[ka[i]], m[kb[i]], '$path.${ka[i]}');
      if (d != null) return d;
    }
    return null;
  }
  if (a is List<dynamic>) {
    final l = b! as List<dynamic>;
    if (a.length != l.length) return '$path: length ${a.length} vs ${l.length}';
    for (var i = 0; i < a.length; i++) {
      final d = differ(a[i], l[i], '$path[$i]');
      if (d != null) return d;
    }
    return null;
  }
  if (a is double) {
    final y = b! as double;
    if (a.isNaN && y.isNaN) return null;
    return a == y && a.isNegative == y.isNegative ? null : '$path: $a vs $y';
  }
  return a == b ? null : '$path: $a vs $b';
}

/// Fetches the benchmark files once with dart:io, before any timing, and
/// returns them by name.
Future<Map<String, Uint8List>> loadBenchFiles() async {
  final client = HttpClient();
  final files = <String, Uint8List>{};
  try {
    for (final name in benchFiles) {
      final request = await client.getUrl(Uri.parse('$benchBase/$name'));
      final response = await request.close();
      final builder = BytesBuilder(copy: false);
      await response.forEach(builder.add);
      files[name] = builder.takeBytes();
    }
  } finally {
    client.close();
  }
  return files;
}
