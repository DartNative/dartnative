// The JSON benchmark, DartNative app. Its routes turn JSON into Dart objects
// with DartNative: from bytes with the framework's decoder, or from a URL with
// dartnative_http. bench_core.dart, the same file as in the Flutter app, times
// them.
//
//   dn run --release                               # decode
//   dn run --release --dart-define=MODE=fetch      # fetch from the CDN and decode
//   dn run --release --dart-define=MODE=loopback   # the same, from a server in the app
//   dn run --release --dart-define=MODE=idle       # wait on another isolate
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_http/http.dart';

import 'bench_core.dart';
import 'dartnative_plugin_registrant.dart';

const _mode = String.fromEnvironment('MODE', defaultValue: 'decode');
final _lines = ValueNotifier<List<String>>(const ['loading the files…']);

final List<DecodeRoute> _decodeRoutes = [
  // Dart's own decoder on this app's Dart VM, as a reference. The Flutter app
  // runs the same code, so this shows whether the two apps' VMs decode at the
  // same speed, and any other gap comes from the decoder.
  DecodeRoute('dart jsonDecode (reference)', (bytes) => jsonDecode(utf8.decode(bytes))),
  // DartNative's decoder, on the calling isolate and on a background isolate.
  DecodeRoute('dartnative jsonDecodeNative', jsonDecodeNative),
  DecodeRoute('dartnative jsonDecodeInBackground', jsonDecodeInBackground, background: true),
  // The same code in both apps, so the two Dart VMs can be compared.
  DecodeRoute('dart Isolate.run(jsonDecode) (reference)', (bytes) => _jsonDecodeInIsolate(bytes), background: true),
];

// Top-level functions, so the closure sent to the background isolate captures
// only the bytes.
Object? _jsonDecodeBytes(Uint8List bytes) => jsonDecode(utf8.decode(bytes));
Future<Object?> _jsonDecodeInIsolate(Uint8List bytes) => Isolate.run(() => _jsonDecodeBytes(bytes));

// No HTTP cache and no cookie store: every request goes to the network, as
// with the Flutter app's clients.
final _client = NativeHttpClient(cache: false, cookies: false);

final List<FetchRoute> _fetchRoutes = [
  // The two ways DartNative's docs show. getJson runs the whole request and
  // the decoding on a background isolate; get returns the response first, and
  // jsonDecodeInBackground then decodes its body on a background isolate.
  FetchRoute('dartnative_http getJson', (url) async {
    final response = await _client.getJson(url);
    if (response.statusCode != 200) throw StateError('status ${response.statusCode}');
    return response.json;
  }),
  FetchRoute('dartnative_http + jsonDecodeInBackground', (url) async {
    final response = await _client.get(url);
    if (response.statusCode != 200) throw StateError('status ${response.statusCode}');
    return jsonDecodeInBackground(response.bodyBytes);
  }),
  dartIoReference,
];

void main() {
  DartNativePluginRegistrant.registerAll();
  // Code push is off: its update check at launch is network work on this
  // isolate.
  runApp(const BenchApp(), codePush: false);
  _run();
}

Future<void> _run() async {
  final files = await loadBenchFiles();
  void log(String line) {
    print(line);
    // Only the summary lines and the lines starting with '#' reach the screen,
    // so it redraws between files and never during a file's rounds.
    if (line.startsWith('summary') || line.startsWith('#')) _lines.value = [..._lines.value, line];
  }

  if (_mode == 'idle') {
    await runIdleBench('JSON (DN)', log: log);
  } else if (_mode == 'fetch' || _mode == 'loopback') {
    await runFetchBench('JSON (DN)', _fetchRoutes, files, loopback: _mode == 'loopback', log: log);
  } else {
    await runDecodeBench('JSON (DN)', _decodeRoutes, files, log: log);
  }
}

class BenchApp extends StatelessWidget {
  const BenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.light,
      appBar: AppBar(title: const Text('JSON (DN)')),
      backgroundColor: const Color(0xFFFFFFFF),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: _lines,
        builder: (context, lines, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [for (final l in lines) Text(l, style: const TextStyle(fontSize: 12))],
        ),
      ),
    );
  }
}
