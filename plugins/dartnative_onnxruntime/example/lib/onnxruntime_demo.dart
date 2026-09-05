/// Addition model demo — the canonical minimal ONNX Runtime smoke-test.
///
/// Bundles a tiny `addition_model.ort` (copied from the upstream
/// flutter_onnxruntime example), extracts it to a temp file at startup, then
/// runs inference on two user-supplied floats and displays the result.
///
/// Exercises the full API lifecycle:
///   createSession → OrtValue.fromList → session.run → asFlattenedList →
///   dispose → session.close
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_onnxruntime/dartnative_onnxruntime.dart';

class OnnxRuntimeDemoApp extends StatelessWidget {
  const OnnxRuntimeDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App(
      title: 'dartnative_onnxruntime',
      theme: ThemeData.dark(),
      home: const _DemoScreen(),
    );
  }
}

class _DemoScreen extends StatefulWidget {
  const _DemoScreen();

  @override
  State<_DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<_DemoScreen> {
  final _aController = TextEditingController(text: '3.0');
  final _bController = TextEditingController(text: '4.0');

  OrtSession? _session;
  String _status = 'Loading model…';
  String _result = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _session?.close();
    _aController.dispose();
    _bController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    try {
      final path = await _extractAsset('assets/models/addition_model.ort');
      _session = await OnnxRuntime().createSession(path);
      setState(() => _status = 'Model ready  •  inputs: ${_session!.inputNames}');
    } catch (e) {
      setState(() => _status = 'Load failed: $e');
    }
  }

  Future<void> _runInference() async {
    final session = _session;
    if (session == null) return;

    final a = double.tryParse(_aController.text);
    final b = double.tryParse(_bController.text);
    if (a == null || b == null) {
      setState(() => _result = 'Enter valid numbers.');
      return;
    }

    setState(() => _result = 'Running…');

    OrtValue? valA, valB;
    try {
      valA = await OrtValue.fromList(Float32List.fromList([a]), [1]);
      valB = await OrtValue.fromList(Float32List.fromList([b]), [1]);

      final sw = Stopwatch()..start();
      final outputs = await session.run({'A': valA, 'B': valB});
      final us = sw.elapsedMicroseconds;
      final timing = us >= 1000 ? '${us ~/ 1000}ms' : '${us}µs';

      final flat = await outputs.values.first.asFlattenedList();
      for (final v in outputs.values) {
        await v.dispose();
      }

      setState(() => _result = '$a + $b = ${flat.first}  ($timing)');
    } catch (e) {
      setState(() => _result = 'Inference failed: $e');
    } finally {
      await valA?.dispose();
      await valB?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'dartnative_onnxruntime',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          const Text(
            'Runs a bundled addition model: output = x + y.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            _status,
            style: const TextStyle(color: Color(0xFF636366), fontSize: 12),
          ),
          const SizedBox(height: 24),
          const _SectionHeader('Inputs'),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NumberField(label: 'A', controller: _aController),
                const SizedBox(height: 12),
                _NumberField(label: 'B', controller: _bController),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            label: 'Run inference',
            onTap: _session != null ? _runInference : null,
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionHeader('Result'),
            const SizedBox(height: 8),
            _Card(
              child: Text(
                _result,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 15,
                  fontFamily: 'Menlo',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Future<String> _extractAsset(String assetPath) async {
  final bytes = base64Decode(_kAdditionModelBase64);
  final dir = await Directory.systemTemp.createTemp('dn_ort_');
  final name = assetPath.split('/').last;
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes);
  return file.path;
}

// addition_model.ort — upstream flutter_onnxruntime example model (MIT).
// Embedded to avoid asset system dependency. Regenerate with:
//   base64 -i example/assets/models/addition_model.ort | tr -d '\n'
const _kAdditionModelBase64 =
    'GAAAAE9SVE0AAAAADAAQAAwACAAAAAQADAAAAAwAAACYAAAALAUAABb9//8EAAAAAQAAAAQAAAC0'
    '/f//EAAAAAQAAAABAAAAEAAAAAcAAAA6QWRkOjE0ANT9//8IAAAADAAAAAEAAABUAAAAAwAAADAA'
    'AAAgAAAADAAAAAAABgAIAAcABgAAAAAAAAEIAAgAAAAEAAgAAAABAAAABAAEAAQAAAAUACgAIAAc'
    'ABgAFAAQAAgAAAAEABQAAAA4AAAA/////////39oBAAAbAQAAHQEAADAAgAACAAAAAAAAAAUACQA'
    'IAAcABgAFAAQAAwACAAEABQAAABsAgAAbAIAAHgCAAAUAAAAAQAAABQAAADoAAAATAIAAAEAAAAY'
    'AAAAAQAAAEQAAAAAAAoADAAAAAQACAAKAAAADAAAAAQAAAAAAAAAAAAAAAAAHgAwACwAKAAkACAA'
    'AAAcAAAAGAAUABAADAAIAAQAHgAAADAAAAAwAAAAJAAAADQAAAA4AAAAQAAAAFgAAAAOAAAApAMAA'
    'FQAAABYAAAAAAAAAAAAAAACAAAAAQAAAAEAAAABAAAAwAEAAAIAAADUAQAAyAEAABQAAABDUFVF'
    'eGVjdXRpb25Qcm92aWRlcgAAAAADAAAAQWRkAAAAAAAAAAAABAAAAC9BZGQAAAAAAwAAANwAAABs'
    'AAAABAAAAKb///8IAAAAfAEAAC7///8IAAAAAAAAAZz///8BAAAABAAAABr///8EAAAAAQAAAAQAAAAq'
    '////BAAAAAr///8AAAACBAAAAAoAAABiYXRjaF9zaXplAAAAAAoADAAIAAAABAAKAAAACAAAAPwA'
    'AACS////EAAAAAAAAAEIAAwABAAIAAgAAAABAAAABAAAAIb///8EAAAAAQAAAAQAAACW////BAAAAHb'
    '///8AAAACBAAAAAoAAABiYXRjaF9zaXplAAAAAAoADgAIAAAABAAKAAAAFAAAAKQAAAAAAAoADAAA'
    'AAsABAAKAAAAEAAAAAAAAAEIAA4ABAAIAAgAAAABAAAADAAAAAAABgAIAAQABgAAAAQAAAABAAAA'
    'DAAAAAAABgAKAAQABgAAABAAAAAAAAoADAAHAAAACAAKAAAAAAAAAgQAAAAKAAAAYmF0Y2hfc2l6'
    'ZQAAAAAAAAAAAAABAAAABAAAAAEAAABDAAAAAgAAABAAAAAEAAAAAQAAAEIAAAABAAAAQQAAAAkA'
    'AACEAQAAWAEAACQBAADwAAAAvAAAAJAAAABcAAAAMAAAAAQAAADQ/v//AQAAAAAAAAAEAAAAEAAA'
    'AG9yZy5weXRvcmNoLmF0ZW4AAAAA+P7//wEAAAAAAAAABAAAABMAAABjb20ubWljcm9zb2Z0Lm'
    '5jaHdjACD///8BAAAAAAAAAAQAAAAaAAAAY29tLm1pY3Jvc29mdC5leHBlcmltZW50YWwAACj///'
    '8BAAAAAAAAAAAAAAAEAAAADQAAAGNvbS5taWNyb3NvZnQAAAB4////AQAAAAAAAAAEAAAAGAAAAGFp'
    'Lm9ubngucHJldmlldy50cmFpbmluZwAAAACA////EgAAAAAAAAAAAAAABAAAABQAAABjb20ubXMu'
    'aW50ZXJuYWwubmh3YwAAAADY////AQAAAAAAAAAEAAAAEAAAAGFpLm9ubngudHJhaW5pbmcAAAAA'
    'CAAQAAwABAAIAAAAAwAAAAAAAAAEAAAACgAAAGFpLm9ubngubWwAAAgAFAAQAAQACAAAABEAAAAA'
    'AAAAAAAAAAQAAAAAAAAAAAAAAAUAAAAyLjQuMQAAAAcAAABweXRvcmNoAAEAAAA1AAAA';

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 15),
            decoration: const InputDecoration(
              hintText: '0.0',
              hintStyle: TextStyle(color: Color(0xFF636366)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: disabled ? const Color(0xFF48484A) : const Color(0xFF0A84FF),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
