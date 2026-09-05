import '../state/auth_state.dart';
import '../state/notes_state.dart';
import '../state/theme_state.dart';

/// One place that owns every app wide ChangeNotifier.
///
/// Screens read state through here instead of constructing their own:
///
/// ```dart
/// final auth = AppRepository.authState..watch(context);
/// ```
///
/// `watch(context)` subscribes the widget, so it rebuilds when the notifier
/// changes. This tiny pattern is deliberately the whole state story of the
/// starter: no extra package, easy to follow, and it scales to a handful of
/// notifiers before you need anything fancier.
class AppRepository {
  AppRepository._();

  static final AuthState authState = AuthState();
  static final NotesState notesState = NotesState();
  static final ThemeState themeState = ThemeState();
}
