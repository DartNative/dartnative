/// App wide configuration.
///
/// Values that change per install (Supabase project, Google client id) come
/// from the bundled `.dnkeys` file, read once at startup by DnKeys.load().
/// Everything else is a plain constant.
///
/// The app runs without any keys: when Supabase is not configured the
/// onboarding offers a demo session instead of real sign in, so you can run
/// the project the moment you clone it.
library;

import 'package:dartnative_keys/dartnative_keys.dart';

class AppConfig {
  const AppConfig._();

  /// Supabase project URL, for example https://abcd1234.supabase.co
  static String get supabaseUrl => DnKeys.get('SUPABASE_URL') ?? '';

  /// Supabase publishable (anon) key. Safe to ship in the app bundle, your
  /// data is protected by Row Level Security, not by hiding this key.
  static String get supabaseAnonKey =>
      DnKeys.get('SUPABASE_PUBLISHABLE_KEY') ?? '';

  /// Web Client ID from Google Cloud Console. Google sign in needs it to
  /// return an ID token that Supabase can verify. Only used on Android.
  static String get googleWebClientId =>
      DnKeys.get('GOOGLE_WEB_CLIENT_ID') ?? '';

  /// True when the keys needed for real auth are present. When false the
  /// app still runs: onboarding shows the demo button only.
  static bool get isAuthConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
