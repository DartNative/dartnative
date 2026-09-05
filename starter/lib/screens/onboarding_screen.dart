import 'dart:async';
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import '../api/auth_service.dart';
import '../config.dart';
import '../theme.dart';
import '../utils/constants.dart';
import '../utils/shared_prefs.dart';
import 'create_profile_screen.dart';
import 'home_screen.dart';

/// A short slide.
class _Slide {
  final String title;
  final String subtitle;
  const _Slide(this.title, this.subtitle);
}

const _slides = <_Slide>[
  _Slide(
    'Welcome',
    'This is your app. Swipe through these slides, then sign in.',
  ),
  _Slide(
    'Real native UI',
    'Every screen here is built from real platform views.',
  ),
  _Slide(
    'Ready to go',
    'Auth, a drawer, state and local storage are already wired.',
  ),
];

/// The notes each slide shows, as (text, favourite) pairs. Short on
/// purpose: these are a glimpse of the app, not something to read.
const _previewNotes = <List<(String, bool)>>[
  [
    ('Lens rental, 24-70 back Thursday 🚀', false),
    ('Milk, coffee, olive oil, something for Sunday 🥛', false),
    ('Book the dentist', false),
    ("Mum's birthday on the 14th 🎁", true),
  ],
  [
    ('Invoice 142 still unpaid. Chase on Monday. 💵', false),
    ('Prints from Whitfield, they shut at 6', false),
    ('Renew the studio insurance before the 30th', true),
    ('Anna asked about family sessions 💌', false),
  ],
  [
    ('Passport photos for Nan, Tuesday morning', false),
    ('Framing quote for the cafe in Hoxton: 12 prints, A3.', false),
    ('Back tyre before the weekend 🚲', false),
    ('That new place on Bermondsey Street ☕️', false),
  ],
];

/// One note drawn the way the grid draws it, without the parts that only
/// mean something there: no tap to edit, no wobble, no delete badge.
///
/// Onboarding shows the app's own cards rather than a picture of them, so
/// the first thing anyone sees is the real interface. The colours come
/// from the dark palette because this screen is dark whatever the app
/// theme says.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard(
      {required this.text, required this.color, required this.favorite});

  final String text;
  final Color color;
  final bool favorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 7, 8, 11),
      decoration: ShapeDecoration(
        color: color,
        // The squircle the note cards use, the continuous curve iOS draws.
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                favorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: favorite ? kDarkPalette.accent : kDarkPalette.text,
                size: 15,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: kDarkPalette.text,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The slide's notes, arriving one after another.
///
/// Each card fades up over a few pixels and then stays put, which is
/// enough to show the grid assembling itself without turning the screen
/// into a demo reel. A slide change rebuilds this with a new key, so the
/// next set arrives the same way.
class _NotesPreview extends StatefulWidget {
  const _NotesPreview({required this.slide, super.key});

  final int slide;

  @override
  State<_NotesPreview> createState() => _NotesPreviewState();
}

class _NotesPreviewState extends State<_NotesPreview>
    with SingleTickerProviderStateMixin {
  /// One card's own entrance, as a fraction of the whole run.
  static const double _cardSpan = 0.5;

  /// How much later each card starts than the one before it. The last card
  /// starts at three of these and still has its span to run inside the one
  /// whole, or it would be caught mid fade when the run ends.
  static const double _stagger = 0.15;

  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// 0 to 1 for the card at [i], eased, delayed by its place in the order.
  double _progressFor(int i) {
    final raw = ((_in.value - i * _stagger) / _cardSpan).clamp(0.0, 1.0);
    return Curves.easeOut.transform(raw);
  }

  Widget _card(int i, (String, bool) note) {
    final (text, favorite) = note;
    return AnimatedBuilder(
      animation: _in,
      builder: (_, child) {
        final t = _progressFor(i);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
      child: _PreviewCard(
        text: text,
        color: kDarkPalette.cardColors[i % kDarkPalette.cardColors.length],
        favorite: favorite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _previewNotes[widget.slide % _previewNotes.length];
    // Two columns, as the grid has, with the taller card leading the left
    // one so the pair reads as masonry rather than a table.
    return SizedBox(
      width: 268,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(0, notes[0]),
                const SizedBox(height: 10),
                _card(2, notes[2]),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 22),
                _card(1, notes[1]),
                const SizedBox(height: 10),
                _card(3, notes[3]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The first screen a new user sees: swipeable slides with sign in at the
/// bottom.
///
/// Dark by design: this screen ignores the app theme on purpose, the
/// pattern to copy for fixed look screens. Themed screens read their
/// colors from ThemeState instead (see home_screen.dart).
///
/// Sign in is Apple on iOS and Google on Android, through AuthService.
/// When the app has no Supabase keys yet, the demo button is the only way
/// in, so the project works the moment it is cloned.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _slide = 0;

  /// Blocks a second tap while a sign in is running. A double tap would
  /// start two native sign in flows at once, and the second one can eat
  /// the result of the first.
  bool _signInInFlight = false;

  void _next() {
    if (_slide < _slides.length - 1) setState(() => _slide++);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -200 && _slide < _slides.length - 1) {
      setState(() => _slide++);
    } else if (v > 200 && _slide > 0) {
      setState(() => _slide--);
    }
  }

  void _navigate(Widget screen, String routeName) {
    // The name (PageRoute.settings) keeps the screen on the stack across
    // hot restarts; unnamed routes are dropped from the replay.
    Navigator.pushReplacement(
      context,
      PageRoute(builder: (_) => screen, settings: routeName),
    );
  }

  Future<void> _onSignIn() async {
    if (_signInInFlight) return;
    setState(() => _signInInFlight = true);
    try {
      // Apple on iOS, Google on Android. Both return the same record, so
      // the rest of the flow is shared.
      final result = Platform.isIOS
          ? await AuthService.signInWithApple()
          : await AuthService.signInWithGoogle();
      if (!mounted) return;

      // Apple sends the name only on the very first sign in. On later sign
      // ins fall back to the metadata AuthService saved back then.
      final providerName = [result.givenName, result.familyName]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' ');
      final meta = AuthService.userMetadata;
      final prefillName = providerName.isNotEmpty
          ? providerName
          : meta?['full_name'] as String?;

      // A returning user has a profile row already; a new user does not.
      final profile = await AuthService.fetchProfile();
      if (!mounted) return;

      if (profile != null && (profile.username?.isNotEmpty ?? false)) {
        await SharedPrefs.instance.setBool(kPrefOnboardingComplete, true);
        if (!mounted) return;
        _navigate(const HomeScreen(), '/home');
      } else {
        _navigate(
          CreateProfileScreen(prefillName: prefillName),
          '/create_profile',
        );
      }
    } catch (e) {
      // The user cancelled the sheet, or the network failed. Stay here so
      // they can try again.
      dnLog('OnboardingScreen: sign in error: $e');
    } finally {
      if (mounted) {
        setState(() => _signInInFlight = false);
      } else {
        _signInInFlight = false;
      }
    }
  }

  Future<void> _onDemo() async {
    await AuthService.signInDemo();
    if (!mounted) return;
    await SharedPrefs.instance.setBool(kPrefOnboardingComplete, true);
    if (!mounted) return;
    _navigate(const HomeScreen(), '/home');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_slide];
    final isLast = _slide == _slides.length - 1;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      body: GestureDetector(
        onHorizontalDragEnd: _onDragEnd,
        onTap: isLast ? null : _next,
        child: Container(
          color: const Color(0x00000000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The top area shows the per slide preview, centered in the
              // space the text and buttons leave over (the gee layout).
              Expanded(
                child: Center(
                  // Keyed by slide: a new key rebuilds the preview, so the
                  // next set of notes arrives the same way the first did.
                  child: _NotesPreview(key: ValueKey(_slide), slide: _slide),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.title,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      slide.subtitle,
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 17,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Page dots.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i == _slide
                            ? const Color(0xFFFFFFFF)
                            : const Color(0x4DFFFFFF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Button(
                      title: _signInInFlight
                          ? 'Signing in...'
                          : Platform.isIOS
                              ? 'Sign in with Apple'
                              : 'Sign in with Google',
                      color: const Color(0xFFFFFFFF),
                      foregroundColor: const Color(0xFF101014),
                      height: 50,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      // The provider logo leads the title (the gee look).
                      // The PNGs are white glyphs; foregroundColor above
                      // template tints them dark on this white button.
                      imageAsset: Platform.isIOS
                          ? 'assets/apple-logo.png'
                          : 'assets/google-logo.png',
                      imageSize: 18,
                      // Until Supabase keys exist, the tap shows a
                      // native alert pointing at the setup instead.
                      onPressed: AppConfig.isAuthConfigured
                          ? _onSignIn
                          : () {
                              showAlert(
                                context: context,
                                title: 'Sign in needs your keys',
                                message: 'Add your Supabase URL and '
                                    'publishable key to the .dnkeys file, '
                                    'then this button signs users in for '
                                    'real. The README walks through it.',
                              );
                            },
                    ),
                    const SizedBox(height: 10),
                    Button(
                      title: 'Try the demo',
                      color: AppConfig.isAuthConfigured
                          ? const Color(0x26FFFFFF)
                          : const Color(0xFFFFFFFF),
                      foregroundColor: AppConfig.isAuthConfigured
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF101014),
                      height: 50,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      onPressed: _onDemo,
                    ),
                    if (!AppConfig.isAuthConfigured) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Sign in works once you add your Supabase keys '
                        'to .dnkeys. See the README.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0x66FFFFFF),
                          fontSize: 12,
                          height: 1.65,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: bottomInset + 24),
            ],
          ),
        ),
      ),
    );
  }
}
