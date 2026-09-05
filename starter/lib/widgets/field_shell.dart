import 'package:dartnative/dartnative.dart';

/// The surface behind a text field.
///
/// dartnative text fields render no box of their own (the documented
/// contract: the field is chromeless, the app styles the surface). Wrap
/// every field sitting on a flat background in one of these.
class FieldShell extends StatelessWidget {
  const FieldShell({super.key, required this.color, required this.child});

  /// The fill, usually the palette's surface color.
  final Color color;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
