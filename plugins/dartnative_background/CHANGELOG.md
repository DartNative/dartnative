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
