/// DartNative tutorial — layout that thinks in widgets.
///
/// A profile card screen built from the core layout vocabulary:
///   • Column / Row for the flows
///   • Stack + Positioned for the banner overlay
///   • Expanded for proportional widths
///   • Padding / SizedBox for rhythm
///
/// Every widget maps to a real native view; layout runs on Yoga (flexbox)
/// with Flutter's sizing rules enforced by the reconciler — so this file
/// reads and behaves exactly like the Flutter you already know.
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const ProfileScreen());
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      brightness: Brightness.light,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Banner(),
          SizedBox(height: 56), // clears the avatar overhang below the banner
          _NameBlock(),
          SizedBox(height: 20),
          _StatsRow(),
          SizedBox(height: 20),
          _Bio(),
          SizedBox(height: 24),
          _ActionButtons(),
        ],
      ),
    );
  }
}

// #region banner
/// Stack: the banner is the in-flow child (it sizes the Stack); the avatar
/// is Positioned to overhang the bottom edge — the classic profile header.
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // In-flow child: defines the Stack's size.
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF29CB1), Color(0xFFFAD9C5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Overlay child: absolute-positioned against the Stack's box.
        Positioned(
          left: 0,
          bottom: -44,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFE25574),
              borderRadius: BorderRadius.circular(44),
              border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
            ),
            child: const Center(
              child: Text(
                'L',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion banner

// #region name
class _NameBlock extends StatelessWidget {
  const _NameBlock();

  @override
  Widget build(BuildContext context) {
    // Row: name grows, badge hugs its content at the trailing edge.
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Lisa Taylor',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '@lisa — building native things',
                style: TextStyle(color: Color(0xFF6B6B70), fontSize: 14),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF7DD),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'PRO',
            style: TextStyle(
              color: Color(0xFF4E7A1E),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion name

// #region stats
/// Three equal columns: Expanded gives each cell an identical share of the
/// row — the flexbox way to build a stats strip.
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    Widget stat(String n, String label) => Expanded(
          child: Column(
            children: [
              Text(
                n,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style:
                    const TextStyle(color: Color(0xFF6B6B70), fontSize: 12),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          stat('128', 'Posts'),
          stat('2.4k', 'Followers'),
          stat('310', 'Following'),
        ],
      ),
    );
  }
}
// #endregion stats

class _Bio extends StatelessWidget {
  const _Bio();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Native UI enthusiast. This whole screen is real platform views — '
      'the text you are reading is a UILabel, and the scroll behind it is '
      'a real scroll view with system physics.',
      style: TextStyle(color: Color(0xFF3C3C43), fontSize: 15, height: 1.5),
    );
  }
}

// #region buttons
/// Two buttons sharing the row 2:1 — Expanded(flex:) is the proportional
/// layout tool; CrossAxisAlignment defaults keep them equal height.
class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Follow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Message',
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion buttons
