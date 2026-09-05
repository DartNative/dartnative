/// Notifications demo — standalone example for dartnative_notifications.
///
/// Tests all local notification APIs without Firebase:
///   - Request notification permission
///   - Show a standard alert notification
///   - Show a Communication-style chat notification (iOS 15+ INSendMessageIntent)
///   - Cancel a specific notification
///   - Cancel all notifications
///   - Display tapped notification payload in real time
///
/// No backend or push server needed. All notifications are triggered locally
/// so the plugin can be tested on its own.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_notifications/dartnative_notifications.dart';

class NotificationsDemo extends StatefulWidget {
  const NotificationsDemo({super.key});

  @override
  State<NotificationsDemo> createState() => _NotificationsDemoState();
}

class _NotificationsDemoState extends State<NotificationsDemo> {
  // ── Permission ────────────────────────────────────────────────────────────
  bool? _permissionGranted;
  bool _permissionLoading = false;

  // ── Notification status ───────────────────────────────────────────────────
  String _defaultStatus = '';
  String _commStatus = '';
  bool _commLoading = false;
  String _cancelStatus = '';

  // ── Tap payload ───────────────────────────────────────────────────────────
  final List<String> _tapPayloads = [];
  StreamSubscription<String>? _tapSub;

  @override
  void initState() {
    super.initState();
    _tapSub = DartNativeNotifications.onTap.listen((payload) {
      if (mounted) setState(() => _tapPayloads.insert(0, payload));
    });
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    setState(() => _permissionLoading = true);
    try {
      final granted = await DartNativeNotifications.requestPermission();
      setState(() => _permissionGranted = granted);
    } catch (e) {
      setState(() => _permissionGranted = false);
    } finally {
      setState(() => _permissionLoading = false);
    }
  }

  void _showDefaultNotification() {
    try {
      DartNativeNotifications.show(
        id: 'demo-default-1',
        title: 'dartnative_notifications',
        body: 'Hello from dartnative 👋  This is a standard notification.',
        payload: '{"type":"default","id":"demo-default-1"}',
      );
      setState(() => _defaultStatus = 'Sent ✓ — background the app to see it');
    } catch (e) {
      setState(() => _defaultStatus = 'Error: $e');
    }
  }

  Future<void> _showChatNotification() async {
    setState(() {
      _commLoading = true;
      _commStatus = 'Downloading avatar…';
    });
    try {
      Uint8List avatar;
      try {
        final request = await HttpClient().getUrl(
          Uri.parse('https://i.pravatar.cc/300'),
        );
        request.headers.set(HttpHeaders.acceptHeader, 'image/jpeg,image/*');
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
        }
        avatar = Uint8List.fromList(bytes);
      } catch (_) {
        avatar = Uint8List(0); // no avatar if network is unavailable
      }

      DartNativeNotifications.showChat(
        id: 'demo-chat-1',
        senderName: 'dartnative Bot',
        body:
            'Hello from dartnative 👋  This is a Communication Notification.',
        avatar: avatar,
        payload: '{"type":"chat","id":"demo-chat-1"}',
      );
      setState(() => _commStatus = 'Sent ✓ — background the app to see it');
    } catch (e) {
      setState(() => _commStatus = 'Error: $e');
    } finally {
      setState(() => _commLoading = false);
    }
  }

  void _cancelOne() {
    DartNativeNotifications.cancel('demo-default-1');
    DartNativeNotifications.cancel('demo-chat-1');
    setState(() => _cancelStatus = 'Cancelled demo-default-1 + demo-chat-1 ✓');
  }

  void _cancelAll() {
    DartNativeNotifications.cancelAll();
    setState(() => _cancelStatus = 'All notifications cancelled ✓');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
          'Notifications Demo',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Intro ─────────────────────────────────────────────────────
          const _SectionHeader('How it works'),
          const SizedBox(height: 8),
          const Text(
            'All notifications are triggered locally — no push server or Firebase '
            'needed. Background the app after sending to see the banner.\n\n'
            'iOS 15+: Chat notification uses INSendMessageIntent and appears as a '
            'communication notification with avatar + sender name.\n'
            'Android: Chat notification uses MessagingStyle with a Person.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── Permission ────────────────────────────────────────────────
          const _SectionHeader('1 · Request Permission'),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Request Notification Permission',
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

          // ── Default notification ──────────────────────────────────────
          const _SectionHeader('2 · Default Notification'),
          const SizedBox(height: 8),
          const Text(
            'Plain alert — title, body, payload. Zero MethodChannel.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
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
          const SizedBox(height: 24),

          // ── Chat notification ─────────────────────────────────────────
          const _SectionHeader('3 · Chat Notification'),
          const SizedBox(height: 8),
          const Text(
            'Downloads a real avatar from pravatar.cc, then sends a '
            'communication notification with sender name + avatar circle.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Show Chat Notification',
            isLoading: _commLoading,
            onTap: _showChatNotification,
          ),
          if (_commStatus.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ResultRow(
              label: 'Status',
              value: _commStatus,
              valueColor: _commStatus.startsWith('Error')
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFF34C759),
            ),
          ],
          const SizedBox(height: 24),

          // ── Cancel ────────────────────────────────────────────────────
          const _SectionHeader('4 · Cancel'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Cancel Demo',
                  isLoading: false,
                  onTap: _cancelOne,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Cancel All',
                  isLoading: false,
                  onTap: _cancelAll,
                ),
              ),
            ],
          ),
          if (_cancelStatus.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ResultRow(
              label: 'Cancel',
              value: _cancelStatus,
              valueColor: const Color(0xFF34C759),
            ),
          ],
          const SizedBox(height: 24),

          // ── Tap log ───────────────────────────────────────────────────
          const _SectionHeader('5 · Tap Payload Log'),
          const SizedBox(height: 8),
          const Text(
            'Tap a delivered notification to bring the app to the foreground. '
            'The payload appears here in real time via DartNativeNotifications.onTap.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (_tapPayloads.isEmpty)
            const Text(
              'No taps yet — send a notification, background the app, then tap it.',
              style: TextStyle(
                color: Color(0xFF636366),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ..._tapPayloads.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ResultRow(label: 'Payload', value: p),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
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
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3C)),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
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
    this.valueColor = const Color(0xFFAEAEB2),
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF636366),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        Expanded(
          child: Text(value, style: TextStyle(color: valueColor, fontSize: 13)),
        ),
      ],
    );
  }
}
