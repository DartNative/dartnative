# Search done right

The finished code for the [search tutorial](https://dartnative.com/tutorials/search-app-bar):
one `AppBar.searchBar` that renders Apple's in-place search on iOS 26 (real
Liquid Glass, the App Store choreography) and the genuine Material 3 search
app bar on Android — live Dart suggestions inside both native surfaces. A
toggle switches the bar live between the two sanctioned arrangements:
back + search and the Gmail-style leading + search + avatar frame.

```sh
dn pub get
dn run
```

The screen at
[`lib/screens/material3/m3_search_appbar_demo.dart`](lib/screens/material3/m3_search_appbar_demo.dart)
is a BYTE-IDENTICAL copy of the DartNative playground's search app bar demo
([`lib/screens/home/demo_ui.dart`](lib/screens/home/demo_ui.dart) is the
playground's shared UI kit, also verbatim) — when the playground demo
improves, this tutorial updates by copying the file again.
[`lib/main.dart`](lib/main.dart) is only a thin entry that registers the
bindings and pushes the screen. Verified against dartnative `^1.0.0`.
