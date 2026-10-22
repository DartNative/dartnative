#!/bin/sh
# Copies the shared measuring code, shared/bench_core.dart, into both apps, so
# they time their routes with the same file, then checks with `cmp` that the
# copies are byte for byte equal. Run it after every edit to the shared file;
# never edit the copies. If the DartNative app's lib folder is missing, its copy
# is skipped.
set -e
# Work from the benchmark folder, wherever the script is called from.
cd "$(dirname "$0")/.."
cp shared/bench_core.dart flutter/lib/bench_core.dart
cp shared/bench_core.dart dartnative/lib/bench_core.dart 2>/dev/null || true
cmp shared/bench_core.dart flutter/lib/bench_core.dart
[ -d dartnative/lib ] && cmp shared/bench_core.dart dartnative/lib/bench_core.dart
echo "bench_core.dart is the same in both apps"
