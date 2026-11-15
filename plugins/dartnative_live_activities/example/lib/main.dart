import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'stories.dart';
import 'story_screen.dart';

void main() {
  // Platform bindings + the plugins' FFI symbols. Keep this as the FIRST line
  // of main() — see lib/dartnative_plugin_registrant.dart.
  DartNativePluginRegistrant.registerAll();
  SystemChrome.defaultStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  runApp(const HomeScreen());
}

const _muted = Color(0xFF6E6E73);
const _card = Color(0xFFF2F2F7);

/// The package's nine gallery designs, each told as a short story.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.light,
      appBar: AppBar(title: const Text('Live Activities')),
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            Platform.isIOS
                ? 'A live activity keeps something that is happening right '
                      'now in sight outside the app: on the lock screen and '
                      'in the Dynamic Island. Pick a story and play it step '
                      'by step.'
                : 'A Live Update keeps something that is happening right '
                      'now in sight outside the app: at the top of the '
                      'notifications, with a chip in the status bar. Pick a '
                      'story and play it step by step.',
            style: const TextStyle(fontSize: 15, color: _muted),
          ),
          if (Platform.isIOS) ...[
            const SizedBox(height: 16),
            const _SetupNote(),
          ],
          for (final story in stories) ...[
            const SizedBox(height: 16),
            _StoryCard(story),
          ],
        ],
      ),
    );
  }
}

/// What an iPhone needs before the activities can show.
class _SetupNote extends StatelessWidget {
  const _SetupNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'On an iPhone this example needs App Group setup: the app and its '
        'widget extension share the activities through an App Group. The '
        'README explains how. The simulator needs nothing.',
        style: TextStyle(fontSize: 14, color: Color(0xFF6B4E16)),
      ),
    );
  }
}

/// A story's picture, name and summary; a tap opens it.
class _StoryCard extends StatelessWidget {
  const _StoryCard(this.story);

  final Story story;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        PageRoute(builder: (_) => StoryScreen(story)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StoryPicture(story),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        story.summary,
                        style: const TextStyle(fontSize: 14, color: _muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
