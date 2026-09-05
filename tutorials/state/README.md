# State, from setState up

The finished code for the [state tutorial](https://dartnative.com/tutorials/state):
every state tool in the box, in the order you'll reach for them —
`signal`/`computed` watched from plain StatelessWidgets, `effect()` for
side-effects, `Listenable.watch` to bridge an existing `ChangeNotifier`,
then a second screen with the Store pattern (a plain Dart class of signal
fields) and `Provided<T>` per-subtree DI. No ProviderScope, no Consumer,
no code generation.

```sh
dn pub get
dn run
```

The two screens under [`lib/screens/`](lib/screens/) are **byte-identical
copies** of the DartNative playground's state demos
(`lib/screens/home/demo_ui.dart` is the playground's shared UI kit, also
verbatim) — when the playground demos improve, this tutorial updates by
copying the files again. [`lib/main.dart`](lib/main.dart) adds only a thin
two-row launcher. Verified against dartnative `^1.0.0`.
