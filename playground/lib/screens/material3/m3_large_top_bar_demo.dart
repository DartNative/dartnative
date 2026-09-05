/// Material 3 — the LARGE TOP APP BAR, from the same `AppBar.largeTitle`
/// field that gives iOS 26 its native large-title band.
///
/// On Android: the M3 collapsing band — the large title renders in a
/// surface-colored band under the toolbar and collapses natively with your
/// scroll (band slides under the bar + fades, the bar title cross-fades in,
/// reversal tracks the finger; zero Dart work per frame).
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class M3LargeTopBarDemo extends StatefulWidget {
  const M3LargeTopBarDemo({super.key});

  @override
  State<M3LargeTopBarDemo> createState() => _M3LargeTopBarDemoState();
}

class _M3LargeTopBarDemoState extends State<M3LargeTopBarDemo> {
  /// One constant drives BOTH the screen background and the Android bar
  /// color (this screen's rule): the bar always matches the background —
  /// seamless look, and an opaque surface keeps the cross-fading bar title
  /// legible over content scrolling beneath.
  static Color get _screenBg => kHomeBg;

  static const _inbox = [
    ('Build is green', 'CI · just now'),
    ('Design review at 3', 'Ava · 5m'),
    ('The collapse looks native 👌', 'Bruno · 12m'),
    ('Merged the band driver', 'Chiara · 30m'),
    ('One field, two platforms', 'Dario · 1h'),
    ('Try the reverse tracking', 'Elena · 2h'),
    ('Ship it', 'Fede · 3h'),
    ('M3 spec motion confirmed', 'Gaia · 4h'),
    ('No CoordinatorLayout needed', 'Hugo · 5h'),
    ('Large title = same Dart code', 'Ines · 6h'),
    ('Scroll edge feels right', 'Luca · 7h'),
    ('Band fades under the bar', 'Marta · 8h'),
    ('Reversal tracks the finger', 'Nico · 9h'),
    ('Zero Dart per frame', 'Olga · 10h'),
    ('The twin of the iOS band', 'Paolo · 11h'),
    ('Docs are updated', 'Rita · 12h'),
  ];

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.paddingOf(context).top;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Inbox',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        largeTitle: Text(
          'Inbox',
          style: TextStyle(
            color: kTextPrimary,
            // Native per platform: M3 headline-medium (28sp regular) on
            // Android; the iOS large-title scale (34pt bold) elsewhere.
            fontSize: Platform.isAndroid ? 28 : 34,
            fontWeight: Platform.isAndroid ? FontWeight.w400 : FontWeight.bold,
          ),
        ),
        // With largeTitle set, the subtitle renders in the EXPANDED band
        // under the headline (M3 with-subtitle container: 136dp for
        // medium flexible; label-large type) and collapses into the bar's
        // composed title+subtitle block.
        subtitle: Text(
          '12 unread',
          style: TextStyle(color: kTextSecondary, fontSize: 14),
        ),
        // Android: the SCREEN BACKGROUND color (see _screenBg) — never
        // transparent (title over moving rows) and never omitted (the
        // wrapper's default is WHITE). iOS 26 keeps the glass tint.
        backgroundColor: isIOS26 ? kBarBgGlass : _screenBg,
      ),
      backgroundColor: _screenBg,
      body: ListView(
        padding: EdgeInsets.only(
          // Android: the medium-flexible WITH-SUBTITLE expanded container
          // is 136dp below the status bar; content starts right under it.
          top: padTop + (isIOS26 ? 108 : (Platform.isAndroid ? 136 : 56)),
          bottom: 40,
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Text(
              'Scroll: the large "Inbox" slides under the bar and fades '
              'while the bar title fades in — reversing tracks your finger. '
              'This is the same AppBar.largeTitle field that drives the '
              'iOS 26 native large-title band.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          for (final (msg, meta) in _inbox)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg,
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, top: 12),
            child: Text(
              'WHY NATIVE MATTERS — the collapse runs natively from your '
              'list\'s scroll offset (no Dart work per frame), on the M3 '
              'medium-flexible geometry (with-subtitle container, '
              'baseline-anchored title, snap to the nearest edge). One '
              'generic field, two design languages: this exact code gives '
              'an iPhone the system large-title treatment.',
              style: TextStyle(color: kTextTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
