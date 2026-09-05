/// Material 3 — the ANCHORED MENU, the real widget: `BarButtonItem.menu`
/// anchors a
/// Material PopupMenu to the toolbar action — glyph icons, the destructive
/// red, and a light/dark tone derived from the bar color. On iOS 26 the
/// SAME Dart code morphs the glass capsule into a UIMenu.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

/// The ⋮ action must be the bar's ONLY action.
class M3MenusDemo extends StatefulWidget {
  const M3MenusDemo({super.key});

  @override
  State<M3MenusDemo> createState() => _M3MenusDemoState();
}

class _M3MenusDemoState extends State<M3MenusDemo> {
  String _last = '(none yet)';

  void _pick(String name) => setState(() => _last = name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Anchored Menu',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
        actions: [
          BarButtonItem(
            menu: [
              MenuAction(
                title: 'Share',
                icon: MaterialSymbolsRounded.share,
                onTap: () => _pick('Share'),
              ),
              MenuAction(
                title: 'Select',
                icon: MaterialSymbolsRounded.check_circle,
                onTap: () => _pick('Select'),
              ),
              MenuAction(
                title: 'Delete',
                icon: MaterialSymbolsRounded.delete,
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
          SizedBox(height: tabListTopGap(context, fallback: 12)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Text(
              'Tap ⋮ — a real Material PopupMenu anchors to the action: '
              'glyph icons, the destructive red, and a light/dark tone '
              'derived from your bar color. Items are plain Dart closures.',
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
                  'Last action: $_last',
                  style: TextStyle(color: kTextPrimary, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
