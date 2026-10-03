/// hive_ce's own storage benchmark, as its repository publishes it
/// (`benchmarks/storage`, BSD-3-Clause and Apache-2.0): N awaited
/// `box.add` calls of a ten-field object into a fresh box, five passes,
/// the average time and the size of the file left behind.
///
/// It runs on both of the plugin's backends. hive_ce itself is measured
/// with the same file in a Flutter app, with two lines changed: the import
/// (`package:hive_ce/hive_ce.dart`) and `Hive.init(root.path)`.
library;

import 'dart:io';

import 'package:dartnative_hive/dartnative_hive.dart';

/// The operation counts hive_ce's table publishes, up to 100,000: a phone
/// holds a million entries in memory, but each pass then takes minutes.
const hiveCeOperations = [10, 100, 1000, 10000, 100000];

/// The passes hive_ce averages over.
const hiveCePasses = 5;

/// One operation count on one backend.
final class HiveCeResult {
  const HiveCeResult({
    required this.operations,
    required this.mapped,
    required this.time,
    required this.bytes,
  });

  final int operations;
  final bool mapped;

  /// The average of the passes.
  final Duration time;

  /// The box file's size after the last pass closed it.
  final int bytes;

  double get milliseconds => time.inMicroseconds / 1000;
  double get megabytes => bytes / 1024 / 1024;
}

/// Runs hive_ce's benchmark for every count in [operations], on one
/// backend, in a temporary folder.
Future<List<HiveCeResult>> runHiveCeBenchmark({
  required bool mapped,
  List<int> operations = hiveCeOperations,
  void Function(HiveCeResult result)? onResult,
}) async {
  final root = await Directory.systemTemp.createTemp('hive_ce_bench_');
  Hive.initDartNative(root.path, mmap: mapped);
  if (!Hive.isAdapterRegistered(TestModelAdapter().typeId)) {
    Hive.registerAdapter(TestModelAdapter());
  }
  final boxFile = File('${root.path}/$_boxName.hive');

  try {
    final results = <HiveCeResult>[];
    for (final count in operations) {
      var total = Duration.zero;
      for (var pass = 1; pass <= hiveCePasses; pass++) {
        if (boxFile.existsSync()) boxFile.deleteSync();
        final box = await Hive.openBox<dynamic>(_boxName);

        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < count; i++) {
          await box.add(_model);
        }
        total += stopwatch.elapsed;

        await box.close();
      }
      final result = HiveCeResult(
        operations: count,
        mapped: mapped,
        time: Duration(microseconds: total.inMicroseconds ~/ hiveCePasses),
        bytes: boxFile.lengthSync(),
      );
      results.add(result);
      onResult?.call(result);
      print(
        '[HIVE_BENCH] hive_ce benchmark, ${mapped ? 'mapped' : 'file'} '
        'backend: $count writes in ${result.milliseconds.toStringAsFixed(3)} '
        'ms, ${result.megabytes.toStringAsFixed(2)} MB',
      );
    }
    return results;
  } finally {
    await Hive.deleteBoxFromDisk(_boxName, path: root.path);
    await root.delete(recursive: true);
  }
}

/// Both backends side by side, one line per operation count, times in
/// milliseconds. Ready to paste into a results document, and the table the
/// chart is drawn from.
String hiveCeAsMarkdown(List<HiveCeResult> results) {
  final file = {for (final r in results.where((r) => !r.mapped)) r.operations: r};
  final mapped = {for (final r in results.where((r) => r.mapped)) r.operations: r};
  final buffer = StringBuffer()
    ..writeln(
      '| Writes | File backend (ms) | Mapped backend (ms) | Faster | '
      'Size (MB) |',
    )
    ..writeln('| ---: | ---: | ---: | ---: | ---: |');
  for (final count in file.keys) {
    final before = file[count]!;
    final after = mapped[count];
    if (after == null) continue;
    final ratio = before.time.inMicroseconds / after.time.inMicroseconds;
    buffer.writeln(
      '| $count | ${before.milliseconds.toStringAsFixed(3)} | '
      '${after.milliseconds.toStringAsFixed(3)} | '
      '${ratio.toStringAsFixed(1)}x | ${after.megabytes.toStringAsFixed(2)} |',
    );
  }
  return buffer.toString();
}

const _boxName = 'test_box';

const _model = TestModel(
  testModelFieldZero: 0,
  testModelFieldOne: 1,
  testModelFieldTwo: 2,
  testModelFieldThree: 3,
  testModelFieldFour: 4,
  testModelFieldFive: 5,
  testModelFieldSix: 6,
  testModelFieldSeven: 7,
  testModelFieldEight: 8,
  testModelFieldNine: 9,
);

/// hive_ce's benchmark model.
class TestModel {
  const TestModel({
    required this.testModelFieldZero,
    required this.testModelFieldOne,
    required this.testModelFieldTwo,
    required this.testModelFieldThree,
    required this.testModelFieldFour,
    required this.testModelFieldFive,
    required this.testModelFieldSix,
    required this.testModelFieldSeven,
    required this.testModelFieldEight,
    required this.testModelFieldNine,
  });

  final int testModelFieldZero;
  final int testModelFieldOne;
  final int testModelFieldTwo;
  final int testModelFieldThree;
  final int testModelFieldFour;
  final int testModelFieldFive;
  final int testModelFieldSix;
  final int testModelFieldSeven;
  final int testModelFieldEight;
  final int testModelFieldNine;
}

/// hive_ce's generated adapter for [TestModel], as its benchmark has it.
class TestModelAdapter extends TypeAdapter<TestModel> {
  @override
  final typeId = 0;

  @override
  TestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestModel(
      testModelFieldZero: (fields[0] as num).toInt(),
      testModelFieldOne: (fields[1] as num).toInt(),
      testModelFieldTwo: (fields[2] as num).toInt(),
      testModelFieldThree: (fields[3] as num).toInt(),
      testModelFieldFour: (fields[4] as num).toInt(),
      testModelFieldFive: (fields[5] as num).toInt(),
      testModelFieldSix: (fields[6] as num).toInt(),
      testModelFieldSeven: (fields[7] as num).toInt(),
      testModelFieldEight: (fields[8] as num).toInt(),
      testModelFieldNine: (fields[9] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, TestModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.testModelFieldZero)
      ..writeByte(1)
      ..write(obj.testModelFieldOne)
      ..writeByte(2)
      ..write(obj.testModelFieldTwo)
      ..writeByte(3)
      ..write(obj.testModelFieldThree)
      ..writeByte(4)
      ..write(obj.testModelFieldFour)
      ..writeByte(5)
      ..write(obj.testModelFieldFive)
      ..writeByte(6)
      ..write(obj.testModelFieldSix)
      ..writeByte(7)
      ..write(obj.testModelFieldSeven)
      ..writeByte(8)
      ..write(obj.testModelFieldEight)
      ..writeByte(9)
      ..write(obj.testModelFieldNine);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
