// The hot reload benchmark, Flutter app: an app bar and 40 cards whose colour
// comes from cardColor. ../tool/measure.py writes a new cardColor, reloads
// the app the way an editor does on save, and times the new colour on the
// simulator's screen.
//
//   flutter run -d <simulator id>    # by hand: change cardColor, save, press r
import 'dart:io' show HttpClient;

import 'package:flutter/material.dart';

const cardColor = Color(0xFF4A90E2);

void main() => runApp(const MaterialApp(home: BenchScreen()));

class BenchScreen extends StatelessWidget {
  const BenchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => reportColour());
    return Scaffold(
      appBar: AppBar(title: const Text('Hot reload')),
      body: ListView.builder(
        itemCount: 40,
        itemBuilder: (context, i) => Container(
          height: 72,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Card $i',
            style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 17),
          ),
        ),
      ),
    );
  }
}

// After each frame, tells the measuring script on this Mac which colour the
// app has just shown, so it knows the reload has landed. The time measured
// comes from the screen recording, not from this message.
void reportColour() {
  final hex = cardColor.toARGB32().toRadixString(16);
  HttpClient()
      .getUrl(Uri.parse('http://127.0.0.1:48765/shown?colour=$hex'))
      .then((request) => request.close())
      .then((response) => response.drain<void>())
      .catchError((_) {});
}
