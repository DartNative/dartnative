import 'dart:io';

import 'package:dartnative_hive/dartnative_hive.dart';

import 'benchmark_runner.dart';
import 'benchmark_types.dart';

/// The four payloads every case runs with.
List<(String, Object Function(int))> _payloads() => [
  ('string', (_) => benchmarkStringValue),
  ('integer', (index) => index),
  ('boolean', (index) => index.isEven),
  ('buffer 256B', (_) => benchmarkBufferValue),
];

/// Hive keeps its values in memory. With the file backend, `put` updates
/// memory and returns a future that completes once a write call has
/// appended the change to the file. With the mapped backend, `put` has
/// already copied the change into the memory-mapped file when it returns;
/// its future only reports that.
///
/// The cases come in three groups, in this order:
///
/// * Stored writes. The clock stops when every change is stored, so these
///   are where the two backends differ.
///   * `every put awaited` waits for each put in turn: one call, one key,
///     safe from a kill on every return. The row to compare. Overwriting
///     one key leaves old entries behind, so Hive compacts the box every
///     few dozen writes, and that is part of this row.
///   * `every put awaited, 1000 keys` is the same loop on different keys:
///     nothing is replaced, so nothing is compacted.
///   * `1000 puts, last awaited` issues the puts and waits for the last.
///   * `one putAll` stores 1000 keys in a single call, which is how Hive
///     takes bulk writes.
/// * `put not awaited` issues the puts and never waits. On the file backend
///   nothing is stored when the clock stops: it is the cost of updating
///   memory. On the mapped backend every put is stored, so this is its
///   write as an app that does not await sees it.
/// * Reads, of one key and of 1000 keys. A `get` is a lookup in memory on
///   both backends.
List<BenchmarkCase> createHiveCases(
  Box<dynamic> box, {
  required int operations,
  required bool mapped,
}) {
  final stored = mapped ? Durability.handedToKernel : Durability.written;
  final notAwaited = mapped ? Durability.handedToKernel : Durability.inProcess;

  return <BenchmarkCase>[
    for (final (kind, value) in _payloads()) ...[
      BenchmarkCase(
        name: '$kind, every put awaited',
        durability: stored,
        run: (key) async {
          for (var index = 0; index < operations; index++) {
            await box.put(key, value(index));
          }
        },
      ),
      BenchmarkCase(
        name: '$kind, every put awaited, 1000 keys',
        durability: stored,
        run: (key) async {
          for (var index = 0; index < operations; index++) {
            await box.put('$key-$index', value(index));
          }
        },
      ),
      BenchmarkCase(
        name: '$kind, 1000 puts, last awaited',
        durability: stored,
        run: (key) async {
          Future<void>? last;
          for (var index = 0; index < operations; index++) {
            last = box.put(key, value(index));
          }
          await last;
        },
      ),
      BenchmarkCase(
        name: '$kind, one putAll',
        durability: stored,
        run: (key) async {
          await box.putAll(<String, dynamic>{
            for (var index = 0; index < operations; index++)
              '$key-$index': value(index),
          });
        },
      ),
    ],
    for (final (kind, value) in _payloads()) ...[
      BenchmarkCase(
        name: '$kind, $_notAwaited',
        durability: notAwaited,
        run: (key) {
          for (var index = 0; index < operations; index++) {
            box.put(key, value(index));
          }
        },
      ),
      BenchmarkCase(
        name: '$kind, $_notAwaited, 1000 keys',
        durability: notAwaited,
        run: (key) {
          for (var index = 0; index < operations; index++) {
            box.put('$key-$index', value(index));
          }
        },
      ),
    ],
    for (final (kind, value) in _payloads()) ...[
      BenchmarkCase(
        name: '$kind read',
        durability: Durability.read,
        setup: (key) => box.put(key, value(1)),
        run: (key) {
          final expected = value(1);
          var matches = 0;
          for (var index = 0; index < operations; index++) {
            if (_matches(box.get(key), expected)) matches++;
          }
          if (matches != operations) {
            throw StateError('$kind read checksum mismatch: $matches');
          }
        },
      ),
      BenchmarkCase(
        name: '$kind read, 1000 keys',
        durability: Durability.read,
        setup: (key) => box.putAll(<String, dynamic>{
          for (var index = 0; index < operations; index++)
            '$key-$index': value(index),
        }),
        run: (key) {
          var matches = 0;
          for (var index = 0; index < operations; index++) {
            if (_matches(box.get('$key-$index'), value(index))) matches++;
          }
          if (matches != operations) {
            throw StateError('$kind read checksum mismatch: $matches');
          }
        },
      ),
    ],
  ];
}

const _notAwaited = 'put not awaited';

bool _matches(Object? read, Object expected) => expected is List<int>
    ? read is List<int> && read.length == expected.length
    : read == expected;

/// The group a row belongs to on screen and in the table.
enum CaseGroup {
  stored('Stored writes', 'The clock stops when every change is stored.'),
  notAwaited(
    'Writes not awaited',
    'When the clock stops the file backend has stored nothing yet, and the '
        'mapped backend has stored every put: it stores before put returns.',
  ),
  reads('Reads', 'A read is a lookup in memory on both backends.');

  const CaseGroup(this.title, this.note);

  final String title;
  final String note;

  static CaseGroup of(BenchmarkRow row) => row.durability == Durability.read
      ? reads
      : row.name.contains(_notAwaited)
      ? notAwaited
      : stored;

  /// Only stored writes depend on the backend, so only they get a ratio.
  bool get compares => this == stored;
}

/// Runs every case on one backend, in a fresh box in a temporary folder.
Future<List<BenchmarkRow>> runHiveBenchmarks({
  required bool mapped,
  int operations = benchmarkOperations,
  int warmupRounds = benchmarkWarmupRounds,
  int measuredRounds = benchmarkMeasuredRounds,
  void Function(BenchmarkRow row)? onRow,
}) async {
  final root = await Directory.systemTemp.createTemp('hive_bench_');
  final boxName = 'bench_${DateTime.now().microsecondsSinceEpoch}';
  Hive.initDartNative(root.path, mmap: mapped);
  final box = await Hive.openBox<dynamic>(boxName);

  try {
    return await runBenchmarkCases(
      backend: mapped ? 'mapped' : 'file',
      cases: createHiveCases(box, operations: operations, mapped: mapped),
      clear: () => box.clear(),
      operations: operations,
      warmupRounds: warmupRounds,
      measuredRounds: measuredRounds,
      onRow: onRow,
    );
  } finally {
    await box.close();
    await Hive.deleteBoxFromDisk(boxName, path: root.path);
    await root.delete(recursive: true);
  }
}

/// Runs every case on the file backend, then on the mapped backend.
Future<List<BenchmarkRow>> runBackendComparison({
  void Function(BenchmarkRow row)? onRow,
}) async => <BenchmarkRow>[
  ...await runHiveBenchmarks(mapped: false, onRow: onRow),
  ...await runHiveBenchmarks(mapped: true, onRow: onRow),
];

/// One table: both backends side by side, a heading row per group, and how
/// many times faster the mapped backend was where the backend does the
/// work. Ready to paste into a results document.
String comparisonAsMarkdown(List<BenchmarkRow> rows) {
  final file = {for (final r in rows.where((r) => r.backend == 'file')) r.name: r};
  final mapped = {
    for (final r in rows.where((r) => r.backend == 'mapped')) r.name: r,
  };
  final operations = rows.isEmpty ? 0 : rows.first.operations;
  final buffer = StringBuffer()
    ..writeln(
      '| Case | File backend, $operations ops (ms) | '
      'Mapped backend, $operations ops (ms) | Faster |',
    )
    ..writeln('| --- | ---: | ---: | ---: |');
  CaseGroup? group;
  for (final name in file.keys) {
    final before = file[name]!;
    final after = mapped[name];
    if (after == null) continue;
    final rowGroup = CaseGroup.of(before);
    if (rowGroup != group) {
      group = rowGroup;
      buffer.writeln('| **${rowGroup.title}** | | | |');
    }
    final ratio = rowGroup.compares
        ? '${(before.elapsedMicros / after.elapsedMicros).toStringAsFixed(1)}x'
        : '';
    buffer.writeln(
      '| $name | ${before.elapsedMs.toStringAsFixed(3)} | '
      '${after.elapsedMs.toStringAsFixed(3)} | $ratio |',
    );
  }
  return buffer.toString();
}
