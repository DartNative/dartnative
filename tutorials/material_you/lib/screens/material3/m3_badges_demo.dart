/// Material 3 — LIVE BADGES, the real widgets.
///
///   • tab badge    → com.google.android.material BadgeDrawable on the
///                    BottomNavigationView item (M3 red, "99+" verbatim);
///   • action badge → the same BadgeDrawable anchored to the toolbar
///                    action, updated in place (no re-attach flicker).
/// On iOS the SAME Dart code maps to UITabBarItem.badgeValue and the
/// badge on the system capsule.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class M3BadgesDemo extends StatefulWidget {
  const M3BadgesDemo({super.key});

  @override
  State<M3BadgesDemo> createState() => _M3BadgesDemoState();
}

class _M3BadgesDemoState extends State<M3BadgesDemo> {
  int _tab = 0;
  int _chats = 4;
  int _inbox = 2;

  @override
  void initState() {
    super.initState();
    // System strip matches the dark bar; the Navigator restores the
    // previous style automatically on pop.
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle(
      navBarColor: isIOS26 ? Colors.transparent : kBarBg,
    ));
  }

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

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        child: Text(
          text,
          style: TextStyle(color: kTextSecondary, fontSize: 13),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Badges',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
        actions: [
          // Single badged action → the NATIVE action badge (BadgeDrawable
          // on Android; the system capsule overlay on iOS 26).
          Badge(
            count: _inbox == 0 ? null : _inbox,
            child: BarButtonItem(
              title: 'Inbox',
              titleStyle: TextStyle(color: kTextPrimary),
              onPressed: () {},
            ),
          ),
        ],
      ),
      backgroundColor: kHomeBg,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kBarBg,
        labelFontStyle: TextStyle(color: kTextSecondary),
        selectedLabelFontStyle: TextStyle(color: kTextPrimary),
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          BottomNavigationBarItem(
            label: 'Chats',
            // Badge on the icon → the native tab badge.
            icon: Badge(
              count: _chats == 0 ? null : _chats,
              child: const Icon(CupertinoIcons.chat_bubble_2),
            ),
          ),
          const BottomNavigationBarItem(
            label: 'You',
            icon: Icon(CupertinoIcons.person),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: isIOS26 ? 90 : 12, top: 8),
            children: [
              const SectionHeader('LIVE BADGES'),
              _note(
                'The Chats tab and the Inbox action carry REAL Material '
                'badges — driven by plain Dart state. Counts over 99 '
                'render "99+" verbatim; clearing removes the badge with '
                'no flicker.',
              ),
              _row('Chats badge +1  (now $_chats)',
                  () => setState(() => _chats++)),
              _row('Inbox badge +1  (now $_inbox)',
                  () => setState(() => _inbox++)),
              _row('Set both to 120 — caps to 99+', () {
                setState(() {
                  _chats = 120;
                  _inbox = 120;
                });
              }),
              _row('Clear both', () {
                setState(() {
                  _chats = 0;
                  _inbox = 0;
                });
              }),
              Padding(
                padding: EdgeInsets.only(left: 28, right: 28, top: 16),
                child: Text(
                  'WHY NATIVE MATTERS — these are the Material library\'s '
                  'own BadgeDrawable instances, not re-drawings: metrics, '
                  'colors and motion track the real library by definition. '
                  'The same Dart code gives iOS its native equivalents — '
                  'UITabBarItem badges and the badge on the system capsule.',
                  style: TextStyle(color: kTextTertiary, fontSize: 12),
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              'You tab — switch back to keep playing.',
              style: TextStyle(color: kTextSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
