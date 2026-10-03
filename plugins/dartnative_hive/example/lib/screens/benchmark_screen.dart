/// Benchmark: hive_ce's own benchmark, then every write and read case of
/// ours, on the file backend and on the memory-mapped one, side by side.
library;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_hive/dartnative_hive.dart';
import 'package:dartnative_path_provider/dartnative_path_provider.dart';

import '../benchmark/benchmark_types.dart';
import '../benchmark/hive_ce_benchmark.dart';
import '../benchmark/hive_cases.dart';

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  final _hiveCeFile = <int, HiveCeResult>{};
  final _hiveCeMapped = <int, HiveCeResult>{};
  final _file = <String, BenchmarkRow>{};
  final _mapped = <String, BenchmarkRow>{};
  String _status = 'Runs on both backends; about a minute.';
  bool _running = false;

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _hiveCeFile.clear();
      _hiveCeMapped.clear();
      _file.clear();
      _mapped.clear();
      _status = "Running hive_ce's benchmark on the file backend…";
    });
    void onHiveCe(HiveCeResult result) {
      if (!mounted) return;
      setState(() {
        (result.mapped ? _hiveCeMapped : _hiveCeFile)[result.operations] =
            result;
        _status = result.mapped
            ? "Running hive_ce's benchmark on the mapped backend…"
            : "Running hive_ce's benchmark on the file backend…";
      });
    }

    try {
      final official = [
        ...await runHiveCeBenchmark(mapped: false, onResult: onHiveCe),
        ...await runHiveCeBenchmark(mapped: true, onResult: onHiveCe),
      ];
      print("[HIVE_BENCH] === TABLE: hive_ce's benchmark (copy from here) ===");
      for (final line in hiveCeAsMarkdown(official).trimRight().split('\n')) {
        print('[HIVE_BENCH] $line');
      }
      print("[HIVE_BENCH] === TABLE: hive_ce's benchmark (copy to here) ===");
      final rows = await runBackendComparison(
        onRow: (row) {
          if (!mounted) return;
          setState(() {
            (row.backend == 'file' ? _file : _mapped)[row.name] = row;
            _status = row.backend == 'file'
                ? 'Running on the file backend…'
                : 'Running on the mapped backend…';
          });
        },
      );
      print('[HIVE_BENCH] === TABLE: every case (copy from here) ===');
      for (final line in comparisonAsMarkdown(rows).trimRight().split('\n')) {
        print('[HIVE_BENCH] $line');
      }
      print('[HIVE_BENCH] === TABLE: every case (copy to here) ===');
      if (mounted) {
        setState(() => _status = 'Done. The table is also in the console.');
      }
    } catch (error, stackTrace) {
      print('[HIVE_BENCH] FAIL: $error\n$stackTrace');
      if (mounted) setState(() => _status = 'Benchmark failed: $error');
    } finally {
      // The benchmark pointed Hive at a temporary folder; the demo's boxes
      // live in the documents folder.
      Hive.initDartNative(getApplicationDocumentsDirectory(), subDir: 'hive');
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'Benchmark',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'The same writes and reads on the file backend (mmap: false, a '
            'write call per change) and on the mapped backend (the default: '
            'a memory-mapped file the system keeps safe if the app crashes '
            'or is killed). Lower is better.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _running ? null : _run,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                _running ? 'Running…' : 'Run benchmark',
                style: TextStyle(
                  color: _running
                      ? const Color(0xFF636366)
                      : const Color(0xFF0A84FF),
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _status,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          if (_hiveCeFile.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              "hive_ce's benchmark",
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "hive_ce's own benchmark, as it publishes it: awaited box.add "
              'calls of a ten-field object into a fresh box, average of 5 '
              'passes.',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
            const SizedBox(height: 8),
            const _ResultRow(
              name: 'Writes',
              file: 'File',
              mapped: 'Mapped',
              faster: 'Faster',
              header: true,
            ),
            for (final result in _hiveCeFile.values)
              _ResultRow(
                name: _count(result.operations),
                file: _time(result.milliseconds),
                mapped: _hiveCeMapped[result.operations] == null
                    ? '…'
                    : _time(_hiveCeMapped[result.operations]!.milliseconds),
                faster: _hiveCeMapped[result.operations] == null
                    ? ''
                    : '${(result.time.inMicroseconds / _hiveCeMapped[result.operations]!.time.inMicroseconds).toStringAsFixed(1)}x',
              ),
          ],
          for (final group in CaseGroup.values)
            if (_file.values.any((row) => CaseGroup.of(row) == group)) ...[
              const SizedBox(height: 24),
              Text(
                group.title,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                group.note,
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
              ),
              const SizedBox(height: 8),
              _ResultRow(
                name: 'Case',
                file: 'File',
                mapped: 'Mapped',
                faster: group.compares ? 'Faster' : '',
                header: true,
              ),
              for (final row in _file.values)
                if (CaseGroup.of(row) == group)
                  _ResultRow(
                    name: row.name,
                    file: row.elapsedMs.toStringAsFixed(2),
                    mapped:
                        _mapped[row.name]?.elapsedMs.toStringAsFixed(2) ?? '…',
                    faster: !group.compares || _mapped[row.name] == null
                        ? ''
                        : '${(row.elapsedMicros / _mapped[row.name]!.elapsedMicros).toStringAsFixed(1)}x',
                  ),
            ],
        ],
      ),
    );
  }
}

/// 100000 → "100,000".
String _count(int count) => count.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (match) => '${match[1]},',
);

/// Milliseconds, or seconds from one second up.
String _time(double milliseconds) => milliseconds >= 1000
    ? '${(milliseconds / 1000).toStringAsFixed(2)} s'
    : '${milliseconds.toStringAsFixed(2)} ms';

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.name,
    required this.file,
    required this.mapped,
    required this.faster,
    this.header = false,
  });

  final String name;
  final String file;
  final String mapped;
  final String faster;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: header ? const Color(0xFF8E8E93) : const Color(0xFFFFFFFF),
      fontSize: 13,
      fontWeight: header ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(name, style: style)),
          Expanded(
            flex: 2,
            child: Text(file, style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text(mapped, style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text(faster, style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
