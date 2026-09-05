import 'package:dartnative/dartnative.dart';

import '../repositories/app_repository.dart';

/// A friendly empty state: a large glyph in a soft circle, a title and a
/// message. Used by the stub screens and by Notes before the first note.
///
/// Shared widgets like this live in lib/widgets/: anything reused by more
/// than one screen moves here, screens keep only what is theirs.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    this.title,
    required this.message,
  });

  final IconData icon;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = (AppRepository.themeState..watch(context)).palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Two soft circles behind the glyph give it a little depth
            // without a single image asset, and they recolor with the
            // theme for free.
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(64),
              ),
              child: Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: p.avatarBg,
                    borderRadius: BorderRadius.circular(46),
                  ),
                  child: Center(
                    child: Icon(icon, color: p.textSoft, size: 44),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: p.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.textSoft,
                fontSize: 15,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
