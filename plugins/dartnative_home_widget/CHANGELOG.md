## 0.1.0

- Home screen widgets on iOS: the home screen in four sizes, the lock screen
  in three, drawn from a design written in Dart. The app lists its widgets
  in pubspec.yaml; a design is sent once and its values change cheaply.
- A tap opens the app at the design's link (`HomeWidgets.taps`,
  `HomeWidgets.launchTap`); a button runs in the app without opening it, on
  iOS 17 and later (`HomeWidgets.actions`).
- `HomeWidgets.values` reads what a widget shows; `HomeWidgets.placed` lists
  the widgets on the home screen and the lock screen.
- Home screen widgets on Android 12 and later, from the same pubspec list and
  the same designs: resizable across the listed sizes, light and dark with
  the phone, taps that open the app at the link, and buttons that reach the
  app. Icons take a PNG for Android (`LiveIcon.symbol(..., android:)`).
- `HomeWidgets.handleActions` runs the app's handler for each button
  pressed, with the app open, in the background or closed: iOS wakes the
  app, Android runs the handler on its own without the app's screen.
- A timeline of values to come (`update(timeline: [HomeWidgetEntry(...)])`):
  the widget changes on its own at each entry's time, with the app closed.
- `update(values:)` adds to the values the widget has; a null removes one.
- Android 15 and later: the widget list shows the widget as the app draws it.
- Android: `HomeWidgets.canPin` and `HomeWidgets.pin` ask the home screen to
  add a widget.
