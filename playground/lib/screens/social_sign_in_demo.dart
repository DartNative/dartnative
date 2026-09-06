/// Social sign-in demo.
///
/// Showcases dartnative_social_sign_in:
///   - Sign in with Apple (ASAuthorizationController via FFI)
///   - Sign in with Google (GIDSignIn via FFI)
///
/// What the playground ships without: the Sign in with Apple capability,
/// because it needs a paid Apple developer account and the playground is
/// meant to build on a free Apple ID. Add it under Signing & Capabilities in
/// Xcode and the Apple buttons work; until then they report that in place.
/// Google needs only the shipped GoogleService-Info.plist and its
/// REVERSED_CLIENT_ID URL scheme, so it works as is.
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_social_sign_in/social_sign_in.dart';
import 'home/demo_ui.dart';

/// The playground ships without the Sign in with Apple capability, so a free
/// Apple ID can sign it. Adding it is one checkbox in Xcode, on a paid account.
const String _kNeedsAppleCapability =
    'Needs Sign in with Apple under Signing & Capabilities in Xcode, which '
    'requires a paid Apple developer account. The playground ships without it '
    'so a free Apple ID can build it.';

class SocialSignInDemo extends StatefulWidget {
  const SocialSignInDemo({super.key});

  @override
  State<SocialSignInDemo> createState() => _SocialSignInDemoState();
}

class _SocialSignInDemoState extends State<SocialSignInDemo> {
  // ── Apple state ───────────────────────────────────────────────────────────
  String _appleStatus = 'Not signed in';
  String? _appleIdToken;
  String? _appleGivenName;
  String? _appleEmail;
  bool _appleLoading = false;

  // ── Google state ──────────────────────────────────────────────────────────
  String _googleStatus = 'Not signed in';
  String? _googleIdToken;
  String? _googleDisplayName;
  String? _googleEmail;
  bool _googleLoading = false;

  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _signInWithApple() async {
    if (!Platform.isIOS) {
      setState(() => _appleStatus =
          'Sign in with Apple: iOS only (not supported on ${Platform.operatingSystem})');
      return;
    }
    setState(() {
      _appleLoading = true;
      _appleStatus = 'Waiting for Apple…';
    });
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      if (!mounted) return;
      setState(() {
        _appleStatus = 'Signed in ✓';
        _appleIdToken = _truncate(credential.identityToken);
        _appleGivenName = credential.givenName;
        _appleEmail = credential.email;
      });
    } on SignInWithAppleAuthorizationException catch (e) {
      if (!mounted) return;
      setState(() {
        _appleStatus = switch (e.code) {
          AuthorizationErrorCode.canceled => 'Canceled by user',
          // Error 1000: the system found no Sign in with Apple entitlement
          // on the app. The expected outcome on a free account.
          AuthorizationErrorCode.unknown => _kNeedsAppleCapability,
          _ => 'Auth error: ${e.message}',
        };
      });
    } catch (e) {
      if (mounted) setState(() => _appleStatus = 'Error: $e');
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _googleStatus = 'Waiting for Google…';
    });
    try {
      // Android: serverClientId (web OAuth 2.0 client ID) is required by
      // Credential Manager. Pass it via:
      //   dn run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
      // iOS: reads clientId from GoogleService-Info.plist automatically.
      const googleSignIn = GoogleSignIn(
        serverClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
      );
      final account = await googleSignIn.signIn();
      if (!mounted) return;
      if (account == null) {
        setState(() => _googleStatus = 'Canceled by user');
        return;
      }
      setState(() {
        _googleStatus = 'Signed in ✓';
        _googleIdToken = _truncate(account.authentication.idToken);
        _googleDisplayName = account.displayName;
        _googleEmail = account.email;
      });
    } on GoogleSignInException catch (e) {
      if (mounted) setState(() => _googleStatus = 'Error: ${e.message}');
    } catch (e) {
      if (mounted) setState(() => _googleStatus = 'Error: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String? _truncate(String? s) {
    if (s == null || s.isEmpty) return null;
    return '${s.substring(0, s.length.clamp(0, 24))}…';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Social Sign-In',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: Container(
        color: kHomeBg,
        child: ListView(
          padding: EdgeInsets.fromLTRB(24,
              isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 24, 24, 24),
          children: [
            // ─── Apple ─────────────────────────────────────────────────────
            _SectionHeader(
                'Sign in with Apple (FFI → ASAuthorizationController)'),
            const SizedBox(height: 8),
            Text(
              _kNeedsAppleCapability,
              style: TextStyle(color: kTextTertiary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _VariantLabel('Native Button widget'),
            const SizedBox(height: 6),
            _NativeSignInButton(
              label: 'Sign in with Apple',
              assetIcon: 'assets/apple-logo.png',
              tintIcon: true,
              isLoading: _appleLoading,
              onTap: _signInWithApple,
            ),
            const SizedBox(height: 10),
            _VariantLabel('GestureDetector + Container'),
            const SizedBox(height: 6),
            _SignInButton(
              label: 'Sign in with Apple',
              assetIcon: 'assets/apple-logo.png',
              tintIcon: true,
              isLoading: _appleLoading,
              onTap: _signInWithApple,
            ),
            const SizedBox(height: 16),
            _ResultCard(
              status: _appleStatus,
              rows: {
                if (_appleGivenName != null) 'Name:': _appleGivenName!,
                if (_appleEmail != null) 'Email:': _appleEmail!,
                if (_appleIdToken != null) 'ID token;': _appleIdToken!,
              },
            ),
            const SizedBox(height: 32),

            // ─── Google ────────────────────────────────────────────────────
            _SectionHeader(
                'Sign in with Google (FFI → GIDSignIn / Credential Manager)'),
            const SizedBox(height: 8),
            Text(
              'iOS: requires GoogleService-Info.plist + REVERSED_CLIENT_ID URL scheme.\n'
              'Android: requires the WEB OAuth 2.0 client ID. Pass it via\n'
              '  dn run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com',
              style: TextStyle(color: kTextTertiary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _VariantLabel('Native Button widget'),
            const SizedBox(height: 6),
            _NativeSignInButton(
              label: 'Sign in with Google',
              assetIcon: 'assets/google-logo.png',
              tintIcon: false,
              isLoading: _googleLoading,
              onTap: _signInWithGoogle,
            ),
            const SizedBox(height: 10),
            _VariantLabel('GestureDetector + Container'),
            const SizedBox(height: 6),
            _SignInButton(
              label: 'Sign in with Google',
              assetIcon: 'assets/google-logo.png',
              tintIcon: false,
              isLoading: _googleLoading,
              onTap: _signInWithGoogle,
            ),
            const SizedBox(height: 16),
            _ResultCard(
              status: _googleStatus,
              rows: {
                if (_googleDisplayName != null) 'Name:': _googleDisplayName!,
                if (_googleEmail != null) 'Email:': _googleEmail!,
                if (_googleIdToken != null) 'ID token:': _googleIdToken!,
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: kTextTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.label,
    required this.assetIcon,
    required this.tintIcon,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final String assetIcon;
  final bool tintIcon;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFF0169FF),
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Image(
              image: AssetImage(assetIcon),
              width: 23,
              height: 23,
              color: tintIcon ? Colors.white : null,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 34),
          ],
        ),
      ),
    );
  }
}

class _NativeSignInButton extends StatelessWidget {
  const _NativeSignInButton({
    required this.label,
    required this.assetIcon,
    required this.tintIcon,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final String assetIcon;
  final bool tintIcon;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Button(
      title: label,
      imageAsset: assetIcon,
      foregroundColor: Colors.white,
      color: const Color(0xFF0169FF),
      shape: const StadiumBorder(),
      height: 44,
      fontSize: 15,
      fontWeight: FontWeight.bold,
      imageSize: 23,
      onPressed: isLoading ? null : onTap,
    );
  }
}

class _VariantLabel extends StatelessWidget {
  const _VariantLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: kTextTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.status, required this.rows});

  final String status;
  final Map<String, String> rows;

  Color get _statusColor {
    if (status.contains('✓')) return const Color(0xFF30D158);
    if (status.contains('Error') || status.contains('error')) {
      return const Color(0xFFFF453A);
    }
    return kTextSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kRowBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: TextStyle(
              color: _statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(color: kChipBg, height: 1),
            const SizedBox(height: 10),
            ...rows.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        e.key,
                        style: TextStyle(
                          color: kTextTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
