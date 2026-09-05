/// Material 3 — SEARCH AS THE APP BAR (`AppBar.searchBar`): the bar region
/// IS the M3 search pill.
///
/// Two supported arrangements, toggled LIVE (exercising the AppBar update
/// path): back + search on a pushed screen (the pill-only layout belongs to
/// root/home screens), and leading + search + avatar action (the Gmail
/// layout). Tapping the pill expands the native SearchView
/// over the whole bar — leading/actions vanish under the overlay and return
/// on collapse, no app-side choreography.
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class M3SearchAppBarDemo extends StatefulWidget {
  const M3SearchAppBarDemo({super.key});

  @override
  State<M3SearchAppBarDemo> createState() => _M3SearchAppBarDemoState();
}

class _M3SearchAppBarDemoState extends State<M3SearchAppBarDemo> {
  static const _mail = [
    ('Yoo, Haneul', 'Q3 performance summary'),
    ('Ava Rossi', 'Design review notes'),
    ('Bruno Bianchi', 'Lunch on Friday?'),
    ('Chiara Conti', 'Re: the search app bar'),
    ('Dario Ferrari', 'Native morph looks great'),
    ('Elena Esposito', 'One field, two platforms'),
    ('Gaia Colombo', 'Ship it'),
    ('Hugo Ricci', 'M3 spec check'),
  ];

  /// false = search only (home-page frame); true = leading + search + avatar.
  bool _full = false;
  String _query = '';

  /// Tap verification for the bar slots (leading / avatar action).
  String _lastBarTap = '';

  void _barTap(String which) {
    dnLog('[M3SearchAppBarDemo] bar tap: $which');
    setState(() => _lastBarTap = which);
  }

  List<(String, String)> get _matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _mail;
    return [
      for (final m in _mail)
        if (m.$1.toLowerCase().contains(q) || m.$2.toLowerCase().contains(q)) m,
    ];
  }

  // Opaque dark root: the native search surfaces (Android SearchView / the
  // iOS suggestions overlay) supply their own platform background — the
  // demo's dark theme rides on top of either.
  Widget _suggestions() => Container(
        color: kHomeBg,
        child: _suggestionsList(),
      );

  Widget _suggestionsList() => ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final (from, subject) in _matches)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      from,
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject,
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Pushed screen → keep the auto back button (the pill lays out
        // after it). The pill-only look (edge to edge, no back button) is
        // for root/home screens that have nothing to pop to.
        // The APP-side custom layout: leading + pill + avatar — plain slot
        // composition; the avatar is ordinary app code, not a framework
        // widget.
        leading: _full
            ? GestureDetector(
                onTap: () => _barTap('menu'),
                // Android: a REAL sized container (Padding adds no view of
                // its own, and margins don't survive the bar's own slot
                // layout) whose padding provides the M3 16dp icon inset;
                // hugging the glyph makes the wrapper's 16dp slot gap the
                // icon→pill rhythm. iOS: the bare glyph — the system bar
                // wraps leading buttons in its own 44pt glass capsule
                // (centered with the search field), so any app-side inset
                // would just sit off-center inside the capsule.
                child: Platform.isAndroid
                    ? Container(
                        width: 40,
                        height: 48,
                        padding: const EdgeInsets.only(left: 16, top: 12),
                        child: Icon(
                          MaterialSymbolsRounded.menu,
                          color: kTextPrimary,
                          size: 24,
                        ),
                      )
                    : Icon(
                        MaterialSymbolsRounded.menu,
                        color: kTextPrimary,
                        size: 24,
                      ),
              )
            : null,
        actions: _full
            ? [
                GestureDetector(
                  onTap: () => _barTap('avatar'),
                  // iOS: the avatar matches the search field's 44pt capsule
                  // height (siblings in the band); Android keeps the M3
                  // reference 32dp.
                  child: Container(
                    width: Platform.isAndroid ? 32 : 42,
                    height: Platform.isAndroid ? 32 : 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C6BAE),
                      borderRadius:
                          BorderRadius.circular(Platform.isAndroid ? 16 : 22),
                    ),
                    child: Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ]
            : null,
        searchBar: SearchBar(
          hintText: 'Search in mail',
          onChanged: (q) => setState(() => _query = q),
          suggestions: _suggestions(),
        ),
        // The avatar is a self-designed circle — no framework capsule
        // behind it (iOS 26; the designed opt-out, default true).
        actionsGlassBackground: false,
        backgroundColor: kBarBg,
      ),
      backgroundColor: kHomeBg,
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 40),
        children: [
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 12),
            child: Text(
              'The bar region IS the search pill (AppBar.searchBar). Tap it '
              '— the native morph expands over the whole bar. Typing '
              'filters BOTH the suggestions inside the search surface and '
              'this list.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          // Frame toggle (exercises the AppBar update path live).
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _full = !_full),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _full
                      ? 'Switch to: search only'
                      : 'Switch to: leading + search + avatar',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (_lastBarTap.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 28, bottom: 12),
              child: Text(
                'Bar tap verified: $_lastBarTap',
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
            ),
          if (_matches.isEmpty)
            Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No mail matches the query.',
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
            )
          else
            for (final (from, subject) in _matches)
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
                        from,
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subject,
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, top: 12),
            child: Text(
              'WHY NATIVE MATTERS — the pill and the expanding surface are '
              'the real com.google.android.material SearchBar + SearchView '
              'pair: the M3 morph, back handling and keyboard choreography '
              'are the library\'s own, not re-implemented. Declaring search '
              'as part of the bar (AppBar.searchBar) is what lets the '
              'framework lower it structurally — on Android to this search '
              'app bar, and on iOS to a real UISearchBar in the '
              'navigation bar, searching in place.',
              style: TextStyle(color: kTextTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
