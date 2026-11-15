# live_activities_example

The example app of `dartnative_live_activities`. It tells nine of the
package's designs as short stories (a ride pickup, a trip PIN, a delivery
order, a store pickup, a match, a stock quote, a flight, a car charging, a
waiting room) that you play step by step: start the activity, update it,
send an alert, end it. Each story shows what its activity looks like, says
what each step changes and where to look, and lists what happened, buttons
tapped on the activity's card included.

- **iOS:** the activity shows in the Dynamic Island and on the lock screen.
  iOS shows nothing of it while the app is open, so a step with an alert
  waits until you leave the app and goes out two seconds later.
- **Android:** a notification that Android 16 and later promote to a Live
  Update, with its chip in the status bar.

```sh
dn pub get
dn run -d <device-id>
```

## On an iPhone: App Group setup

The simulator needs nothing. On an iPhone, the app and its widget extension
share the activities through an App Group, and a phone only runs an app whose
App Group is registered for your team:

1. Change the bundle id (`com.dartnative.liveActivitiesExample`) to one of
   your own in Xcode, on the **Runner** target, then run
   `dn build ios --simulator` once: the App Group follows the id
   (`group.<your bundle id>`). A build started from Xcode does not move it.
2. Open `ios/Runner.xcworkspace` in Xcode and, under *Signing &
   Capabilities*, pick your team for the **Runner** and the
   **DartNativeWidgets** targets.
3. Build and run once from Xcode on the phone. From then on `dn run` works
   too.
