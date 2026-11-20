## 1.0.3

- A task that arrives while the app is open now runs inside the app.
- Call `initialize` from `main()` every time the app starts.
- A task that runs late no longer hands its result to the next one.
- On Android, two tasks due at the same time now both run.
- On iOS, a task whose handler returns false is now reported as failed.

## 1.0.2

- Simulator builds work again with Xcode 26.

## 1.0.1

- Apps that import the plugin in their `AppDelegate` now build with Xcode 27.

## 1.0.0

- First release: run Dart code in the background on iOS and Android, once or
  on a schedule.
- On iOS, cancelling a periodic task now stops it for good.
