import 'package:dartnative/dartnative.dart';
import 'package:dartnative_app_review/dartnative_app_review.dart';

/// Demonstrates `dartnative_app_review`:
///
/// * **isAvailable** — capability check.
/// * **requestReview** — the quota-limited native prompt (may show nothing).
/// * **openStoreListing** — the always-works "Rate us" fallback.
///
/// Replace `_kAppStoreId` with your own App Store id to test openStoreListing
/// on iOS.
class AppReviewDemo extends StatefulWidget {
  const AppReviewDemo({super.key});

  @override
  State<AppReviewDemo> createState() => _AppReviewDemoState();
}

// Your app's numeric App Store id (iOS only; Android uses its own package).
// openStoreListing opens THIS app's page, so it only shows a real listing once
// the app is published on the store — replace with your id.
const String _kAppStoreId = '000000000';

class _AppReviewDemoState extends State<AppReviewDemo> {
  final _review = InAppReview.instance;
  final List<String> _log = [];

  void _append(String message) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _log.insert(0, '$ts  $message');
      if (_log.length > 12) _log.removeLast();
    });
  }

  Future<void> _checkAvailable() async {
    final ok = await _review.isAvailable();
    _append('isAvailable → $ok');
  }

  Future<void> _requestReview() async {
    await _review.requestReview();
    _append('requestReview() called (OS decides if it shows)');
  }

  Future<void> _openStoreListing() async {
    await _review.openStoreListing(appStoreId: _kAppStoreId);
    _append("openStoreListing() → this app's page (real once published)");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.light,
      appBar: AppBar(
        title: const Text(
          'dartnative_app_review',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _Section('In-app review prompt (stars only)'),
          Button(
            title: 'Check isAvailable()',
            variant: ButtonVariant.filled,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            onPressed: _checkAvailable,
          ),
          const SizedBox(height: 10),
          Button(
            title: 'Request review',
            variant: ButtonVariant.filled,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            onPressed: _requestReview,
          ),
          const _Hint(
            'Quota-limited: the OS may show nothing, and never reports whether '
            'it did. On Android it only works from a Play-distributed build.',
          ),
          const SizedBox(height: 28),
          const _Section('Full review — store listing (stars + title + text)'),
          Button(
            title: 'Open store listing',
            variant: ButtonVariant.filled,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            onPressed: _openStoreListing,
          ),
          const _Hint("The full review — opens the store's review composer "
              '(stars + title + message), unlike the star-only prompt above. '
              "Opens THIS app's page, so it's real only once published. "
              'appStoreId is iOS-only.'),
          const SizedBox(height: 28),
          const _Section('Event log'),
          if (_log.isEmpty)
            const _Hint('No events yet.')
          else
            ..._log.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  e,
                  style: const TextStyle(
                    color: Color(0xFF1E9E4A),
                    fontSize: 13,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF636366),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
        ),
      );
}
