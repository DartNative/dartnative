import 'dart:async';
import 'dart:typed_data';

/// The string every string case writes.
const benchmarkStringValue = 'dartnative_hive benchmark value';

/// The 256 bytes every buffer case writes.
final benchmarkBufferValue = Uint8List.fromList(
  List<int>.generate(256, (index) => index & 0xff),
);

/// How far a write got before the case stopped timing it.
///
/// Only rows with the same value here can be compared: two writes that
/// stopped at different points are different operations, however similar
/// the code looks.
///
/// None of these values means the bytes are on the flash chip. Neither
/// backend calls `fsync` on its write path (`box.flush()` does), so
/// surviving a power cut is not a property any row has. What separates the
/// values is whether the write survives the app being killed, which is the
/// failure an app actually meets.
enum Durability {
  /// The bytes were copied into a memory-mapped file before the clock
  /// stopped. The kernel owns them, so a crash or a kill does not lose
  /// them. Every mapped backend write is this, awaited or not.
  handedToKernel,

  /// The write returned while the bytes were still inside the app. A crash
  /// or a kill loses them. A `put` with its future dropped is this.
  inProcess,

  /// The write waited for a write call to the file, so the bytes reached
  /// the kernel, the same place as [handedToKernel], through a system call
  /// per append. The file backend's awaited writes are this.
  written,

  /// A read. Durability does not apply.
  read,
}

/// One timed operation, run [BenchmarkCase.run] times per round.
typedef BenchmarkOperation = FutureOr<void> Function(String key);

/// A named case: an optional untimed [setup], then the timed [run].
final class BenchmarkCase {
  const BenchmarkCase({
    required this.name,
    required this.durability,
    this.setup,
    required this.run,
  });

  final String name;
  final Durability durability;
  final BenchmarkOperation? setup;
  final BenchmarkOperation run;
}

/// The median of a case's measured rounds, for one backend.
final class BenchmarkRow {
  BenchmarkRow({
    required this.backend,
    required this.name,
    required this.durability,
    required this.elapsedMicros,
    required this.operations,
    required List<int> samplesMicros,
  }) : samplesMicros = List<int>.unmodifiable(samplesMicros);

  final String backend;
  final String name;
  final Durability durability;
  final int elapsedMicros;
  final int operations;
  final List<int> samplesMicros;

  double get elapsedMs => elapsedMicros / 1000.0;

  double get opsPerSecond => operations * 1000000 / elapsedMicros;

  double get microsecondsPerOperation => elapsedMicros / operations;

  double get minMicrosecondsPerOperation => samplesMicros.first / operations;

  double get maxMicrosecondsPerOperation => samplesMicros.last / operations;
}
