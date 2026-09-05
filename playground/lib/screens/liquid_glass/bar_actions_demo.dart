/// Liquid Glass — the BARS, part 1: Dart widgets inside real nav-bar glass
/// pills, the capsule→UIMenu morph, and glass riding a route transition.
///
/// A platform-view bar is an island: its buttons must be native content
/// configured over a bridge, and glass composited that way cannot ride a
/// route transition or sit under a sheet. Here the bar IS the screen's
/// bar: pills host Dart widgets, the morph is the system's own, and
/// transitions are just UIKit compositing UIKit.
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class BarActionsDemo extends StatefulWidget {
  const BarActionsDemo({super.key});

  @override
  State<BarActionsDemo> createState() => _BarActionsDemoState();
}

class _BarActionsDemoState extends State<BarActionsDemo> {
  String _lastAction = '(none yet)';

  void _pick(String name) => setState(() => _lastAction = name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Bar Actions',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isIOS26 ? kBarBgGlass : kBarBg,
        actions: [
          // The ⋯ morph button — a menu action must be the bar's ONLY action.
          BarButtonItem(
            icon: 'ellipsis',
            menu: [
              MenuAction(
                title: 'Share',
                icon: Platform.isAndroid
                    ? MaterialSymbolsRounded.share
                    : CupertinoIcons.square_arrow_up,
                onTap: () => _pick('Share'),
              ),
              MenuAction(
                title: 'Select',
                icon: Platform.isAndroid
                    ? MaterialSymbolsRounded.check_circle
                    : CupertinoIcons.checkmark_circle,
                onTap: () => _pick('Select'),
              ),
              MenuAction(
                title: 'Delete',
                icon: Platform.isAndroid
                    ? MaterialSymbolsRounded.delete
                    : CupertinoIcons.trash,
                destructive: true,
                onTap: () => _pick('Delete'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: kHomeBg,
      body: ListView(
        children: [
          SizedBox(
              height: isIOS26
                  ? 8
                  : 12), // bar clearance is AUTOMATIC now (null-padding scrollable + extendBodyBehindAppBar); keep only the breathing gap
          const SectionHeader('CAPSULE → MENU MORPH'),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 10),
            child: Text(
              'Tap the ⋯ capsule in the bar: the glass morphs into the '
              'system menu — the WhatsApp behavior. Items are plain Dart '
              'closures and stay fresh across rebuilds. On Android the same '
              'API anchors a Material popup to the action.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Last menu action: $_lastAction',
                  style: TextStyle(color: kTextPrimary, fontSize: 15),
                ),
              ),
            ),
          ),
          const SectionHeader('WIDGETS IN PILLS + TRANSITIONS'),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 10),
            child: Text(
              'Push a screen whose bar stacks THREE glass actions — each '
              'pill hosts a Dart widget (one even carries a live Badge). '
              'Watch the glass through the push and the swipe-back: it '
              'stays glass the whole way.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                PageRoute(
                  builder: (_) => const _MultiActionsScreen(),
                  settings: '/liquid-glass-bar-actions-multi',
                ),
              ),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Push the multi-actions screen',
                    style: TextStyle(
                      color: kAccentBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SectionHeader('NATIVE ACTION BADGE'),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 10),
            child: Text(
              'Wrap a single bar action in Badge(count:) and it lowers to '
              'the NATIVE capsule badge — a red pill glued to the glass '
              'capsule\'s corner, driven live by plain Dart state.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                PageRoute(
                  builder: (_) => const _ActionBadgeScreen(),
                  settings: '/liquid-glass-bar-actions-badge',
                ),
              ),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Push the live-badge screen',
                    style: TextStyle(
                      color: kAccentBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, top: 16),
            child: Text(
              'WHY NATIVE MATTERS — a platform-view bar\'s buttons are '
              'native content configured over a bridge (an SF symbol '
              'name, a label); these pills host YOUR widgets, because the '
              'bar and the widgets share one native hierarchy. And the '
              'glass rides the route transition untouched, because there '
              'is no platform-view island for it to leak out of.',
              style: TextStyle(color: kTextTertiary, fontSize: 12),
            ),
          ),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}

/// The pushed screen: three trailing actions, each in its own glass
/// pill; Inbox carries a composed Badge. Doubles as the transition beat —
/// the pills stay glass through push and swipe-back.
class _MultiActionsScreen extends StatefulWidget {
  const _MultiActionsScreen();

  @override
  State<_MultiActionsScreen> createState() => _MultiActionsScreenState();
}

class _MultiActionsScreenState extends State<_MultiActionsScreen> {
  String _lastTapped = '(none yet)';
  int _inboxCount = 3;

  void _tap(String name) => setState(() => _lastTapped = name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Multi Actions',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isIOS26 ? kBarBgGlass : kBarBg,
        actions: [
          BarButtonItem(
            fontIcon: Platform.isAndroid
                ? MaterialSymbolsRounded.share
                : CupertinoIcons.square_arrow_up,
            titleStyle: TextStyle(color: kTextPrimary),
            onPressed: () => _tap('Share'),
          ),
          BarButtonItem(
            fontIcon: Platform.isAndroid
                ? MaterialSymbolsRounded.add
                : CupertinoIcons.plus,
            titleStyle: TextStyle(color: kTextPrimary),
            onPressed: () => _tap('Plus'),
          ),
          Badge(
            count: _inboxCount == 0 ? null : _inboxCount,
            child: BarButtonItem(
              title: 'Inbox',
              titleStyle: TextStyle(color: kTextPrimary),
              onPressed: () => _tap('Inbox'),
            ),
          ),
        ],
      ),
      backgroundColor: kHomeBg,
      body: ListView(
        children: [
          SizedBox(
              height: isIOS26
                  ? 8
                  : 12), // bar clearance is AUTOMATIC now (null-padding scrollable + extendBodyBehindAppBar); keep only the breathing gap
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 10),
            child: Text(
              'Three actions, three glass pills — the icons and the Inbox '
              'label are Dart widgets; the badge is composed by Dart too. '
              'Every pill gives the native glass press response. Swipe back '
              'and watch the bar stay glass through the transition.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Last tapped: $_lastTapped',
                  style: TextStyle(color: kTextPrimary, fontSize: 15),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => setState(() => _inboxCount++),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Tap to increment the Inbox badge',
                    style: const TextStyle(
                      color: kAccentBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}

/// The pushed live-badge screen: ONE badged action — the single-action bar
/// path carries the NATIVE badge (the system capsule overlay).
/// Live +1 / cap / clear straight from setState, no re-install flicker.
class _ActionBadgeScreen extends StatefulWidget {
  const _ActionBadgeScreen();

  @override
  State<_ActionBadgeScreen> createState() => _ActionBadgeScreenState();
}

class _ActionBadgeScreenState extends State<_ActionBadgeScreen> {
  int _count = 3;

  Widget _row(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: kRowBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: kAccentBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Live Badge',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isIOS26 ? kBarBgGlass : kBarBg,
        actions: [
          Badge(
            count: _count == 0 ? null : _count,
            child: BarButtonItem(
              title: 'Inbox',
              titleStyle: TextStyle(color: kTextPrimary),
              onPressed: () {},
            ),
          ),
        ],
      ),
      backgroundColor: kHomeBg,
      body: ListView(
        children: [
          SizedBox(
              height: isIOS26
                  ? 8
                  : 12), // bar clearance is AUTOMATIC now (null-padding scrollable + extendBodyBehindAppBar); keep only the breathing gap
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 10),
            child: Text(
              'The red badge on the Inbox capsule is the NATIVE overlay — '
              'watch it update live, cap at 99+, and clear without the '
              'action flickering. On Android the same Badge lowers to the '
              'Material badge.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          _row('+1  (now \$_count)', () => setState(() => _count++)),
          _row('Set 120 — caps to 99+', () => setState(() => _count = 120)),
          _row('Clear', () => setState(() => _count = 0)),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}
