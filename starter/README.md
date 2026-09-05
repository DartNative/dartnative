# dartnative starter

A skeleton app you can build on. It is extracted from the first dartnative
app that shipped to production, so the flows here are the ones we actually
run: onboarding, Apple and Google sign in through Supabase, a home screen
with the framework drawer, simple state management and a local SQLite
database.

It runs the moment you clone it. Without any configuration the onboarding
offers a demo session with a fake user, so you can explore every screen
before touching a single key.

## Run it

```sh
cp -n .dnkeys.example .dnkeys   # first run only; empty values are fine (demo session)
dn pub get
dn run -d <device-id>
```

dartnative apps require a license. Configure your key once with
`dn config --license-key dnk_...` and `dn run` then just works. You can
also skip the configure step and pass the key on any single run:
`dn run --dart-define=DN_LICENSE_KEY=dnk_...`. See the getting started
guide for details.

Always use `dn` for run, build and pub commands.

## What is inside

```
lib/
  main.dart            App boot and the root router (which screen hosts the root)
  config.dart          Configuration, read from the bundled .dnkeys file
                       (publishable keys only, never secrets: the file
                       ships inside the app)
  models/              Plain data classes (User)
  theme.dart           The light and dark palettes. The toggle lives in
                       ThemeState; the button sits top right on the home
                       screen. Onboarding stays dark by design on purpose.
  api/                 Talks to the outside world (AuthService)
  state/               The ChangeNotifier classes themselves: each holds
                       one concern's data and logic (AuthState, NotesState,
                       ThemeState). A new piece of shared state means a new
                       file here.
  repositories/        AppRepository, the single place that owns one
                       instance of each notifier (screens reach state as
                       AppRepository.authState). As your data grows, data
                       repositories live here too: one singleton per data
                       domain that owns its reads and writes, for example
                       a LocalNotesRepository for the SQLite queries and a
                       RemoteNotesRepository for server sync. Our
                       production app pairs a local and a remote
                       repository for its chat data.
  db/                  SQLite: table names, the database singleton, and
                       upgrade/ with one migration script per schema
                       version
  services/            Add it when you need it: long lived singletons that
                       wrap one capability (notifications, purchases,
                       audio, background work). Not network calls (api/),
                       not watched state (state/). Our production app has
                       a dozen of these.
  screens/             One file per screen
  widgets/             Shared widgets, used by more than one screen
                       (EmptyState, NoteCard, NoteGrid, the note
                       editor sheet).
                       Screens keep their private widgets in their
                       own file.
  utils/               SharedPrefs wrapper, preference keys, URL opening
```

The flow: onboarding with swipeable slides, sign in (or demo), a create
profile step for new users, then home. Home is the app's hub: the
framework drawer selects sections (Home, Notes, Favorites, Account,
Notifications) that render in place with the selected item highlighted,
the way Material's NavigationDrawer works. Secondary screens would be
pushed routes with a back button, and the Website item is neither: it
hands its URL to the system browser. Notes and Favorites show state
management and SQLite working together: notes are written in a native
sheet and stored locally, tapping one reopens the sheet to edit it, and
the heart on a card saves it to Favorites. Both sections render the same
grid and watch the same notifier, so neither keeps anything in sync by
hand, while an edit or a heart writes only that note's signal and
repaints its card alone. The
remaining sections say they are yours to build.

## Turn on real sign in

The demo session needs nothing. Real sign in needs a Supabase project and,
for the store, the sign in capabilities configured. All values go into the
`.dnkeys` file in the project root, which is bundled with the app. They are
publishable client config, not secrets: your data is protected by Row
Level Security.

If your team prefers keeping even publishable config out of git, you can
gitignore `.dnkeys` and commit a `.dnkeys.example` copy instead. Just
remember the app declares `.dnkeys` as a bundled asset, so every developer
must create the real file before building.

1. Create a project at supabase.com. From Project Settings, API, copy the
   URL and the publishable key into `.dnkeys`.

2. Create the profiles table. In the Supabase SQL editor run:

   ```sql
   create table public.profiles (
     id uuid primary key references auth.users on delete cascade,
     name text,
     username text unique,
     email text
   );

   alter table public.profiles enable row level security;

   create policy "Users read own profile"
     on public.profiles for select using (auth.uid() = id);
   create policy "Users insert own profile"
     on public.profiles for insert with check (auth.uid() = id);
   create policy "Users update own profile"
     on public.profiles for update using (auth.uid() = id);
   ```

3. Apple sign in (iOS). In your Apple Developer account enable the Sign in
   with Apple capability for your bundle id, and add the capability in the
   Xcode project. In Supabase, Authentication, Providers, enable Apple and
   follow their guide.

4. Google sign in (Android). In Google Cloud Console create OAuth
   credentials. You need TWO client ids: an Android one (with your package
   name and SHA-1) and a Web one. Put the WEB client id in `.dnkeys` as
   GOOGLE_WEB_CLIENT_ID. In Supabase enable the Google provider with the
   same Web client id.

5. Run the app again. The onboarding now shows the real sign in button.

## Make it yours

- App identity: change the bundle id and application id from
  `com.dartnative.starter` in `ios/` and `android/`.
- Icon and splash: replace `assets/dn-logo.png`, then
  `dart run tool/generate_app_assets.dart --source=assets/dn-logo.png --bg=#000000`
- Screens: start by replacing the stub screens behind the drawer items.
- Database: grow the schema in `lib/db/`, the comments there show how to
  add tables and versions.

To go deeper into what the starter already uses, the tutorials folder
next to this app covers social sign in, storage, state and navigation,
each as a small standalone app.

There is a CLAUDE.md in this folder. If you build with an AI assistant it
reads that file and follows the same structure this app already uses. For
deeper framework knowledge, give your assistant the skills in the skills
folder next to this app: dart-native (the developer guide, with widget
APIs and their native lowerings) and dart-native-porting (for migrating
an existing Flutter app).

The docs folder next to this app is also written to work for you and your
assistant alike:

- getting_started.md: the CLI, licensing and your first project
- widgets.md: every widget, what is Flutter compatible and what to use
  when a Flutter widget has no native equivalent
- state_management.md: the framework's reactive state types (Signal and
  friends), an alternative to the ChangeNotifier pattern this starter uses
- plugin_development.md: build your own plugin around any native SDK
- plugin_async_callbacks.md: calling Dart back from native code (events,
  progress, streams)
- architecture.md: how the framework works and how it differs from React
  Native
- logging.md: one terminal stream for Dart and native logs
- skia.md: the optional Skia canvas for custom drawing
- troubleshooting.md: common issues and their fixes
