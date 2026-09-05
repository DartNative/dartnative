# dartnative — State Management

DartNative ships a reactive state model built around four public types. That is the whole public surface.

1. **`Signal<T>`** — a writable reactive value.
2. **`Computed<T>`** — a read-only derived value that recomputes when its inputs change.
3. **`effect(fn)`** — a non-widget side-effect that re-runs whenever any signal it reads changes.
4. **`Provided<T>`** — a thin `InheritedWidget` wrapper that hands a fixed value down a subtree, read with `Provided.of<T>(context)`.

Signals and Computed values connect to the widget tree through a single extension: `.watch(context)` subscribes the calling widget and rebuilds it on change. The same extension works on any existing `ChangeNotifier` / `ValueNotifier`, so existing app classes keep working without modification.

```dart
// Define
final isOnline = signal<bool>(true);

// Read (no rebuild)
final v = isOnline.value;

// Watch (subscribes the widget, rebuilds on change)
Widget build(BuildContext context) {
  final online = isOnline.watch(context);
  return Text(online ? 'online' : 'offline');
}

// Update (from anywhere — widget, service, callback, timer, stream listener)
isOnline.value = false;
```

No scope. No registry. No ref. No consumer base class. No notifier base class.

State objects are plain Dart values that you reference however your app already references them: top-level `final`, repository singleton, DI container, constructor injection — all of them work, because there is no framework container that owns them.

Prefer a different approach? That's fine: any pure-Dart package works out of the box — for example [`get_it`](https://pub.dev/packages/get_it), [`bloc`](https://pub.dev/packages/bloc), or [`solidart`](https://pub.dev/packages/solidart).

---

## Why This Shape

The things developers actually need in real apps are:

1. Access state from services, repositories, and callbacks.
2. Watch a value and rebuild a widget when it changes.
3. Update state from anywhere.
4. Hand a per-subtree value down without prop-drilling (e.g. "this tile's chatroom", "this row's item").

Everything else — scopes, refs, families, providers, consumer base classes — exists to solve problems that come from a specific library's design choices, not from the apps themselves. Dropping those concepts leaves:

- one type to learn (`Signal<T>`)
- one extension to learn (`.watch(context)`)
- one bridge to learn (`Listenable.watch(context)`)
- one helper to learn (`Provided<T>` for per-subtree DI)

---

## Public API

### `Signal<T>`

A writable reactive value.

```dart
final counter = signal<int>(0);

counter.value++;                    // write
final v = counter.value;            // read (no subscription)
counter.update((c) => c + 1);      // functional update
```

`Signal<T>` exposes:

- `value` getter and setter
- `update(T Function(T current) fn)`
- `addListener(VoidCallback)` / `removeListener(...)` (for non-widget listeners)
- `dispose()`

### `Computed<T>`

A read-only derived value. Recomputes only when one of its inputs changes.

```dart
final user            = signal<User?>(null);
final isAuthenticated = computed(() => user.value != null);
final displayName     = computed(() => user.value?.name ?? 'Guest');
```

### `.watch(context)` extension on `Signal<T>` and `Computed<T>`

Subscribes the current element and rebuilds it when the value changes.

```dart
Widget build(BuildContext context) {
  final tab   = selectedTab.watch(context);
  final authed = isAuthenticated.watch(context);
  return ...;
}
```

Rules:

- Must be called during `build`.
- Subscriptions are dropped automatically when the element unmounts.
- Multiple `.watch` calls in the same `build` coalesce into a single rebuild per frame.

### `Listenable.watch(context)` extension

The same idea for any existing `Listenable`, including `ChangeNotifier`, `ValueNotifier`, and `AnimationController`. This is the migration bridge.

```dart
final lang = AppRepository.languageProvider..watch(context);
Text(lang.locale.languageCode);
```

The existing `ChangeNotifier` class is untouched. Only the widget-side subscription changes.

### `effect(fn)` — non-widget side-effects

For reactive work outside the widget tree (logging, persistence, syncing).

```dart
final stop = effect(() {
  print('counter changed: ${counter.value}');
});
// stop() to cancel.
```

### Stateful lifecycle parity

For `StatefulWidget`, dartnative supports Flutter's core lifecycle hooks:
`initState()`, `didChangeDependencies()`, `didUpdateWidget()`, and `dispose()`.

`didChangeDependencies()` runs after `initState()` on first build, and runs
again whenever an inherited dependency (for example `Provided<T>`) notifies.

### Two rules worth memorizing

**1. You can update a signal from anywhere.**

Signals don't need a `BuildContext` or a `Ref` to be written. Any code on the app isolate — widget callbacks, services, `Future` continuations, stream listeners, timers — can do `mySignal.value = ...`.

```dart
// widget callback
onPressed: () => AppRepository.themeMode.value = ThemeMode.dark,

// service
class ConnectivityService {
  void _onChange(bool online) => AppRepository.isOnline.value = online;
}
```

**2. To stay reactive, expose the `Signal<T>`, not its value.**

A getter that returns the signal preserves reactivity. A getter that returns the unwrapped value breaks the subscription chain — the widget has nothing to watch.

```dart
class AuthStore {
  final _user = signal<User?>(null);

  // Reactive: widgets can call store.user.watch(context).
  Signal<User?> get user => _user;

  // NOT reactive: returns a User?, widgets cannot subscribe.
  User? get currentUser => _user.value;

  // Reactive: derived value, recomputes when _user changes.
  late final isAuthenticated = computed(() => _user.value != null);
}
```

Stores and holders expose `Signal<T>` / `Computed<T>` fields. Unwrapping to `T` is what the **caller** does — inside `build` via `.watch(context)`.

---

## State Patterns

The framework only ships the primitives above. The patterns below are how you use them — they are not new framework types.

### Pattern A — Top-level signal

For simple app-wide values.

```dart
// lib/state/app_state.dart
final isOnline  = signal<bool>(true);
final themeMode = signal<ThemeMode>(ThemeMode.system);

// in a widget
final online = isOnline.watch(context);

// from a service
isOnline.value = false;
```

### Pattern B — Plain class with signals (the "store" pattern)

For feature state with behavior. A regular Dart class — no base class required.

```dart
class AuthStore {
  final user      = signal<User?>(null);
  final isLoading = signal(false);
  late final isAuthenticated = computed(() => user.value != null);

  final AuthApi _api;
  AuthStore(this._api);

  Future<void> signIn(String email, String password) async {
    isLoading.value = true;
    user.value = await _api.signIn(email, password);
    isLoading.value = false;
  }

  void signOut() => user.value = null;

  void dispose() {
    user.dispose();
    isLoading.dispose();
    isAuthenticated.dispose();
  }
}
```

In a widget:

```dart
final auth    = AppRepository.auth;
final loading = auth.isLoading.watch(context);
final authed  = auth.isAuthenticated.watch(context);

Button(onPressed: () => auth.signIn(email, pw), child: Text('Sign in'));
```

In a service:

```dart
AppRepository.auth.signOut();
```

### Pattern C — Existing `ChangeNotifier`

Keep the class. Just change how widgets subscribe.

```dart
class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}

// in a widget — the only change vs Provider:
final lang = AppRepository.languageProvider..watch(context);
Text(lang.locale.languageCode);

// from a service — completely unchanged:
AppRepository.languageProvider.setLocale(const Locale('it'));
```

### Pattern D — Throttled / delayed UI rebuild

For cases where you want to decouple state mutation from rebuild timing — for example, letting a navigation animation finish before forcing a long list to rebuild.

Use a separate "rebuild tick" signal that the widget also watches:

```dart
class MessageStore {
  final messages    = signal<List<Message>>(const []);
  final rebuildTick = signal<int>(0);

  void addAll(List<Message> next, {int delayMs = 450}) {
    messages.value = _dedup([...messages.value, ...next]);
    Future.delayed(Duration(milliseconds: delayMs), () {
      rebuildTick.value++;
    });
  }
}
```

The widget watches both:

```dart
final list = store.messages.watch(context);
store.rebuildTick.watch(context); // triggers the delayed flush
```

---

## Where Do I Put My State?

The framework has no registry, so where state lives is up to you. The convention that scales:

> **Group related state into named holder classes. One well-known holder per scope.**

### The convention

**App-wide state** lives in one root holder, conventionally `AppRepository`:

```dart
// lib/state/app_repository.dart
class AppRepository {
  AppRepository._();

  // Stores (classes that group signals + actions)
  static final auth         = AuthStore(AuthApi());
  static final language     = LanguageStore();
  static final notification = NotificationStore();

  // Top-level signals (trivial app-wide values)
  static final themeMode = signal<ThemeMode>(ThemeMode.system);
  static final isOnline  = signal<bool>(true);
}
```

**Feature-scoped state** lives in a feature holder, named after the feature:

```dart
// lib/state/chat_state.dart
class ChatState {
  ChatState._();

  static final messages    = MessageStore();
  static final draftText   = signal<String>('');
  static final isRecording = signal<bool>(false);
}
```

**Per-instance state** (one form, one modal, etc.) goes on a regular instance:

```dart
class ChatRoomController {
  final messages  = signal<List<Message>>(const []);
  final draftText = signal<String>('');

  void dispose() {
    messages.dispose();
    draftText.dispose();
  }
}
```

### Why this is enough

| Concern | How holders solve it |
|---|---|
| "How do I find all the state?" | Open the holder file. It lists every signal and store. |
| "How do I access state from a service?" | `AppRepository.auth.signIn()` — direct, type-safe. |
| "How do I rename a signal?" | IDE rename refactor across the workspace. |
| "How do I see who uses this signal?" | "Find usages" on the holder field. |
| "How do I swap state in tests?" | Replace the static with a test instance in `setUp`, or use constructor injection. |
| "How do I keep a feature's state out of global scope?" | Use a feature holder or a per-instance class. |

### Naming guidance

- App-wide holder: `AppRepository`, `AppState`, or your existing convention.
- Feature holders: `ChatState`, `SettingsState`, `OnboardingState`.
- Stores (signals + actions): `AuthStore`, `MessageStore`, `LanguageStore`.
- Top-level signals: descriptive nouns (`isOnline`, `themeMode`).

### How it looks in a real app

The layering this convention produces, in a full project:

```
lib/
├── models/           # Pure Dart data classes — no framework imports
├── api/              # Raw HTTP / external-service calls
├── repositories/     # Data access — one class per domain (DB, sync)
├── services/         # App orchestration — no UI dependencies
├── state/            # UI-facing stores — signals, computed, actions
│   ├── app_repository.dart    # root holder: app-wide stores & signals
│   ├── auth_store.dart        # one store per domain
│   └── chat_state.dart        # feature holder
├── screens/          # One file per route — widgets only, read state via .watch
├── widgets/          # Shared widgets
└── theme/            # Design tokens (colors, typography)
```

State flows one way through the layers: `screens/` watch stores in `state/`;
stores call `services/` and `repositories/`; nothing below `state/` imports a
widget.

This is the structure we use in our own apps — a suggestion, not a rule. The
framework has no opinion about your folders: shape the project however works
for you.

---

## What This Model Does Not Provide

Stated up front so you know before you start:

- **No scoped overrides on `Signal<T>` itself.** Signals are global reactive values; they have no per-subtree variant. The per-subtree DI need is covered by `Provided<T>` (see below) — nothing to integrate, it ships with the framework.
- **No families.** The replacement is a `Map<Key, Signal<T>>` or a method on a store that returns the right signal.
- **No code generation.**
- **No autodispose.** Stores own their signals and dispose them in `dispose()`, which the host (singleton, controller, route) already handles.

Tests construct stores directly and inject them via constructor or by swapping the singleton in `setUp` / `tearDown`.

---

## Per-subtree Values — `Provided<T>`

Some patterns need one value per subtree — for example, in a chat app, each chat tile in a list gets its own chatroom, each row its own message. This is per-subtree dependency injection, not reactive global state. dartnative covers it with `Provided<T>`.

```dart
// Wrap a subtree with a value specific to that instance:
Provided<Chatroom>(value: room, child: const ChatTile())

// Read from any descendant — no constructor parameter needed:
final room = Provided.of<Chatroom>(context);
```

When `value` changes (new identity), `updateShouldNotify` fires and every descendant that called `Provided.of<T>` rebuilds automatically.

For reactive per-subtree values, wrap a `Signal<T>` or a store:

```dart
Provided<Signal<Locale>>(value: localeSignal, child: ...)

// in a descendant:
final locale = Provided.of<Signal<Locale>>(context).watch(context);
```

### When to use which

| Need | Use |
|---|---|
| Reactive value shared across the whole app | `Signal<T>` in a holder |
| Per-subtree fixed value | `Provided<T>` |
| Per-subtree reactive value | `Provided<Signal<T>>` (or `Provided<MyStore>`), then `.watch(context)` on the inner signal |

---

## Replacing Provider / Riverpod

The migration is mechanical. Every ported file gets smaller, not larger.

| Old pattern | Replacement |
|---|---|
| `ProviderScope` (root) | delete |
| `ProviderScope(overrides: [p.overrideWithValue(v)])` | `Provided<T>(value: v, child: ...)` |
| `MultiProvider` | delete; keep your singleton holders |
| `ChangeNotifierProvider(.value)` | delete; the `ChangeNotifier` instance stays |
| `Consumer<T>` / `Consumer` | delete; replace with `target..watch(context)` |
| `ConsumerWidget` / `ConsumerStatefulWidget` | plain `StatelessWidget` / `StatefulWidget` |
| `context.watch<T>()` | `target..watch(context)` (where `target` is your singleton/notifier) |
| `context.read<T>()` | direct reference to your singleton/store |
| `Provider.of<T>(listen: false)` | direct reference |
| `StateProvider<T>` | `final foo = signal<T>(initial);` |
| `StateNotifier<T>` / `StateNotifierProvider` | plain class holding `signal<T>` fields |
| `Notifier` / `AsyncNotifier` (Riverpod 2.x) | plain class holding `signal<T>` fields (+ `signal<bool>` for loading, `signal<Object?>` for error) |
| stored global `WidgetRef` | delete; call methods on your store directly |
| `ref.watch(provider)` | `store.field.watch(context)` |
| `ref.read(provider.notifier).method()` | `store.method()` |
| `ref.watch(scopedProvider)` (inside override) | `Provided.of<T>(context)` |

---

## Porting Concrete Examples

### Porting a `ChangeNotifier` + Provider widget

```dart
// BEFORE — Provider
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  void setMode(ThemeMode m) { _mode = m; notifyListeners(); }
}

// Root
runApp(ChangeNotifierProvider(create: (_) => ThemeProvider(), child: const MyApp()));

// Widget
class ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Switch(
      value: theme.mode == ThemeMode.dark,
      onChanged: (v) => context.read<ThemeProvider>().setMode(
        v ? ThemeMode.dark : ThemeMode.light),
    );
  }
}
```

```dart
// AFTER — dartnative  (ThemeProvider class is UNCHANGED)
class AppRepository {
  static final theme = ThemeProvider();
}

// No root wrapper needed — delete ChangeNotifierProvider

class ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = AppRepository.theme..watch(context);   // ← only change
    return Switch(
      value: theme.mode == ThemeMode.dark,
      onChanged: (v) => AppRepository.theme.setMode(
        v ? ThemeMode.dark : ThemeMode.light),
    );
  }
}
```

### Porting a Riverpod `StateNotifier` / `Notifier`

```dart
// BEFORE — Riverpod
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state++;
  void reset()     => state = 0;
}
final counterProvider =
    StateNotifierProvider<CounterNotifier, int>((ref) => CounterNotifier());

class CounterWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(counterProvider);
    return Row(children: [
      Text('$n'),
      Button(title: '+', onPressed: () => ref.read(counterProvider.notifier).increment()),
    ]);
  }
}
```

```dart
// AFTER — dartnative
class CounterStore {
  final count = signal<int>(0);
  void increment() => count.value++;
  void reset()     => count.value = 0;
}

class AppRepository {
  static final counter = CounterStore();
}

class CounterWidget extends StatelessWidget {   // ← plain StatelessWidget
  @override
  Widget build(BuildContext context) {
    final n = AppRepository.counter.count.watch(context);  // ← ref.watch → .watch(context)
    return Row(children: [
      Text('$n'),
      Button(title: '+', onPressed: AppRepository.counter.increment),
    ]);
  }
}
```

### Porting a Riverpod `AsyncNotifier`

```dart
// BEFORE — Riverpod 2.x
class UserNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<void> signIn(String email, String pw) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authApiProvider).signIn(email, pw),
    );
  }
}
final userProvider = AsyncNotifierProvider<UserNotifier, User?>(() => UserNotifier());

// Widget
final asyncUser = ref.watch(userProvider);
asyncUser.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
  data: (user) => Text(user?.name ?? 'guest'),
);
```

```dart
// AFTER — dartnative
class AuthStore {
  final user      = signal<User?>(null);
  final isLoading = signal<bool>(false);
  final error     = signal<Object?>(null);

  Future<void> signIn(String email, String pw) async {
    isLoading.value = true;
    error.value = null;
    try {
      user.value = await AuthApi.instance.signIn(email, pw);
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }
}

// Widget
final loading = AppRepository.auth.isLoading.watch(context);
final err     = AppRepository.auth.error.watch(context);
final user    = AppRepository.auth.user.watch(context);

if (loading) return const CircularProgressIndicator();
if (err != null) return Text('Error: $err');
return Text(user?.name ?? 'guest');
```

### Porting `ValueListenableBuilder` / `TextEditingController`

For new dartnative code, use the idiomatic `.watch(context)` extension on the notifier — it subscribes the widget and rebuilds it on change without any builder nesting:

```dart
// Idiomatic dartnative — call watch once at the top of build()
Widget _buildSearchField() {
  _searchController.watch(context);   // subscribe; rebuilds on every keystroke

  return Row(children: [
    // ... TextField ...
    if (_searchController.text.isNotEmpty)
      GestureDetector(
        onTap: () => _searchController.clear(),
        child: const Icon(CupertinoIcons.xmark_circle_fill),
      ),
  ]);
}
```

This is preferred because it removes one level of indirection (`builder` parameter), keeps the dependent widget code flat alongside the rest of `build`, and is consistent with how `Signal<T>` is watched.

`ValueListenableBuilder<T>` is also a fully supported `StatefulWidget` in dartnative — **no migration required**. Code using it ports unchanged:

```dart
// Works as-is in dartnative — no changes needed
ValueListenableBuilder<TextEditingValue>(
  valueListenable: _searchController,
  builder: (_, value, __) {
    return value.text.isNotEmpty
        ? GestureDetector(
            onTap: () => _searchController.clear(),
            child: const Icon(CupertinoIcons.xmark_circle_fill),
          )
        : const SizedBox.shrink();
  },
)
```

The `addListener` / `setState` pattern is equally replaceable — if you have:

```dart
// initState
_searchController.addListener(_onSearchChanged);

// ...
void _onSearchChanged() {
  if (mounted) setState(() {});
}
```

Replace by removing `addListener`, removing `_onSearchChanged`, and calling `_searchController.watch(context)` in `build` instead. The widget will rebuild automatically on every text change.

---

## Playground Demos and Tutorial

The [`playground/`](../playground/) app includes two state screens:

**State — Basics** ([`/state-basics`](../playground/lib/screens/state_basics_demo.dart)):
`Signal<int>` counter, `Computed<String>` label, `Signal<bool>` toggle, and a `ChangeNotifier` bridge — all in `StatelessWidget`s with no `setState`. An `effect()` logs every counter change to the console.

**State — Store + Provided** ([`/state-store`](../playground/lib/screens/state_store_demo.dart)):
`TaskStore` (Pattern B) with `signal` + `computed` fields and actions. Two separate store instances, each wrapped in `Provided<TaskStore>`, showing per-subtree DI with `Provided.of<TaskStore>(context)`.

For a guided walkthrough — `setState`, then `signal` + `watch`, then
`Provided<T>` subtree values — build the [state tutorial](../tutorials/state/),
a complete runnable app.

---

## API Reference

### `signal<T>(T initial) → Signal<T>`
Create a writable reactive value.

### `Signal<T>.value`
Read or write the current value. Setting a new value (that differs by `==`) notifies all listeners.

### `Signal<T>.update(T Function(T) fn)`
Functional update — equivalent to `value = fn(value)`.

### `Signal<T>.addListener(VoidCallback)` / `removeListener`
Manual listener management for non-widget code.

### `Signal<T>.dispose()`
Release all listeners. Call in `dispose()` if the signal is instance-scoped.

### `computed<T>(T Function() fn) → Computed<T>`
Create a read-only derived value that recomputes when any signal read in `fn` changes.

### `Computed<T>.dispose()`
Release input subscriptions and all listeners.

### `effect(void Function() fn) → VoidCallback`
Run `fn` immediately and re-run it on every signal change it reads. Returns a cancel callback.

### `Signal<T>.watch(BuildContext context) → T`
### `Computed<T>.watch(BuildContext context) → T`
Subscribe the current element to this signal/computed and return the current value. Call inside `build` only.

### `Listenable.watch<T extends Listenable>(BuildContext context) → T`
Subscribe the current element to any `Listenable` (ChangeNotifier, ValueNotifier). Returns `this` for cascade use (`target..watch(context)`).

### `Provided<T>(value: T, child: Widget)`
Pass `value` down the subtree via `InheritedWidget`.

### `Provided.of<T>(BuildContext context) → T`
Read the nearest `Provided<T>` ancestor. Registers a rebuild dependency.
