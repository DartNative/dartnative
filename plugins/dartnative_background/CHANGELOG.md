## 1.0.3

* A task that arrives while the app runs now runs inside the app, instead of
  in a second copy of Dart beside it. Plugins the task used no longer stop
  the app afterwards, and the app keeps receiving their events. Call
  `initialize` at every start of the app, from `main()`.
* A task that runs out of time and finishes after the next task has started
  no longer gives the next task its result; the next task waits for its own.
* Android: two tasks that become due together run one after the other; before,
  the second could take the first's place and the first never ran.
* iOS: a background task whose handler returns false is reported to the
  system as failed; before, it was always reported as done.

## 1.0.2

* iOS: simulator builds work again with Xcode 26. 1.0.1's native library was
  built by a tool that left its simulator half unaligned, which Xcode 26
  refuses to link ("Slice is not page aligned"); it is built again. The code
  is unchanged.

## 1.0.1

* iOS: apps that `import dartnative_background` in their `AppDelegate`, as
  this README shows, now build with Xcode 27 as well as Xcode 26. The plugin's
  native library is built again, with the files Xcode needs to read it from
  any newer Swift. The code is unchanged.

## 1.0.0

* iOS: A cancelled periodic task no longer re-arms itself. A `BGAppRefreshTask`
  re-submits its next request every time it fires, so `cancelAll()` /
  `cancelByUniqueName()` (which only drop the *pending* request) used to leave
  the task firing — it would reschedule itself on the next OS launch or forced
  `_simulateLaunch`. Cancelling now clears the task's "wanted" flag and the
  handler skips the re-arm, so the task stops for good.
* Example: added **Cancel periodic** and **Cancel processing** buttons that
  cancel a single task by unique name via `cancelByUniqueName`.
