/// Permissions demo — mirrors the upstream `permission_handler` example:
/// a list of permissions, each row showing its current (colour-coded) status;
/// tap a row to `request()` it, and use "Open app settings" to jump to the
/// system settings page when a permission is permanently denied.
///
/// Exercises the public API on iOS and Android:
///   • Permission.x.status   — current status, no dialog
///   • Permission.x.request() — show the system prompt, return the new status
///   • openAppSettings()      — open this app's Settings page
///
/// Visual chrome: Scaffold + AppBar (white title on a dark-gray bar) over
/// a black ListView body.
library;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_permissions/dartnative_permissions.dart';

class PermissionsDemoApp extends StatelessWidget {
  const PermissionsDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App(
      title: 'dartnative_permissions',
      theme: ThemeData.dark(),
      home: const PermissionsDemoScreen(),
    );
  }
}

class PermissionsDemoScreen extends StatefulWidget {
  const PermissionsDemoScreen({super.key});

  @override
  State<PermissionsDemoScreen> createState() => _PermissionsDemoScreenState();
}

class _PermissionsDemoScreenState extends State<PermissionsDemoScreen> {
  /// The permissions this demo shows, with display labels. Storage and videos
  /// have no iOS mapping (resolve to granted there) but map to real runtime
  /// permissions on Android.
  static const List<(Permission, String)> _permissions = [
    (Permission.camera, 'Camera'),
    (Permission.microphone, 'Microphone'),
    (Permission.photos, 'Photos'),
    (Permission.videos, 'Videos'),
    (Permission.location, 'Location'),
    (Permission.locationWhenInUse, 'Location (when in use)'),
    (Permission.contacts, 'Contacts'),
    (Permission.notification, 'Notifications'),
    (Permission.storage, 'Storage'),
  ];

  final Map<Permission, PermissionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _loadStatuses() async {
    for (final (permission, _) in _permissions) {
      final status = await permission.status;
      if (!mounted) return;
      setState(() => _statuses[permission] = status);
    }
  }

  Future<void> _request(Permission permission) async {
    final status = await permission.request();
    if (!mounted) return;
    setState(() => _statuses[permission] = status);
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
          'dartnative_permissions',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          const Text(
            'Tap a permission to request it. The coloured dot shows its '
            'current status; green = granted, red = denied, grey = '
            'permanently denied.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 16),
          _ActionButton(label: 'Open app settings', onTap: openAppSettings),
          const SizedBox(height: 20),
          for (final (permission, label) in _permissions) ...[
            _PermissionTile(
              label: label,
              status: _statuses[permission],
              onTap: () => _request(permission),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.label,
    required this.status,
    required this.onTap,
  });

  final String label;
  final PermissionStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _statusColor(status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 15),
              ),
            ),
            Text(
              _statusLabel(status),
              style: TextStyle(color: _statusColor(status), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.emphasized = true,
  });
  final String label;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: disabled
                ? const Color(0xFF48484A)
                : emphasized
                ? const Color(0xFF0A84FF)
                : const Color(0xFF8E8E93),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

String _statusLabel(PermissionStatus? status) => switch (status) {
  null => '…',
  PermissionStatus.granted => 'granted',
  PermissionStatus.denied => 'denied',
  PermissionStatus.permanentlyDenied => 'permanently denied',
  PermissionStatus.limited => 'limited',
  PermissionStatus.restricted => 'restricted',
  PermissionStatus.provisional => 'provisional',
};

Color _statusColor(PermissionStatus? status) => switch (status) {
  PermissionStatus.granted => const Color(0xFF30D158), // green
  PermissionStatus.denied => const Color(0xFFFF453A), // red
  PermissionStatus.limited => const Color(0xFFFF9F0A), // orange
  PermissionStatus.provisional => const Color(0xFF0A84FF), // blue
  _ => const Color(0xFF8E8E93), // grey: permanentlyDenied / restricted / null
};
