// dartnative_firebase example app.
//
// Internal test bed for the dartnative_firebase plugin. Mirrors a subset of
// the upstream firebase_messaging example UI (subscribe/unsubscribe topics,
// APNs token, send-test-message HTTP button) and exercises every public API
// of the plugin (foreground messages, tap handling, initial message, topics).
//
// On iOS, also installs the AppDelegate forwarder for silent-push delivery
// while the app is suspended in background (see ios/Runner/AppDelegate.swift).

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_skia/dartnative_skia.dart';
import 'package:dartnative_firebase/dartnative_firebase.dart';
import 'package:http/http.dart' as http;

import 'dartnative_plugin_registrant.dart';

void main() {
  runZonedGuarded(
    () {
      DartNativeLogger.run(() async {
        DartNativePluginRegistrant.registerAll();
        registerSkiaFactories();

        try {
          await Firebase.initializeApp();
          FirebaseMessaging.setup();
        } catch (e, st) {
          // ignore: avoid_print
          print('[main] Firebase init failed — continuing degraded: $e\n$st');
        }

        runApp(const FirebaseExampleApp());
      });
    },
    (error, stack) {
      // ignore: avoid_print
      print('[zone] uncaught: $error\n$stack');
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Root
// ─────────────────────────────────────────────────────────────────────────────

class FirebaseExampleApp extends StatelessWidget {
  const FirebaseExampleApp({super.key});

  @override
  Widget build(BuildContext context) => const MessagingScreen();
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  bool? _permissionGranted;
  bool _permissionLoading = false;

  String? _fcmToken;
  bool _tokenLoading = false;

  String? _apnsToken;
  bool _apnsLoading = false;

  bool _topicLoading = false;
  String _topicStatus = '';

  String? _initialMessageJson;

  final List<String> _foregroundLog = [];
  final List<String> _openedLog = [];

  bool _sendingPush = false;
  String _sendStatus = '';

  static const String _testTopic = 'fcm_test';
  // FCM legacy HTTP endpoint. Pass the project's Cloud Messaging
  // *legacy* server key at run time:
  //   --dart-define=FCM_LEGACY_SERVER_KEY=AAAA...
  // (Firebase Console → Project settings → Cloud Messaging → Cloud
  //  Messaging API (Legacy). If disabled, click "Manage API in Google
  //  Cloud Console" and enable it.)
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';
  static const String _legacyServerKeyDefine = String.fromEnvironment(
    'FCM_LEGACY_SERVER_KEY',
  );
  String get _legacyServerKey => _legacyServerKeyDefine;

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((msg) {
      setState(() {
        _foregroundLog.insert(
          0,
          '[${msg.from}] ${msg.notificationTitle ?? '(no title)'}: '
          '${msg.notificationBody ?? '(no body)'}  data=${msg.data}',
        );
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      setState(() {
        _openedLog.insert(
          0,
          '[${msg.from}] ${msg.notificationTitle ?? '(no title)'}: '
          '${msg.notificationBody ?? '(no body)'}',
        );
      });
    });

    Future<void>.delayed(const Duration(seconds: 2), () async {
      try {
        final initial = await FirebaseMessaging.getInitialMessage();
        if (initial != null && mounted) {
          setState(
            () => _initialMessageJson = const JsonEncoder.withIndent('  ')
                .convert({
                  'from': initial.from,
                  'messageId': initial.messageId,
                  'title': initial.notificationTitle,
                  'body': initial.notificationBody,
                  'data': initial.data,
                }),
          );
        }
      } catch (_) {}
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    setState(() => _permissionLoading = true);
    try {
      final granted = await FirebaseMessaging.requestPermission();
      setState(() => _permissionGranted = granted);
    } catch (_) {
      setState(() => _permissionGranted = false);
    } finally {
      setState(() => _permissionLoading = false);
    }
  }

  Future<void> _fetchToken() async {
    setState(() {
      _tokenLoading = true;
      _fcmToken = '…';
    });
    try {
      final token = await FirebaseMessaging.getToken();
      setState(() => _fcmToken = token ?? '(null)');
    } on TimeoutException {
      setState(() => _fcmToken = 'Timed out — check APNs / Firebase config.');
    } catch (e) {
      setState(() => _fcmToken = 'Error: $e');
    } finally {
      setState(() => _tokenLoading = false);
    }
  }

  Future<void> _fetchAPNSToken() async {
    if (!Platform.isIOS) return;
    setState(() {
      _apnsLoading = true;
      _apnsToken = '…';
    });
    try {
      final token = await FirebaseMessaging.getAPNSToken();
      setState(
        () => _apnsToken = token == null || token.isEmpty
            ? '(null — not yet registered)'
            : token,
      );
    } catch (e) {
      setState(() => _apnsToken = 'Error: $e');
    } finally {
      setState(() => _apnsLoading = false);
    }
  }

  Future<void> _subscribe() async {
    setState(() {
      _topicLoading = true;
      _topicStatus = 'Subscribing to "$_testTopic"…';
    });
    try {
      await FirebaseMessaging.subscribeToTopic(_testTopic);
      setState(() => _topicStatus = 'Subscribed to "$_testTopic" ✓');
    } catch (e) {
      setState(() => _topicStatus = 'Error: $e');
    } finally {
      setState(() => _topicLoading = false);
    }
  }

  Future<void> _unsubscribe() async {
    setState(() {
      _topicLoading = true;
      _topicStatus = 'Unsubscribing from "$_testTopic"…';
    });
    try {
      await FirebaseMessaging.unsubscribeFromTopic(_testTopic);
      setState(() => _topicStatus = 'Unsubscribed from "$_testTopic" ✓');
    } catch (e) {
      setState(() => _topicStatus = 'Error: $e');
    } finally {
      setState(() => _topicLoading = false);
    }
  }

  Future<void> _sendTestPush() async {
    if (_fcmToken == null ||
        _fcmToken!.startsWith('Error') ||
        _fcmToken!.startsWith('Timed') ||
        _fcmToken == '(null)') {
      setState(() => _sendStatus = 'Fetch a valid FCM token first.');
      return;
    }
    if (_legacyServerKey.isEmpty) {
      setState(
        () => _sendStatus =
            'No FCM_LEGACY_SERVER_KEY — set it in .env (or pass --dart-define).',
      );
      return;
    }
    setState(() {
      _sendingPush = true;
      _sendStatus = 'Sending…';
    });
    try {
      final res = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'key=$_legacyServerKey',
        },
        body: jsonEncode({
          'to': _fcmToken,
          'priority': 'high',
          'notification': {
            'title': 'Hello from dartnative!',
            'body': 'Test push at ${DateTime.now()}',
          },
          'data': {
            'via': 'dartnative_firebase example',
            'when': DateTime.now().toIso8601String(),
          },
        }),
      );
      final body = res.body.length > 120
          ? '${res.body.substring(0, 120)}…'
          : res.body;
      setState(() => _sendStatus = 'HTTP ${res.statusCode} — $body');
    } catch (e) {
      setState(() => _sendStatus = 'Error: $e');
    } finally {
      setState(() => _sendingPush = false);
    }
  }

  Future<void> _copyToken() async {
    if (_fcmToken == null ||
        _fcmToken!.startsWith('Error') ||
        _fcmToken!.startsWith('Timed') ||
        _fcmToken == '(null)') {
      setState(() => _sendStatus = 'Fetch a valid FCM token first.');
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      setState(
        () => _sendStatus =
            'Token copied. Open Firebase Console → Cloud Messaging → '
            '"Send test message", paste, send.',
      );
    } catch (e) {
      setState(() => _sendStatus = 'Error: $e');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'dartnative_firebase',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _Section('1 · Permission'),
          const SizedBox(height: 8),
          _Btn(
            label: 'Request notification permission',
            loading: _permissionLoading,
            onTap: _requestPermission,
          ),
          if (_permissionGranted != null) ...[
            const SizedBox(height: 8),
            _Row(
              'Result',
              _permissionGranted! ? 'Granted ✓' : 'Denied ✗',
              color: _permissionGranted!
                  ? const Color(0xFF34C759)
                  : const Color(0xFFFF3B30),
            ),
          ],
          const SizedBox(height: 24),

          const _Section('2 · Tokens'),
          const SizedBox(height: 8),
          _Btn(
            label: 'Get FCM registration token',
            loading: _tokenLoading,
            onTap: _fetchToken,
          ),
          if (_fcmToken != null) ...[
            const SizedBox(height: 8),
            _Row('FCM', _fcmToken!),
          ],
          if (Platform.isIOS) ...[
            const SizedBox(height: 12),
            _Btn(
              label: 'Get APNs token (iOS)',
              loading: _apnsLoading,
              onTap: _fetchAPNSToken,
            ),
            if (_apnsToken != null) ...[
              const SizedBox(height: 8),
              _Row('APNs', _apnsToken!),
            ],
          ],
          const SizedBox(height: 24),

          const _Section('3 · Topics ("$_testTopic")'),
          const SizedBox(height: 8),
          _Btn(label: 'Subscribe', loading: _topicLoading, onTap: _subscribe),
          const SizedBox(height: 8),
          _Btn(
            label: 'Unsubscribe',
            loading: _topicLoading,
            onTap: _unsubscribe,
          ),
          if (_topicStatus.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Row('Status', _topicStatus),
          ],
          const SizedBox(height: 24),

          const _Section('4 · Send test push'),
          const SizedBox(height: 8),
          const Text(
            'Send: posts directly to FCM legacy HTTP API. Requires '
            '--dart-define=FCM_LEGACY_SERVER_KEY=AAAA…\n'
            'Copy token: paste into Firebase Console → Cloud Messaging '
            '→ "Send test message".',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
          ),
          const SizedBox(height: 8),
          _Btn(label: 'Send', loading: _sendingPush, onTap: _sendTestPush),
          const SizedBox(height: 8),
          _Btn(label: 'Copy token', loading: false, onTap: _copyToken),
          if (_sendStatus.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Row('Send', _sendStatus),
          ],
          const SizedBox(height: 24),

          const _Section('5 · Initial message (cold-launch tap)'),
          const SizedBox(height: 8),
          _Row(
            'Result',
            _initialMessageJson ??
                '(none — launch the app via a notification tap)',
          ),
          const SizedBox(height: 24),

          const _Section('6 · Notification taps'),
          const SizedBox(height: 8),
          if (_openedLog.isEmpty)
            const _Empty('No taps yet')
          else
            ..._openedLog.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _Row('', m),
              ),
            ),
          const SizedBox(height: 24),

          const _Section('7 · Foreground messages'),
          const SizedBox(height: 8),
          if (_foregroundLog.isEmpty)
            const _Empty('No foreground messages yet')
          else
            ..._foregroundLog.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _Row('', m),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.loading, required this.onTap});
  final String label;
  final bool loading;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3A3A3C)),
        ),
        alignment: Alignment.center,
        child: Text(
          loading ? '…' : label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0A84FF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.color = const Color(0xFFAEAEB2)});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: label.isEmpty
          ? Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label  ',
                  style: const TextStyle(
                    color: Color(0xFF636366),
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF636366),
      fontSize: 12,
      fontStyle: FontStyle.italic,
    ),
  );
}
