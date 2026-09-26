/// The bar under the feed: five items on black, the framed plus button in
/// the middle, as on the real thing. The bar is opaque and takes the bottom
/// safe area, so the video ends at its top edge. The glyphs are images
/// from the "Tiktok interface" vector set by aquagreen on Freepik
/// (assets/tiktok), an outline and a filled one per item, used under the
/// Freepik free licence with its credit on the demo's Profile tab.
library;

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

const _white = Color(0xFFFFFFFF);

class TikTokBar extends StatelessWidget {
  const TikTokBar({super.key, required this.current, required this.onTap});

  /// The selected item; 0 is Home. The plus button is item 2.
  final int current;
  final ValueChanged<int> onTap;

  static const double height = 49;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      color: const Color(0xFF000000),
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            _item(0, 'Home', 'home'),
            _item(1, 'Discover', 'discover'),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(2),
                child: Center(
                  child: Image.asset(
                    'assets/tiktok/create.png',
                    width: 46,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            _item(3, 'Inbox', 'inbox'),
            _item(4, 'Profile', 'me'),
          ],
        ),
      ),
    );
  }

  Widget _item(int index, String label, String glyph) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/tiktok/$glyph${active ? '_fill' : ''}.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: _white,
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The back button of the feed and of the profile, in the same place on
/// both: on Android, Material's arrow in a 48dp target 4dp from the edge,
/// where Android's own bars put it; on iPhone, the chevron in a 44pt
/// target 16pt in, in a Liquid Glass capsule when [capsule] is on.
class TikTokBackButton extends StatelessWidget {
  const TikTokBackButton({super.key, required this.onTap, this.capsule = false});

  final VoidCallback onTap;
  final bool capsule;

  /// From the screen's start edge to the button.
  static double get inset => Platform.isAndroid ? 4 : 16;

  @override
  Widget build(BuildContext context) {
    final android = Platform.isAndroid;
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: android ? 48 : 44,
        height: 44,
        child: Center(
          child: Icon(
            android ? MaterialSymbolsRounded.arrow_back : CupertinoIcons.chevron_left,
            size: android ? 24 : 20,
            color: _white,
          ),
        ),
      ),
    );
    if (android || !capsule) return button;
    return GlassEffectContainer(
      brightness: Brightness.dark,
      interactive: true,
      borderRadius: BorderRadius.circular(22),
      child: button,
    );
  }
}
