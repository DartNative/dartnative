/// Liquid Glass — MORPHING BUTTONS: bar buttons move & merge across screens.
///
/// iOS 26's navigation bar animates its buttons BETWEEN screens: on push,
/// buttons that persist glide to their new place, related ones blur-merge
/// into a single capsule, and the rest dissolve — the messaging-app effect
/// where the camera and ⊕ buttons melt into the chat's call button. Popping
/// plays it in reverse. The animation is the system's own.
///
/// A bar using only plain native features (text title/subtitle, icon
/// actions, default background) is hosted on the system navigation bar
/// with real bar buttons, and the transition matches them automatically —
/// these screens need no morph-specific code at all. Two bar-button
/// tools complete the look: `prominent: true` renders the filled, tinted
/// capsule (tint from `titleStyle.color`), and adjacent actions share
/// ONE glass capsule — a `SizedBox(width: 8)` between actions splits
/// them. `AppBar.ios` (`AppBarIOSConfig.systemBar`) selects the host
/// explicitly when needed.
///
/// iOS 18 and older and Android keep their regular bar — no morph.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class MorphingButtonsDemo extends StatelessWidget {
  const MorphingButtonsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          BarButtonItem(
            icon: 'camera.fill',
            onPressed: () {},
          ),
          // Splits the camera and ⊕ into separate capsules — adjacent
          // actions otherwise share one.
          const SizedBox(width: 8),
          BarButtonItem(
            icon: 'plus',
            prominent: true,
            titleStyle: const TextStyle(color: kAccentGreen),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The bar\'s action buttons MORPH between views: open the '
                'chat and the camera and green ⊕ merge into its call '
                'button; going back separates them again. The transition '
                'is the system\'s own.',
                style: TextStyle(
                    color: kTextSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Center(
                child: Button(
                  title: 'See the icons morph between views',
                  variant: ButtonVariant.filled,
                  onPressed: () => Navigator.push(
                    context,
                    PageRoute(
                      builder: (_) => const _MorphChatScreen(),
                      settings: '/liquid-glass-morphing-buttons-chat',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chat screen the buttons morph into: one shared capsule holding the
/// call button (matched with the camera) and its options chevron —
/// adjacent actions share a capsule, no field needed.
class _MorphChatScreen extends StatelessWidget {
  const _MorphChatScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: const Text('Saved Messages'),
        subtitle: const Text('You'),
        actions: [
          BarButtonItem(
            icon: 'video.fill',
            onPressed: () {},
          ),
          BarButtonItem(
            icon: 'chevron.down',
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'The camera became the call button; the ⊕ dissolved into '
              'it. Go back and watch them separate again.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: kTextSecondary, fontSize: 14, height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
