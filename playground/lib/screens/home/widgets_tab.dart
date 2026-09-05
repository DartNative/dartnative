/// Widgets tab — building blocks: text & input, components, layout,
/// scrollables, and state management.
import 'package:dartnative/dartnative.dart';

import '../fast_list_demo.dart';
import '../globalkey_demo.dart';
import '../grid_demo.dart';
import '../hittest_demo.dart';
import '../stack_demo.dart';
import '../state_basics_demo.dart';
import '../state_store_demo.dart';
import '../system_components_demo.dart';
import '../text_field_demo.dart';
import '../text_rendering_demo.dart';
import 'demo_ui.dart';

class WidgetsTab extends StatelessWidget {
  const WidgetsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kHomeBg,
      child: ListView(
        children: [
          SizedBox(height: tabListTopGap(context)),
          const SectionHeader('TEXT & INPUT'),
          DemoRow(
            icon: CupertinoIcons.textformat,
            tint: kAccentBlue,
            title: 'Text Rendering',
            tagline: 'UILabel + CoreText — weights, colors, spans',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const TextRenderingDemo(),
                settings: '/text-rendering',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.keyboard,
            tint: kAccentIndigo,
            title: 'TextField',
            tagline: 'Real UITextField / EditText — secure, multiline',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const TextFieldDemo(),
                settings: '/text-field',
              ),
            ),
          ),
          const SectionHeader('COMPONENTS'),
          DemoRow(
            icon: CupertinoIcons.slider_horizontal_3,
            tint: kAccentGreen,
            title: 'System Components',
            tagline: 'Switches, sliders, alerts, pickers, tab bars',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const SystemComponentsDemo(),
                settings: '/system-components',
              ),
            ),
          ),
          const SectionHeader('LAYOUT & TOUCH'),
          DemoRow(
            icon: CupertinoIcons.square_on_square,
            tint: kAccentOrange,
            title: 'Stack + Positioned',
            tagline: 'Overlap, corners, fills, alignment',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const StackDemo(), settings: '/stack'),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.hand_draw_fill,
            tint: kAccentPink,
            title: 'HitTestBehavior',
            tagline: 'opaque · deferToChild · translucent',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const HitTestDemo(),
                settings: '/hittest',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.globe,
            tint: kAccentTeal,
            title: 'GlobalKey.currentContext',
            tagline: 'Any mounted widget\'s context, from anywhere',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const GlobalKeyDemo(),
                settings: '/globalkey',
              ),
            ),
          ),
          const SectionHeader('SCROLLABLES'),
          DemoRow(
            icon: CupertinoIcons.list_dash,
            tint: kAccentYellow,
            title: 'FastList',
            tagline: '10,000 rows, native recycling, flat memory',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const FastListDemo(),
                settings: '/fast-list',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.square_grid_2x2,
            tint: kAccentTeal,
            title: 'GridView',
            tagline: 'count · builder · spacing · aspect ratio',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const GridDemo(), settings: '/grid'),
            ),
          ),
          const SectionHeader('STATE'),
          DemoRow(
            icon: CupertinoIcons.bolt_fill,
            tint: kAccentPurple,
            title: 'State Basics',
            tagline: 'Signal, Computed, effect — no setState',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const StateBasicsDemo(),
                settings: '/state-basics',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.tray_full_fill,
            tint: kAccentRed,
            title: 'State Store',
            tagline: 'Store + per-subtree DI with Provided',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const StateStoreDemo(),
                settings: '/state-store',
              ),
            ),
          ),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}
