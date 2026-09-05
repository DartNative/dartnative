/// Liquid Glass — the BARS, part 2: `AppBar.largeTitle` with the iOS 26
/// see-through bar: clear bar surface + the native large-title band collapse
/// + the system scroll-edge blur ramp. Deliberately LIGHT-themed — the edge
/// ramp needs a light surface to read.
///
/// The native large-title collapse is UIKit behavior that only runs when
/// the scrolling CONTENT is native too. Here the list is an ordinary Dart
/// ListView, yet the collapse, the tracking, and the edge ramp are the
/// system's own — because the "Dart" list IS a native scroll view.
import 'package:dartnative/dartnative.dart';

class LargeTitleDemo extends StatefulWidget {
  const LargeTitleDemo({super.key});

  @override
  State<LargeTitleDemo> createState() => _LargeTitleDemoState();
}

class _LargeTitleDemoState extends State<LargeTitleDemo> {
  bool _showSubtitle = false;

  @override
  void initState() {
    super.initState();
    // Fixed-LIGHT screen (white by design, both app themes): pin dark status
    // icons. The Navigator restores the previous style on pop.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  static const _chats = [
    ('Ava', 'See you at the demo tomorrow!', '17:02'),
    ('Bruno', 'The glass bar looks unreal 👌', '16:48'),
    ('Chiara', 'Push the new build when ready', '16:30'),
    ('Dario', 'Large title collapse = chef\'s kiss', '15:55'),
    ('Elena', 'Can you send the TestFlight link?', '15:21'),
    ('Fede', 'Rows stay visible under the bar 🤯', '14:47'),
    ('Gaia', 'That scroll-edge blur is native right?', '14:12'),
    ('Hugo', 'Shipping it', '13:58'),
    ('Ines', 'Reverse-tracking follows the finger', '13:20'),
    ('Luca', 'No SliverAppBar in sight', '12:44'),
    ('Marta', 'The band fades exactly like Messages', '12:10'),
    ('Nico', 'Try the pull-down stretch', '11:35'),
    ('Olga', 'Rotation mid-scroll holds up', '11:02'),
    ('Paolo', 'This is the Feed look from the article', '10:40'),
    ('Rita', 'Morning! Build is green', '09:15'),
    ('Sara', 'The small title fades in on cue', '08:50'),
    ('Tom', 'Edge ramp keeps it legible', '08:22'),
    ('Vera', 'Clear bar, zero frost — love it', '07:58'),
  ];

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.paddingOf(context).top;
    return Scaffold(
      // Body extends under the bar so the scroll-edge ramp has content to
      // act on (a body that starts below the bar clips at its own edge).
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Live-toggled bar subtitle (the ⓘ action): a second line under the
        // bar title — here fed by plain Dart state (the list length).
        subtitle: _showSubtitle
            ? Text(
                '${_chats.length} chats',
                style: const TextStyle(
                  color: Color(0xFF6B6B70),
                  fontSize: 12,
                ),
              )
            : null,
        actions: [
          // CupertinoIcons render on BOTH platforms (font glyphs) — no
          // adaptive branch needed on this deliberately iOS-styled screen.
          BarButtonItem(
            fontIcon: CupertinoIcons.info_circle,
            titleStyle: const TextStyle(color: Color(0xFF111111)),
            onPressed: () => setState(() => _showSubtitle = !_showSubtitle),
          ),
        ],
        largeTitle: const Text(
          'Chats',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        // NO backgroundColor → the fully CLEAR iOS 26 bar: glass lives on
        // the controls, the surface stays see-through, and the system
        // scroll-edge ramp (not a frost sheet) keeps the region legible.
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        // Clearance handoff: with the body extended, content starts at the
        // screen top — clear the status inset + bar strip + large-title
        // band on iOS 26 (bar + composed header pre-26).
        padding: EdgeInsets.only(
          top: padTop + (isIOS26 ? 108 : 56),
          bottom: 40,
        ),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Scroll: the large title slides under the bar and fades while '
              'the small title fades in — reversing tracks your finger. '
              'Rows passing beneath the bar stay visible through the '
              'system\'s progressive blur ramp. Tap ⓘ to toggle a live bar '
              'subtitle (the chat count, straight from Dart state).',
              style: TextStyle(color: Color(0xFF6B6B70), fontSize: 13),
            ),
          ),
          for (final (name, preview, time) in _chats)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F0FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          name.substring(0, 1),
                          style: const TextStyle(
                            color: Color(0xFF0A84FF),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preview,
                            style: const TextStyle(
                              color: Color(0xFF6B6B70),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF6B6B70),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(left: 28, right: 28, top: 16),
            child: Text(
              'WHY NATIVE MATTERS — this collapse is the system\'s own '
              'large-title behavior, and it\'s driven by an ordinary Dart '
              'ListView. The system only runs it when the scrolling '
              'content is a native scroll view — and here it is, so the '
              'bar and the content coordinate the way UIKit always has.',
              style: TextStyle(color: Color(0xFF9A9AA0), fontSize: 12),
            ),
          ),
          if (!isIOS26)
            const Padding(
              padding: EdgeInsets.only(left: 28, right: 28, top: 12),
              child: Text(
                'On this device the large title renders as a body header '
                '(the pre-26/Android fallback) — run on iOS 26 for the '
                'native collapse and the see-through bar.',
                style: TextStyle(color: Color(0xFF9A9AA0), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
