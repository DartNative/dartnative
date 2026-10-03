import 'dart:async';

import 'benchmark_types.dart';

const benchmarkOperations = 1000;
const benchmarkWarmupRounds = 2;
const benchmarkMeasuredRounds = 7;

/// Runs each case: warm-up rounds, then the median of the measured rounds.
/// Every row carries the durability its case reached, so a write that left
/// the app is never put beside one that did not without saying so.
Future<List<BenchmarkRow>> runBenchmarkCases({
  required String backend,
  required List<BenchmarkCase> cases,
  required FutureOr<void> Function() clear,
  int operations = benchmarkOperations,
  int warmupRounds = benchmarkWarmupRounds,
  int measuredRounds = benchmarkMeasuredRounds,
  void Function(BenchmarkRow row)? onRow,
}) async {
  if (operations <= 0 || warmupRounds < 0 || measuredRounds <= 0) {
    throw RangeError('Rounds and operations must be positive.');
  }

  final rows = <BenchmarkRow>[];
  for (final benchmarkCase in cases) {
    final samplesMicros = <int>[];
    for (var round = 0; round < warmupRounds + measuredRounds; round++) {
      await clear();
      final key = 'value-$round';
      await benchmarkCase.setup?.call(key);
      final stopwatch = Stopwatch()..start();
      try {
        await benchmarkCase.run(key);
      } finally {
        stopwatch.stop();
      }
      if (round >= warmupRounds) {
        samplesMicros.add(stopwatch.elapsedMicroseconds.clamp(1, 0x7fffffff));
      }
    }

    samplesMicros.sort();
    final row = BenchmarkRow(
      backend: backend,
      name: benchmarkCase.name,
      durability: benchmarkCase.durability,
      elapsedMicros: samplesMicros[samplesMicros.length ~/ 2],
      operations: operations,
      samplesMicros: samplesMicros,
    );
    rows.add(row);
    onRow?.call(row);
    print(
      '[HIVE_BENCH] ${row.backend} ${row.name} '
      '(${row.durability.name}): ${row.elapsedMs.toStringAsFixed(3)} ms, '
      '${row.microsecondsPerOperation.toStringAsFixed(2)} us/op, '
      'range ${row.minMicrosecondsPerOperation.toStringAsFixed(2)}-'
      '${row.maxMicrosecondsPerOperation.toStringAsFixed(2)} us/op, '
      '${row.opsPerSecond.toStringAsFixed(0)} ops/s',
    );
  }
  return rows;
}
