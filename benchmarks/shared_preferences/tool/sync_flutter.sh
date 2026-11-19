#!/bin/bash
# Copies the benchmark code from the plugin's example into the Flutter app,
# changing the two lines that differ: the import and the side's name.
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
SRC=$HERE/../../plugins/dartnative_shared_preferences/example/lib/benchmark
DST=$HERE/flutter/lib/benchmark
mkdir -p "$DST"
cp "$SRC/benchmark_runner.dart" "$SRC/benchmark_types.dart" "$DST/"
sed -e "s#import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';#import 'package:shared_preferences/shared_preferences.dart';#" \
    -e "s#^const benchmarkSide = 'dartnative';#const benchmarkSide = 'flutter';#" \
    "$SRC/prefs_cases.dart" > "$DST/prefs_cases.dart"
echo "Lines that differ from the DartNative side (two expected):"
diff "$SRC/prefs_cases.dart" "$DST/prefs_cases.dart" | grep -c '^>' || true
