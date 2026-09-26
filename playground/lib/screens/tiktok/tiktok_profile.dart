/// The creator's profile, reached by swiping left on a video, or by tapping
/// the avatar or the handle, the way TikTok does it.
library;

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_share/dartnative_share.dart';

import 'tiktok_bar.dart';
import 'tiktok_clips.dart';

const _white = Color(0xFFFFFFFF);
const _grey = Color(0xFF8A8A8E);
const _like = Color(0xFFFE2C55);

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.handle,
    required this.showGrid,
    required this.onBack,
    required this.onFollowChanged,
    required this.onOpenClip,
  });

  final String handle;

  /// Whether the clip grid loads its pictures. The page sits beside the
  /// feed and follows the creator of the clip on screen, so with the grid
  /// always loading every swipe fetched eighteen pictures behind the
  /// video; they load once the page is being pulled in.
  final bool showGrid;
  final VoidCallback onBack;
  final VoidCallback onFollowChanged;
  final ValueChanged<TikTokClip> onOpenClip;

  @override
  Widget build(BuildContext context) {
    final clips = clipsBy(handle);
    final social = clips.isEmpty ? null : socialFor(clips.first);
    final likes = clips.fold<int>(0, (n, c) => n + socialFor(c).likes);
    final isFollowing = followed.contains(handle);
    final insets = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final tile = (width - 2) / 3;

    return Container(
      color: const Color(0xFF000000),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: insets.top),
            // On iPhone the bar's two buttons sit in Liquid Glass capsules,
            // as the system draws them on a navigation bar; on Android the
            // back button is Material's arrow, as on Android's own bars.
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(width: TikTokBackButton.inset),
                  TikTokBackButton(onTap: onBack, capsule: true),
                  Expanded(
                    child: Center(
                      child: Text(
                        displayName(handle),
                        style: const TextStyle(
                          color: _white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  _capsule(
                    CupertinoIcons.ellipsis,
                    () => Share.share('https://www.pexels.com/@$handle'),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassEffectContainer(
              brightness: Brightness.dark,
              borderRadius: BorderRadius.circular(50),
              child: SizedBox(
                width: 100,
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: ClipOval(
                    child: clips.isEmpty
                        ? const SizedBox.shrink()
                        : Image.network(clips.first.posterUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '@$handle',
              style: const TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stat(compactCount(38 + handle.length * 11), 'Following'),
                _divider(),
                _stat(compactCount((social?.likes ?? 0) * 3 + 900), 'Followers'),
                _divider(),
                _stat(compactCount(likes), 'Likes'),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    isFollowing ? followed.remove(handle) : followed.add(handle);
                    onFollowChanged();
                  },
                  child: Container(
                    width: 150,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isFollowing ? const Color(0xFF2C2C2E) : _like,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          color: _white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _shareButton(),
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                social?.caption ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 0.5, color: const Color(0xFF2C2C2E)),
            Wrap(
              spacing: 1,
              runSpacing: 1,
              children: [
                for (final clip in clips)
                  GestureDetector(
                    onTap: () => onOpenClip(clip),
                    child: SizedBox(
                      width: tile,
                      height: tile * 4 / 3,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: showGrid
                                ? Image.network(clip.posterUrl, fit: BoxFit.cover)
                                : Container(color: const Color(0xFF1C1C1E)),
                          ),
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.play_fill, size: 12, color: _white),
                                const SizedBox(width: 4),
                                Text(
                                  compactCount(socialFor(clip).likes * 6),
                                  style: const TextStyle(
                                    color: _white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: insets.bottom + 90),
          ],
        ),
      ),
    );
  }

  /// Share, beside Follow: a Liquid Glass square on iPhone; on Android a
  /// grey square, the fill of the Following button, since glass draws
  /// nothing there.
  Widget _shareButton() {
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Share.share('https://www.pexels.com/@$handle'),
      child: const SizedBox(
        width: 42,
        height: 42,
        child: Center(
          child: Icon(CupertinoIcons.arrowshape_turn_up_right_fill, size: 18, color: _white),
        ),
      ),
    );
    if (Platform.isAndroid) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: button,
      );
    }
    return GlassEffectContainer(
      brightness: Brightness.dark,
      interactive: true,
      borderRadius: BorderRadius.circular(8),
      child: button,
    );
  }

  Widget _capsule(IconData icon, VoidCallback onTap) => GlassEffectContainer(
    brightness: Brightness.dark,
    interactive: true,
    borderRadius: BorderRadius.circular(22),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(child: Icon(icon, size: 20, color: _white)),
      ),
    ),
  );

  Widget _stat(String value, String label) => SizedBox(
    width: 96,
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _grey, fontSize: 13)),
      ],
    ),
  );

  Widget _divider() => Container(width: 0.5, height: 14, color: const Color(0xFF3A3A3C));
}
