/// Hero demo — Instagram-style story-viewer pattern.
///
/// One named avatar at top-centre. Tapping it pushes a fullscreen
/// "story viewer" route. The push uses `RouteTransition.none` so
/// the Hero overlay IS the visible transition: the avatar morphs
/// from its source position to the full-screen position while the
/// destination route fades in around it. Dragging the viewer down
/// past a threshold pops the route — the same Hero runs in
/// reverse, collapsing the open viewer back into the avatar
/// position.
///
/// The pop uses a simple drag-distance threshold (no interactive
/// scrubbing in lockstep with the gesture).
library;

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class HeroDemo extends StatefulWidget {
  const HeroDemo({super.key});

  @override
  State<HeroDemo> createState() => _HeroDemoState();
}

class _HeroDemoState extends State<HeroDemo> {
  static const _tile = _StoryTile(
    id: 'lisa',
    name: 'Lisa Taylor',
    timeAgo: '1h',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Hero Animations',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: Container(
        color: kHomeBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Tap the avatar to open a story viewer.',
              style: TextStyle(color: kTextSecondary, fontSize: 15),
            ),
            const SizedBox(height: 32),
            _AvatarTile(_tile),
          ],
        ),
      ),
    );
  }
}

/// The named avatar tile. Wraps its avatar circle in a `Hero` keyed
/// by the story id; tapping pushes the `_StoryViewerRoute`.
class _AvatarTile extends StatelessWidget {
  final _StoryTile tile;
  const _AvatarTile(this.tile);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRoute(
          builder: (_) => _StoryViewerRoute(tile: tile),
          // RouteTransition.none keeps the new route fully opaque from
          // t=0 so the Hero morph (running INSIDE the new route's view
          // tree) is visible the whole way. With .fade the route's own
          // alpha animation would hide our morph until late in the
          // transition, since the morphing view lives in the fading
          // tree.
          transition: RouteTransition.none,
          duration: const Duration(milliseconds: 250),
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'story-${tile.id}',
            child: Container(
              color: Colors.transparent,
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0A84FF), width: 3),
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: Image.asset(
                  'assets/avatar.jpg',
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tile.name,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The destination "story viewer" route. Renders the same avatar
/// image full-bleed; wrapping it in a Hero with the same tag triggers
/// the morph from the source tile. A pan gesture pops the route once
/// the drag exceeds a vertical threshold. Overlays a top bar (avatar,
/// name, time, close button) and a bottom hint.
class _StoryViewerRoute extends StatefulWidget {
  final _StoryTile tile;
  const _StoryViewerRoute({required this.tile});

  @override
  State<_StoryViewerRoute> createState() => _StoryViewerRouteState();
}

class _StoryViewerRouteState extends State<_StoryViewerRoute> {
  // Vertical drag accumulator. Once it crosses [_popThreshold], we pop.
  double _dragY = 0;
  static const _popThreshold = 120.0;

  @override
  void initState() {
    super.initState();
    // Story viewer is fullscreen: let the image bleed behind both the
    // status bar and the Android system nav bar by making both
    // transparent, with light foreground icons against the photo.
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      // Bleed body behind both the status bar and the system nav bar
      // so the fullscreen image and the gradient scrims fill the
      // whole window (matching the transparent SystemChrome above).
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: GestureDetector(
        onPanUpdate: (d) {
          // Only respond to mostly-vertical, downward drags. Horizontal
          // motion is ignored so any sideways gestures inside the viewer
          // (future "navigate to next story" pager) can co-exist.
          if (d.delta.dy.abs() > d.delta.dx.abs() && d.delta.dy > 0) {
            setState(() => _dragY += d.delta.dy);
          }
        },
        onPanEnd: (_) {
          if (_dragY > _popThreshold) {
            Navigator.pop(context);
          } else {
            setState(() => _dragY = 0);
          }
        },
        child: SizedBox.expand(
          // Drag shifts the WHOLE story screen (image + overlays) as
          // a single unit — image, top bar, gradient scrim and bottom
          // hint all translate together. The Hero lives inside this
          // Transform so its capture rect at pop time is correctly
          // taken from the dragged-down position.
          child: Transform.translate(
            offset: Offset(0, _dragY),
            child: Stack(
              children: [
                // Full-bleed image with the Hero tag.
                Positioned.fill(
                  child: Hero(
                    tag: 'story-${widget.tile.id}',
                    // Inner Stack > Positioned.fill > Image.asset so
                    // the image fills regardless of how the wrapping
                    // Hero element lays out its child.
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/hero_demo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Top gradient scrim — improves contrast of the top
                // overlay over a bright background image. ~50% black
                // at the top, fading to fully transparent at the
                // bottom of the 80-px strip.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 150,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom gradient scrim — mirrors the top scrim so
                // the bottom hint stays readable over a bright
                // background image.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 150,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Top overlay bar: avatar | name | time-ago | X
                Positioned(
                  left: 0,
                  right: 0,
                  top: 50,
                  child: _TopBar(
                    tile: widget.tile,
                    onClose: () => Navigator.pop(context),
                  ),
                ),
                // Bottom overlay hint: label + down chevron
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: _BottomHint(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top overlay bar for the story viewer.
///
/// Layout (left → right):
///   [ small avatar ] [ name ] [ "·" ] [ "1h" ] ............ [ X ]
class _TopBar extends StatelessWidget {
  final _StoryTile tile;
  final VoidCallback onClose;
  const _TopBar({required this.tile, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Small circular avatar (separate from the Hero so the
          // morphing avatar isn't doubled up here).
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Image.asset(
                'assets/avatar.jpg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            tile.name,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tile.timeAgo,
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                CupertinoIcons.xmark,
                size: 22,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom overlay hint: label + down chevron, centred horizontally.
class _BottomHint extends StatelessWidget {
  const _BottomHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'Drag down to close',
          style: TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 13,
          ),
        ),
        SizedBox(height: 6),
        Icon(
          CupertinoIcons.chevron_down,
          size: 20,
          color: Color(0xCCFFFFFF),
        ),
      ],
    );
  }
}

class _StoryTile {
  final String id;
  final String name;
  final String timeAgo;
  const _StoryTile({
    required this.id,
    required this.name,
    required this.timeAgo,
  });
}
