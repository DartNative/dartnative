# Lists that never jank

The finished code for the [FastList tutorial](https://dartnative.com/tutorials/fast-list):
a feed that paginates from 50 to 10,000 rows on `FastList` (a real
`UITableView` / `RecyclerView`), in two flavors — featherweight text rows and
photo rows decoded at cell size with content windowing (`keepAliveCount`) for
flat memory at any depth — plus index-based programmatic scrolling and a live
mount-time readout.

```sh
dn pub get
dn run
```

The screen under [`lib/screens/`](lib/screens/) is a BYTE-IDENTICAL copy of
the playground's FastList demo (`lib/screens/home/demo_ui.dart` is the
playground's shared UI kit, also verbatim) — when the playground demo
improves, this tutorial updates by copying the files again;
[`lib/main.dart`](lib/main.dart) is only the thin entry. The result line's
RSS readout is the playground's honest memory harness: resident memory plus
its delta against a baseline captured at screen entry, after clearing the
in-memory image caches. Verified against dartnative `^1.0.0`.
