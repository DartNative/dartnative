/// Material 3 — DYNAMIC COLOR (Material You): the device's wallpaper-derived
/// tonal palettes and the M3 color scheme built from them, straight from
/// `DynamicColor`.
///
/// Android 12+ shows the REAL device palette — change the wallpaper and
/// relaunch to watch every strip and role re-tint. Older devices (and iOS)
/// get the honest fallback story: `null`, theme from your own seed.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class M3DynamicColorDemo extends StatelessWidget {
  const M3DynamicColorDemo({super.key});

  /// The 13 M3 tones the device samples (TonalPalette.tone is exact here).
  static const _tones = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100];

  Widget _strip(String name, TonalPalette palette) => Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  for (final t in _tones)
                    Expanded(
                      child: Container(
                        height: 34,
                        color: palette.tone(t),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _role(String name, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          name,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );

  /// The selected-tab pill in a navigation bar uses `secondaryContainer` for its
  /// background and `onSecondaryContainer` for its glyph, so this row shows what
  /// a tab bar should match. Both are read off the accent2 ramp at the tones
  /// Material 3 specifies:
  ///   light: container = tone 90, on = tone 10
  ///   dark:  container = tone 30, on = tone 90
  /// They sit at opposite ends of the same ramp as the plain `secondary` chip.
  Widget _secondaryContainerRoles(TonalPalette accent2, Brightness b) {
    final dark = b == Brightness.dark;
    final container = accent2.tone(dark ? 30 : 90);
    final onContainer = accent2.tone(dark ? 90 : 10);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _role('secondaryContainer', container, onContainer),
        _role('onSecondaryContainer', onContainer, container),
      ],
    );
  }

  Widget _roles(String header, ColorScheme s, [TonalPalette? accent2]) =>
      Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            if (accent2 != null) ...[
              _secondaryContainerRoles(accent2, s.brightness),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _role('primary', s.primary, s.onPrimary),
                _role('primaryContainer', s.primaryContainer,
                    s.onPrimaryContainer),
                _role('secondary', s.secondary, s.onSecondary),
                _role('surface', s.surface, s.onSurface),
                _role('surfaceContainer', s.surfaceContainer, s.onSurface),
                _role('surfaceContainerHigh', s.surfaceContainerHigh,
                    s.onSurface),
                _role('surfaceContainerHighest', s.surfaceContainerHighest,
                    s.onSurface),
                _role('outline', s.outline, s.surface),
                _role('error', s.error, s.onError),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final palette = DynamicColor.corePalette();
    final dark = DynamicColor.colorScheme(brightness: Brightness.dark);
    final light = DynamicColor.colorScheme(brightness: Brightness.light);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dynamic Color',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      backgroundColor: kHomeBg,
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 40),
        children: [
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 16),
            child: Text(
              'The wallpaper-derived Material You palette, read from the '
              'system and rebuilt into the M3 color roles in Dart. Change '
              'your wallpaper and relaunch — every strip re-tints.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          if (palette == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'No device palette here — Material You needs Android 12+. '
                  'DynamicColor.colorScheme() returned null (the honest '
                  'fallback: theme from your own seed instead).',
                  style: TextStyle(color: kTextPrimary, fontSize: 14),
                ),
              ),
            )
          else ...[
            _strip('PRIMARY (accent1)', palette.primary),
            _strip('SECONDARY (accent2)', palette.secondary),
            _strip('TERTIARY (accent3)', palette.tertiary),
            _strip('NEUTRAL (neutral1)', palette.neutral),
            _strip('NEUTRAL VARIANT (neutral2)', palette.neutralVariant),
            if (dark != null)
              _roles('M3 ROLES — DARK', dark, palette.secondary),
            if (light != null)
              _roles('M3 ROLES — LIGHT', light, palette.secondary),
          ],
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, top: 12),
            child: Text(
              'WHY NATIVE MATTERS — these are the REAL system tonal '
              'palettes (android.R.color.system_accent1_* …), not a '
              'seed-simulated scheme: the exact colors every Material You '
              'app on this device is themed with. One native read per '
              'launch; the role mapping is Compose Material3\'s, in Dart.',
              style: TextStyle(color: kTextTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
