// The one screen of this app.
//
// This file never changes during the tutorial. Every fix goes into
// fix_me.dart; this screen only reads the values from there, while it draws,
// through plain calls. That is the point: a fix reaches every caller of a
// fixed function, so a screen that never changed still shows the corrected
// values once the fix is applied.

import 'package:dartnative/dartnative.dart';

import 'fix_me.dart';

const Color _ink = Color(0xFF111111);
const Color _grey = Color(0xFF6B6B70);
const Color _faint = Color(0xFF8E8E93);
const Color _card = Color(0xFFF2F2F7);
const Color _red = Color(0xFFB00020);
const Color _green = Color(0xFF1E8E3E);
const Color _greenSoft = Color(0xFFE6F4EA);
const Color _amberSoft = Color(0xFFFFF1CC);
const Color _white = Color(0xFFFFFFFF);

/// The ids this app comes with. An app id belongs to the first account that
/// ships it, so the tutorial asks you to change them to ids of your own
/// before the release. The card at the top of the screen stays until you do.
const String _shippedIosId = 'com.dartnative.tutorials.codePushTutorial';
const String _shippedAndroidId = 'com.dartnative.tutorials.code_push_tutorial';

/// Turns the word from [paidIcon] into an icon.
///
/// This lives here, in a file no fix touches, because a fix may not build an
/// Icon or name an IconData itself. Both icons are named here, so the app
/// already carries both glyphs when it ships; a fix only changes which word
/// comes back from fix_me.dart.
IconData iconNamed(String name) {
  switch (name) {
    case 'check':
      return CupertinoIcons.checkmark_circle_fill;
    case 'cart':
      return CupertinoIcons.cart;
    default:
      return CupertinoIcons.question_circle;
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _checking = false;
  String? _checkOutcome;
  String? _automaticOutcome;

  @override
  void initState() {
    super.initState();
    // Right after this screen comes up, the app asks by itself whether a fix
    // is waiting, and downloads it for the next launch. That is how phones
    // get fixes: nobody has to tap anything. Show what that check ended with.
    CodePush.automaticCheck.then((String outcome) {
      if (mounted) {
        setState(() => _automaticOutcome = outcome);
      }
    });
  }

  /// Asks the update service whether a fix is waiting and, if so, downloads
  /// it for the NEXT launch. The app already did this once by itself, right
  /// after this screen came up; the button asks again so you can watch it.
  /// Nothing on screen changes because of this call: a fix is only ever
  /// applied when the app starts.
  Future<void> _checkForFix() async {
    setState(() {
      _checking = true;
      _checkOutcome = null;
    });
    final String outcome = await CodePush.checkForUpdates();
    if (!mounted) {
      return;
    }
    setState(() {
      _checking = false;
      _checkOutcome = outcome;
    });
  }

  /// Shown while the app still runs under an id it came with. It goes away
  /// on its own once you set an id of your own and build again.
  Widget _reminderCard(String appId) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amberSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'This app still has the id it came with ($appId). Change it to one '
        'of your own before you make the release; the README says how, '
        'under Before you start. If you already made a release with this '
        'id, make a new one after the change and install it again. This '
        'card goes away on its own once the id is yours.',
        style: const TextStyle(color: _ink, fontSize: 14, height: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The four values, read through plain calls with nothing catching around
    // them. Until a fix is applied these run the code that shipped; after
    // one, the very same calls run the fixed code.
    final int total = priceWithTax(100);
    final String title = screenTitle();
    final double totalSize = totalFontSize();
    final String icon = paidIcon();

    // This screen knows the right answers so it can label each mistake as
    // "as shipped" or "fixed". A real app would not, of course.
    final bool totalFixed = total == 108;
    final bool titleFixed = title == 'Checkout';
    final bool sizeFixed = totalSize >= 24;
    final bool iconFixed = icon == 'check';

    final CodePushStatus status = CodePush.status;
    final int? fix = status.activePatch;
    final bool downloaded = _checkOutcome?.contains('downloaded') ?? false;

    // The id this build carries, from the platform bindings.
    final String? appId = DartNativeLicense.appBundleId;
    final bool shippedId = appId == _shippedIosId || appId == _shippedAndroidId;

    return Scaffold(
      brightness: Brightness.light,
      backgroundColor: _white,
      // No style on the title: each platform draws its own bar title.
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (shippedId) ...[
            _reminderCard(appId!),
            const SizedBox(height: 16),
          ],
          _statusCard(fix),
          const SizedBox(height: 16),
          _receipt(
            total: total,
            totalFixed: totalFixed,
            totalSize: totalSize,
            icon: icon,
            iconFixed: iconFixed,
          ),
          _heading('The four mistakes that shipped'),
          _mistake(
            what: 'The total',
            now: 'shows $total',
            shouldBe: 'It should be 108: 100 plus 8% tax.',
            fixed: totalFixed,
          ),
          _mistake(
            what: 'The screen title',
            now: 'says "$title"',
            shouldBe: 'It should say Checkout.',
            fixed: titleFixed,
          ),
          _mistake(
            what: 'The size of the total',
            now: '${totalSize.toStringAsFixed(0)} points',
            shouldBe: 'It should be 40, large enough to read.',
            fixed: sizeFixed,
          ),
          _mistake(
            what: 'The icon next to Paid',
            now: icon == 'check' ? 'a check mark' : 'a $icon',
            shouldBe: 'It should be a check mark.',
            fixed: iconFixed,
          ),
          _heading('Get the fix'),
          Button(
            title: _checking ? 'Checking…' : 'Check for a fix',
            variant: ButtonVariant.filled,
            onPressed: _checking ? null : _checkForFix,
          ),
          if (_checkOutcome != null) ...[
            const SizedBox(height: 10),
            Text(
              _checkOutcome!,
              style: const TextStyle(color: _grey, fontSize: 13, height: 1.4),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: downloaded ? _amberSoft : _card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              downloaded
                  ? 'The fix is on this phone but not running yet. Close the '
                      'app completely (swipe it away in the app switcher), '
                      'then open it again. It will start with the fix.'
                  : 'A fix is applied when the app starts, never while it is '
                      'running. Once the check has found one: close the app '
                      'completely, then open it again.',
              style: TextStyle(
                color: downloaded ? _ink : _grey,
                fontSize: 14,
                fontWeight: downloaded ? FontWeight.w600 : FontWeight.normal,
                height: 1.4,
              ),
            ),
          ),
          _heading('What a fix cannot do'),
          const Text(
            'A fix carries Dart code only. It cannot bring a new picture, '
            'font or sound file: those are packed into the app by the store '
            'build, so a fix can only choose among the files the app already '
            'has, or show one differently. It cannot change a plugin\'s '
            'native code, and it cannot change the framework. All of those '
            'need a normal store release.',
            style: TextStyle(color: _grey, fontSize: 13, height: 1.4),
          ),
          _heading('What the app reported when it started'),
          if (status.lastApplyReport.isEmpty)
            const Text(
              'Nothing yet.',
              style: TextStyle(color: _faint, fontSize: 12),
            ),
          for (final String line in status.lastApplyReport)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(color: _faint, fontSize: 12, height: 1.35),
              ),
            ),
          _heading("What the app's own check found"),
          Text(
            _automaticOutcome ?? 'Still checking.',
            style: const TextStyle(color: _faint, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statusCard(int? fix) {
    final bool running = fix != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: running ? _greenSoft : _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            running ? 'Running fix $fix' : 'Running as shipped',
            style: TextStyle(
              color: running ? _green : _ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            running
                ? 'This fix arrived over the network and was applied when the '
                    'app started. No app store, no reinstall.'
                : 'No fix has been applied on this phone. What you see below '
                    'is the code that shipped.',
            style: const TextStyle(color: _grey, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _receipt({
    required int total,
    required bool totalFixed,
    required double totalSize,
    required String icon,
    required bool iconFixed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _receiptLine('Price', '100'),
          const SizedBox(height: 6),
          _receiptLine('Tax', '8%'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$total',
                style: TextStyle(
                  color: totalFixed ? _green : _red,
                  fontSize: totalSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                iconNamed(icon),
                size: 22,
                color: iconFixed ? _green : _grey,
              ),
              const SizedBox(width: 8),
              const Text(
                'Paid',
                style: TextStyle(color: _ink, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _grey, fontSize: 15)),
        Text(value, style: const TextStyle(color: _ink, fontSize: 15)),
      ],
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: _ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _mistake({
    required String what,
    required String now,
    required String shouldBe,
    required bool fixed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: fixed ? _green : _red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              fixed ? 'FIXED' : 'AS SHIPPED',
              style: const TextStyle(
                color: _white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$what $now.',
                  style: const TextStyle(color: _ink, fontSize: 15),
                ),
                if (!fixed)
                  Text(
                    shouldBe,
                    style: const TextStyle(color: _grey, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
