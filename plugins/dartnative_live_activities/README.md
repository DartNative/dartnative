# dartnative_live_activities

Live Activities on iOS and Live Updates on Android, from one Dart API. You
write a design once in Dart; the iPhone draws it on the lock screen and in
the Dynamic Island, and Android shows it at the top of the notifications,
with a chip in the status bar.

## See it in action

https://github.com/user-attachments/assets/ff817169-8dab-4006-8340-005456d448c5

The example's stories, each started from the app and followed in the
Dynamic Island: a ride pickup, a football match, a stock quote, a car
charging and a doctor's waiting room. This is the plugin's example app.

## Why you'll like it

- **One API.** `LiveActivities.start`, `update` and `end` do the same on iOS
  and Android.
- **Design in Dart.** A design is a tree of components (`LiveText`, `LiveRow`,
  `LiveProgress`, `LiveSparkline`…) tied to your data with `bind('field')`.
  SwiftUI draws it on iOS; Android draws it as a Live Update.
- **Ready-made designs.** 15 presets and 16 more elaborate designs (a ride
  pickup, a delivery order, a match score, a flight…) to use as they are or
  change.
- **Light updates.** The design travels once; each update only carries the
  data that changed.
- **Buttons, alerts and push.** Buttons on the lock screen card and in the
  notification, alerts that light up the island, and updates from your
  server with APNs and FCM.
- **No extension to write.** The widget extension that draws the activities
  is added to your iOS project for you.

## Requirements

| | Minimum | Notes |
| --- | --- | --- |
| iOS | 16.1 | Buttons on the card need iOS 17; starting from a push, iOS 17.2 |
| Android | 8.0 (API 26) | Android 16 and later promote it to a Live Update; before that it is an ongoing notification with a bar |

## Install

```yaml
dependencies:
  dartnative_live_activities: ^0.1.0   # from dartpub.dev
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

## iOS setup

**1. Raise the minimum to iOS 16.1**, the first version with Live
Activities. In `ios/Podfile`:

```ruby
platform :ios, '16.1'
```

and in Xcode set the *Runner* target's **Minimum Deployments** to 16.1.

**2. Nothing else to add by hand.** When `dn` runs `pod install`, DartNative
adds to your project everything the activities need:

- a `DartNativeWidgets` widget extension that draws them, with its files in
  `ios/DartNativeWidgets/`;
- the App Group `group.<your bundle id>` on the app and on the extension,
  which is how the two share the activities;
- `NSSupportsLiveActivities` in the app's `Info.plist`;
- the file that tells iOS about the activity's buttons.

On the simulator that is all: run the app.

**3. On an iPhone, App Group setup.** A phone only runs an app whose App Group
is registered for your team, and only Xcode can register it:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Under *Signing & Capabilities*, pick your team for the **Runner** and the
   **DartNativeWidgets** targets. Each one shows the App Group
   `group.<your bundle id>`.
3. Build and run once from Xcode on the phone. From then on `dn run` works
   too.

If you change the bundle id later, the next `dn` build moves the App Group to
the new id (a build started from Xcode does not), and step 3 registers it.

**Push (optional).** To update or start activities from your server, add the
*Push Notifications* capability to the Runner target and start the activity
with `requestPushToken: true` (see [Push](#push)).

## Android setup

Nothing to add: the plugin declares the notification permissions it needs.
Your app's `minSdk` must be 26 or higher.

Ask for permission before the first activity:

```dart
await LiveActivities.requestPermission();
```

On Android 16 and later the user can turn off promoted notifications for an
app; `LiveActivities.openPromotionSettings()` opens that screen.

## Quick look

```dart
import 'package:dartnative_live_activities/dartnative_live_activities.dart';

final activity = await LiveActivities.start(
  layout: const ParkingPreset().build(),
  state: {
    'title': 'Parking active',
    'subtitle': 'Blue zone · Main Street 400',
    'name': 'Plate ABC-123',
    'arrivesAt': DateTime.now().add(const Duration(minutes: 45)),
    'progress': 0.0,
  },
);

await activity.update({'progress': 0.5}); // only what changes travels
await activity.end(dismiss: const LiveDismiss.after(Duration(minutes: 5)));
```

Each preset takes its most common options (`accent`, `icon`, `appLogo`,
`buttons`, `chip`…) and documents the data it reads. `.override(...)`
replaces one region and keeps the rest:

```dart
final layout = const TripPreset(accent: Color(0xFFD81B60)).override(
  compactTrailing: LiveText.from(
    const LiveText(LiveBind('plate')),
    size: 15,
    weight: 600,
    accent: true,
  ),
);
```

## Your own design

```dart
final layout = LiveLayout(
  theme: const LiveTheme(accent: Color(0xFF00897B)),
  compactLeading: const LiveIcon.symbol('timer', accent: true),
  compactTrailing: LiveText.from(
    LiveText.countdown(bind('endsAt')),
    size: 15, weight: 600, accent: true,
  ),
  minimal: const LiveIcon.symbol('timer', accent: true),
  expanded: LiveExpanded(
    leading: const LiveBox(
      child: LiveIcon.symbol('timer', accent: true),
      size: 46, radius: 14, tint: 0.22,
    ),
    center: const LiveColumn([
      LiveText(LiveBind('title'), size: 15, weight: 600),
      LiveText(LiveBind('detail'), size: 13, muted: true),
    ]),
    trailing: LiveText.from(
      LiveText.countdown(bind('endsAt')),
      size: 22, weight: 700, accent: true,
    ),
    bottom: LiveProgress.bar(value: bind('progress')),
  ),
  lockScreen: const LiveLockScreen.sameAsExpanded(),
  android: LiveAndroid(
    title: bind('title'),
    text: const LiveText.format('{detail}'),
    chip: LiveChip.countdown(bind('endsAt')),
  ),
);
```

The design travels once, when the activity starts; each update carries only
the data, which keeps it under iOS's 4 KB limit. `LiveActivities.check(layout,
state)` tells you before you ship what does not fit or does not show on a
platform: a state that is too large, a long text in the compact island, an
Android chip that will not appear.

## Alerts and stale state

```dart
// The island expands and plays a sound (iOS); on Android the notification
// sounds and shows as a heads-up.
await activity.update(
  {'status': 'arrived'},
  alert: const LiveAlert(title: 'Your driver is here', body: 'Plate ABC-123'),
);
```

iOS shows nothing of an activity while its own app is open, alerts included:
send them while the app is in the background, or from your server.

`staleAfter` on `start` or `update` marks the content as out of date after
that time, and a design can show it with `LiveIf(LiveBind.stale.isTrue, …)`
(iOS 16.2 and later; on Android it is always `false`).

## Buttons

```dart
LiveActivities.onAction((id) {
  // the id of the LiveButton that was tapped
});
```

Buttons show on the lock screen card (iOS 17 and later, without opening the
app) and in the Android notification. The Dynamic Island does not draw them:
a tap on the island opens the app. A tap that arrives while the app is
closed is delivered once you listen to `onAction` again.

## Your own ids and what happened

```dart
await LiveActivities.start(layout: layout, state: state, customId: 'trip-42');

// Later, even after the app restarted:
final trip = await LiveActivities.activity('trip-42');

LiveActivities.stateChanges.listen((change) {
  // change.state: active, stale, ended or dismissed
});
```

Starting with a `customId` that is already alive updates that activity
instead of creating a second one.

## Push

- **iOS:** start with `requestPushToken: true` and send the tokens from
  `LiveActivities.pushTokens` to your server, which updates the activity
  through APNs. On iOS 17.2 and later the server can also start one;
  `LiveActivities.startedByPush` reports it. A design used that way is
  registered ahead with `LiveActivities.registerLayout(name, layout)`.
- **Android:** pass your FCM data messages to
  `LiveActivities.handlePush(data)`.

## Presets

| Preset | Case |
| --- | --- |
| `TripPreset` | Taxi |
| `DeliveryPreset` | Food delivery |
| `CourierPreset` | Package on its way |
| `PickupPreset` | Order for pickup |
| `QueuePreset` | Queue ticket |
| `FlightPreset` | Flight |
| `ParkingPreset` | Parking |
| `EvChargingPreset` | Car charging |
| `WorkoutPreset` | Workout |
| `CookingTimerPreset` | Cooking timer |
| `UploadPreset` | File upload |
| `TechnicianPreset` | Home technician |
| `TransitPreset` | Public transport |
| `WaitingRoomPreset` | Medical waiting room |
| `ScorePreset` | Sports score |

More elaborate designs, used the same way (`.build()`, `.sampleState()`,
`.override(...)`):

| Design | What it shows |
| --- | --- |
| `RidePickupPreset` | Ride pickup, light or dark card |
| `RideArrivalPreset` | Arrival time, fare and the car with its plate |
| `RideTripPreset` | Trip with phase, destination, category and fare |
| `RidePinPreset` | Trip start with the PIN, the driver's photo and a bar |
| `RideStopPreset` | A stop before pickup, the car with its plate |
| `RideDestinationPreset` | On the way to the destination |
| `DeliveryOrderPreset` | Delivery order in four stages |
| `StorePickupPreset` | Order pickup in three steps |
| `TrainPreset` | Train line with stations |
| `RunPreset` | A run: distance, time and goal |
| `MatchPreset` | A match score |
| `StockPreset` | A share price with its chart |
| `FlightPathPreset` | A flight on its curved route |
| `OrbitPreset` | An arc with a dot that advances |
| `ChargePreset` | Charging with a glowing cable |
| `FareSplitPreset` | A fare split into base, service and tip |

### Android: Live Update or card

The more elaborate designs use the **card** on Android by default, so Android
draws the same design as iOS; the card is never promoted to a Live Update and
has no chip. Pass `androidStyle: LiveAndroidStyle.liveUpdate` for the native
style that Android 16 promotes: title, text, bar, one large image and the
chip.

```dart
RidePickupPreset(androidStyle: LiveAndroidStyle.liveUpdate)
```

The card needs Android 12 or later; before that the native style is used.

## Troubleshooting

**Nothing shows on an iPhone.** Check, in order:
`await LiveActivities.areEnabled()` is `true` (the user can turn Live
Activities off per app in Settings); the App Group is registered (iOS
setup, step 3); and `LiveActivities.check(layout, state)` reports no errors.

**`pod install` says a pod "required a higher minimum deployment target".**
Set `platform :ios, '16.1'` in `ios/Podfile` (iOS setup, step 1).

**`LiveActivitiesException` codes.** `disabled`: the user turned Live
Activities (iOS) or notifications (Android) off. `unsupported`: the device
has no Live Activities (iPad, Mac). `not_found`: the activity already ended.
`not_configured`: the App Group is missing; build again, and on an iPhone
check step 3 of the iOS setup. `start_failed`: the system refused; the message says why.

**The activity stops at an old value.** iOS limits how often an activity
updates and ends it after eight hours. Set `staleAfter` so the card shows it
is old, and update it through push.

**No chip on Android.** It needs Android 16 and promoted notifications
allowed for the app (`LiveActivities.openPromotionSettings()`).

## Compatibility

| | iOS | Android 16 and later |
| --- | --- | --- |
| Dynamic Island (compact, minimal, expanded) | Yes | Does not exist |
| Your own lock screen design | Yes (`LiveLockScreen.custom`) | A standard notification |
| Text, icons and images | Yes | Title, text, chip and icons |
| Bar, stages and points | Yes, fully styled | Colour and markers; the system sets the thickness |
| Dashed line, glowing cable, glowing border | Yes | Left out |
| Ring and arc | Yes | Shown as a bar |
| Curved route | Yes | A bar with the same icon |
| Line chart and split bar | Yes | Left out |
| A fully custom design | Yes | With the card (no chip, no Live Update) |
| Buttons | Lock screen card (iOS 17 and later) | In the notification |
| Stale state | iOS 16.2 and later | Always `false` |

## Example

The [`example/`](./example) app tells nine designs as short stories (a ride
pickup, a trip PIN, a delivery order, a store pickup, a match, a stock
quote, a flight, a car charging, a waiting room) that you play step by
step. On an iPhone it needs the App Group setup above.

## Credits & license

A port of [`live_island_kit`](https://github.com/VMichael1999/live_island_kit)
by Michael Valdiviezo (MIT).

First-party DartNative plugin, free to use in any DartNative app. Distributed
through [dartpub.dev](https://dartpub.dev); report issues on the plugin's page.
