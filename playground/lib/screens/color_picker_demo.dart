/// Color Picker: the system picker driving the screen behind it.
///
/// Tapping the button presents `UIColorPickerViewController`, the same picker
/// system apps use, with its grid, spectrum, sliders, opacity and eyedropper.
/// The background follows the selection while the sheet is open, so the whole
/// screen previews the colour before it is committed.
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import 'home/demo_ui.dart';

class ColorPickerDemo extends StatefulWidget {
  const ColorPickerDemo({super.key});

  @override
  State<ColorPickerDemo> createState() => _ColorPickerDemoState();
}

class _ColorPickerDemoState extends State<ColorPickerDemo> {
  Color _color = const Color(0xFFFF2D6F);

  /// True while the screen background is dark enough to need light text.
  bool get _isDark {
    final luma = (0.299 * _color.red + 0.587 * _color.green + 0.114 * _color.blue) / 255;
    return luma < 0.55;
  }

  Future<void> _pick() async {
    final picked = await showColorPicker(
      context: context,
      initialColor: _color,
      title: 'Change color',
      // Live preview: the background tracks the picker while it is open.
      onChanged: (c) => setState(() => _color = c),
    );
    if (picked != null && mounted) setState(() => _color = picked);
  }

  @override
  Widget build(BuildContext context) {
    final onColor = _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E);
    return Scaffold(
      backgroundColor: _color,
      appBar: AppBar(
        title: Text(
          'Color Picker',
          style: TextStyle(
            color: onColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _color,
        leading: BackButton(iconColor: onColor),
      ),
      body: Container(
        color: _color,
        child: Center(
          child: Platform.isIOS
              ? _PickButton(onTap: _pick)
              : const _UnsupportedNote(),
        ),
      ),
    );
  }
}

/// The white pill that opens the picker.
class _PickButton extends StatelessWidget {
  const _PickButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change color',
              style: TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Text('🎨', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

/// Android has no system colour picker: neither the platform nor the Material
/// components ship one, so there is nothing native to present here.
class _UnsupportedNote extends StatelessWidget {
  const _UnsupportedNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        'The system color picker is an iOS control.\n'
        'Android has no platform equivalent.',
        textAlign: TextAlign.center,
        style: TextStyle(color: kTextPrimary, fontSize: 15, height: 1.4),
      ),
    );
  }
}
