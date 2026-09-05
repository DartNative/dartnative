/// DartNative tutorial — on-device neural text-to-speech.
///
/// The screens under lib/screens/media/ are BYTE-IDENTICAL copies of the
/// DartNative playground's SuperTonic demo (lib/screens/home/demo_ui.dart is
/// the playground's shared UI kit, also verbatim). When the playground demo
/// improves, this tutorial updates by copying the files again:
///   • supertonic_demo.dart — SuperTonic-3 (`dartnative_supertonic_tts`), a
///     pure-Dart all-ONNX pipeline on `dartnative_onnxruntime`: ModelManager
///     download-on-first-use (~144 MB, delete on demand), generateStream()
///     PCM chunks played through dartnative_audio's PcmStreamPlayer
///   • language_picker_screen.dart — full-screen picker over all 31
///     SuperTonic languages ([TTSLanguage.all])
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/media/supertonic_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Light look (white background), matching the site's light styling.
  playgroundPalette = kLightPalette;
  runApp(const SuperTonicDemo());
}
