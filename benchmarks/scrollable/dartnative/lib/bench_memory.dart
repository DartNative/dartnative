/// Writes the Dart heap's counters for the harness's memory census.
///
/// The harness's driver takes the census from outside the Dart VM (the
/// process's dirty pages, the malloc heap, the window's layers), so the
/// VM's own account of its heap has to come from inside the app. With
/// `BENCH_MEMORY=1` in the environment, the app writes the counters to
/// `Documents/bench_heap.txt` once a second, and the census adds the latest
/// line to its file.
///
/// The counters come from `PlatformDispatcher.dartHeapUsage`: how much the
/// Dart objects occupy (including garbage not yet collected) and how much
/// the heap has reserved, for the new and the old space separately, plus
/// the largest size the new space has reserved since launch (the VM grows
/// it and never shrinks it). The census's untagged dirty pages minus the
/// heap's reserved pages is the memory the VM uses for itself. For the new
/// space, "used" is its reserved size, a cheap counter the VM keeps by
/// design; for the old space it is exact.
library;
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'bench_env.dart';

void startHeapReport() {
  if (benchEnv('BENCH_MEMORY') != '1') return;
  final home = benchEnv('HOME');
  if (!Platform.isIOS || home == null) return;
  final file = File('$home/Documents/bench_heap.txt');
  final staging = File('${file.path}.tmp');
  var newPeak = 0;
  void write(Timer _) {
    final h = ui.PlatformDispatcher.instance.dartHeapUsage;
    if (h.newCapacity > newPeak) newPeak = h.newCapacity;
    String mib(int bytes) => (bytes / 1048576).toStringAsFixed(2);
    try {
      staging.writeAsStringSync(
        'dart heap: ${mib(h.used)} MiB used of ${mib(h.capacity)} reserved '
        '(new ${mib(h.newCapacity)} reserved, at most ${mib(newPeak)} since launch; '
        'old ${mib(h.oldUsed)} of ${mib(h.oldCapacity)}, '
        'external ${mib(h.external)})\n',
      );
      staging.renameSync(file.path);
    } on FileSystemException {
      // The container is not writable yet; the next write, a second later,
      // tries again.
    }
  }

  Timer.periodic(const Duration(seconds: 1), write);
}
