/// Showcase tab — a curated best-of reel, the first thing a dev sees.
///
/// Entries are pointers, not exclusive homes: every screen here also lives in
/// its taxonomy tab. Big visual cards, one-line pitches, tech chips.
import 'dart:io' show Platform;

import '../drawer_feel_demo.dart';
import 'package:dartnative/dartnative.dart';

import '../backdrop_filter_demo.dart';
import '../canvas_demo.dart';
import '../chat_screen_demo.dart';
import '../media/chatgpt_picker_demo.dart';
import '../music/music_demo.dart';
import '../color_picker_demo.dart';
import '../carousel_demo.dart';
import '../text_typewriter_demo.dart';
import '../hero_demo.dart';
import '../staggered_cards_demo.dart';
import 'demo_ui.dart';

class ShowcaseTab extends StatelessWidget {
  const ShowcaseTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kHomeBg,
      child: ListView(
        children: [
          SizedBox(height: tabListTopGap(context, fallback: 20)),
          ShowcaseCard(
            gradient: const [Color(0xFFFA243C), Color(0xFF8E2431)],
            icon: CupertinoIcons.music_note_2,
            title: 'Music',
            pitch: 'Floating glass tab bar with a live mini player above it. '
                'Scroll to minimise, tap to open the full player.',
            tags: const ['UITabAccessory', 'UISearchTab', 'real playback'],
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const MusicDemo(),
                settings: '/music',
              ),
            ),
          ),
          ShowcaseCard(
            gradient: const [Color(0xFF2A1B4A), Color(0xFF4A1B2A)],
            icon: CupertinoIcons.music_albums_fill,
            title: 'Carousel',
            pitch: 'Cover flow that snaps: cards scale as they pass and the '
                'screen repaints to the centred album.',
            tags: const ['drag + spring', 'per-frame transforms'],
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const CarouselDemo(),
                settings: '/carousel',
              ),
            ),
          ),
          ShowcaseCard(
            gradient: const [Color(0xFF30D158), Color(0xFF0A84FF)],
            icon: CupertinoIcons.photo_on_rectangle,
            title: 'ChatGPT Picker',
            pitch: 'The attach flow, replicated: a panel that opens over the '
                'keyboard, becomes the photo grid, and throws the picked '
                'photos into the composer.',
            tags: const ['over the keyboard', 'one morphing panel'],
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const ChatGptPickerDemo(),
                settings: '/chatgpt-picker',
              ),
            ),
          ),
          ShowcaseCard(
            gradient: const [Color(0xFF12343B), Color(0xFF2D5F5D)],
            icon: CupertinoIcons.textformat_alt,
            title: 'Live Text',
            pitch: 'A message types itself in real native text, emoji and '
                'all, straight from the pack this device is set to.',
            tags: const ['native labels', 'device emoji'],
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const TextTypewriterDemo(),
                settings: '/live-text',
              ),
            ),
          ),
          // Not exposed on Android: the picker is an iOS control.
          if (Platform.isIOS)
            ShowcaseCard(
              gradient: const [Color(0xFFFF2D6F), Color(0xFFFFC300)],
              icon: CupertinoIcons.paintbrush_fill,
              title: 'Color Picker',
              pitch: 'The system color picker drives the screen behind it, '
                  'live as you drag.',
              tags: const ['UIColorPickerViewController', 'iOS only'],
              onTap: (ctx) => Navigator.push(
                ctx,
                PageRoute(
                  builder: (_) => const ColorPickerDemo(),
                  settings: '/color-picker',
                ),
              ),
            ),
          ShowcaseCard(
            gradient: const [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
            icon: CupertinoIcons.bubble_left_bubble_right_fill,
            title: 'Chat Screen',
            pitch: 'Native list scrolling, rubber-band physics, and a '
                'keyboard-attached input bar.',
            tags: const ['UITableView', 'RecyclerView', 'no Skia'],
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const ChatScreenDemo(),
                settings: '/chat',
              ),
            ),
          ),
          ShowcaseCard(
            gradient: const [Color(0xFFBF5AF2), Color(0xFFFF375F)],
            icon: CupertinoIcons.rectangle_stack_fill,
            title: 'Hero Animations',
            pitch: 'Story viewer that morphs from tile to fullscreen — '
                'drag down to dismiss.',
            tags: const ['native overlay'],
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const HeroDemo(), settings: '/hero'),
            ),
          ),
          ShowcaseCard(
            gradient: const [Color(0xFFFF9F0A), Color(0xFFFF453A)],
            icon: CupertinoIcons.square_stack_3d_up_fill,
            title: 'Staggered Cards',
            pitch: 'Entrance choreography from AnimatedOpacity + '
                'AnimatedSlide — pure implicit animation.',
            tags: const ['implicit animations'],
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const StaggeredCardsDemo(),
                settings: '/staggered-cards',
              ),
            ),
          ),
          ShowcaseCard(
            gradient: const [Color(0xFF64D2FF), Color(0xFF0A84FF)],
            icon: CupertinoIcons.drop_fill,
            title: 'BackdropFilter',
            pitch: 'Real native blur — UIVisualEffectView and RenderEffect, '
                'no Skia.',
            tags: const ['UIVisualEffectView', 'RenderEffect'],
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const BackdropFilterDemo(),
                settings: '/backdrop-filter',
              ),
            ),
          ),
          ShowcaseCard(
            gradient: const [Color(0xFF30D158), Color(0xFF64D2FF)],
            icon: CupertinoIcons.paintbrush_fill,
            title: 'Canvas Surface',
            pitch: 'CustomPainter on a Metal-backed Skia surface, driven '
                'over FFI from the main isolate.',
            tags: const ['Skia', 'FFI'],
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                  builder: (_) => const CanvasDemo(), settings: '/canvas'),
            ),
          ),
          ShowcaseCard(
            gradient: const [Color(0xFF30D158), Color(0xFF0A84FF)],
            icon: CupertinoIcons.sidebar_left,
            title: 'Side Drawer',
            pitch: 'The push-style drawer and its native release feel — '
                'drag it, flick it, let go mid-way.',
            tags: const ['gesture', 'release feel', 'push style'],
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const DrawerFeelDemo(),
                settings: '/drawer-feel',
              ),
            ),
          ),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}
