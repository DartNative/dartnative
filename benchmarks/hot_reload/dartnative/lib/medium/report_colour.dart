import 'dart:io' show HttpClient;

import 'package:dartnative/dartnative.dart';

// After each frame, tells the measuring script on this Mac which colour the
// app has just shown, so it knows the reload has landed. The time measured
// comes from the screen recording, not from this message.
void reportColour(Color colour) {
  final hex = colour.value.toRadixString(16);
  HttpClient()
      .getUrl(Uri.parse('http://127.0.0.1:48765/shown?colour=$hex'))
      .then((request) => request.close())
      .then((response) => response.drain<void>())
      .catchError((_) {});
}
