import 'package:dartnative/dartnative.dart' show Color;
import 'package:dartnative_home_widget/dartnative_home_widget.dart';

/// How a sky looks: its symbol (an SF Symbol on iOS, a PNG on Android),
/// the symbol's color and the widget's color.
class _SkyLook {
  const _SkyLook(this.symbol, this.android, this.symbolColor, this.background);

  final String symbol;
  final String android;
  final Color symbolColor;
  final Color background;
}

const _icons = 'assets/icons';

const _white = Color(0xFFFFFFFF);

const _looks = {
  'Sunny': _SkyLook('sun.max.fill', '$_icons/sun.png', Color(0xFFFFD60A), Color(0xFF1F7FE5)),
  'Cloudy': _SkyLook('cloud.fill', '$_icons/cloud.png', _white, Color(0xFF5E7491)),
  'Light rain': _SkyLook('cloud.drizzle.fill', '$_icons/rain.png', Color(0xFFBFE3FF), Color(0xFF3F5878)),
  'Windy': _SkyLook('wind', '$_icons/wind.png', _white, Color(0xFF23869A)),
  'Clear': _SkyLook('moon.stars.fill', '$_icons/moon.png', Color(0xFFFFE9A8), Color(0xFF1E2B5C)),
};

/// The weather widget: the place, the temperature, the sky and the chance
/// of rain, on a color that follows the sky, with a rectangle, a circle and
/// a line for the lock screen. The color and the symbol come from [sky], so the
/// app sends the design with each new weather.
HomeWidgetDesign weatherDesign(String sky) {
  final look = _looks[sky] ?? _looks['Sunny']!;
  final symbol = LiveIcon.symbol(
    look.symbol,
    android: look.android,
    size: 22,
    color: look.symbolColor,
  );
  final place = LiveRow([
    LiveText(bind('place'), size: 15, weight: 600, lines: 1),
    const LiveIcon.symbol('location.fill', android: '$_icons/location.png', size: 10),
  ], gap: 4);
  return HomeWidgetDesign(
    accent: look.background,
    background: HomeWidgetBackground.accent,
    link: 'homewidgetexample://weather',
    small: LiveColumn([
      place,
      LiveText(bind('temperature'), size: 44, weight: 300),
      const LiveSpacer(),
      symbol,
      LiveText(bind('sky'), size: 13, weight: 600, lines: 1),
      LiveText.format('Rain {rainText}', size: 12, muted: true, lines: 1),
    ], align: LiveAlign.start, gap: 2),
    medium: LiveRow([
      LiveColumn([
        place,
        LiveText(bind('temperature'), size: 52, weight: 300),
        const LiveSpacer(),
        LiveRow([
          symbol,
          LiveText(bind('sky'), size: 15, weight: 600, lines: 1),
        ], gap: 6),
      ], align: LiveAlign.start, gap: 2),
      const LiveSpacer(),
      LiveColumn([
        LiveProgress.ring(
          value: bind('rain'),
          size: 76,
          style: const LiveProgressStyle(height: 7),
          child: LiveColumn([
            const LiveIcon.symbol(
              'drop.fill',
              android: '$_icons/drop.png',
              size: 13,
              color: Color(0xFFBFE3FF),
            ),
            LiveText(bind('rainText'), size: 15, weight: 600),
          ], gap: 1),
        ),
        LiveText.literal('Chance of rain', size: 11, muted: true),
      ], gap: 6),
    ], gap: 12),
    lockRectangular: LiveRow([
      LiveIcon.symbol(look.symbol, size: 22),
      LiveColumn([
        LiveText(bind('place'), size: 13, weight: 600, lines: 1),
        LiveText.format('{temperature} · {sky}', size: 15, lines: 1),
      ], align: LiveAlign.start, gap: 1),
    ], gap: 8),
    lockCircular: LiveColumn([
      LiveIcon.symbol(look.symbol, size: 14),
      LiveText(bind('temperature'), size: 18, weight: 600),
    ], gap: 1),
    lockInline: LiveRow([
      LiveIcon.symbol(look.symbol),
      LiveText.format('{temperature} {place}'),
    ]),
  );
}

/// The counter widget: a number and a button that raises it from the
/// widget, without opening the app (iOS 17 and later, and Android).
final counterDesign = HomeWidgetDesign(
  accent: const Color(0xFF27AE60),
  link: 'homewidgetexample://counter',
  small: LiveColumn([
    LiveText.literal('Counter', size: 13, weight: 600, muted: true),
    const LiveSpacer(),
    LiveText(bind('count'), size: 44, weight: 600, tabular: true),
    const LiveSpacer(),
    LiveButton(id: 'add', label: 'Add one'),
  ], align: LiveAlign.center),
);
