/// Storage — sub-menu screen.
///
/// Lists the storage demos (Preferences, SecureStorage, CacheStore, SQLite)
/// so the main playground only needs one "Storage" entry.
import 'package:dartnative/dartnative.dart';

import 'storage_demo.dart';
import 'home/demo_ui.dart';

class StorageMenuScreen extends StatelessWidget {
  const StorageMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Storage',
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
            _StorageCard(
              title: 'Preferences',
              body: 'Persist typed values — booleans, numbers, strings, '
                  'string lists — that survive app restarts. '
                  'Safe to call from any isolate, including background tasks. '
                  'Use it to write tokens or flags from a WorkManager-style task, '
                  'then sync to CacheStore in the foreground.',
              onTap: (ctx) => Navigator.push(
                ctx,
                PageRoute(
                  builder: (_) =>
                      const StorageDemo(initialTab: StorageTab.preferences),
                  settings: '/storage-prefs',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StorageCard(
              title: 'Secure Storage',
              body: 'Store tokens and passwords in the iOS Keychain. '
                  'Encrypted by the OS and persisted across reinstalls. '
                  'Direct FFI — no platform channel.',
              onTap: (ctx) => Navigator.push(
                ctx,
                PageRoute(
                  builder: (_) =>
                      const StorageDemo(initialTab: StorageTab.secureStorage),
                  settings: '/storage-secure',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StorageCard(
              title: 'Hive',
              body: 'File-backed key-value box (community Hive). '
                  'Loads into memory on open, reads are synchronous after that. '
                  'A counter that survives process kills.',
              onTap: (ctx) => Navigator.push(
                ctx,
                PageRoute(
                  builder: (_) =>
                      const StorageDemo(initialTab: StorageTab.hive),
                  settings: '/storage-cache',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StorageCard(
              title: 'SQLite (direct)',
              body: 'Direct SQLite access via dart:ffi. '
                  'Create tables, insert rows, run transactions, '
                  'and walk through schema migrations.',
              onTap: (ctx) => Navigator.push(
                ctx,
                PageRoute(
                  builder: (_) =>
                      const StorageDemo(initialTab: StorageTab.sqlite),
                  settings: '/storage-sqlite',
                ),
              ),
            ),
            const SizedBox(height: 36),
            const _WhySection(),
          ],
        ),
      ),
    );
  }
}

// ── Why section ───────────────────────────────────────────────────────────────

class _WhySection extends StatelessWidget {
  const _WhySection();

  static const _bullets = [
    'All storage calls use dart:ffi directly — no platform channel, no async overhead.',
    'NSUserDefaults and Keychain accessed via native Swift @_cdecl functions called directly from Dart.',
    'CacheStore: synchronous reads after first load, changes written through to SQLite automatically.',
    'SQLite via dart:ffi — compatible with the Zero offline-sync stack.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why DartNative storage?',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ..._bullets.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(color: kTextSecondary, fontSize: 14),
                ),
                Expanded(
                  child: Text(
                    b,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _StorageCard extends StatelessWidget {
  const _StorageCard({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final void Function(BuildContext ctx) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: kRowBg,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
