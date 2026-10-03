// The example's stand-in for `package:http`'s `http.get(url).bodyBytes`,
// which upstream uses to fetch fonts and images at runtime. `dart:io` is
// available to the app, so a plain HttpClient does the same job.

import 'dart:io';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';

import '../stall_probe.dart';

var _requests = 0;

/// GETs [url] and returns the body.
///
/// Diagnostics: logs when the request starts, when the headers arrive and
/// when the body is in, with the wall-clock stamp the jank logs share.
Future<Uint8List> getBytes(String url) async {
  final n = ++_requests;
  final clock = Stopwatch()..start();
  dnLog('[OOB-Net] @${stallStamp()} #$n GET $url');
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    final headers = clock.elapsedMilliseconds;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    dnLog('[OOB-Net] @${stallStamp()} #$n ${bytes.length}B in '
        '${clock.elapsedMilliseconds}ms (headers at ${headers}ms)');
    return bytes;
  } finally {
    client.close();
  }
}
