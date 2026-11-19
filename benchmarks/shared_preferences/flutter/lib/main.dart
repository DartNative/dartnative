// Flutter side of dartnative_shared_preferences' benchmark: the plugin
// example's lib/benchmark/ copied in, two lines changed (see prefs_cases.dart),
// run with `flutter run --profile`. Same output as the DartNative side.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'benchmark/prefs_cases.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // A black screen with black system bars, as the DartNative side's.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF000000),
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: Color(0xFF000000),
      child: Center(
        child: Text('Running the benchmark…',
            style: TextStyle(color: Color(0xFFFFFFFF))),
      ),
    ),
  ));
  WidgetsBinding.instance.addPostFrameCallback((_) => _run());
}

Future<void> _run() async {
  final out = File('${Directory.systemTemp.path}/prefs_bench.txt');
  if (out.existsSync()) out.deleteSync();
  try {
    final rows = await runPrefsBenchmarks();
    print('[PREFS_BENCH] === TABLE: every case (copy from here) ===');
    for (final line in rowsAsMarkdown(rows).trimRight().split('\n')) {
      print('[PREFS_BENCH] $line');
    }
    print('[PREFS_BENCH] === TABLE: every case (copy to here) ===');
    print('[PREFS_BENCH] DONE: ${rows.length} rows');
    // Also to tmp/, for a run launched without the Flutter tool attached.
    out.writeAsStringSync('${rowsAsMarkdown(rows)}DONE: ${rows.length} rows\n');
  } catch (error, stackTrace) {
    print('[PREFS_BENCH] FAIL: $error\n$stackTrace');
  }
}
