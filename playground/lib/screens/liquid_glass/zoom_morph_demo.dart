/// Liquid Glass — ZOOM MORPH: the tapped tile BECOMES the screen.
///
/// Apple's zoom transition (Photos / App Store, iOS 18+): pushing with
/// `RouteTransition.zoom` morphs the source control into the incoming
/// screen, and popping shrinks the screen back into it. The system also
/// grants its pinch/drag-to-dismiss gesture on the pushed screen for free.
///
/// Wiring: wrap the tappable in a [Hero] (its tag registers the native
/// source view) and name that tag in the route:
///
/// ```dart
/// Navigator.push(context, PageRoute(
///   transition: RouteTransition.zoom,
///   zoomSourceTag: 'tile-3',
///   builder: (_) => const DetailScreen(),
/// ));
/// ```
///
/// Pre-18 iOS and Android fall back to the standard push (Android's
/// Material counterpart — container transform — is a planned lowering).
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class ZoomMorphDemo extends StatelessWidget {
  const ZoomMorphDemo({super.key});

  static const _tiles = [
    (CupertinoIcons.photo_fill_on_rectangle_fill, 'Photos', Color(0xFF3B82F6)),
    (CupertinoIcons.music_note_2, 'Music', Color(0xFFEF4444)),
    (CupertinoIcons.map_fill, 'Maps', Color(0xFF10B981)),
    (CupertinoIcons.chat_bubble_2_fill, 'Chats', Color(0xFF8B5CF6)),
  ];

  Widget _tile(BuildContext context, int i) {
    final (icon, label, color) = _tiles[i];
    final tag = 'zoom-morph-$i';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRoute(
          transition: RouteTransition.zoom,
          zoomSourceTag: tag,
          builder: (_) => _ZoomDetail(icon: icon, label: label, color: color),
        ),
      ),
      // The Hero names this tile as the zoom's morph source. Don't reuse
      // the tag on the destination screen — a matched Hero pair would run
      // its own animation on top of the zoom.
      child: Hero(
        tag: tag,
        child: GlassEffectContainer(
          borderRadius: BorderRadius.circular(28),
          interactive: true,
          tint: color.withOpacity(0.35),
          brightness: playgroundPalette.brightness,
          child: SizedBox(
            width: 150,
            height: 110,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 34, color: kTextPrimary),
                const SizedBox(height: 10),
                Text(label,
                    style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(title: const Text('Zoom Morph')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tap a tile — it morphs into the screen. EVERY way back '
                'reverses the morph: the back button, an edge swipe, a '
                'drag down, or a pinch all shrink the screen into its '
                'tile. The animation is the system\'s own.',
                style: TextStyle(
                    color: kTextSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_tile(context, 0), _tile(context, 1)],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_tile(context, 2), _tile(context, 3)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pushed screen the tile morphs into. Deliberately simple: a tinted
/// surface with the same icon at screen scale, so the morph reads as "the
/// tile grew into this" — content continuity is what sells the effect.
class _ZoomDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ZoomDetail(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(title: Text(label)),
      body: SafeArea(
        top: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(44),
                ),
                child: Icon(icon, size: 72, color: kTextPrimary),
              ),
              const SizedBox(height: 28),
              Text(label,
                  style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'Back button, edge swipe, drag down or pinch —\n'
                'every exit shrinks this screen back into its tile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: kTextSecondary, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
