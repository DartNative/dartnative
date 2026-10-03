// Diagnostics for jank on a screen's first open: while a screen is new, log
// every stretch the main thread was busy long enough to drop frames.
//
// Dart runs on the platform main thread here, the thread UIKit and the Rive
// views draw on, so a short periodic timer that fires late measures exactly
// that: file parsing, image decoding, network callbacks, a heavy build — all
// of it delays the timer by as long as it held the thread. Each line carries
// a wall-clock stamp to line up with the plugin's `[DNRive] timing` lines.

import 'dart:async';

import 'package:dartnative/dartnative.dart';

/// Wall-clock time as `HH:mm:ss.SSS`, the stamp every jank log shares.
String stallStamp() {
  final t = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.'
      '${t.millisecond.toString().padLeft(3, '0')}';
}

abstract final class StallProbe {
  /// A gap this long means at least two frames were missed at 60 Hz.
  static const _threshold = Duration(milliseconds: 34);

  /// Watches the main thread for [window] from now, under [label].
  static void watch(String label,
      {Duration window = const Duration(seconds: 6)}) {
    final clock = Stopwatch()..start();
    var last = Duration.zero;
    var stalls = 0;
    var worst = Duration.zero;
    var blocked = Duration.zero;
    dnLog('[DN-Stall] @${stallStamp()} watching "$label" for '
        '${window.inMilliseconds}ms');
    Timer.periodic(const Duration(milliseconds: 8), (timer) {
      final now = clock.elapsed;
      final gap = now - last;
      last = now;
      if (gap > _threshold) {
        stalls++;
        blocked += gap;
        if (gap > worst) worst = gap;
        dnLog('[DN-Stall] @${stallStamp()} "$label" +${now.inMilliseconds}ms: '
            'main thread blocked ~${gap.inMilliseconds}ms');
      }
      if (now >= window) {
        timer.cancel();
        dnLog('[DN-Stall] @${stallStamp()} "$label" done: $stalls stalls, '
            'worst ${worst.inMilliseconds}ms, '
            'total ${blocked.inMilliseconds}ms blocked');
      }
    });
  }
}
