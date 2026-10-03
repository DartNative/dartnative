// Upstream's menu, entry for entry.
//
// Names, order and descriptions are rive-flutter's own (see their
// `example/lib/main.dart`). Each entry either points at our port of that
// screen or states what the port is waiting on.
//
// Keep this list in upstream's order even as entries go from blocked to done,
// so the two menus stay walkable side by side.

import 'package:dartnative/dartnative.dart';

import '../rive_controls_demo.dart';
import '../rive_flutter_examples_demo.dart';
import '../rive_grid_demo.dart';
import '../rive_list_demo.dart';
import '../rive_hit_test_demo.dart';
import '../rive_layout_demo.dart';
import '../rive_official/inputs.dart' as official;
import '../rive_sources_demo.dart';
import 'catalogue.dart';
import 'screens/databinding.dart';
import 'screens/databinding_artboards.dart';
import 'screens/databinding_images.dart';
import 'screens/databinding_lists.dart';
import 'screens/events.dart';
import 'screens/hit_test_behaviour.dart';
import 'screens/inputs.dart';
import 'screens/marketplace/audio_player.dart';
import 'screens/marketplace/big_wheel.dart';
import 'screens/marketplace/dragon_ball.dart';
import 'screens/marketplace/sleep_onboarding.dart';
import 'screens/marketplace/studiorun.dart';
import 'screens/multi_touch.dart';
import 'screens/network_asset.dart';
import 'screens/out_of_band_assets.dart';
import 'screens/out_of_band_assets_audio.dart';
import 'screens/out_of_band_assets_cached.dart';
import 'screens/painters.dart';
import 'screens/pause_play.dart';
import 'screens/responsive_layouts.dart';
import 'screens/rive_audio.dart';
import 'screens/rive_widget.dart';
import 'screens/semantics.dart';
import 'screens/semantics_omni.dart';
import 'screens/test_graphic_resizing.dart';
import 'screens/test_memory_cleanup.dart';
import 'screens/text_runs.dart';
import 'screens/ticker_mode.dart';
import 'screens/transform.dart';

List<Section> buildSections() => const [
      Section('Getting Started', [
        Entry(
          'Rive Widget',
          'Simple example usage of the Rive widget with common parameters.',
          builder: buildRiveWidget,
          upstreamFile: 'rive_widget.dart',
        ),
        Entry(
          'Rive Widget Builder',
          'Example usage of the Rive builder widget with common parameters.',
          builder: buildRiveWidgetBuilder,
          upstreamFile: 'rive_widget_builder.dart',
        ),
      ]),
      Section('Rive Features', [
        Entry(
          'Data Binding',
          'Example using Rive data binding at runtime.',
          builder: buildDataBinding,
          upstreamFile: 'databinding.dart',
        ),
        Entry(
          'Data Binding - Images',
          'Example using Rive data binding images at runtime.',
          builder: buildDataBindingImages,
          upstreamFile: 'databinding_images.dart',
        ),
        Entry(
          'Data Binding - Artboards',
          'Example using Rive data binding artboards at runtime.',
          builder: buildDataBindingArtboards,
          upstreamFile: 'databinding_artboards.dart',
        ),
        Entry(
          'Data Binding - Lists',
          'Example using Rive data binding lists at runtime.',
          builder: buildDataBindingLists,
          upstreamFile: 'databinding_lists.dart',
        ),
        Entry(
          'Responsive Layouts',
          'Create responsive Rive graphics that adapt to screen size.',
          builder: buildResponsiveLayouts,
          upstreamFile: 'responsive_layouts.dart',
        ),
        Entry(
          'Semantics [Omni]',
          'All-purpose semantics testing: pick an artboard from semantics.riv.',
          builder: buildSemanticsOmni,
          upstreamFile: 'semantics_omni.dart',
        ),
        Entry(
          'Semantics [Examples]',
          'Expose authored semantic data to screen readers.',
          builder: buildSemantics,
          upstreamFile: 'semantics.dart',
        ),
        Entry(
          'Events',
          'Handle Rive events.',
          builder: buildEvents,
          upstreamFile: 'events.dart',
        ),
        Entry(
          'Audio',
          'Example Rive file with audio.',
          builder: buildRiveAudio,
          upstreamFile: 'rive_audio.dart',
        ),
      ]),
      Section('Asset Loading', [
        Entry(
          'Network .riv Asset',
          'Load and display Rive graphics from network URLs.',
          builder: buildNetworkAsset,
          upstreamFile: 'network_asset.dart',
        ),
        Entry(
          'Out-of-band Assets',
          'Load Rive files with external assets (images, audio) separately.',
          builder: buildOutOfBandAssets,
          upstreamFile: 'out_of_band_assets.dart',
        ),
        Entry(
          'Out-of-band Assets - Audio',
          'Load Rive files with audio assets.',
          builder: buildOutOfBandAssetsAudio,
          upstreamFile: 'out_of_band_assets_audio.dart',
        ),
        Entry(
          'Out-of-band Assets - Cached',
          'Load Rive files with cached external assets for better immediate '
              'availability.',
          builder: buildOutOfBandAssetsCached,
          upstreamFile: 'out_of_band_assets_cached.dart',
        ),
      ]),
      Section('Painters [Advanced]', [
        Entry(
          'State Machine Painter',
          'Advanced: Custom painter for state machines.',
          builder: buildStateMachinePainter,
          upstreamFile: 'state_machine_painter.dart',
        ),
        Entry(
          'Single Animation Painter',
          'Advanced: Custom painter for single animation playback.',
          builder: buildSingleAnimationPainter,
          upstreamFile: 'animation_painter.dart',
        ),
      ]),
      Section('Concepts/Integration', [
        // Upstream comments this out: its screen is their todo.dart placeholder.
        // Entry('Lists', 'Rive graphics in a scrolling list.'),
        Entry(
          'Pause/Play',
          'Pause and play Rive graphics.',
          builder: buildPausePlay,
          upstreamFile: 'pause_play.dart',
        ),
        Entry(
          'Hit Test + Cursor Behaviour',
          'Specifying hit test and cursor behaviour.',
          builder: buildHitTestBehaviour,
          upstreamFile: 'hit_test_behaviour.dart',
        ),
        Entry(
          'Ticker Mode',
          'Rive graphics respect ticker mode.',
          builder: buildTickerMode,
          upstreamFile: 'ticker_mode.dart',
        ),
        Entry(
          'Transform',
          'Rive graphics respect transform.',
          builder: buildTransform,
          upstreamFile: 'transform.dart',
        ),
        Entry(
          'Multi Touch',
          'Rive graphics respect multi touch.',
          builder: buildMultiTouch,
          upstreamFile: 'multi_touch.dart',
        ),
        // Upstream comments these out too, all four on the todo.dart placeholder.
        // Entry('Hero Transitions', 'Rive graphics across a Hero transition.'),
        // Entry('State Management',
        //     'Rive graphics under a state management solution.'),
        // Entry('Localization', 'Localized Rive graphics.'),
        // Entry('Internationalization', 'Internationalized Rive graphics.'),
      ]),
      Section('Performance/Memory testing', [
        Entry(
          'Graphic resizing test',
          'Test graphic resizing texture creation (flicker on resize).',
          builder: buildTestGraphicResizing,
          upstreamFile: 'test_graphic_resizing.dart',
        ),
        Entry(
          'Memory cleanup test',
          'Test memory cleanup by toggling the visibility of a Rive widget.',
          builder: buildTestMemoryCleanup,
          upstreamFile: 'test_memory_cleanup.dart',
        ),
      ]),
      // Upstream's last section. Both play on Rive's classic runtime
      // (Rive(legacy: true)): inputs and text runs are what the current one
      // dropped for data binding.
      Section('Legacy Features [Use data binding instead]', [
        Entry(
          'Inputs [Nested]',
          'Legacy: Handle input [nested] controls in Rive graphics.',
          builder: buildInputs,
          upstreamFile: 'inputs.dart',
        ),
        Entry(
          'Text Runs [Nested]',
          'Legacy: Handle text runs [nested] components in Rive graphics.',
          builder: buildTextRuns,
          upstreamFile: 'text_runs.dart',
        ),
      ]),

      // Not upstream's. Files played as they were published, with nothing
      // of the example's around them: four from the Rive Marketplace, under
      // their creators' licence (CC BY 4.0, credited on their screens and in
      // assets/rive/marketplace/NOTICE.md), and DartNative's own traced
      // artwork, from an image generated with Craiyon (credited on its
      // screen). Their files are in assets/rive/marketplace/ and their
      // screens in screens/marketplace/.
      Section('Rive Marketplace Demos', [
        Entry(
          'Audio Player',
          'A scripted audio player by RiottersDesign, from the Rive '
              'Marketplace (CC BY 4.0).',
          builder: buildAudioPlayer,
        ),
        Entry(
          'StudioRun',
          'A cosmic runner game by TheLittleLabs, from the Rive Marketplace '
              '(CC BY 4.0).',
          builder: buildStudioRun,
        ),
        Entry(
          'Big Wheel',
          'Tap the character to change its head, body or wheel. By JcToon, '
              'from the Rive Marketplace (CC BY 4.0).',
          builder: buildBigWheel,
        ),
        Entry(
          'Sleep Onboarding',
          'An onboarding screen to tap through. By marciofpantoja, from the '
              'Rive Marketplace (CC BY 4.0).',
          builder: buildSleepOnboarding,
        ),
        Entry(
          'Dragon Ball',
          'A traced illustration as one artboard, with a little that moves.',
          builder: buildDragonBall,
        ),
      ]),

      // Not upstream's. The screens this example had before it was rebuilt
      // as a replica of theirs, kept here until it is decided which become
      // official, and DartNative's own since. Each of the former brings its
      // own Scaffold, hence selfManaged.
      Section('Additional demos', [
        Entry(
          'Controls',
          'Playback, state machine inputs, and the event log.',
          builder: _controls,
          selfManaged: true,
        ),
        Entry(
          'Who owns the input',
          'hitTestBehavior, and the workaround the README names.',
          builder: _hitTest,
          selfManaged: true,
        ),
        Entry(
          'Four upstream cases, one screen',
          "Ports of four of rive-flutter's examples on one screen, to compare.",
          builder: _flutterExamples,
          selfManaged: true,
        ),
        Entry(
          'Layout',
          "Every fit and alignment — ports rive-ios's own demo.",
          builder: _layout,
          selfManaged: true,
        ),
        Entry(
          'Text, artboards, URL',
          'The API surfaces nothing else here covers.',
          builder: _sources,
          selfManaged: true,
        ),
        Entry(
          "Rive's own: Inputs",
          'Their examples/inputs.dart, ported line for line.',
          builder: _officialInputs,
          selfManaged: true,
        ),
        Entry(
          'Grid',
          'Many artboards in a recycling FastGrid.',
          builder: _grid,
          selfManaged: true,
        ),
        Entry(
          'List',
          'The same artboards as the rows of a recycling FastList.',
          builder: _list,
          selfManaged: true,
        ),
      ]),
    ];

Widget _controls(BuildContext _) => const RiveControlsDemo();
Widget _hitTest(BuildContext _) => const RiveHitTestDemo();
Widget _flutterExamples(BuildContext _) => const RiveFlutterExamplesDemo();
Widget _layout(BuildContext _) => const RiveLayoutDemo();
Widget _sources(BuildContext _) => const RiveSourcesDemo();
Widget _officialInputs(BuildContext _) => const official.ExampleInputs();
Widget _grid(BuildContext _) => const RiveGridDemo();
Widget _list(BuildContext _) => const RiveListDemo();
