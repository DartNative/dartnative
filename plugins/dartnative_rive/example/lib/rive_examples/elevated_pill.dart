// Upstream's Material `ElevatedButton`, which DartNative does not have, drawn
// the way the reference app shows it on upstream's dark theme: a grey pill
// with its label in the primary colour.

import 'package:dartnative/dartnative.dart';

import 'theme.dart';

/// `ElevatedButton(onPressed:, child:)`; [backgroundColor] and
/// [foregroundColor] stand in for `ElevatedButton.styleFrom`.
class ElevatedPill extends StatelessWidget {
  const ElevatedPill({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = buttonColor,
    this.foregroundColor = primaryColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: foregroundColor,
          fontSize: 14,
          fontFamily: monoFont,
        ),
        child: child,
      ),
    ),
  );
}
