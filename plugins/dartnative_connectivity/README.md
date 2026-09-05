# dartnative_connectivity

Internet reachability and network type for DartNative — two questions, two
clearly-named answers:

- **"Can I reach the internet?"** — `InternetConnection` (adapted from
  [`internet_connection_checker_plus`](https://github.com/OutdatedGuy/internet_connection_checker_plus)).
- **"What network am I on?"** — `Connectivity` (adapted from
  [`connectivity_plus`](https://github.com/fluttercommunity/plus_plugins), over
  `NWPathMonitor` / `ConnectivityManager` via FFI).

They are **not** the same: a transport can be "up" with no working internet — a
captive portal, a router with no WAN, a wifi link the path monitor briefly
reports as absent. So for online/offline, always use `InternetConnection`.

## Internet reachability (`InternetConnection`)

```dart
import 'package:dartnative_connectivity/connectivity.dart';

// Point-in-time check
final online = await InternetConnection().hasInternet;
if (!online) showOfflineBanner();
```

`hasInternet` fires HTTP `HEAD` requests to a few well-known endpoints (incl.
`captive.apple.com`, so captive portals read as offline); any success = online.
If they all fail, a DNS lookup is used as a last-chance double-check before
declaring offline.

### Detecting offline — prefer your API calls

For the everyday "the app is offline" case, **don't poll** — the reliable,
zero-cost signal is already in your app: **your own API calls.** When a request
fails with a connectivity error (socket failure / timeout), that's when you
genuinely know you're offline; when the next one succeeds, you're back.
Centralize it in your HTTP layer and surface the banner there.

### Reactive status (`onInternetChanged`) — opt-in

When you need reactive, idle-time status (a live "connection lost" indicator):

```dart
final sub = InternetConnection().onInternetChanged.listen((online) {
  // ...
});
final now = InternetConnection().isConnected; // sync, cached (null until first)
```

`onInternetChanged` re-checks on a poll **and** whenever the transport changes,
emitting only on change. Because it polls, it is **not instant** — a change can
take up to one interval to surface. The interval defaults to **5 s** and is a
parameter:

```dart
InternetConnection().checkInterval = const Duration(seconds: 3); // before subscribing
```

It runs **only while subscribed** — an app that never listens pays nothing.
Still, prefer the API-call signal above where you can; reach for the stream only
for genuinely reactive UI.

## Network type (`Connectivity`)

When you specifically need the transport (metered-connection logic, a "you're on
cellular" hint) — **not** for offline detection:

```dart
final type = await Connectivity().checkConnectivityType(); // wifi | cellular | ethernet | unknown

Connectivity().onConnectivityTypeChanged.listen((type) {
  print('now on: $type');
});
```

`ConnectivityType.unknown` means the transport couldn't be clearly identified —
it is **not** a proxy for "offline" (use `InternetConnection` for that).

## Install

```yaml
dependencies:
  dartnative_connectivity: ^1.0.0   # from dartpub.dev
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

## Platform setup

### iOS
No native setup required.

### Android
No native setup required — the plugin declares `ACCESS_NETWORK_STATE` for you.

## Credits & license

- Network transport is **adapted from**
  [`connectivity_plus`](https://github.com/fluttercommunity/plus_plugins/tree/main/packages/connectivity_plus)
  (BSD-3-Clause) — the native `NWPathMonitor` / `ConnectivityManager` providers,
  reworked to FFI.
- Internet reachability is **adapted from**
  [`internet_connection_checker_plus`](https://github.com/OutdatedGuy/internet_connection_checker_plus)
  (BSD-3-Clause) — the HEAD-probe strategy, reworked to use this plugin's own
  transport stream as the trigger, with a DNS double-check added.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file
issues on the plugin's page.
