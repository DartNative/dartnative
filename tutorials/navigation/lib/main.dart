/// DartNative tutorial — navigation & routes.
///
/// A three-screen mini-app covering the whole navigation surface:
///   • Navigator.push + PageRoute — the standard slide-from-right
///   • registerRoutes + Navigator.pushNamed — named routes
///   • PageRoute(transition: slideFromBottom) — the slide-up full-screen route
///   • the automatic back button + the OS back gesture, for free
///
/// There is no MaterialApp and no routes: map on a root widget — routes are
/// registered once in main(), and every transition is the platform's own.
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // #region routes
  // Named routes, registered once. Any screen can Navigator.pushNamed them.
  registerRoutes({
    '/settings': (_) => const SettingsScreen(),
  });
  // #endregion routes
  runApp(const HomeScreen());
}

// ── Screen 1: home ───────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      brightness: Brightness.light,
      appBar: AppBar(
        title: const Text(
          'Navigation',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // #region push
          _NavCard(
            title: 'Push a screen',
            subtitle: 'Navigator.push — native slide, swipe back to return',
            onTap: () => Navigator.push(
              context,
              PageRoute(builder: (_) => const DetailScreen()),
            ),
          ),
          // #endregion push
          // #region push-named
          _NavCard(
            title: 'Push a named route',
            subtitle: "pushNamed('/settings') — registered in main()",
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          // #endregion push-named
          // #region slide-up
          _NavCard(
            title: 'Slide-up route',
            subtitle: 'PageRoute with RouteTransition.slideFromBottom',
            onTap: () => Navigator.push(
              context,
              PageRoute(
                builder: (_) => const ComposeScreen(),
                transition: RouteTransition.slideFromBottom,
                duration: const Duration(milliseconds: 380),
              ),
            ),
          ),
          // #endregion slide-up
        ],
      ),
    );
  }
}

// ── Screen 2: a pushed detail (automatic back button) ───────────────────────

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      brightness: Brightness.light,
      // automaticallyImplyLeading defaults to true: because this screen CAN
      // pop, the native back button appears — and the OS edge-swipe works.
      appBar: AppBar(
        title: const Text(
          'Detail',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Swipe from the left edge (iOS) or use the system back gesture '
            '(Android). Nothing was wired for that — the navigation stack '
            'is the platform\'s own.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF3C3C43), fontSize: 15, height: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Screen 3: a named route ──────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      brightness: Brightness.light,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Reached via Navigator.pushNamed(context, \'/settings\')',
          style: TextStyle(color: Color(0xFF6B6B70), fontSize: 14),
        ),
      ),
    );
  }
}

// ── Screen 4: a slide-up route (bottom-up transition, explicit close) ───────

class ComposeScreen extends StatelessWidget {
  const ComposeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      brightness: Brightness.light,
      appBar: AppBar(
        automaticallyImplyLeading: false, // slide-up screens close, not "back"
        title: const Text(
          'Compose',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          BarButtonItem(
            title: 'Close',
            titleStyle: const TextStyle(color: Color(0xFF0A84FF), fontSize: 16),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Presented with RouteTransition.slideFromBottom.',
          style: TextStyle(color: Color(0xFF6B6B70), fontSize: 14),
        ),
      ),
    );
  }
}

// ── Shared row card ──────────────────────────────────────────────────────────

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF6B6B70), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
