// The shared_preferences benchmark, DartNative app. Runs every case of
// lib/benchmark/, the same files as in the Flutter app with two lines changed,
// on launch, and prints the table in one block:
//
//   dn run --profile                           # the table in the console
//   dn build ios --profile                     # or: dn build apk --profile
//
// The table also goes to prefs_bench.txt in the app's temporary folder (tmp/
// in its container on iOS, cache/ on Android), for a run launched without the
// tool attached: ../tool/run_ios.sh and ../tool/run_android.sh read it there.
//
// The store is cleared before every round and at the end.
import 'dart:io';

import 'package:dartnative/dartnative.dart';

import 'benchmark/prefs_cases.dart';
import 'dartnative_plugin_registrant.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const _BenchmarkApp());
}

final class _BenchmarkApp extends StatefulWidget {
  const _BenchmarkApp();

  @override
  State<_BenchmarkApp> createState() => _BenchmarkAppState();
}

final class _BenchmarkAppState extends State<_BenchmarkApp> {
  String _status = 'Running the benchmark…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final out = File('${Directory.systemTemp.path}/prefs_bench.txt');
    if (out.existsSync()) out.deleteSync();
    try {
      final rows = await runPrefsBenchmarks();
      _printTable('every case', rowsAsMarkdown(rows));
      print('[PREFS_BENCH] DONE: ${rows.length} rows');
      out.writeAsStringSync('${rowsAsMarkdown(rows)}DONE: ${rows.length} rows\n');
      if (mounted) {
        setState(() => _status = 'Done: ${rows.length} rows. '
            'The table is in the console.');
      }
    } catch (error, stackTrace) {
      print('[PREFS_BENCH] FAIL: $error\n$stackTrace');
      if (mounted) setState(() => _status = 'Benchmark failed: $error');
    }
  }

  /// One block, nothing interleaved, so it copies straight out of the
  /// console.
  void _printTable(String name, String markdown) {
    print('[PREFS_BENCH] === TABLE: $name (copy from here) ===');
    for (final line in markdown.trimRight().split('\n')) {
      print('[PREFS_BENCH] $line');
    }
    print('[PREFS_BENCH] === TABLE: $name (copy to here) ===');
  }

  // A black screen with black system bars, as the Flutter side's.
  static const _black = Color(0xFF000000);

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: _black,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: _black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: _black,
          body: Center(
            child: Text(
              _status,
              style: const TextStyle(color: Color(0xFFFFFFFF)),
            ),
          ),
        ),
      );
}
