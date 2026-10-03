import 'package:dartnative/dartnative.dart';

import 'benchmark/hive_ce_benchmark.dart';
import 'benchmark/hive_cases.dart';
import 'dartnative_plugin_registrant.dart';

/// Runs hive_ce's own benchmark, then every case of ours, on launch, and
/// prints each table in one block, ready to paste into a results document;
/// the chart (`tool/generate_benchmark_chart.dart`) is drawn from the first:
///
///     dn run --profile -t lib/benchmark_main.dart
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
    try {
      final official = [
        ...await runHiveCeBenchmark(mapped: false),
        ...await runHiveCeBenchmark(mapped: true),
      ];
      _printTable("hive_ce's benchmark", hiveCeAsMarkdown(official));
      final rows = await runBackendComparison();
      _printTable('every case', comparisonAsMarkdown(rows));
      print('[HIVE_BENCH] DONE: ${rows.length} rows');
      if (mounted) {
        setState(() => _status = 'Done: ${rows.length} rows. '
            'The table is in the console.');
      }
    } catch (error, stackTrace) {
      print('[HIVE_BENCH] FAIL: $error\n$stackTrace');
      if (mounted) setState(() => _status = 'Benchmark failed: $error');
    }
  }

  /// One block, nothing interleaved, so it copies straight out of the
  /// console.
  void _printTable(String name, String markdown) {
    print('[HIVE_BENCH] === TABLE: $name (copy from here) ===');
    for (final line in markdown.trimRight().split('\n')) {
      print('[HIVE_BENCH] $line');
    }
    print('[HIVE_BENCH] === TABLE: $name (copy to here) ===');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hive benchmark')),
    body: Center(child: Text(_status)),
  );
}
