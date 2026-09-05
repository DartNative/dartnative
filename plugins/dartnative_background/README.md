# dartnative_background

Background task scheduling for DartNative apps — one-off, periodic, and processing
tasks that run your Dart code in a **headless isolate** when the OS wakes the app.
iOS (`BGTaskScheduler`) and Android (`WorkManager`), all over FFI — no `MethodChannel`.

## Why you'll like it

- **Both platforms, one API** — `TaskManager().registerOneOffTask(…)` schedules on
  iOS and Android; the same Dart `callbackDispatcher` runs the work.
- **Real background execution** — the OS boots a headless Dart isolate with no UI;
  other FFI plugins (e.g. path provider) work inside it too.
- **Clean API** — `TaskManager` and `ExistingTaskPolicy` use task-centric names
  that work naturally on both iOS and Android.

## Highlights

- **`TaskManager().initialize(callbackDispatcher)`** — register your dispatcher.
- **`registerOneOffTask` / `registerPeriodicTask` / `registerProcessingTask`** — schedule.
- **`cancelByUniqueName` / `cancelAll`** — cancel.
- **`checkBackgroundRefreshPermission()`** — iOS background-refresh state.

## Install

```yaml
dependencies:
  dartnative_background: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

```dart
import 'package:dartnative_background/dartnative_background.dart';

// Top-level + @pragma so the OS can run it in the headless isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  TaskManager().executeTask((taskName, inputData) async {
    // … your background work …
    return true; // false → the task is retried / rescheduled
  });
}

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

```dart
await TaskManager().initialize(callbackDispatcher, isInDebugMode: true);

await TaskManager().registerOneOffTask(
  'com.yourapp.sync',                       // uniqueName (also the task name on iOS)
  'com.yourapp.sync',                       // taskName
  initialDelay: const Duration(seconds: 10),
  inputData: {'source': 'manual'},
);

await TaskManager().registerPeriodicTask('com.yourapp.refresh', 'com.yourapp.refresh');
await TaskManager().cancelAll();
```

## Platform setup

### iOS

1. **`Info.plist`** — list every periodic/processing identifier + the modes:

   ```xml
   <key>BGTaskSchedulerPermittedIdentifiers</key>
   <array>
     <string>com.yourapp.refresh</string>
     <string>com.yourapp.processing</string>
   </array>
   <key>UIBackgroundModes</key>
   <array><string>fetch</string><string>processing</string></array>
   ```

2. **`AppDelegate.swift`** — register the same identifiers before launch returns:

   ```swift
   import dartnative_background
   // …in didFinishLaunchingWithOptions, before `return`:
   if #available(iOS 13.0, *) {
     DartNativeBackgroundPlugin.registerPeriodicTask(
       withIdentifier: "com.yourapp.refresh",
       frequency: NSNumber(value: 15 * 60))  // ~15 min — the OS-enforced minimum
     DartNativeBackgroundPlugin.registerBGProcessingTask(
       withIdentifier: "com.yourapp.processing")
   }
   ```

   No `setPluginRegistrantCallback` is needed — dartnative plugins reach native over
   FFI, not a headless plugin registry. One-off tasks use `beginBackgroundTask` and
   need no `Info.plist` entry. The identifiers in `Info.plist` and the AppDelegate
   must match exactly.

   **How iOS schedules periodic tasks** — `frequency` is your *requested* minimum
   interval, but iOS enforces a hard ~15-minute floor no matter what value you pass.
   More importantly, actual dispatch is entirely system-controlled: iOS learns your
   app's usage patterns over time (this can take days), then combines that with battery
   level, network availability, and overall device load to decide when to actually wake
   your app. In practice the gap between runs is often longer than 15 minutes, and
   the OS may skip runs entirely when the device is under constraint. Each invocation
   is capped to ~30 s of CPU time — that is a per-run execution limit, not a scheduling
   interval. Design your background work around these constraints: keep each run short,
   be resilient to long gaps, and never rely on a specific wall-clock time.

   **Tip** — the *first* run can take a few hours, and sometimes a
   day or more. That is normal on iOS, not a bug: the phone decides when to run
   it. iOS watches how often you open the app, so **opening the app a few times
   a day** (especially in the first days) tells iOS the app matters and makes
   your task run sooner and more often. If you need something more dependable,
   use a **processing task** and leave the phone charging overnight.

### Android

Nothing beyond the dartnative host — `WorkManager` auto-initializes.

**How Android schedules periodic tasks** — `WorkManager` enforces a hard 15-minute
minimum period; you cannot request a shorter interval than that. The OS may defer
execution further depending on Doze mode, battery saver, data saver, or overall system
load — actual runs can lag behind the requested interval by minutes to hours. WorkManager
handles these constraints transparently: it queues the task and runs it during the next
available maintenance window. For periodic tasks that must survive a reboot, add
`RECEIVE_BOOT_COMPLETED` to your app manifest.

## Example

The [`example/`](./example) app schedules every task type and runs them through the
headless dispatcher, which writes a marker file via `dartnative_path_provider` to
prove FFI plugins work in the background isolate.

```bash
cd example && dn pub get
# iOS — REAL device (BGTasks don't run on Simulator):
(cd ios && pod install) && dn run
# Android:
dn run
```

On launch the app asks for the notification permission (so a grant never interrupts a
later tap). Tap **Initialize** to register the dispatcher, then register tasks. One-off
tasks run when you background the app. Force an iOS periodic/processing task from lldb:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.dartnative.background.processingTask"]
```

On Android, watch `adb logcat | grep -E "dn-bg|DNTaskManager"`. A task ran if you see
its debug notification, the `[dn-bg]` log line, and a `dnbg_<task>.txt` marker file.

> The example asks for the notification permission with
> `DartNativeNotifications.requestPermission()`. If your app already manages every
> permission through [`dartnative_permissions`](https://dartpub.dev), its
> `Permission.notification.request()` requests the exact same one — use whichever
> fits your app.

## Credits & license

Adapted from
[`flutter_workmanager`](https://github.com/fluttercommunity/flutter_workmanager) (MIT).

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on
the plugin's page.
