/// DartNative tutorial — build the chat screen.
///
/// lib/screens/chat_screen_demo.dart is a BYTE-IDENTICAL copy of the
/// DartNative playground's chat demo (lib/screens/home/demo_ui.dart is the
/// playground's shared UI kit, also verbatim). When the playground screen
/// improves, this tutorial updates by copying the file again:
///   • chat_screen_demo.dart — reverse message list (switchable ListMode:
///     ListView, ListView.builder, CustomScrollView slivers, or FastList),
///     a growing input bar riding the system keyboard, a scroll-to-bottom
///     FAB, jump-to-message with a highlight flash, and Liquid Glass polish
///     on iOS 26
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/chat_screen_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const ChatScreenDemo());
}
