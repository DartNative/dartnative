import 'package:dartnative/dartnative.dart';

import '../api/auth_service.dart';
import '../repositories/app_repository.dart';
import '../utils/launch_url.dart';
import '../widgets/colored_avatar.dart';
import '../widgets/empty_state.dart';
import 'favorites_view.dart';
import 'notes_view.dart';

/// The sections the drawer can select. Each renders IN PLACE as the home
/// screen's body; nothing is pushed.
enum _Section { home, notes, favorites, account, notifications }

/// Home: the app's hub. An AppBar, the framework drawer, and a body that
/// switches between sections.
///
/// The drawer runs the two patterns our production app uses, which are
/// also Flutter's own (Material NavigationDrawer selects destinations in
/// place; secondary screens are pushed):
///
///  - SECTIONS (Home, Notes, Favorites, Account, Notifications): tapping
///    one swaps the body in place and closes the drawer. No navigation
///    and no back button; the hamburger reopens the drawer, which shows
///    the current section highlighted.
///  - PUSHED SCREENS (think settings, a profile editor): tapping one
///    closes the drawer and pushes a real route with a back button.
///  - LINKS (Website here): tapping one closes the drawer and hands the
///    URL to the system browser. No route, no screen.
///
/// Use a section for a main destination and a pushed screen for a
/// secondary one.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Section _section = _Section.home;

  static const _titles = {
    _Section.home: 'Home',
    _Section.notes: 'Notes',
    _Section.favorites: 'Favorites',
    _Section.account: 'Account',
    _Section.notifications: 'Notifications',
  };

  Future<void> _signOut() async {
    // The root router watches auth state: when the session ends it swaps
    // the root back to the onboarding and clears pushed routes. No manual
    // navigation needed here.
    await AuthService.signOut();
  }

  Widget _body() {
    switch (_section) {
      case _Section.home:
        return _HomeSection(
          onOpenSection: (s) => setState(() => _section = s),
        );
      case _Section.notes:
        return const NotesView();
      case _Section.favorites:
        return const FavoritesView();
      case _Section.account:
        return const EmptyState(
          icon: MaterialSymbolsRounded.person,
          title: 'This section is yours to build',
          message: 'Replace it with your real Account content.',
        );
      case _Section.notifications:
        return const EmptyState(
          icon: MaterialSymbolsRounded.notifications,
          title: 'This section is yours to build',
          message: 'Replace it with your real Notifications content.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppRepository.themeState..watch(context);
    final p = theme.palette;

    return Scaffold(
      backgroundColor: p.bg,
      // Native surfaces under this screen follow the chosen theme.
      brightness: p.brightness,
      // The screen lifts and slides over a drawer that stays put, rather
      // than the two travelling together.
      drawerStyle: DrawerStyle.slideOver,
      drawer: _AppDrawer(
        selected: _section,
        onSelect: (s) {
          if (s != _section) setState(() => _section = s);
        },
        onOpenWebsite: () => openUrl('www.dartnative.com'),
        onSignOut: _signOut,
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(MaterialSymbolsRounded.menu, color: p.text),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          _titles[_section]!,
          style: TextStyle(
            color: p.text,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // The theme toggle. Everything it does lives in ThemeState:
          // swap the palette, pin the native appearance, persist, notify.
          IconButton(
            icon: Icon(
              theme.isDark
                  ? MaterialSymbolsRounded.light_mode
                  : MaterialSymbolsRounded.dark_mode,
              color: p.text,
            ),
            onPressed: AppRepository.themeState.toggle,
          ),
        ],
        backgroundColor: p.bg,
      ),
      body: _body(),
    );
  }
}

/// The Home section: a greeting and one card per destination.
///
/// Each card says what its screen does and which pattern it demonstrates,
/// so the app reads as a tour of itself. Tapping one opens that section,
/// which makes the cards shortcuts as well as documentation.
class _HomeSection extends StatelessWidget {
  const _HomeSection({required this.onOpenSection});

  final void Function(_Section section) onOpenSection;

  @override
  Widget build(BuildContext context) {
    final auth = AppRepository.authState..watch(context);
    final user = auth.user;
    final p = (AppRepository.themeState..watch(context)).palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Hi ${user?.firstName ?? 'there'}',
          style: TextStyle(
            color: p.text,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This demo shows the pieces you and your LLM need to '
          'quickly build dartnative apps: sqlite db, database versioning, '
          'sharing state across screens, UI reactive updates, sign in, '
          'cache, theming, drawer and more.',
          style: TextStyle(
            color: p.textSoft,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _HomeCard(
          icon: MaterialSymbolsRounded.description,
          title: 'Notes',
          subtitle: 'Notes kept in SQLite and written in a native sheet. '
              'Shows the state plus storage pattern, and a signal per note '
              'so editing one repaints one row.',
          onTap: () => onOpenSection(_Section.notes),
        ),
        const SizedBox(height: 10),
        _HomeCard(
          icon: MaterialSymbolsRounded.favorite,
          title: 'Favorites',
          subtitle: 'The notes you hearted, read from the same notifier '
              'Notes uses. Shows two sections sharing one source of truth '
              'with nothing to keep in sync.',
          onTap: () => onOpenSection(_Section.favorites),
        ),
        const SizedBox(height: 10),
        _HomeCard(
          icon: MaterialSymbolsRounded.person,
          title: 'Account and Notifications',
          subtitle: 'Empty on purpose. Copy the shape of Notes and make '
              'them yours.',
          onTap: () => onOpenSection(_Section.account),
        ),
        const SizedBox(height: 10),
        // Builder gives the card a context BELOW the Scaffold, which is
        // what Scaffold.of needs to find it.
        Builder(
          builder: (context) => _HomeCard(
            icon: MaterialSymbolsRounded.menu,
            title: 'The drawer',
            subtitle: 'Swipe from the left edge, or tap the menu button. '
                'Sections switch in place, the Website item hands a URL to '
                'the browser.',
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ],
    );
  }
}

/// A tappable card on the home section.
class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = (AppRepository.themeState..watch(context)).palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: p.text, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: p.textSoft,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The drawer panel: user header, section items with the selected one
/// highlighted, a pushed screen item, sign out.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.selected,
    required this.onSelect,
    required this.onOpenWebsite,
    required this.onSignOut,
  });

  final _Section selected;
  final void Function(_Section section) onSelect;
  final VoidCallback onOpenWebsite;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final auth = AppRepository.authState..watch(context);
    final user = auth.user;
    final p = (AppRepository.themeState..watch(context)).palette;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    // Taps that navigate INSIDE the app close the drawer first, then act.
    // This context is inside the Scaffold, so Scaffold.of can find it.
    void go(VoidCallback action) {
      Scaffold.maybeOf(context)?.closeDrawer();
      action();
    }

    Widget item(_Section section, IconData icon, String label) => _DrawerItem(
          icon: icon,
          label: label,
          selected: section == selected,
          onTap: () => go(() => onSelect(section)),
        );

    return Drawer(
      backgroundColor: p.drawerBg,
      // The panel and the page share a background, so the right edge is
      // what separates them. A strip, not a border: only a border's TOP
      // side is read here. Positioned.fill keeps the Stack full height,
      // since a Stack fills only when every child is positioned.
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User header.
                Padding(
                  padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 20),
                  child: Row(
                    children: [
                      ColoredAvatar(initials: user?.initials ?? ''),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Guest',
                              style: TextStyle(
                                color: p.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (user?.username != null)
                              Text(
                                '@${user!.username}',
                                style: TextStyle(
                                  color: p.textSoft,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Sections: switch the home body in place.
                item(_Section.home, MaterialSymbolsRounded.home, 'Home'),
                item(_Section.notes, MaterialSymbolsRounded.description,
                    'Notes'),
                item(_Section.favorites, MaterialSymbolsRounded.favorite,
                    'Favorites'),
                item(
                    _Section.account, MaterialSymbolsRounded.person, 'Account'),
                item(_Section.notifications,
                    MaterialSymbolsRounded.notifications, 'Notifications'),
                // A link, not a screen: the system browser takes it from here.
                // The drawer deliberately stays OPEN. Leaving for another app is
                // not navigation inside this one, so coming back should show the
                // app exactly as it was left, drawer included.
                _DrawerItem(
                  icon: MaterialSymbolsRounded.language,
                  label: 'Website',
                  selected: false,
                  onTap: onOpenWebsite,
                ),
                const Expanded(child: SizedBox()),
                _DrawerItem(
                  icon: MaterialSymbolsRounded.logout,
                  label: 'Sign out',
                  selected: false,
                  onTap: () => go(onSignOut),
                ),
                SizedBox(height: bottomInset + 12),
              ],
            ),
          ),
          // The panel's trailing edge, for DrawerStyle.push: there the
          // drawer and the screen travel together as one flat plane, and
          // the hairline is what separates them. Under slideOver the
          // screen is a card lifted above the drawer with a shadow of its
          // own, which does that job. Uncomment when going back to push.
          // Positioned(
          //   right: 0,
          //   top: 0,
          //   bottom: 0,
          //   child: Container(width: 0.5, color: p.drawerEdge),
          // ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = (AppRepository.themeState..watch(context)).palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          // The selected section keeps its highlight while the drawer is
          // closed, so reopening it shows where you are.
          color: selected ? p.drawerSelection : const Color(0x00000000),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? p.text : p.textSoft, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: p.text,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
