import 'dart:io' show Platform;
import 'dart:async' show runZonedGuarded;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_skia/dartnative_skia.dart';
import 'package:dartnative_sqlite/dartnative_sqlite.dart';
import 'package:dartnative_firebase/dartnative_firebase.dart';
import 'package:dartnative_notifications/dartnative_notifications.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/chat_screen_demo.dart';
import 'screens/media/chatgpt_picker_demo.dart';
import 'screens/home/demo_ui.dart' show playgroundOverlayStyle;
import 'screens/home/home_shell.dart';
import 'screens/grid_demo.dart';
import 'screens/image_demo.dart';
import 'screens/canvas_demo.dart';
import 'screens/text_field_demo.dart';
import 'screens/text_rendering_demo.dart';
import 'screens/state_menu_screen.dart';
import 'screens/state_basics_demo.dart';
import 'screens/state_store_demo.dart';
import 'screens/storage_menu_screen.dart';
import 'screens/storage_demo.dart';
import 'screens/system_connectivity_demo.dart';
import 'screens/social_sign_in_demo.dart';
import 'screens/notifications_demo.dart';
import 'screens/animated_size_demo.dart';
import 'screens/liquid_glass/liquid_glass_menu.dart';
import 'screens/liquid_glass/glass_merge_demo.dart';
import 'screens/liquid_glass/morphing_buttons_demo.dart';
import 'screens/liquid_glass/zoom_morph_demo.dart';
import 'screens/liquid_glass/bar_actions_demo.dart';
import 'screens/liquid_glass/large_title_demo.dart';
import 'screens/liquid_glass/floating_tab_bar_demo.dart';
import 'screens/liquid_glass/bar_surfaces_demo.dart';
import 'screens/material3/material3_menu.dart';
import 'screens/material3/m3_hide_on_scroll_demo.dart';
import 'screens/material3/m3_badges_demo.dart';
import 'screens/material3/m3_large_top_bar_demo.dart';
import 'screens/material3/m3_dynamic_color_demo.dart';
import 'screens/material3/m3_search_demo.dart';
import 'screens/material3/m3_search_appbar_demo.dart';
import 'screens/material3/m3_menus_demo.dart';
import 'screens/music/music_demo.dart';
import 'screens/color_picker_demo.dart';
import 'screens/carousel_demo.dart';
import 'screens/text_typewriter_demo.dart';

void main() {
  runZonedGuarded(() {
    // `verbose: true` enables framework debug logs (mutations, setState,
    // scroll events, …). Invaluable for debugging, but the logging I/O has a
    // real performance cost — use `verbose: false, saveToFile: false` when
    // measuring scroll performance or shipping.
    DartNativeLogger.run(() async {
      // Registers platform bindings (iOS/Android) AND loads FFI symbols for
      // every dartnative_* plugin in pubspec.yaml. Single source of truth —
      // regenerate via `dn pub get`.
      DartNativePluginRegistrant.registerAll();
      registerSkiaFactories();
      // Pre-warm SQLite FFI linkage so all panels can open databases
      // immediately without lazy-init overhead.
      Sqlite.ensureInitialized();
      if (Platform.isIOS) {
        // Register pubspec-declared fonts (assets/fonts/*.ttf|.otf) with UIKit
        // so `IconData(0xXXXX, fontFamily: 'CustomFamily')` and
        // `TextStyle(fontFamily: 'CustomFamily')` resolve correctly.
        DartNativeFontRegistrant.registerAll();
      }
      // Firebase loads symbols + initializes the default app from the
      // platform config (GoogleService-Info.plist / google-services.json),
      // then installs the FCM delegate. Done here so the token is ready
      // before any screen opens.
      try {
        await Firebase.initializeApp();
        FirebaseMessaging.setup();
      } catch (e, st) {
        dnLog(
            '[main] Firebase init failed — continuing without Firebase: $e\n$st');
      }
      try {
        DartNativeNotifications.setup(onTap: (payload) {
          // TODO: route to the relevant screen based on payload.
        });
      } catch (e, st) {
        dnLog('[main] Notifications init failed: $e\n$st');
      }
      registerRoutes({
        '/chat': (_) => const ChatScreenDemo(),
        '/chatgpt-picker': (_) => const ChatGptPickerDemo(),
        '/music': (_) => const MusicDemo(),
        '/color-picker': (_) => const ColorPickerDemo(),
        '/carousel': (_) => const CarouselDemo(),
        '/live-text': (_) => const TextTypewriterDemo(),
        '/grid': (_) => const GridDemo(),
        '/image': (_) => const ImageDemo(),
        '/text-field': (_) => const TextFieldDemo(),
        '/text-rendering': (_) => const TextRenderingDemo(),
        '/canvas': (_) => const CanvasDemo(),
        '/state': (_) => const StateMenuScreen(),
        '/state-basics': (_) => const StateBasicsDemo(),
        '/state-store': (_) => const StateStoreDemo(),
        '/storage': (_) => const StorageMenuScreen(),
        '/storage-prefs': (_) =>
            const StorageDemo(initialTab: StorageTab.preferences),
        '/storage-secure': (_) =>
            const StorageDemo(initialTab: StorageTab.secureStorage),
        '/storage-cache': (_) => const StorageDemo(initialTab: StorageTab.hive),
        '/storage-sqlite': (_) =>
            const StorageDemo(initialTab: StorageTab.sqlite),
        '/system-connectivity': (_) => const SystemConnectivityDemo(),
        '/social-sign-in': (_) => const SocialSignInDemo(),
        '/notifications': (_) => const NotificationsDemo(),
        '/animated-size': (_) => const AnimatedSizeDemo(),
        '/liquid-glass': (_) => const LiquidGlassMenuScreen(),
        '/liquid-glass-merge': (_) => const GlassMergeDemo(),
        '/liquid-glass-zoom': (_) => const ZoomMorphDemo(),
        '/liquid-glass-morphing-buttons': (_) => const MorphingButtonsDemo(),
        '/liquid-glass-bar-actions': (_) => const BarActionsDemo(),
        '/liquid-glass-large-title': (_) => const LargeTitleDemo(),
        '/liquid-glass-tab-bar': (_) => const FloatingTabBarDemo(),
        '/liquid-glass-surfaces': (_) => const BarSurfacesDemo(),
        '/material3': (_) => const Material3MenuScreen(),
        '/material3-hide-on-scroll': (_) => const M3HideOnScrollDemo(),
        '/material3-badges': (_) => const M3BadgesDemo(),
        '/material3-large-top-bar': (_) => const M3LargeTopBarDemo(),
        '/material3-dynamic-color': (_) => const M3DynamicColorDemo(),
        '/material3-search': (_) => const M3SearchDemo(),
        '/material3-search-appbar': (_) => const M3SearchAppBarDemo(),
        '/material3-menus': (_) => const M3MenusDemo(),
      });
      if (DartNativeLogger.filePath != null) {
        dnLog('[Logger] Log file: ${DartNativeLogger.filePath}');
      }
      // Theme before first build — a hot restart from a PUSHED screen builds
      // that screen's tree immediately with the global palette.
      await restorePlaygroundTheme();
      // App-level DEFAULT system chrome, applied by the Navigator on every
      // push — theme-aware. Screens with a fixed look override it in their
      // initState; the Navigator restores the previous style on pop.
      SystemChrome.defaultStyle = playgroundOverlayStyle();
      runApp(const PlaygroundHome());
    }, verbose: false, saveToFile: false);
  }, (error, stack) {
    dnLog('[main] UNCAUGHT ERROR: $error\n$stack');
  });
}
