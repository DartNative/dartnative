# dartnative_home_widget

Home screen widgets for DartNative apps. You write the widget's design in
Dart, with the same components as `dartnative_live_activities`, and the
plugin draws it natively: on the iOS home screen in four sizes and on the
lock screen in three, and on the Android home screen. Send the design once,
then change only its values.

## See it in action

https://github.com/user-attachments/assets/ea6f3211-3081-4efb-bbbd-5b4f55641ed5

The example's widgets in the widget gallery, each drawn as it will look:
the weather in two sizes and the counter with its button. Then the weather
widget is added to the home screen. This is the plugin's example app.

## Why you'll like it

- **No Swift or Kotlin to write.** The widgets live in your `pubspec.yaml`;
  the design is Dart. DartNative builds the widgets into your app on both
  platforms.
- **Native drawing.** Text, icons, images, rings and bars drawn by SwiftUI
  on iOS and by Android's own widget views on Android, with the system's
  margins, corners, light and dark backgrounds and lock screen tint.
- **Cheap updates.** A design reads its values with `bind('field')`, so an
  update sends a few values, not the whole design.
- **Changes on its own.** Give a widget values for later, an agenda's next
  event or the hours of a forecast, and it shows each at its time with your
  app closed.
- **Taps and buttons.** A tap opens your app at a link you choose; a button
  runs your Dart code without opening the app, even when it is closed (iOS
  17 and later, and Android).
- **The widget list shows your widget.** On Android 15 and later the list
  people pick widgets from shows your widget as you draw it, and on Android
  your app can offer to add a widget to the home screen.

## Requirements

| | Minimum | Notes |
| --- | --- | --- |
| iOS | 16.0 | Buttons need iOS 17 |
| Android | 12 | Up to 16 widgets per app |

## Install

```yaml
dependencies:
  dartnative_home_widget: ^0.1.0   # from dartpub.dev
```

```bash
dn pub get
```

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## List your widgets

Each widget your app offers is listed in `pubspec.yaml`, at the top level:

```yaml
dartnative_home_widget:
  widgets:
    - id: weather
      name: Weather
      description: The temperature and the sky where you are.
      sizes: [small, medium, lockRectangular]
```

- `id` is the widget's name for the system: lowercase letters, digits and
  underscores. Keep it once your app is published, or the widgets people
  placed disappear.
- `name` and `description` are shown in the widget gallery.
- `sizes` are `small`, `medium`, `large`, `extraLarge` (iPad) and the lock
  screen's `lockCircular`, `lockRectangular` and `lockInline`. On Android a
  widget starts at its smallest home screen size (small is 2 × 2 cells,
  medium 4 × 2, large 4 × 4) and can be resized across the sizes it lists;
  Android has no lock screen widgets.

The widgets are built into the app, so a change to this list takes a new
build.

## iOS setup

**1. Raise the minimum to iOS 16.0.** In `ios/Podfile`:

```ruby
platform :ios, '16.0'
```

and in Xcode set the *Runner* target's **Minimum Deployments** to 16.0.

**2. Nothing else to add by hand.** When `dn` runs `pod install`, DartNative
adds to your project everything the widgets need:

- a `DartNativeWidgets` widget extension that draws them, with its files in
  `ios/DartNativeWidgets/`;
- the App Group `group.<your bundle id>` on the app and on the extension,
  which is how the two share the designs;
- the file that tells iOS about the widgets' buttons.

On the simulator that is all: run the app.

**3. On an iPhone, App Group setup.** A phone only runs an app whose App Group
is registered for your team, and only Xcode can register it:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Under *Signing & Capabilities*, pick your team for the **Runner** and the
   **DartNativeWidgets** targets. Each one shows the App Group
   `group.<your bundle id>`.
3. Build and run once from Xcode on the phone. From then on `dn run` works
   too.

**Links.** A tap opens your app at the design's `link`. Register its scheme
in `ios/Runner/Info.plist` under `CFBundleURLTypes`, as for any link your app
opens.

## Android setup

Nothing to add by hand. When the app builds, DartNative adds each widget you
list to the widget list of the home screen, with its name, description and
sizes. A tap opens your app's own screen with the link, so the link needs no
setup on Android.

The first build also writes `android/app/dartnative_home_widget_slots.txt`.
Keep it in your repository: it is how a widget someone placed stays the
same widget when you reorder or remove widgets in `pubspec.yaml`.

**Icons.** SF Symbols are iOS only: give each icon a PNG for Android, listed
under your assets.

```dart
const LiveIcon.symbol('sun.max.fill', android: 'assets/icons/sun.png')
```

## Draw a widget

```dart
import 'package:dartnative_home_widget/dartnative_home_widget.dart';

final weather = HomeWidgetDesign(
  link: 'myapp://weather',
  small: LiveColumn([
    LiveText(bind('place'), size: 13, weight: 600),
    const LiveSpacer(),
    LiveText(bind('temperature'), size: 44, weight: 300),
    LiveText(bind('sky'), size: 13, muted: true),
  ], align: LiveAlign.start),
  lockRectangular: LiveText.format('{temperature} · {sky}'),
);

// Once, or when the design changes:
await HomeWidgets.update('weather',
    design: weather,
    values: {'place': 'Lisbon', 'temperature': '21°', 'sky': 'Sunny'});

// Later, only what changed:
await HomeWidgets.update('weather', values: {'temperature': '23°'});
```

The values you send are added to the ones the widget has; a value set to
`null` is removed.

A size with no design of its own takes the nearest smaller home screen
size's; `any:` is the design of every size left. The lock screen sizes take
only their own design or `any`, as they are drawn in one tint by the system.

`background:` is `system` (light or dark with the phone), `light`, `dark` or
`accent`; `accent:` colours what the design marks as accent.

## Values that change on their own

A widget can take values at times to come, with your app closed. Each
entry holds only what changes at its time:

```dart
await HomeWidgets.update('agenda', values: {'next': 'Standup', 'at': '9:00'}, timeline: [
  HomeWidgetEntry(DateTime(2026, 5, 4, 9, 30), {'next': 'Design review', 'at': '11:00'}),
  HomeWidgetEntry(DateTime(2026, 5, 4, 11, 30), {'next': 'Lunch', 'at': '12:30'}),
]);
```

A new `timeline:` replaces the one the widget had, and `timeline: []` ends
it. Once an entry's time has come it counts as part of the widget's values,
so values you send, in the same call or later, win over it, and
`HomeWidgets.values` returns what the widget shows now.

iOS shows each entry at its time. Android shows it within ten minutes of
its time, or at its time when your app may set exact alarms. For that, add
`<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>`
to `android/app/src/main/AndroidManifest.xml`; from Android 14 it is off
until the person allows it in the system settings (Alarms & reminders).
`USE_EXACT_ALARM` needs no allowing, but Google Play accepts it only in
alarm clock and calendar apps.

For a countdown or a time that counts up, use `LiveText.countdown` and
`LiveText.stopwatch`: the system runs them on its own. `LiveText.relative`
("in 5 min") keeps up on its own on iOS; on Android it is written when the
widget is drawn.

## Taps and buttons

```dart
// The app was opened by a tap on a widget:
final tap = await HomeWidgets.launchTap();

// Taps while the app runs:
HomeWidgets.taps.listen((t) => print('${t.widget} opened ${t.link}'));
```

A button runs your Dart code without opening the app (iOS 17 and later, and
Android), whether the app is open, in the background or closed:

```dart
LiveButton(id: 'add', label: 'Add one');

@pragma('vm:entry-point')
Future<void> onWidgetAction(HomeWidgetAction action) async {
  if (action.widget != 'counter' || action.button != 'add') return;
  final count = (await HomeWidgets.values('counter'))['count'] as int? ?? 0;
  await HomeWidgets.update('counter', values: {'count': count + 1});
}

void main() {
  DartNativePluginRegistrant.registerAll();
  HomeWidgets.handleActions(onWidgetAction);
  runApp(const MyApp());
}
```

The handler must be a top-level or static function marked
`@pragma('vm:entry-point')`, and the presses reach it one after the other.
Call `handleActions` in `main()`, before anything listens to
`HomeWidgets.actions`.

With the app closed, iOS wakes your app in the background, which runs
`main()` and then the handler. On Android the handler runs on its own,
without your app's screen and without `main()`: if it uses other DartNative
plugins, load them at its start, for example with
`DartNativePluginRegistrant.registerAll()` (loading twice is harmless). The
system keeps your app running until the handler is done, for up to about 20
seconds on iOS and 45 on Android; keep the work short.

`HomeWidgets.actions` is the stream of presses while your app runs, for a
screen that shows them.

## Add a widget from the app (Android)

```dart
if (await HomeWidgets.canPin()) {
  await HomeWidgets.pin('counter'); // the home screen asks the user
}
```

`canPin()` is false on iOS, where people add widgets from the home screen,
and on Android launchers that cannot do it.

## Placed widgets

```dart
final placed = await HomeWidgets.placed(); // [HomeWidgetPlacement(weather, medium)]
```

## With dartnative_live_activities

Both plugins share the design components (`LiveText`, `LiveRow`…). In a file
that imports both, import one with a prefix:

```dart
import 'package:dartnative_home_widget/dartnative_home_widget.dart' as hw;
```

## Troubleshooting

**`update` fails with `not_listed`.** The widget is not in the app: list it
under `dartnative_home_widget: widgets:` in `pubspec.yaml`, then build the
app again.

**The widget shows its name only.** The app has not drawn it since it was
installed: call `HomeWidgets.update` with a design.

**`update` fails with `not_configured` (iOS).** The App Group is missing:
run the app with `dn` once, which sets it up.

**A widget is missing from the Android widget list.** A widget with only
lock screen sizes has no Android version; give it a home screen size.

**A button does nothing with the app closed.** Call
`HomeWidgets.handleActions` in `main()`, and run the app once after
installing it: that is when the system learns the handler. The handler must
be a top-level or static function marked `@pragma('vm:entry-point')`. On
Android an app the user force-stopped in the system settings gets no
presses until it is opened again, as for any Android app.

**A timeline entry shows late on Android.** Without the exact alarm
permission Android shows it within ten minutes of its time; see "Values
that change on their own".

## Example

The `example/` app offers a weather widget, with all three lock screen
sizes and a timeline for the next minutes, and a counter whose button works
with the app closed.

## Credits & license

Built on [home_widget](https://pub.dev/packages/home_widget) by Anton
Borries (BSD 3-Clause), and on the design components of
`dartnative_live_activities`, from
[live_island_kit](https://pub.dev/packages/live_island_kit) (MIT). See
`THIRD_PARTY_NOTICES`. The plugin is distributed under the DartNative
Framework License (`LICENSE`).
