/// Notifications demo.
///
/// Showcases dartnative_firebase (FCM) + dartnative_notifications:
///   - Request APNs / FCM permission
///   - Fetch FCM registration token
///   - Send a standard local alert notification (via FCM foreground handler)
///   - Send a Communication-style iOS 15+ notification (chat banner with avatar)
///
/// ## Prerequisites (replace with your own configs before testing)
///   • Supply your own Firebase config at
///     playground/ios/Runner/GoogleService-Info.plist.
///   • Push Notifications + Background Modes (Remote notifications) capabilities
///     must be enabled in the Runner target.
///   • dartnative_notifications added to pubspec.yaml (path dep).
///   • The device must be physical (APNs does not work on the simulator).
///
/// The demo works read-only without a backend — it shows the local token and
/// lets you trigger a *local* communication notification so you can see the
/// iOS chat-style banner without a real push.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';

import 'package:dartnative_firebase/dartnative_firebase.dart';
import 'package:dartnative_notifications/dartnative_notifications.dart';
import 'home/demo_ui.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class NotificationsDemo extends StatefulWidget {
  const NotificationsDemo({super.key});

  @override
  State<NotificationsDemo> createState() => _NotificationsDemoState();
}

class _NotificationsDemoState extends State<NotificationsDemo> {
  // ── Permission ────────────────────────────────────────────────────────────
  bool? _permissionGranted;
  bool _permissionLoading = false;

  // ── Token ─────────────────────────────────────────────────────────────────
  String? _fcmToken;
  bool _tokenLoading = false;

  // ── Foreground message stream ─────────────────────────────────────────────
  final List<String> _receivedMessages = [];

  // ── Communication notification ────────────────────────────────────────────
  String _commStatus = '';
  bool _commLoading = false;

  // ── Default notification ──────────────────────────────────────────────────
  String _defaultStatus = '';

  @override
  void initState() {
    super.initState();
    // Listen for foreground FCM messages throughout demo lifetime.
    if (Platform.isIOS) {
      FirebaseMessaging.onMessage.listen((msg) {
        setState(() {
          _receivedMessages.insert(
            0,
            '[${msg.from}] ${msg.notificationTitle ?? ''}: '
            '${msg.notificationBody ?? '(no body)'}',
          );
        });
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _permissionLoading = true);
    try {
      // dartnative_notifications handles permission on both platforms:
      //   iOS  — UNUserNotificationCenter.requestAuthorization (also covers APNs/FCM)
      //   Android — POST_NOTIFICATIONS runtime permission (API 33+)
      final granted = await DartNativeNotifications.requestPermission();
      if (!mounted) return;
      setState(() => _permissionGranted = granted);
    } catch (e) {
      if (mounted) setState(() => _permissionGranted = false);
    } finally {
      if (mounted) setState(() => _permissionLoading = false);
    }
  }

  Future<void> _fetchToken() async {
    if (!Platform.isIOS) return;
    setState(() {
      _tokenLoading = true;
      _fcmToken = null;
    });
    try {
      final token = await FirebaseMessaging.getToken();
      if (!mounted) return;
      setState(() => _fcmToken = token ?? '(null — check APNs entitlements)');
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _fcmToken =
          'Timed out — Push Notifications capability missing in Runner target, '
              'or Firebase init failed (check logs).');
    } catch (e) {
      if (mounted) setState(() => _fcmToken = 'Error: $e');
    } finally {
      if (mounted) setState(() => _tokenLoading = false);
    }
  }

  Future<void> _showCommunicationNotification() async {
    setState(() {
      _commLoading = true;
      _commStatus = 'Downloading avatar…';
    });
    try {
      // Download a real avatar image for the communication notification.
      Uint8List avatar;
      try {
        final request =
            await HttpClient().getUrl(Uri.parse('https://i.pravatar.cc/300'));
        request.headers.set(HttpHeaders.acceptHeader, 'image/jpeg,image/*');
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
        }
        avatar = Uint8List.fromList(bytes);
      } catch (_) {
        // Network unavailable — send notification without a custom avatar.
        avatar = Uint8List(0);
      }

      if (!mounted) return;
      DartNativeNotifications.showChat(
        id: 'demo-chat-1',
        senderName: 'dartnative Bot',
        body: 'Hello from dartnative 👋  This is a Communication Notification.',
        avatar: avatar,
        payload: '{}',
      );
      setState(() => _commStatus = 'Chat notification sent ✓');
    } catch (e) {
      if (mounted) setState(() => _commStatus = 'Error: $e');
    } finally {
      if (mounted) setState(() => _commLoading = false);
    }
  }

  void _showDefaultNotification() {
    try {
      DartNativeNotifications.show(
        id: 'demo-default-1',
        title: 'dartnative',
        body: 'Hello from dartnative 👋  This is a default notification.',
        payload: '{}',
      );
      setState(() => _defaultStatus = 'Default notification sent ✓');
    } catch (e) {
      setState(() => _defaultStatus = 'Error: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Notifications (FCM)',
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
            // ── Intro ─────────────────────────────────────────────────────
            const _SectionHeader('How it works'),
            const SizedBox(height: 8),
            Text(
              'dartnative_firebase replaces firebase_messaging with a zero-channel '
              'FFI implementation. The FCM delegate is installed at app startup in '
              'main() — so the token is ready immediately.\n\n'
              'Bring your own Firebase project: place its '
              'GoogleService-Info.plist in ios/Runner.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // ── Permission ────────────────────────────────────────────────
            const _SectionHeader('1 · Request Permission'),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'Request APNs + FCM Permission',
              isLoading: _permissionLoading,
              onTap: _requestPermission,
            ),
            if (_permissionGranted != null) ...[
              const SizedBox(height: 10),
              _ResultRow(
                label: 'Permission',
                value: _permissionGranted! ? 'Granted ✓' : 'Denied ✗',
                valueColor: _permissionGranted!
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
              ),
            ],
            const SizedBox(height: 24),

            // ── Token (FCM, iOS only) ─────────────────────────────────────
            if (Platform.isIOS) ...[
              const _SectionHeader('2 · FCM Registration Token'),
              const SizedBox(height: 8),
              Text(
                'This token is what your server sends push notifications to. '
                'It is fetched via FFI → Messaging.token — no MethodChannel.',
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _ActionButton(
                label: 'Get FCM Token',
                isLoading: _tokenLoading,
                onTap: _fetchToken,
              ),
              if (_fcmToken != null) ...[
                const SizedBox(height: 10),
                _ResultRow(label: 'Token', value: _fcmToken!),
              ],
              const SizedBox(height: 24),
            ],

            // ── Local notifications ────────────────────────────────────────
            const _SectionHeader('3 · Local Notifications'),
            const SizedBox(height: 8),
            Text(
              'Trigger local notifications via dartnative_notifications — '
              'pure FFI, zero MethodChannel.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'Show Default Notification',
              isLoading: false,
              onTap: _showDefaultNotification,
            ),
            if (_defaultStatus.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ResultRow(
                label: 'Status',
                value: _defaultStatus,
                valueColor: _defaultStatus.startsWith('Error')
                    ? const Color(0xFFFF3B30)
                    : const Color(0xFF34C759),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              Platform.isIOS
                  ? 'iOS 15+ "Communication Notifications" appear as '
                      'chat-style banners with an avatar and sender name — '
                      'the style messaging apps use for incoming messages. '
                      'Implemented via INSendMessageIntent — pure FFI.'
                  : 'Android chat notifications show the sender name as title '
                      'and the avatar as a circle in the notification.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'Show Chat Notification',
              isLoading: _commLoading,
              onTap: _showCommunicationNotification,
            ),
            if (_commStatus.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ResultRow(
                label: 'Chat',
                value: _commStatus,
                valueColor: _commStatus.startsWith('Error')
                    ? const Color(0xFFFF3B30)
                    : const Color(0xFF34C759),
              ),
            ],
            const SizedBox(height: 24),

            // ── Foreground message log (FCM, iOS only) ────────────────────
            if (Platform.isIOS) ...[
              const _SectionHeader('4 · Foreground Message Log'),
              const SizedBox(height: 8),
              Text(
                'Messages received via FirebaseMessaging.onMessage while the app '
                'is in the foreground appear here in real time.',
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (_receivedMessages.isEmpty)
                Text(
                  'No messages yet — send a test push from the Firebase Console.',
                  style: TextStyle(
                      color: kTextTertiary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                )
              else
                ..._receivedMessages.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ResultRow(label: '', value: m),
                  ),
                ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Small shared widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: kTextPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: kRowBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kChipBg),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF0A84FF),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0A84FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;

  /// `null` → themed secondary text color.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kRowBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: label.isEmpty
          ? Text(value,
              style: TextStyle(
                  color: valueColor ?? kTextSecondary,
                  fontSize: 13,
                  fontFamily: 'monospace'))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label  ',
                  style: TextStyle(color: kTextTertiary, fontSize: 13),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? kTextSecondary,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
