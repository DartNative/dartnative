import 'dart:io';

// The Flutter copy of this folder changes two lines: this import, to
// `package:shared_preferences/shared_preferences.dart`, and [benchmarkSide],
// to 'flutter'. Everything else runs unchanged on both sides.
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';

import 'benchmark_runner.dart';
import 'benchmark_types.dart';

const benchmarkSide = 'dartnative';

bool get _flutter => benchmarkSide == 'flutter';

/// One value type of the API: its setter, its getter, and the value a case
/// writes on its n-th operation.
final class _Payload {
  const _Payload(this.kind, this.value, this.write, this.read);

  final String kind;
  final Object Function(int index) value;
  final Future<bool> Function(SharedPreferences prefs, String key, Object v)
      write;
  final Object? Function(SharedPreferences prefs, String key) read;
}

/// The five types `SharedPreferences` stores.
List<_Payload> _payloads() => [
      // Every write stores a value that differs from the one before:
      // UserDefaults skips a write whose value is unchanged, which would
      // time nothing.
      _Payload(
        'string',
        (index) => '$benchmarkStringValue $index',
        (p, k, v) => p.setString(k, v as String),
        (p, k) => p.getString(k),
      ),
      _Payload(
        'integer',
        (index) => index,
        (p, k, v) => p.setInt(k, v as int),
        (p, k) => p.getInt(k),
      ),
      _Payload(
        'double',
        (index) => index + 0.5,
        (p, k, v) => p.setDouble(k, v as double),
        (p, k) => p.getDouble(k),
      ),
      _Payload(
        'boolean',
        (index) => index.isEven,
        (p, k, v) => p.setBool(k, v as bool),
        (p, k) => p.getBool(k),
      ),
      _Payload(
        'string list',
        (index) => [...benchmarkStringListValue, '$index'],
        (p, k, v) => p.setStringList(k, v as List<String>),
        (p, k) => p.getStringList(k),
      ),
    ];

/// How far a write got when its case stops the clock: see [Durability].
Durability _durability({required bool awaited}) {
  if (_flutter) {
    if (!awaited) return Durability.inProcess;
    return Platform.isIOS ? Durability.userDefaults : Durability.committed;
  }
  return Durability.mapped;
}

/// Flutter's `SharedPreferences` keeps every value in a Dart map, so a
/// `get…` is a map lookup, and a `set…` updates the map and sends the value
/// over a platform channel; its future completes when the platform has
/// stored it. DartNative's reads through a cache of its own in each isolate,
/// checked against a version counter the whole process shares; a `set…` is
/// one FFI call into the store, and has stored the value when it returns,
/// before its future is awaited.
///
/// The cases come in three groups, in this order:
///
/// * Stored writes. The clock stops when every value is stored.
///   * `every set awaited` waits for each set in turn, on one key.
///   * `every set awaited, 1000 keys` is the same loop on different keys.
///   * `1000 sets, last awaited` issues the sets and waits for the last.
/// * `set not awaited` issues the sets and never waits. On Flutter nothing
///   has to be stored when the clock stops; on DartNative every set is.
/// * Reads, of one key and of 1000 keys.
List<BenchmarkCase> createPrefsCases(
  SharedPreferences prefs, {
  required int operations,
}) {
  final stored = _durability(awaited: true);
  final notAwaited = _durability(awaited: false);

  return <BenchmarkCase>[
    for (final p in _payloads()) ...[
      BenchmarkCase(
        name: '${p.kind}, every set awaited',
        durability: stored,
        run: (key) async {
          for (var index = 0; index < operations; index++) {
            await p.write(prefs, key, p.value(index));
          }
        },
      ),
      BenchmarkCase(
        name: '${p.kind}, every set awaited, 1000 keys',
        durability: stored,
        run: (key) async {
          for (var index = 0; index < operations; index++) {
            await p.write(prefs, '$key-$index', p.value(index));
          }
        },
      ),
      BenchmarkCase(
        name: '${p.kind}, 1000 sets, last awaited',
        durability: stored,
        run: (key) async {
          Future<bool>? last;
          for (var index = 0; index < operations; index++) {
            last = p.write(prefs, key, p.value(index));
          }
          await last;
        },
      ),
    ],
    for (final p in _payloads()) ...[
      BenchmarkCase(
        name: '${p.kind}, $_notAwaited',
        durability: notAwaited,
        run: (key) {
          for (var index = 0; index < operations; index++) {
            p.write(prefs, key, p.value(index));
          }
        },
      ),
      BenchmarkCase(
        name: '${p.kind}, $_notAwaited, 1000 keys',
        durability: notAwaited,
        run: (key) {
          for (var index = 0; index < operations; index++) {
            p.write(prefs, '$key-$index', p.value(index));
          }
        },
      ),
    ],
    for (final p in _payloads()) ...[
      BenchmarkCase(
        name: '${p.kind} read',
        durability: Durability.read,
        setup: (key) => p.write(prefs, key, p.value(1)),
        run: (key) {
          final expected = p.value(1);
          var matches = 0;
          for (var index = 0; index < operations; index++) {
            if (_matches(p.read(prefs, key), expected)) matches++;
          }
          if (matches != operations) {
            throw StateError('${p.kind} read checksum mismatch: $matches');
          }
        },
      ),
      BenchmarkCase(
        name: '${p.kind} read, 1000 keys',
        durability: Durability.read,
        setup: (key) async {
          for (var index = 0; index < operations; index++) {
            await p.write(prefs, '$key-$index', p.value(index));
          }
        },
        run: (key) {
          var matches = 0;
          for (var index = 0; index < operations; index++) {
            if (_matches(p.read(prefs, '$key-$index'), p.value(index))) {
              matches++;
            }
          }
          if (matches != operations) {
            throw StateError('${p.kind} read checksum mismatch: $matches');
          }
        },
      ),
    ],
  ];
}

const _notAwaited = 'set not awaited';

bool _matches(Object? read, Object expected) => expected is List
    ? read is List &&
        read.length == expected.length &&
        Iterable<int>.generate(read.length).every((i) => read[i] == expected[i])
    : read == expected;

/// Runs every case on this side, starting from an empty store.
Future<List<BenchmarkRow>> runPrefsBenchmarks({
  int operations = benchmarkOperations,
  int warmupRounds = benchmarkWarmupRounds,
  int measuredRounds = benchmarkMeasuredRounds,
  void Function(BenchmarkRow row)? onRow,
}) async {
  final prefs = await SharedPreferences.getInstance();
  try {
    return await runBenchmarkCases(
      backend: benchmarkSide,
      cases: createPrefsCases(prefs, operations: operations),
      clear: prefs.clear,
      operations: operations,
      warmupRounds: warmupRounds,
      measuredRounds: measuredRounds,
      onRow: onRow,
    );
  } finally {
    await prefs.clear();
  }
}

/// One table of this side's rows, ready to paste beside the other side's:
/// the case, how far its writes got, and the median time.
String rowsAsMarkdown(List<BenchmarkRow> rows) {
  final platform = Platform.isIOS ? 'iOS' : 'Android';
  final operations = rows.isEmpty ? 0 : rows.first.operations;
  final buffer = StringBuffer()
    ..writeln('| Case | Durability | $benchmarkSide, $platform, '
        '$operations ops (ms) | Range per op (us) |')
    ..writeln('| --- | --- | ---: | ---: |');
  for (final row in rows) {
    buffer.writeln(
      '| ${row.name} | ${row.durability.name} | '
      '${row.elapsedMs.toStringAsFixed(3)} | '
      '${row.minMicrosecondsPerOperation.toStringAsFixed(2)}-'
      '${row.maxMicrosecondsPerOperation.toStringAsFixed(2)} |',
    );
  }
  return buffer.toString();
}
