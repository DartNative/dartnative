# Build the chat screen

The finished code for the [chat screen tutorial](https://dartnative.com/tutorials/build-the-chat-screen):
a WhatsApp-style conversation with a reverse message list, a growing input
bar that rides the system keyboard curve, a scroll-to-bottom FAB,
jump-to-message with a highlight flash, and Liquid Glass polish on iOS 26.

```sh
dn pub get
dn run
```

The screen under `lib/screens/` is a BYTE-IDENTICAL copy of the DartNative
playground's chat demo ([`lib/screens/chat_screen_demo.dart`](lib/screens/chat_screen_demo.dart);
[`lib/screens/home/demo_ui.dart`](lib/screens/home/demo_ui.dart) is the
playground's shared UI kit, also verbatim) — when the playground screen
improves, this tutorial updates by copying the files again.
[`lib/main.dart`](lib/main.dart) is just the thin entry: register the
bindings, run the screen.

The demo is written with the Flutter widget API — if you know Flutter, every
line reads as expected; the difference is that each widget drives the
platform's real view (`FastList` → `UITableView`/`RecyclerView` with native
cell recycling, `TextField` → `UITextField`, the keyboard animation → the
system's own compositor transaction). A `ListMode` switch at the top of the
screen file swaps the same chat between `ListView`, `ListView.builder`,
`CustomScrollView` slivers, and `FastList`.

Verified against dartnative `^1.0.0`.
