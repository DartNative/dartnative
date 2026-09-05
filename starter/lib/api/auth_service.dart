import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartnative/dartnative.dart' show dnLog;
import 'package:dartnative_social_sign_in/social_sign_in.dart';
import 'package:dartnative_supabase/dartnative_supabase.dart';

import '../config.dart';
import '../models/user.dart' as app;
import '../utils/constants.dart';
import '../utils/shared_prefs.dart';

/// Auth in one place: Supabase session handling, native Apple and Google
/// sign in, the profile row, and the keyless demo session.
///
/// This is the flow we run in production (extracted from our first shipped
/// app), including the details that took real debugging to learn:
///
///  - Apple sends the user's name and email ONLY on the very first sign in
///    of an Apple ID. We persist them to Supabase user metadata right away
///    so a reinstall can still greet the user by name.
///  - Apple sign in uses the OIDC nonce flow: a random nonce is hashed into
///    the Apple request and the raw nonce goes to Supabase, which verifies
///    the pair.
///  - The session is restored asynchronously after Supabase.initialize().
///    Never assume it is there right after init, wait for the auth stream
///    (AuthState.waitUntilResolved does this).
///
/// When [AppConfig.isAuthConfigured] is false none of the network paths are
/// reachable and the demo session is the only way in.
class AuthService {
  AuthService._();

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static final _authController = StreamController<AuthChangeEvent>.broadcast();

  /// Broadcast stream of Supabase auth events (signedIn, signedOut, ...).
  /// AuthState mirrors these into a ChangeNotifier for widgets.
  static Stream<AuthChangeEvent> get authStream => _authController.stream;

  /// The signed in user's profile, null until loaded. Kept static so
  /// services can read it without a BuildContext.
  static app.User? currentUser;

  static Session? session;

  /// True while the app runs on the fake demo user (no Supabase).
  static bool demoSession = false;

  /// Notified whenever [currentUser] changes so AuthState can rebuild the
  /// widgets watching it.
  static void Function(app.User user)? onProfileChanged;

  static bool get isAuthenticated => demoSession || session != null;

  /// Supabase user metadata (name and email saved on first sign in).
  static Map<String, dynamic>? get userMetadata =>
      AppConfig.isAuthConfigured ? _auth.currentUser?.userMetadata : null;

  // ── Initialization ─────────────────────────────────────────────────────

  /// Call once from main() after Supabase.initialize(). Mirrors every
  /// Supabase auth event into [authStream] and keeps [session] fresh.
  static void initialize() {
    _auth.onAuthStateChange.listen((data) {
      session = data.session;
      _authController.add(data.event);
      if (data.event == AuthChangeEvent.signedOut) {
        currentUser = null;
        session = null;
      }
    });
    // Restore an existing session if one was persisted.
    session = _auth.currentSession;
  }

  /// Restores a demo session persisted by a previous launch. Call from
  /// main() before the router decides the first screen. Returns true when
  /// a demo session is active.
  static bool restoreDemoSession() {
    demoSession =
        SharedPrefs.instance.getBool(kPrefDemoSession) ?? false;
    if (demoSession) {
      final cached = SharedPrefs.instance.getString(kPrefCachedProfile);
      if (cached != null) currentUser = app.User.fromJson(cached);
      currentUser ??= _demoUser;
    }
    return demoSession;
  }

  // ── Demo session ───────────────────────────────────────────────────────

  static const _demoUser = app.User(
    id: 'demo',
    name: 'Dev User',
    username: 'dev',
    email: 'dev@example.com',
  );

  /// Signs in without any backend: a fake user, persisted locally so the
  /// app stays signed in across launches. Everything past this point
  /// (home, drawer, notes) works exactly as it does with a real session.
  static Future<void> signInDemo() async {
    demoSession = true;
    currentUser = _demoUser;
    await SharedPrefs.instance.setBool(kPrefDemoSession, true);
    await SharedPrefs.instance
        .setString(kPrefCachedProfile, _demoUser.toJson());
    _authController.add(AuthChangeEvent.signedIn);
  }

  // ── Apple sign in ──────────────────────────────────────────────────────

  /// Signs in with Apple using the Supabase OIDC nonce flow.
  ///
  /// Returns the name and email Apple provided. Both are null on every
  /// sign in after the first one, that is Apple's documented behavior, so
  /// the caller falls back to the user metadata we saved the first time.
  static Future<({String? givenName, String? familyName, String? email})>
      signInWithApple() async {
    // A random nonce, hashed into the Apple request. Supabase receives the
    // raw nonce and verifies the two match, which ties the Apple token to
    // this one sign in attempt.
    final rawNonce = List.generate(32, (_) => Random.secure().nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('No identity token in the Apple credential.');
    }

    await _auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // credential.email can be null after the first sign in, but Supabase
    // stored the email back then, so the auth user is the reliable source.
    final email = credential.email ?? _auth.currentUser?.email;

    // Persist name and email to user metadata now. Apple will never send
    // them again, and metadata survives reinstalls.
    final meta = <String, dynamic>{};
    if (credential.givenName != null || credential.familyName != null) {
      meta['full_name'] = [credential.givenName, credential.familyName]
          .whereType<String>()
          .join(' ');
    }
    if (email != null) meta['email'] = email;
    if (meta.isNotEmpty) {
      // Fire and forget: a backup for later sign ins, never worth blocking
      // navigation on.
      unawaited(_saveUserMetadata(meta));
    }

    return (
      givenName: credential.givenName,
      familyName: credential.familyName,
      email: email,
    );
  }

  /// Saves name and email into Supabase user metadata. Failures are logged
  /// and swallowed: this is a recovery backup, not a required step.
  static Future<void> _saveUserMetadata(Map<String, dynamic> meta) async {
    try {
      await _auth.updateUser(UserAttributes(data: meta));
    } catch (e) {
      dnLog('AuthService: metadata save failed: $e');
    }
  }

  // ── Google sign in ─────────────────────────────────────────────────────

  /// Signs in with Google using the native dialog, then hands the ID token
  /// to Supabase. Needs GOOGLE_WEB_CLIENT_ID in .dnkeys (the Web client id
  /// from Google Cloud Console, not the Android one).
  static Future<({String? givenName, String? familyName, String? email})>
      signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      serverClientId: AppConfig.googleWebClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign in was cancelled.');
    }

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthException('No ID token from Google.');
    }

    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );

    // Google sends the display name on every sign in, so no metadata dance
    // is needed here. Split it for the same return shape as Apple.
    String? givenName;
    String? familyName;
    final displayName = googleUser.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      givenName = parts.first;
      familyName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    }

    return (
      givenName: givenName,
      familyName: familyName,
      email: googleUser.email,
    );
  }

  // ── Profile (the `profiles` table) ─────────────────────────────────────

  /// Loads the profile row for the signed in user. Null when the row does
  /// not exist yet (a brand new user, route them to Create Profile).
  static Future<app.User?> fetchProfile() async {
    if (demoSession) return currentUser;
    final uid = _auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', uid);
      if (rows.isEmpty) return null;
      final user = app.User.fromMap(rows.first);
      _setUser(user);
      return user;
    } catch (e) {
      dnLog('AuthService: fetchProfile failed: $e');
      return null;
    }
  }

  /// Creates or updates the profile row, then caches it locally.
  static Future<void> saveProfile({
    required String name,
    required String username,
  }) async {
    if (demoSession) {
      _setUser(app.User(
        id: 'demo',
        name: name,
        username: username,
        email: currentUser?.email,
      ));
      return;
    }
    final uid = _auth.currentUser?.id;
    if (uid == null) throw const AuthException('Not signed in.');
    final row = {
      'id': uid,
      'name': name,
      'username': username,
      'email': _auth.currentUser?.email,
    };
    await Supabase.instance.client.from('profiles').upsert(row);
    _setUser(app.User.fromMap(row));
  }

  static void _setUser(app.User user) {
    currentUser = user;
    unawaited(
        SharedPrefs.instance.setString(kPrefCachedProfile, user.toJson()));
    onProfileChanged?.call(user);
  }

  // ── Sign out ───────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    if (demoSession) {
      demoSession = false;
      currentUser = null;
      await SharedPrefs.instance.remove(kPrefDemoSession);
      await SharedPrefs.instance.remove(kPrefCachedProfile);
      _authController.add(AuthChangeEvent.signedOut);
      return;
    }
    await SharedPrefs.instance.remove(kPrefCachedProfile);
    await _auth.signOut();
    currentUser = null;
    session = null;
  }
}
