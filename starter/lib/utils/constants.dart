/// SharedPreferences keys, defined in one place so renaming is trivial and
/// typos surface here instead of at scattered call sites.
library;

/// True once the user has finished the onboarding flow.
const String kPrefOnboardingComplete = 'onboarding_complete';

/// JSON of the signed in user's profile, cached for offline starts.
const String kPrefCachedProfile = 'cached_profile';

/// True while a demo session is active (the app runs with a fake user and
/// no Supabase). Cleared on sign out.
const String kPrefDemoSession = 'demo_session';

/// True when the user chose the dark theme. Missing means dark, the
/// app's default look.
const String kPrefDarkTheme = 'dark_theme';

/// True once the sample notes have been written. They seed a fresh
/// install so the app has something to show, and the flag makes sure a
/// user who deletes them does not get them back on the next launch.
const String kPrefNotesSeeded = 'notes_seeded';
