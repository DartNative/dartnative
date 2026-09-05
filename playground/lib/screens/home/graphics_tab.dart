/// Graphics tab — canvas rendering (Skia + native), Lottie, and motion.
import 'package:dartnative/dartnative.dart';

import '../lottie/lottie_assets_grid_demo.dart';
import '../lottie/lottie_controls_demo.dart';
import '../lottie/lottie_grid_demo.dart';
import '../animated_size_demo.dart';
import '../backdrop_filter_demo.dart';
import '../canvas_demo.dart';
import '../custom_paint_demo.dart';
import '../hero_demo.dart';
import '../implicit_animations_demo.dart';
import '../morphing_icon_demo.dart';
import '../staggered_cards_demo.dart';
import 'demo_ui.dart';

class GraphicsTab extends StatelessWidget {
  const GraphicsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kHomeBg,
      child: ListView(
        children: [
          SizedBox(height: tabListTopGap(context)),
          const SectionHeader('CANVAS'),
          DemoRow(
            icon: CupertinoIcons.paintbrush_fill,
            tint: kAccentGreen,
            title: 'Canvas Surface',
            tagline: 'Skia CustomPainter on CAMetalLayer via FFI',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                  builder: (_) => const CanvasDemo(), settings: '/canvas'),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.scribble,
            tint: kAccentBlue,
            title: 'CustomPaint (native)',
            tagline: 'Core Graphics / android.Canvas — no Skia',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const CustomPaintDemo(),
                settings: '/custom-paint',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.wand_stars_inverse,
            tint: kAccentPurple,
            title: 'Morphing Icon',
            tagline: 'Shape-to-shape point-set interpolation',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const MorphingIconDemo(),
                settings: '/morphing-icon',
              ),
            ),
          ),
          const SectionHeader('LOTTIE'),
          DemoRow(
            icon: CupertinoIcons.film_fill,
            tint: kAccentRed,
            title: 'Lottie Controls',
            tagline: 'Play, pause, seek, speed, loop',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const LottieControlsDemo(),
                settings: '/lottie-controls',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.square_grid_2x2,
            tint: kAccentPink,
            title: 'Sticker Grid (URL)',
            tagline: 'FastGrid of network Lottie stickers',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const LottieGridDemo(),
                settings: '/lottie-grid-url',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.photo_fill,
            tint: kAccentOrange,
            title: 'Sticker Grid (Assets)',
            tagline: 'Bundled stickers, FastGrid recycling',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const LottieAssetsGridDemo(),
                settings: '/lottie-grid-assets',
              ),
            ),
          ),
          const SectionHeader('MOTION'),
          DemoRow(
            icon: CupertinoIcons.sparkles,
            tint: kAccentYellow,
            title: 'Implicit Animations',
            tagline: 'Align, Padding, Rotation, Scale, Slide',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const ImplicitAnimationsDemo(),
                settings: '/implicit-animations',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.arrow_up_arrow_down,
            tint: kAccentTeal,
            title: 'AnimatedSize',
            tagline: 'Animated expand / collapse of any child',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const AnimatedSizeDemo(),
                settings: '/animated-size',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.rectangle_stack_fill,
            tint: kAccentPink,
            title: 'Hero Animations',
            tagline: 'Tile-to-fullscreen overlay flight',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const HeroDemo(), settings: '/hero'),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.square_stack_3d_up_fill,
            tint: kAccentOrange,
            title: 'Staggered Cards',
            tagline: 'Fade-in + slide-up entrance choreography',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const StaggeredCardsDemo(),
                settings: '/staggered-cards',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.drop_fill,
            tint: kAccentBlue,
            title: 'BackdropFilter',
            tagline: 'Native blur behind any widget',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const BackdropFilterDemo(),
                settings: '/backdrop-filter',
              ),
            ),
          ),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}
