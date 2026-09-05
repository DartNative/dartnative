/// System tab — OS-backed services: storage, notifications, accounts, device.
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import '../device_orientation_demo.dart';
import '../liquid_glass/liquid_glass_menu.dart';
import '../material3/material3_menu.dart';
import '../notifications_demo.dart';
import '../social_sign_in_demo.dart';
import '../storage_demo.dart';
import '../system_connectivity_demo.dart';
import 'demo_ui.dart';

class SystemTab extends StatelessWidget {
  const SystemTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kHomeBg,
      child: ListView(
        children: [
          SizedBox(height: tabListTopGap(context)),
          // iOS-26-only section: the showcase is about the live material —
          // on other devices the row would open a screen of fallbacks.
          if (isIOS26) ...[
            const SectionHeader('LIQUID GLASS (iOS 26)'),
            DemoRow(
              icon: CupertinoIcons.sparkles,
              tint: kAccentTeal,
              title: 'Liquid Glass',
              tagline: 'The material, the bars — real system glass',
              onTap: (ctx) => Navigator.push(
                ctx,
                PageRoute(
                  builder: (_) => const LiquidGlassMenuScreen(),
                  settings: '/liquid-glass',
                ),
              ),
            ),
          ],
          // Android twin of the Liquid Glass section: the same generic API
          // lowering to Material 3's native components.
          if (Platform.isAndroid) ...[
            const SectionHeader('MATERIAL 3 (Android)'),
            DemoRow(
              icon: MaterialSymbolsRounded.android,
              tint: kAccentGreen,
              title: 'Material 3',
              tagline: 'The real M3 components — one adaptive API',
              onTap: (ctx) => Navigator.push(
                ctx,
                PageRoute(
                  builder: (_) => const Material3MenuScreen(),
                  settings: '/material3',
                ),
              ),
            ),
          ],
          const SectionHeader('STORAGE'),
          DemoRow(
            icon: CupertinoIcons.archivebox_fill,
            tint: kAccentBlue,
            title: 'Preferences',
            tagline: 'NSUserDefaults / SharedPreferences',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) =>
                    const StorageDemo(initialTab: StorageTab.preferences),
                settings: '/storage-prefs',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.lock_fill,
            tint: kAccentGreen,
            title: 'Secure Storage',
            tagline: 'Keychain / Android Keystore',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) =>
                    const StorageDemo(initialTab: StorageTab.secureStorage),
                settings: '/storage-secure',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.tray_full_fill,
            tint: kAccentOrange,
            title: 'Cache (Hive)',
            tagline: 'In-memory + persisted CacheBox',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const StorageDemo(initialTab: StorageTab.hive),
                settings: '/storage-cache',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.table,
            tint: kAccentPurple,
            title: 'SQLite',
            tagline: 'SQL + transactions over FFI',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) =>
                    const StorageDemo(initialTab: StorageTab.sqlite),
                settings: '/storage-sqlite',
              ),
            ),
          ),
          const SectionHeader('NOTIFICATIONS & ACCOUNTS'),
          DemoRow(
            icon: CupertinoIcons.bell_fill,
            tint: kAccentRed,
            title: 'Notifications (FCM)',
            tagline: 'Push via FFI — zero MethodChannel',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const NotificationsDemo(),
                settings: '/notifications',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.person_crop_circle,
            tint: kAccentIndigo,
            title: 'Social Sign-In',
            tagline: 'Sign in with Apple + Google, natively',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const SocialSignInDemo(),
                settings: '/social-sign-in',
              ),
            ),
          ),
          const SectionHeader('DEVICE'),
          DemoRow(
            icon: CupertinoIcons.antenna_radiowaves_left_right,
            tint: kAccentTeal,
            title: 'System + Connectivity',
            tagline: 'PackageInfo, app badge, NWPathMonitor',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const SystemConnectivityDemo(),
                settings: '/system-connectivity',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.rotate_right_fill,
            tint: kAccentYellow,
            title: 'Device Orientation',
            tagline: '4-way physical orientation events',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const DeviceOrientationDemo(),
                settings: '/device-orientation',
              ),
            ),
          ),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}
