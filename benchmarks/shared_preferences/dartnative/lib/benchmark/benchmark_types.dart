import 'dart:async';

/// The string every string case writes.
const benchmarkStringValue = 'dartnative_shared_preferences benchmark value';

/// The list every string list case writes.
const benchmarkStringListValue = <String>['first', 'second', 'third'];

/// How far a write got before the case stopped timing it.
///
/// Only rows with the same value here can be compared: two writes that
/// stopped at different points are different operations, however similar
/// the code looks. The value depends on the platform and on the side:
///
/// | | iOS | Android |
/// | --- | --- | --- |
/// | Flutter, `await set…` | [userDefaults] | [committed] |
/// | Flutter, `set…` not awaited | [inProcess] | [inProcess] |
/// | DartNative, awaited or not | [mapped] | [mapped] |
///
/// DartNative's `set…` stores before it returns, so whether the future is
/// awaited changes nothing on its side.
enum Durability {
  /// `UserDefaults.set` returned (iOS). The value is in UserDefaults, which
  /// hands it to the system's preferences daemon on its own; the app does
  /// nothing more to keep it.
  userDefaults,

  /// The store's `set` returned (DartNative): the value's record is in the
  /// store's memory-mapped file, the kernel's page cache, so the app being
  /// killed or crashing right after loses nothing. The store's thread writes
  /// it to storage within about a second. As far as [userDefaults] gets:
  /// there the preferences daemon holds the value and writes its file on its
  /// own schedule. Not as far as [committed], which is on storage when it
  /// returns and survives a power cut too.
  mapped,

  /// `SharedPreferences.Editor.commit()` returned (Android): the whole XML
  /// file was rewritten and synced to storage. Flutter's legacy API commits
  /// every write.
  committed,

  /// `SharedPreferences.Editor.apply()` returned (Android): the value is in
  /// the store's memory and the file write is queued on a background
  /// thread, so a kill right after can lose it. DartNative before its own
  /// store on Android.
  applied,

  /// The write returned while the value was only in the Dart side's memory:
  /// Flutter's `set…` with its future dropped, before the platform channel
  /// message is handled.
  inProcess,

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

/// The median of a case's measured rounds, for one side.
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
