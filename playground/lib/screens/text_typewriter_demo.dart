/// Live Text: a message typing itself out on a sticky note, in real native
/// text.
///
/// Every glyph here is a native label, so the emoji come from whatever pack
/// the device is set to and the type follows the OS text stack. A Flutter
/// build of the same screen paints its own glyphs from a bundled font, and
/// the emoji are the tell: colours, shapes and skin tones drift from what
/// the rest of the phone shows.
///
/// The typewriter is a plain string that grows: the label is rebuilt with a
/// longer substring each frame, so what animates is real text being laid out
/// by the platform, not a picture of text.
///
/// The screen is the note: yellow paper, dark ink, and a folded corner drawn
/// with a native [CustomPaint]. The block of writing is white paper, or the
/// Liquid Glass material on iOS 26.
import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative/canvas.dart' as ui;

// ── Post-it palette ───────────────────────────────────────────────────────────
//
// Fixed colours, not palette shorthands: the screen is a physical object, and
// a sticky note is yellow with dark ink under a light theme or a dark one.
// The ink tones are warm greys so they sit on the paper rather than on top
// of it.

/// The note itself.
const _kNote = Color(0xFFFCEE93);

/// The desk the note lies on. Visible where the corner is folded away, and
/// in the strip under the note on a home-indicator phone.
const _kDesk = Color(0xFFE7E3D8);

/// The folded corner: the back of the paper, shaded near the crease and
/// catching light at the tip.
const _kFlapCrease = Color(0xFFE0CE72);
const _kFlapTip = Color(0xFFF6E9A4);

/// A hairline of shadow along the crease, so the flap sits ON the note
/// instead of being a flat triangle painted over it.
const _kCrease = Color(0x33705F1E);

const _kInk = Color(0xFF2E2A20);
const _kInkSoft = Color(0xFF7A6C48);

/// Written area: the note is the page, this is the block of writing on it.
const _kPaper = Color(0xFFFFFFFF);

/// The message, written so emoji land on nearly every line, and so several
/// lines end in a RUN of emoji.
///
/// Runs are the interesting case. A single emoji between words looks fine
/// almost anywhere; three or four in a row is where a bundled font shows its
/// seams, because each glyph carries its own advance width and the gaps
/// between them go uneven. The platform text stack spaces a run evenly, so
/// the runs below are the part worth looking at side by side.
///
/// Every line must FIT the writing block on one rendered line, or UILabel
/// wraps it and the wrap collides with the authored line breaks, reading as
/// a break in a random place. The block gives the label ~307pt on the
/// narrowest modern iPhone (375pt screen minus paddings); at 17pt an emoji
/// advances ~20pt and a letter ~7.5pt, so each line here is kept under
/// ~300pt natural width.
const _kLines = <String>[
  'Hey 👋 quick one about the trip ✈️',
  'Still on for Saturday? 🗓️ ❤️❤️❤️',
  'Pizza place 🍕🍝🥗 near the hotel 🏨',
  'Rooftop bar 🍹🍸🥂 sunset at 8 🌅',
  'Weather looks kind 🌤️ maybe rain ☔️',
  'Camera and charger packed 📷🔭🔋🔌',
  'Museum tickets are booked 🎟️🖼️🏛️',
  'Train at 9:15 🚆 platform 4 ⏰',
  'Bring snacks 🥐🍫☕️🍎🥨 long ride',
  'Family is coming 👨‍👩‍👧‍👦 all excited 🎉🎊',
  'For the scrapbook 🇮🇹🇯🇵🇧🇷🇪🇸🇵🇹',
  'Playlist ready 🎧🎸🥁🎹🎺 40 songs',
  'All set 🙌 see you Saturday 😄😁🥳',
];

/// The whole message as one string. Kept flat so the reveal is a single
/// substring rather than a per line state machine.
final String _kMessage = _kLines.join('\n');

/// The message split into grapheme clusters, so the reveal never cuts an
/// emoji in half.
///
/// A Dart string is UTF-16, and an emoji is rarely one code unit: a flag is
/// two regional indicators, a family is four people joined by zero width
/// joiners, and a waving hand with a skin tone carries a modifier. Slicing by
/// code unit lands mid sequence and the label renders a broken box or the
/// wrong emoji for a frame. This walks the string once at startup and groups
/// the pieces that must stay together.
final List<String> _kClusters = _splitGraphemes(_kMessage);

List<String> _splitGraphemes(String s) {
  const zwj = 0x200D;
  const varSel16 = 0xFE0F;
  const combiningEnclosingKeycap = 0x20E3;
  bool isRegionalIndicator(int r) => r >= 0x1F1E6 && r <= 0x1F1FF;
  bool isSkinTone(int r) => r >= 0x1F3FB && r <= 0x1F3FF;

  final runes = s.runes.toList();
  final out = <String>[];
  var i = 0;
  while (i < runes.length) {
    final start = i;
    i++;
    // A flag is exactly two regional indicators; take the pair together.
    if (isRegionalIndicator(runes[start]) &&
        i < runes.length &&
        isRegionalIndicator(runes[i])) {
      i++;
    } else {
      // Absorb everything that modifies or joins onto the base character:
      // skin tones, the emoji presentation selector, keycap marks, and any
      // zero width joiner followed by the glyph it joins.
      while (i < runes.length) {
        final r = runes[i];
        if (r == varSel16 || r == combiningEnclosingKeycap || isSkinTone(r)) {
          i++;
        } else if (r == zwj && i + 1 < runes.length) {
          i += 2;
        } else {
          break;
        }
      }
    }
    out.add(String.fromCharCodes(runes.sublist(start, i)));
  }
  return out;
}

class TextTypewriterDemo extends StatefulWidget {
  const TextTypewriterDemo({super.key});

  @override
  State<TextTypewriterDemo> createState() => _TextTypewriterDemoState();
}

class _TextTypewriterDemoState extends State<TextTypewriterDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _type;

  /// How many clusters are on screen. Derived from the controller each
  /// frame, but stored so a rebuild only happens when the count changes:
  /// the controller ticks at 60fps while the text gains a character about
  /// 25 times a second.
  int _shown = 0;

  /// Blinks the caret while typing.
  bool _caretOn = true;

  /// Typing runs at a steady rate rather than over a fixed duration, so a
  /// longer message simply takes longer instead of typing faster.
  static const _clustersPerSecond = 26.0;

  @override
  void initState() {
    super.initState();
    _applyPaperChrome();
    final seconds = _kClusters.length / _clustersPerSecond;
    _type = AnimationController(
      vsync: this,
      // The tail of the loop is a pause on the finished message before it
      // starts over, long enough to read the whole note.
      duration: Duration(milliseconds: ((seconds + 6.0) * 1000).round()),
    )
      ..addListener(_onTick)
      ..repeat();
  }

  void _onTick() {
    final elapsed = _type.value * _type.duration!.inMilliseconds / 1000;
    final next =
        (elapsed * _clustersPerSecond).floor().clamp(0, _kClusters.length);
    // The caret blinks twice a second while there is still text to come.
    final caret =
        next >= _kClusters.length ? true : (elapsed * 2).floor().isEven;
    if (next != _shown || caret != _caretOn) {
      setState(() {
        _shown = next;
        _caretOn = caret;
      });
    }
  }

  @override
  void dispose() {
    _type.dispose();
    super.dispose();
  }

  /// The visible message. The caret is a character in the same string, so it
  /// sits on the baseline the platform chose instead of being positioned by
  /// hand.
  String get _visible {
    final text = _kClusters.take(_shown).join();
    if (_shown >= _kClusters.length) return text;
    return _caretOn ? '$text▌' : text;
  }

  void _applyPaperChrome() {
    // The note is yellow under either theme, so the status bar icons are
    // always the dark set here: the palette's own choice would go invisible
    // on paper in a dark theme.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  /// The block of writing on the note.
  ///
  /// On iOS 26 it is the real Liquid Glass material, so the yellow of the
  /// note reads through the writing block the way the system does it.
  /// Everywhere else it stays white paper: Liquid Glass is iOS-26 only and
  /// [GlassEffectContainer] deliberately renders NO background elsewhere,
  /// which would leave the ink sitting straight on the note.
  Widget _writingBlock() {
    const padding = EdgeInsets.fromLTRB(18, 16, 18, 16);
    final text = Text(
      _visible,
      style: const TextStyle(color: _kInk, fontSize: 17, height: 1.55),
    );

    if (isIOS26) {
      return GlassEffectContainer(
        borderRadius: BorderRadius.circular(14),
        // The note is light by design. Left to follow the system, the glass
        // would go dark under a dark theme and swallow the dark ink.
        brightness: Brightness.light,
        child: Padding(padding: padding, child: text),
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _kPaper,
        borderRadius: BorderRadius.circular(14),
        // A short, close shadow: a sheet resting on the note, not a card
        // floating above a screen.
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F6B5A17),
            offset: Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _kClusters.isEmpty ? 1.0 : _shown / _kClusters.length;
    return Scaffold(
      // The desk shows through the folded corner, and under the note's
      // bottom edge on a home-indicator phone.
      backgroundColor: _kDesk,
      appBar: AppBar(
        title: const Text(
          'Live Text',
          style: TextStyle(
            color: _kInk,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Same paper as the body, so the note runs up behind the bar
        // instead of starting below it.
        backgroundColor: _kNote,
      ),
      body: Container(
        color: _kNote,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Real native text, typing itself.',
                style: TextStyle(
                  color: _kInkSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _writingBlock(),
              ),
            ),
            const SizedBox(height: 14),
            _ProgressLine(progress: progress),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'What to notice',
                    style: TextStyle(
                      color: _kInkSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '• Real native text, laid out by the platform\n'
                    '• Emoji from this device, perfect size and metrics\n'
                    '• The fold is native CustomPaint, not an image\n'
                    '• Typing updates a real native label each frame',
                    style: TextStyle(
                      color: _kInkSoft,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            // The folded corner closes the note. Last row, hard against the
            // bottom-right, so the crease meets both edges.
            Row(
              children: const [
                Expanded(child: SizedBox()),
                CustomPaint(
                  size: Size(_kFoldSize, _kFoldSize),
                  painter: _FoldPainter(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Side of the square the fold is drawn in, at the note's bottom-right.
const double _kFoldSize = 88;

/// The dog-ear.
///
/// Two triangles inside a square at the corner. The lower-right half is the
/// piece of note that is no longer there, so it is painted in the desk
/// colour; the upper-left half is that same piece folded back along the
/// diagonal, showing the paper's other side.
class _FoldPainter extends CustomPainter {
  const _FoldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // The corner the note lost. Opaque, so it covers the paper under it.
    final cut = Path()
      ..moveTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      cut,
      Paint()
        ..style = PaintingStyle.fill
        ..color = _kDesk,
    );

    // Shadow the raised paper throws on the desk, strongest at the crease
    // where the fold lifts and gone by the corner.
    canvas.drawPath(
      cut,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, h * 0.5),
          Offset(w, h),
          const [Color(0x38000000), Color(0x00000000)],
        ),
    );

    // The flap: the same triangle mirrored across the crease. Shaded from the
    // crease outwards, where a curled corner catches the light.
    final flap = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      flap,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, h * 0.5),
          const Offset(0, 0),
          const [_kFlapCrease, _kFlapTip],
        ),
    );

    // The crease itself.
    canvas.drawLine(
      Offset(w, 0),
      Offset(0, h),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _kCrease,
    );
  }

  @override
  bool shouldRepaint(_FoldPainter oldDelegate) => false;
}

/// A hairline that fills as the message types, so the loop reads as
/// deliberate rather than stalled during the pause at the end.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          // A ruled line on the paper, filled in as the message is written.
          color: const Color(0x1A6B5A17),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            Expanded(
              flex: math.max(1, (progress * 1000).round()),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4B6BD6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              flex: math.max(1, ((1 - progress) * 1000).round()),
              child: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
