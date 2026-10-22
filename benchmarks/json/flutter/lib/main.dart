// The JSON benchmark, Flutter app. Its routes turn JSON into Dart objects the
// ways Flutter apps do: from bytes, or from a URL. bench_core.dart, the same
// file as in the DartNative app, times them.
//
//   flutter run --release --dart-define=cronetHttpNoPlay=true                         # decode
//   flutter run --release --dart-define=cronetHttpNoPlay=true --dart-define=MODE=fetch   # fetch
//   flutter run --release --dart-define=cronetHttpNoPlay=true --dart-define=MODE=loopback  # from a server in the app
//   flutter run --release --dart-define=cronetHttpNoPlay=true --dart-define=MODE=idle  # wait on another isolate
//
// cronetHttpNoPlay makes cronet_http bundle its own Cronet on Android, so the
// version measured is the package's, not the one Google Play Services installs
// on the phone.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'bench_core.dart';

const _mode = String.fromEnvironment('MODE', defaultValue: 'decode');
final _lines = ValueNotifier<List<String>>(const ['loading the files…']);

// Dart's fastest decoder in the standard library: UTF-8 decoding fused with
// JSON decoding, so the bytes become objects with no String in between.
final _fused = const Utf8Decoder().fuse(const JsonDecoder());

Object? _jsonDecode(String body) => jsonDecode(body);
Object? _jsonDecodeBytes(Uint8List bytes) => jsonDecode(utf8.decode(bytes));

// Work sent to a background isolate lives in top-level functions, so each
// closure captures only the value it sends.
Future<Object?> _computeJsonDecode(String body) => compute(_jsonDecode, body);
Future<Object?> _fusedInBackground(Uint8List bytes) => Isolate.run(() => _fused.convert(bytes));
Future<Object?> _jsonDecodeInIsolate(Uint8List bytes) => Isolate.run(() => _jsonDecodeBytes(bytes));
Future<Object?> _requestInBackground(Uri url) => Isolate.run(() => _requestAndDecode(url));

// The whole request on a background isolate: none of it runs on the main
// thread, but each call opens a new connection, with a new TLS handshake.
Future<Object?> _requestAndDecode(Uri url) async {
  final r = await http.get(url);
  if (r.statusCode != 200) throw StateError('status ${r.statusCode}');
  return _fused.convert(r.bodyBytes);
}

final List<DecodeRoute> _decodeRoutes = [
  // As Flutter's cookbook writes it: the bytes to a String first, then
  // jsonDecode.
  DecodeRoute('flutter jsonDecode', (bytes) => jsonDecode(utf8.decode(bytes))),
  // The best a careful developer writes: the fused decoder above.
  DecodeRoute('flutter fused', (bytes) => _fused.convert(bytes)),
  DecodeRoute('flutter compute(jsonDecode)', (bytes) => _computeJsonDecode(utf8.decode(bytes)), background: true),
  DecodeRoute('flutter fused in background', (bytes) => _fusedInBackground(bytes), background: true),
  // The same code in both apps, so the two Dart VMs can be compared.
  DecodeRoute('dart Isolate.run(jsonDecode) (reference)', (bytes) => _jsonDecodeInIsolate(bytes), background: true),
];

// No HTTP cache on any client: every request goes to the network. _platform
// is the platform's own networking: cupertino_http on iOS, cronet_http on
// Android.
final http.Client _io = http.Client();
final http.Client _platform = Platform.isIOS
    ? CupertinoClient.fromSessionConfiguration(URLSessionConfiguration.ephemeralSessionConfiguration()..cache = null)
    : CronetClient.fromCronetEngine(CronetEngine.build(cacheMode: CacheMode.disabled), closeEngine: true);

// Waits for the response and throws unless its status is 200.
Future<http.Response> _ok(Future<http.Response> response) async {
  final r = await response;
  if (r.statusCode != 200) throw StateError('status ${r.statusCode}');
  return r;
}

final List<FetchRoute> _fetchRoutes = [
  // As Flutter's cookbook writes it: package:http, response.body, then
  // compute(jsonDecode).
  FetchRoute('flutter http + compute', (url) async => _computeJsonDecode((await _ok(_io.get(url))).body)),
  // What a careful developer may write instead. The README reports the first
  // as Flutter's best case and the platform client on a row of its own; it
  // describes the whole request in the background but leaves it out of the
  // tables.
  FetchRoute('flutter http + fused in background', (url) async => _fusedInBackground((await _ok(_io.get(url))).bodyBytes)),
  FetchRoute(Platform.isIOS ? 'flutter cupertino_http + fused in background' : 'flutter cronet_http + fused in background',
      (url) async => _fusedInBackground((await _ok(_platform.get(url))).bodyBytes)),
  FetchRoute('flutter request in background + fused', _requestInBackground),
  dartIoReference,
];

void main() {
  runApp(const BenchApp());
  _run();
}

Future<void> _run() async {
  final files = await loadBenchFiles();
  void log(String line) {
    print(line); // ignore: avoid_print
    // Only the summary lines and the lines starting with '#' reach the screen,
    // so it redraws between files and never during a file's rounds.
    if (line.startsWith('summary') || line.startsWith('#')) _lines.value = [..._lines.value, line];
  }

  if (_mode == 'idle') {
    await runIdleBench('JSON (Flutter)', log: log);
  } else if (_mode == 'fetch' || _mode == 'loopback') {
    await runFetchBench('JSON (Flutter)', _fetchRoutes, files, loopback: _mode == 'loopback', log: log);
  } else {
    await runDecodeBench('JSON (Flutter)', _decodeRoutes, files, log: log);
  }
}

class BenchApp extends StatelessWidget {
  const BenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSON (Flutter)',
      home: Scaffold(
        appBar: AppBar(title: const Text('JSON (Flutter)')),
        body: ValueListenableBuilder<List<String>>(
          valueListenable: _lines,
          builder: (context, lines, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final l in lines) Text(l, style: const TextStyle(fontSize: 12))],
          ),
        ),
      ),
    );
  }
}
