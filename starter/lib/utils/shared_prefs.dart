import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';

/// Singleton wrapper around SharedPreferences.
///
/// Reads are synchronous (values live in memory after [initialize]); writes
/// go to disk asynchronously. Initialize once in main() before runApp, then
/// call `SharedPrefs.instance` from anywhere.
class SharedPrefs {
  SharedPrefs._();

  static final SharedPrefs instance = SharedPrefs._();

  SharedPreferences? _prefs;

  bool get isInitialized => _prefs != null;

  /// Safe to call more than once, later calls do nothing.
  Future<void> initialize() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('SharedPrefs used before initialize()');
    }
    return p;
  }

  String? getString(String key) => _p.getString(key);
  bool? getBool(String key) => _p.getBool(key);
  int? getInt(String key) => _p.getInt(key);

  Future<void> setString(String key, String value) => _p.setString(key, value);
  Future<void> setBool(String key, bool value) => _p.setBool(key, value);
  Future<void> setInt(String key, int value) => _p.setInt(key, value);
  Future<void> remove(String key) => _p.remove(key);
}
