## 1.0.0

* iOS: A cancelled periodic task no longer re-arms itself. A `BGAppRefreshTask`
  re-submits its next request every time it fires, so `cancelAll()` /
  `cancelByUniqueName()` (which only drop the *pending* request) used to leave
  the task firing — it would reschedule itself on the next OS launch or forced
  `_simulateLaunch`. Cancelling now clears the task's "wanted" flag and the
  handler skips the re-arm, so the task stops for good.
* Example: added **Cancel periodic** and **Cancel processing** buttons that
  cancel a single task by unique name via `cancelByUniqueName`.
