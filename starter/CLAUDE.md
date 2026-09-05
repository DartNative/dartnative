# Conventions for AI assistants

This project is a dartnative app. dartnative renders real native platform
views from Flutter style Dart code. It is not Flutter: always use the `dn`
CLI (`dn pub get`, `dn run`, `dn build`), never the Flutter one, and only
use widgets that `package:dartnative/dartnative.dart` exports.

## Structure, and where new code goes

- `lib/screens/` one file per screen. A screen is a Scaffold with an
  AppBar. See Navigation below for how screens are pushed. Widgets used
  by a single screen stay private in its file; a widget used by more
  than one screen moves to `lib/widgets/` (see EmptyState, NoteGrid).
- `lib/state/` a ChangeNotifier per concern. Widgets subscribe with
  `AppRepository.myState..watch(context)` and rebuild on `notifyListeners`,
  which rebuilds every watcher of that notifier. A `Signal` is the narrow
  alternative: hold the value in a signal, and the only part of the tree
  that rebuilds when it changes is the widget watching it, wherever in the
  tree that widget sits. `Note.text` is the example: editing a note
  repaints that one card and not the grid around it. Notifier for what
  changes the shape of the tree, signal for what changes inside a single
  element of it. Do not add a state management package; extend this
  pattern.
- `lib/repositories/` holds AppRepository, which owns every app wide
  notifier as a static final (add new notifiers there), and data
  repositories: one singleton per data domain that owns its persistence,
  local (SQLite queries) or remote (server sync). The Notes demo is small
  enough that its SQL sits inside NotesState; when a domain grows past a
  few queries, move the SQL into a LocalXRepository and keep the notifier
  as the thing widgets watch.
- `lib/api/` code that talks to the network. Auth lives in
  `auth_service.dart` and is the only file that touches Supabase auth.
- `lib/services/` does not exist yet; create it for long lived singletons
  that wrap one capability (notifications, purchases, audio, background
  work). A service is not a screen, not a watched notifier and not a
  network client; it is the thing those three call.
- `lib/db/` SQLite. Table and column names are constants in `tables.dart`,
  the connection is the `LocalDatabase.instance` singleton, and screens
  never run SQL directly: they go through a ChangeNotifier in `lib/state/`
  (see `notes_state.dart` for the pattern to copy). The schema lives in
  `db/upgrade/` as one `CommandScript` per version: to change it, add
  `command_scripts_vN.dart`, register it in `LocalDatabase` and bump
  `_version`. Never edit a script that shipped, because devices that ran
  it will not run it again. Fresh installs replay every script and
  existing ones replay only what they lack, so both reach the same schema
  from statements written once (v2, the favorite column, is the worked
  example).
- `lib/config.dart` configuration. Values that vary per install come from
  the bundled `.dnkeys` file through `DnKeys.get`.
- `lib/theme.dart` holds the palettes; ThemeState (state/) holds the
  active one and the toggle. Themed screens read colors from the palette,
  never hardcode them: `(AppRepository.themeState..watch(context)).palette`.
  Themed Scaffolds also pass `brightness: palette.brightness` so native
  surfaces (keyboard, alerts) follow the app theme. The onboarding and
  create profile screens are dark by design and stay out of the theme.

## Navigation

dartnative supports both navigation modes, and this app uses both:

- Named: `Navigator.pushNamed(context, '/notes')`. The builder comes from
  the `registerRoutes` map in `main.dart`. Prefer this for plain screens
  with no constructor arguments; it is one call and the route carries its
  name automatically.
- Programmatic: `Navigator.push(context, PageRoute(builder: ..., settings:
  '/name'))`. Use this when the screen takes arguments (see how the
  onboarding pushes `CreateProfileScreen(prefillName: ...)`) or when you
  need `pushReplacement`, a custom transition, or a result.

The rule that ties them together: every pushed route should carry a name
(`PageRoute.settings`) that exists in `registerRoutes`. On hot restart the
native side replays the route stack from those names, and a route without
a registered name is silently dropped from the stack. `pushNamed` does
this for you; with a hand built `PageRoute` you pass `settings` yourself.
So when you add a screen: add it to `registerRoutes`, then push it by
name, or by builder with the same name in `settings`.

Drawer items are NOT routes by default. A drawer selects sections that
render in place inside the home screen (the enum plus body switch in
home_screen.dart), with the selected item highlighted. Push a route from
the drawer only for secondary screens like settings. Never push a
route for a main destination: back would then walk through destinations,
which is not how drawers behave.

## Rules that prevent real bugs

- `DartNativePluginRegistrant.registerAll()` must stay the first line of
  `main()`. Removing it shows as a white screen with no error.
- The root child and pushed routes are two independent layers. Only
  `_RootRouter` in `main.dart` decides the root child, and it must keep
  acting only on real auth transitions. Do not make it rebuild its child
  on every notify, that duplicates live screens.
- The auth session arrives asynchronously after `Supabase.initialize()`.
  Never assume a session right after init; `AuthState.waitUntilResolved`
  exists for that.
- Demo mode must keep working with an empty `.dnkeys`. Any new feature
  that needs the network should degrade the way `AuthService` does: check
  `AppConfig.isAuthConfigured` or `AuthService.demoSession` and fall back
  to local behavior.
- Widgets never run SQL and never call Supabase directly. Screens talk to
  state notifiers and services, which talk to storage and network.

## Text style

Keep comments and user facing text plain and short. No em dashes, no
jargon. Explain why, not what.
