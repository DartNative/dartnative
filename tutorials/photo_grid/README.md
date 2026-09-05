# Photo grid, infinitely

The finished code for the [photo grid tutorial](https://dartnative.com/tutorials/photo-grid):
an infinite-scrolling photo grid on `FastGrid` (a real `UICollectionView` /
`RecyclerView`) with native-driven load-more, shimmer placeholders, and
right-sized image decoding — plus a masonry tab (`MasonryFastGrid`), a static
`GridView.count`/`GridView.builder` showcase, `IndexedStack` tabs that keep
every grid alive, and scroll-to-index via `FastGridController`.

```sh
dn pub get
dn run
```

The screen is the playground's own code, carried verbatim:
[`lib/screens/grid_demo.dart`](lib/screens/grid_demo.dart) is a
BYTE-IDENTICAL copy of the DartNative playground's grid demo
([`lib/screens/home/demo_ui.dart`](lib/screens/home/demo_ui.dart) is the
playground's shared UI kit, also verbatim) — never edited here, so when the
playground screen improves this tutorial updates by copying the files again.
The only tutorial-specific code is the thin entry
[`lib/main.dart`](lib/main.dart): register the bindings, run the screen.
Verified against dartnative `^1.0.0`.
