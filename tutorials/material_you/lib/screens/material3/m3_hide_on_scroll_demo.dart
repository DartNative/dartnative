/// Material 3 — hide-on-scroll bottom bar.
///
/// The adaptive-first headline: this screen sets ONE generic field —
/// `scrollBehavior: TabBarScrollBehavior.minimizeOnScrollDown` — and each
/// platform lowers it to its own native design language. Here on Android:
/// the real M3 hide-on-scroll (Material's motion specs, 175ms accelerate
/// out / 225ms decelerate in), the bar rendered edge-to-edge with its
/// surface filling the gesture area, and the body auto-extended so hiding
/// the bar reveals content. On iOS 26 the very same field lowers the
/// Scaffold to a real UITabBarController and the floating glass pill
/// minimizes into a capsule.
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class M3HideOnScrollDemo extends StatefulWidget {
  const M3HideOnScrollDemo({super.key});

  @override
  State<M3HideOnScrollDemo> createState() => _M3HideOnScrollDemoState();
}

class _M3HideOnScrollDemoState extends State<M3HideOnScrollDemo> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // System strip matches the dark bar while this screen shows a nav bar;
    // the Navigator restores the previous style automatically on pop.
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle(
      navBarColor: isIOS26 ? Colors.transparent : kBarBg,
    ));
  }

  Widget _row(String text) => Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: kRowBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(color: kTextPrimary, fontSize: 14),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottomPad = isIOS26 ? 90.0 : (Platform.isAndroid ? 108.0 : 12.0);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hide-on-Scroll Bar',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      backgroundColor: kHomeBg,
      bottomNavigationBar: BottomNavigationBar(
        // THE field: M3 hide-on-scroll here, Liquid Glass minimize on iOS 26.
        scrollBehavior: TabBarScrollBehavior.minimizeOnScrollDown,
        backgroundColor: kBarBg,
        labelFontStyle: TextStyle(color: kTextSecondary),
        selectedLabelFontStyle: TextStyle(color: kTextPrimary),
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            label: 'Feed',
            icon: Icon(CupertinoIcons.list_bullet),
          ),
          BottomNavigationBarItem(
            label: 'Library',
            icon: Icon(CupertinoIcons.music_note),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: bottomPad, top: 8),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                child: Text(
                  'Scroll down — the bar slides away with Material\'s own '
                  'motion, its edge-to-edge surface clearing the gesture '
                  'area, and the content you\'re reading gains the space. '
                  'Scroll up — it slides back.',
                  style: TextStyle(color: kTextSecondary, fontSize: 13),
                ),
              ),
              for (var i = 0; i < 40; i++) _row('feed item $i'),
              Padding(
                padding: EdgeInsets.only(left: 28, right: 28, top: 12),
                child: Text(
                  'WHY NATIVE MATTERS — this bar is the real '
                  'com.google.android.material BottomNavigationView, hidden '
                  'and shown with the M3 spec\'s own timings. And the same '
                  'Dart field produces the iOS 26 Liquid Glass pill-minimize '
                  'on an iPhone: one generic API, two native design '
                  'languages — the framework\'s adaptive-first thesis in '
                  'one line of code.',
                  style: TextStyle(color: kTextTertiary, fontSize: 12),
                ),
              ),
            ],
          ),
          ListView(
            padding: EdgeInsets.only(bottom: bottomPad, top: 8),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                child: Text(
                  'A second tab — switching is instant, state intact.',
                  style: TextStyle(color: kTextSecondary, fontSize: 13),
                ),
              ),
              for (var i = 0; i < 20; i++) _row('library item $i'),
            ],
          ),
        ],
      ),
    );
  }
}
