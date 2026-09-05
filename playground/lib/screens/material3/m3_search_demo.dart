/// Material 3 — the SEARCH APP BAR: the real MDC SearchBar pill + the
/// expanding SearchView surface, from the generic `SearchBar` widget.
///
/// Tap the pill: the native morph expands the full-screen search surface;
/// typing streams `onChanged` into Dart, the suggestions below are a LIVE
/// Dart widget subtree mounted inside the native surface; the IME search
/// action fires `onSubmitted`; the back arrow collapses with the native
/// transition.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class M3SearchDemo extends StatefulWidget {
  const M3SearchDemo({super.key});

  @override
  State<M3SearchDemo> createState() => _M3SearchDemoState();
}

class _M3SearchDemoState extends State<M3SearchDemo> {
  static const _contacts = [
    'Ava Rossi',
    'Bruno Bianchi',
    'Chiara Conti',
    'Dario Ferrari',
    'Elena Esposito',
    'Federico Romano',
    'Gaia Colombo',
    'Hugo Ricci',
    'Ines Marino',
    'Luca Greco',
    'Marta Bruno',
    'Nico Gallo',
    'Olga Costa',
    'Paolo Fontana',
    'Rita Serra',
  ];

  String _query = '';
  String _submitted = '';

  List<String> get _matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _contacts;
    return [
      for (final c in _contacts)
        if (c.toLowerCase().contains(q)) c,
    ];
  }

  // Opaque dark root — see m3_search_appbar_demo._suggestions.
  Widget _suggestions() => Container(
        color: kHomeBg,
        child: _suggestionsList(),
      );

  Widget _suggestionsList() => ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (_matches.isEmpty)
            Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No contacts found.',
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
            )
          else
            for (final c in _matches)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: kRowBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(color: kTextPrimary, fontSize: 15),
                  ),
                ),
              ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Expanding Search Pill',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      backgroundColor: kHomeBg,
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 40),
        children: [
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 16),
            child: Text(
              'Tap the pill — the native M3 morph expands the full-screen '
              'search surface. The suggestion list inside it is a live Dart '
              'widget tree; typing filters it through onChanged.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBar(
              // The M3 copy rule: the hint always includes "Search" —
              // scoped here ("Search contacts").
              hintText: 'Search contacts',
              onChanged: (q) => setState(() => _query = q),
              onSubmitted: (q) => setState(() => _submitted = q),
              suggestions: _suggestions(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, right: 28, top: 16),
            child: Text(
              _submitted.isEmpty
                  ? 'Submit a search (the ⏎ search action) to see it here.'
                  : 'Last submitted: "$_submitted"',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, top: 20),
            child: Text(
              'WHY NATIVE MATTERS — this is the real '
              'com.google.android.material SearchBar + SearchView pair: the '
              'expand/collapse morph, back handling and keyboard '
              'choreography are the library\'s own, while the content stays '
              'your Dart widgets. The same generic widget carries the iOS '
              'lowering — a real UISearchBar searching in place.',
              style: TextStyle(color: kTextTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
