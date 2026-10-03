// Ported from rive-flutter's example/lib/examples/text_runs.dart
// (0.15.0-dev.3). Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   File.asset(…, assetLoader:)                   →  Rive(asset:, assetLoader:)
//   RiveWidgetController(file, artboardSelector:  →  Rive(artboardName:,
//     .byName, stateMachineSelector: .byName)          stateMachineName:)
//   artboard.setText('button_text', …)            →  controller.setTextRunValue(…)
//   artboard.getText(…) and its two debugPrints   →  dropped: DartNative sets
//                                                     text runs, it cannot read them
//   rootBundle.load(path)                         →  loadAssetBytes(path)   (sync)
//   RiveExampleApp.getCurrentFactory.decodeFont   →  RiveFactory.decodeFont
//   (text runs play on the classic runtime)       →  Rive(legacy: true)
//   Scaffold(body:)                               →  the catalogue shell's
//
// The text is set before the view mounts, as theirs is before the first
// frame, and reaches the view when it does.

import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

Widget buildTextRuns(BuildContext context) => const ExampleTextRuns();

/// We strongly recommend using Data Binding instead of updating text runs
/// manually. See: https://rive.app/docs/runtimes/data-binding
///
/// An example showing how to read and update text runs at runtime.
/// See: https://rive.app/docs/runtimes/text
class ExampleTextRuns extends StatefulWidget {
  const ExampleTextRuns({super.key});

  @override
  State<ExampleTextRuns> createState() => _ExampleTextRunsState();
}

class _ExampleTextRunsState extends State<ExampleTextRuns> {
  final RiveController _controller = RiveController();

  bool _assetLoader(FileAsset asset, Uint8List? bytes) {
    if (asset is FontAsset) {
      _loadFont(asset);
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    // Update text runs
    // You can access nested text runs by providing an optional path
    _controller.setTextRunValue('button_text', 'Hello, world!');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // This example has the font asset external from the Rive file, and we're
  // loading it manually. If you embedded the font in the Rive file, you can
  // skip this step.
  //
  // See: https://rive.app/docs/runtimes/loading-assets
  Future<void> _loadFont(FontAsset asset) async {
    final bytes = loadAssetBytes('assets/fonts/Inter-Regular.ttf');
    if (bytes == null) return;
    final font = await RiveFactory.decodeFont(bytes);
    if (font != null && mounted) {
      asset.font(font);
      font.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Rive(
      asset: 'assets/rive/electrified_button_nested_text.riv',
      artboardName: 'Button',
      stateMachineName: 'button',
      assetLoader: _assetLoader,
      controller: _controller,
      legacy: true,
    );
  }
}
