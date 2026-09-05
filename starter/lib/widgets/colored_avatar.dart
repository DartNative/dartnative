import 'package:dartnative/dartnative.dart';

/// The gradients an avatar can take. Picked from the initials rather than
/// stored, so the same person always gets the same one without a column
/// in the database to keep in sync.
const _gradients = <LinearGradient>[
  LinearGradient(
    colors: [Color(0xFF7DB8E5), Color(0xFF689EE5), Color(0xFF5696E5)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  LinearGradient(
    colors: [Color(0xFF7FA5FF), Color(0xFF7489FE), Color(0xFF707EFE)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  LinearGradient(
    colors: [Color(0xFF16F1F3), Color(0xFF2CD9DB), Color(0xFF3EBBBD)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  LinearGradient(
    colors: [Color(0xFFFE7E60), Color(0xFFFF6E64), Color(0xFFFF5569)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  LinearGradient(
    colors: [Color(0xFFFFCA69), Color(0xFFFFBA64), Color(0xFFFFAC60)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  LinearGradient(
    colors: [Color(0xFFCFC476), Color(0xFFC8BE75), Color(0xFFB1AF68)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
];

LinearGradient _gradientForInitials(String initials) =>
    _gradients[initials.hashCode.abs() % _gradients.length];

/// A circular avatar showing initials on a gradient, or a person glyph
/// when there are none.
///
/// The gradient comes from the initials, so a name keeps its colour across
/// launches and devices with nothing stored anywhere.
class ColoredAvatar extends StatelessWidget {
  const ColoredAvatar({
    super.key,
    required this.initials,
    this.size = 46,
    this.fontSize,
  });

  final String initials;

  /// Diameter in logical pixels.
  final double size;

  /// Defaults to a share of [size], so one number sizes the whole avatar.
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final isEmpty = initials.isEmpty;
    final effectiveFontSize = fontSize ?? size * 0.36;
    // One letter reads small in a circle sized for two, so it gets more.
    final isSingleLetter = initials.length == 1;

    return Container(
      // Keyed by the initials: a name change is a different avatar, not a
      // repaint of the old one.
      key: ValueKey(initials),
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isEmpty ? null : _gradientForInitials(initials),
        color: isEmpty ? const Color(0xFF3A3A3C) : null,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isEmpty
          ? Icon(
              CupertinoIcons.person,
              color: const Color(0xFFFFFFFF),
              size: size * 0.47,
            )
          : Text(
              initials,
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize:
                    isSingleLetter ? effectiveFontSize * 1.3 : effectiveFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
