import 'dart:async' show Completer;

import 'package:dartnative/dartnative.dart' show ChangeNotifier, dnLog;
import 'package:dartnative_supabase/dartnative_supabase.dart'
    show AuthChangeEvent;

import '../api/auth_service.dart';
import '../models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// The auth state widgets watch.
///
/// AuthService owns the Supabase session; this ChangeNotifier mirrors it so
/// screens can do `AppRepository.authState..watch(context)` and rebuild on
/// sign in, sign out and profile changes. This is the whole state
/// management pattern of this app: a ChangeNotifier per concern, held by
/// AppRepository, watched where needed.
class AuthState extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthState() {
    // Profile changes land in AuthService.currentUser (a static). Mirror
    // them here so widgets watching this notifier rebuild.
    AuthService.onProfileChanged = setUser;
    _init();
  }

  /// Completes once [status] leaves [AuthStatus.initial], meaning the
  /// session has been recovered or confirmed absent, or after [timeout].
  ///
  /// main() awaits this BEFORE runApp so the first frame is already the
  /// right screen. Supabase.initialize() returns before the session is
  /// restored: the session arrives through an async auth event, so without
  /// this wait a signed in user would see the onboarding flash by.
  Future<void> waitUntilResolved([
    Duration timeout = const Duration(seconds: 3),
  ]) {
    if (_status != AuthStatus.initial) return Future<void>.value();
    final completer = Completer<void>();
    void onChange() {
      if (_status != AuthStatus.initial && !completer.isCompleted) {
        completer.complete();
      }
    }

    addListener(onChange);
    return completer.future
        .timeout(timeout, onTimeout: () {})
        .whenComplete(() => removeListener(onChange));
  }

  void _init() {
    // A demo session or an already restored Supabase session resolves the
    // state right away.
    if (AuthService.isAuthenticated) {
      _user = AuthService.currentUser;
      _status = AuthStatus.authenticated;
      dnLog('AuthState: resolved authenticated at construction');
    } else {
      // Stay `initial` until the auth stream speaks, so the router does not
      // flash the onboarding at a signed in user. The safety timeout keeps
      // a slow or offline start from hanging on the splash.
      Future.delayed(const Duration(seconds: 5), () {
        if (_status == AuthStatus.initial) {
          dnLog('AuthState: timeout, resolving to unauthenticated');
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
      });
    }

    // Mirror every auth event into this notifier.
    AuthService.authStream.listen((event) {
      dnLog('AuthState: auth event=$event '
          'session=${AuthService.session != null} '
          'demo=${AuthService.demoSession}');
      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          _status = AuthStatus.authenticated;
          _user = AuthService.currentUser;
          _error = null;
        case AuthChangeEvent.initialSession:
          // This event fires for signed in AND signed out users. Check the
          // session, otherwise a new user would land on the home screen or
          // a returning user on the onboarding.
          _status = AuthService.isAuthenticated
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated;
          _error = null;
        case AuthChangeEvent.signedOut:
          // Only accept the sign out when the session is genuinely gone.
          // A transient signedOut can fire during a token refresh at
          // launch, and reacting to it would flash the onboarding at a
          // signed in user.
          if (!AuthService.isAuthenticated) {
            _status = AuthStatus.unauthenticated;
            _user = null;
            _error = null;
          }
        default:
          break;
      }
      notifyListeners();
    });
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void setError(String message) {
    _status = AuthStatus.error;
    _error = message;
    notifyListeners();
  }
}
