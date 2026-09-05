import 'dart:async' show unawaited;

import 'package:dartnative/dartnative.dart';

import '../theme.dart';
import '../utils/constants.dart';
import '../utils/shared_prefs.dart';

/// The active palette, and the theme toggle.
///
/// Same pattern as every other piece of shared state in this app: screens
/// watch the notifier and read from it.
///
/// ```dart
/// final theme = AppRepository.themeState..watch(context);
/// Container(color: theme.palette.bg, ...)
/// ```
///
/// The choice is persisted, so the app reopens in the theme the user left
/// it in. The constructor reads the preference synchronously, which works
/// because main() initializes SharedPrefs before AppRepository is touched.
class ThemeState extends ChangeNotifier {
  ThemeState() {
    final dark = SharedPrefs.instance.getBool(kPrefDarkTheme) ?? true;
    _palette = dark ? kDarkPalette : kLightPalette;
    // Pin the native appearance (keyboard, alerts, iOS 26 glass surfaces)
    // to the restored theme from the first frame.
    setAppBrightness(_palette.brightness);
  }

  late Palette _palette;

  Palette get palette => _palette;
  bool get isDark => _palette.brightness == Brightness.dark;

  void toggle() {
    _palette = isDark ? kLightPalette : kDarkPalette;
    // Native surfaces (keyboard, alerts, glass) follow the app theme, not
    // the device theme.
    setAppBrightness(_palette.brightness);
    unawaited(SharedPrefs.instance.setBool(kPrefDarkTheme, isDark));
    notifyListeners();
  }
}
