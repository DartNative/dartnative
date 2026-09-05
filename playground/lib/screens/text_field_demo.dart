/// Native TextField demo.
///
/// Shows dartnative's drop-in Flutter TextField backed by UITextField (single
/// line) and UITextView (multiline) — real native views, not Skia/Impeller.
import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class TextFieldDemo extends StatefulWidget {
  const TextFieldDemo({super.key});

  @override
  State<TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<TextFieldDemo> {
  final _singleController = TextEditingController();
  final _multiController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _numberController = TextEditingController();

  String _lastChanged = '';

  @override
  void dispose() {
    _singleController.dispose();
    _multiController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Native TextField',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: Container(
        color: kHomeBg,
        child: ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 16,
            bottom: 16,
          ),
          children: [
            // ── Native features grid ────────────────────────────────────────
            const _NativeFeaturesGrid(),
            const SizedBox(height: 24),

            // ── Section header ──────────────────────────────────────────────
            _SectionHeader('Single-line — UITextField'),

            // ── Default text field ──────────────────────────────────────────
            _FieldLabel('Default'),
            _FieldShell(
              child: TextField(
                controller: _singleController,
                decoration: InputDecoration(
                  hintText: 'Type something…',
                  hintStyle: TextStyle(color: kTextSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: TextStyle(color: kTextPrimary, fontSize: 16),
                onChanged: (v) => setState(() => _lastChanged = v),
              ),
            ),

            // ── Email ───────────────────────────────────────────────────────
            _FieldLabel('Email keyboard · no autocorrect'),
            _FieldShell(
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: TextStyle(color: kTextSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: TextStyle(color: kTextPrimary, fontSize: 16),
              ),
            ),

            // ── Number ─────────────────────────────────────────────────────
            _FieldLabel('Number keyboard'),
            _FieldShell(
              child: TextField(
                controller: _numberController,
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: kTextSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(color: kTextPrimary, fontSize: 16),
              ),
            ),

            // ── Password ───────────────────────────────────────────────────
            _FieldLabel('Password · obscureText'),
            _FieldShell(
              child: TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: kTextSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                obscureText: true,
                style: TextStyle(color: kTextPrimary, fontSize: 16),
              ),
            ),

            const SizedBox(height: 24),

            // ── Section header ──────────────────────────────────────────────
            _SectionHeader('Multiline — UITextView'),

            // ── Multiline / fixed 5-line box (scrolls internally) ───────────
            _FieldLabel('minLines: 5  ·  maxLines: 5'),
            _FieldShell(
              child: TextField(
                controller: _multiController,
                decoration: InputDecoration(
                  hintText: 'Multiline field — type past 5 to scroll…',
                  hintStyle: TextStyle(color: kTextSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                minLines: 5,
                maxLines: 5,
                style: TextStyle(color: kTextPrimary, fontSize: 16),
                onChanged: (v) => setState(() => _lastChanged = v),
              ),
            ),

            const SizedBox(height: 24),

            // ── onChanged readout ───────────────────────────────────────────
            _SectionHeader('onChanged value'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _lastChanged.isEmpty ? '(nothing typed yet)' : _lastChanged,
                style: TextStyle(
                  color: _lastChanged.isEmpty
                      ? kTextTertiary
                      : const Color(0xFF32D74B),
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Native features grid ──────────────────────────────────────────────────────

const _kFeatures = [
  _NativeFeature(
    '1',
    'Magnifier\nLoupe',
    'Barrel loupe (iOS) & floating magnifier (Android) for pixel-precise cursor placement.',
  ),
  _NativeFeature(
    '2',
    'Native Render\n& Toolbar',
    'CoreText / HarfBuzz shaping with real ligatures + system Cut · Copy · Translate action bar.',
  ),
  _NativeFeature(
    '3',
    'Autocorrection',
    'Red-underline corrections & inline replacement bubbles powered by the OS engine.',
  ),
  _NativeFeature(
    '4',
    'Smart\nPunctuation',
    'Auto curly quotes, em-dash on double-hyphen, period on double-space — both platforms.',
  ),
  _NativeFeature(
    '5',
    'Password\nAutoFill',
    'iCloud Keychain (iOS) & Autofill Services (Android) — zero-setup credential filling.',
  ),
  _NativeFeature(
    '6',
    'Predictive\nText',
    'QuickType bar (iOS) & GBoard inline suggestions (Android) above the keyboard.',
  ),
];

class _NativeFeature {
  const _NativeFeature(this.number, this.title, this.description);
  final String number;
  final String title;
  final String description;
}

class _NativeFeaturesGrid extends StatelessWidget {
  const _NativeFeaturesGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'WHY NATIVE TEXTFIELD',
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.6,
          children: _kFeatures.map((f) => _FeatureCell(f)).toList(),
        ),
      ],
    );
  }
}

class _FeatureCell extends StatelessWidget {
  const _FeatureCell(this.feature);
  final _NativeFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kRowBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38383A), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feature.number,
            style: const TextStyle(
              color: Color(0xFF0A84FF),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feature.title,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Text(
              feature.description,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 11,
                height: 1.3,
              ),
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: kTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(color: kTextTertiary, fontSize: 12),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kRowBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF38383A), width: 0.5),
      ),
      child: child,
    );
  }
}
