/// Small pieces the Spotify screens share: the scrolling title, the
/// progress bar, the queue icon and the round buttons.
library;

import 'package:dartnative/dartnative.dart';

import '../music/music_player.dart' show formatTime;
import 'spotify_data.dart';
import 'spotify_player.dart';

// ── Scrolling title ─────────────────────────────────────────────────────────

/// A one-line title that scrolls sideways when it does not fit, fading out
/// at the edges, the way the player shows a long song name. A title that
/// fits is plain text.
///
/// The text is laid out once and moved with a transform; a [ShaderMask]
/// fades the edges over whatever is behind, the video included. Nothing
/// is redrawn while the title moves.
class SpMarquee extends StatefulWidget {
  const SpMarquee({
    super.key,
    required this.text,
    required this.size,
    required this.width,
    this.weight = 'Regular',
    this.color = kSpWhite,
    this.fadeStart = 0,
    this.fadeEnd = 28,
  });

  final String text;
  final double size;

  /// The box the title runs in.
  final double width;
  final String weight;
  final Color color;

  /// Width of the fade at each edge. The left edge stays sharp until the
  /// title first moves.
  final double fadeStart;
  final double fadeEnd;

  @override
  State<SpMarquee> createState() => _SpMarqueeState();
}

class _SpMarqueeState extends State<SpMarquee> {
  /// Points per second, and the pause before each pass.
  static const double _speed = 26;
  static const Duration _pause = Duration(milliseconds: 1600);
  static const double _gap = 48;

  static const _fade = [
    Color(0x00FFFFFF),
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0x00FFFFFF),
  ];

  Ticker? _ticker;
  final ValueNotifier<double> _offset = ValueNotifier(0);
  double _textWidth = 0;

  double get _lineHeight => widget.size * 1.2;

  TextStyle get _style => TextStyle(
        fontFamily: 'Figtree-${widget.weight}',
        fontSize: widget.size,
        color: widget.color,
      );

  @override
  void initState() {
    super.initState();
    _measure();
  }

  @override
  void didUpdateWidget(SpMarquee old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text ||
        old.size != widget.size ||
        old.weight != widget.weight) {
      _measure();
    }
  }

  void _measure() {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: _style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 4000);
    _textWidth = tp.width;
  }

  void _run(double boxWidth) {
    if (_textWidth <= boxWidth) {
      _ticker?.dispose();
      _ticker = null;
      _offset.value = 0;
      return;
    }
    if (_ticker != null) return;
    final cycle = _textWidth + _gap;
    final pauseS = _pause.inMilliseconds / 1000;
    _ticker = Ticker((elapsed) {
      final t = elapsed.inMilliseconds / 1000;
      final period = pauseS + cycle / _speed;
      final inPeriod = t % period;
      _offset.value = inPeriod < pauseS ? 0.0 : (inPeriod - pauseS) * _speed;
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _offset.dispose();
    super.dispose();
  }

  Widget _copy(double left) => Positioned(
        left: left,
        top: 0,
        // A point of room so a rounding difference never wraps the line.
        width: _textWidth + 1,
        child: Text(widget.text, style: _style, maxLines: 1, softWrap: false),
      );

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    _run(w);
    final h = _lineHeight;
    if (_textWidth <= w) {
      return SizedBox(
        width: w,
        height: h,
        child: Text(widget.text, style: _style, maxLines: 1, softWrap: false),
      );
    }
    final line = Stack(children: [_copy(0), _copy(_textWidth + _gap)]);
    return ValueListenableBuilder<double>(
      valueListenable: _offset,
      child: line,
      builder: (context, offset, line) {
        final fadeStart = offset > 0 ? widget.fadeEnd : widget.fadeStart;
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: _fade,
            stops: [
              0,
              (fadeStart / w).clamp(0.0, 0.5),
              1 - widget.fadeEnd / w,
              1
            ],
          ).createShader(bounds),
          child: SizedBox(
            width: w,
            height: h,
            child: Transform.translate(offset: Offset(-offset, 0), child: line),
          ),
        );
      },
    );
  }
}

// ── Progress bar ────────────────────────────────────────────────────────────

/// The scrub bar with elapsed and remaining time under it. Drag or tap to
/// seek; while the finger is down the thumb follows it and the song waits.
class SpProgress extends StatefulWidget {
  const SpProgress({
    super.key,
    required this.width,
    this.timeColor = kSpMuted,
    this.trackColor = kSpTrack,
  });

  final double width;
  final Color timeColor;
  final Color trackColor;

  /// Height of the whole control: the bar's touch band and the times,
  /// whose centre line is 14 pt under the bar's.
  static const double height = 31.5;

  /// Distance from the control's top to the bar's centre line.
  static const double barCenter = 8;

  @override
  State<SpProgress> createState() => _SpProgressState();
}

class _SpProgressState extends State<SpProgress> {
  double? _scrub;

  double _fraction(Duration pos, Duration total) {
    final t = total.inMilliseconds;
    if (t <= 0) return 0;
    return (pos.inMilliseconds / t).clamp(0.0, 1.0);
  }

  void _seekTo(double localX, double width, Duration total) {
    final f = (localX / width).clamp(0.0, 1.0);
    setState(() => _scrub = f);
  }

  @override
  Widget build(BuildContext context) {
    final player = SpotifyPlayer.instance;
    final width = widget.width;
    return ValueListenableBuilder<SpState>(
      valueListenable: player.state,
      builder: (_, state, __) => ValueListenableBuilder<Duration>(
        valueListenable: player.position,
        builder: (_, pos, __) {
          final total = state.duration;
          final f = _scrub ?? _fraction(pos, total);
          final shown = _scrub == null
              ? pos
              : Duration(milliseconds: (f * total.inMilliseconds).round());
          final remaining = total - shown;
          final x = f * width;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) {
              if (total == Duration.zero) return;
              player.beginScrub();
              _seekTo(d.localPosition.dx, width, total);
            },
            onHorizontalDragUpdate: (d) {
              if (total == Duration.zero) return;
              _seekTo(d.localPosition.dx, width, total);
            },
            onHorizontalDragEnd: (_) {
              final s = _scrub;
              if (s == null) return;
              setState(() => _scrub = null);
              player.endScrub(
                Duration(milliseconds: (s * total.inMilliseconds).round()),
              );
            },
            onTapUp: (d) {
              if (total == Duration.zero) return;
              final to = (d.localPosition.dx / width).clamp(0.0, 1.0);
              player.seek(
                Duration(milliseconds: (to * total.inMilliseconds).round()),
              );
            },
            child: SizedBox(
              width: width,
              height: SpProgress.height,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: SpProgress.barCenter - 1.5,
                    height: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.trackColor,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: SpProgress.barCenter - 1.5,
                    width: x,
                    height: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: kSpWhite,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (x - 6).clamp(0.0, width - 12),
                    top: SpProgress.barCenter - 6,
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: kSpWhite,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Text(
                      formatTime(shown),
                      style: spText(12, color: widget.timeColor),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Text(
                      total == Duration.zero
                          ? '-0:00'
                          : '-${formatTime(remaining)}',
                      style: spText(12, color: widget.timeColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Icons and buttons ───────────────────────────────────────────────────────

/// Spotify's line icons that the icon fonts draw differently: shuffle,
/// repeat, the device picker and the queue. Drawn in a 32 pt box, the
/// size they were traced at, and scaled to [size].
enum SpGlyphKind { shuffle, repeat, devices, queue, flag }

class SpGlyph extends StatelessWidget {
  const SpGlyph(this.kind, {super.key, this.size = 32, this.color = kSpWhite});

  final SpGlyphKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GlyphPainter(kind, color),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.kind, this.color);

  final SpGlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 32;
    Offset o(double x, double y) => Offset(x * k, y * k);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (kind) {
      case SpGlyphKind.repeat:
        // A rounded loop open at the bottom left, its end an arrow.
        final p = Path()..moveTo(10.6 * k, 23.9 * k);
        _corner(p, o(10.5, 23.9), o(6.1, 23.9), o(6.1, 19.5));
        p.lineTo(6.1 * k, 11.3 * k);
        _corner(p, o(6.1, 11.3), o(6.1, 6.9), o(10.5, 6.9));
        p.lineTo(22.3 * k, 6.9 * k);
        _corner(p, o(22.3, 6.9), o(26.7, 6.9), o(26.7, 11.3));
        p.lineTo(26.7 * k, 19.5 * k);
        _corner(p, o(26.7, 19.5), o(26.7, 23.9), o(22.3, 23.9));
        p.lineTo(13.6 * k, 23.9 * k);
        canvas.drawPath(p, line);
        canvas.drawPath(
          Path()
            ..moveTo(17.2 * k, 20.6 * k)
            ..lineTo(13.6 * k, 23.9 * k)
            ..lineTo(17.2 * k, 27.2 * k),
          line,
        );
      case SpGlyphKind.devices:
        // A phone's edge beside a speaker.
        final phone = Path()..moveTo(11.3 * k, 8.9 * k);
        phone.lineTo(8.3 * k, 8.9 * k);
        _corner(phone, o(8.3, 8.9), o(6.9, 8.9), o(6.9, 10.3));
        phone.lineTo(6.9 * k, 18.6 * k);
        _corner(phone, o(6.9, 18.6), o(6.9, 20), o(8.3, 20));
        phone.lineTo(10 * k, 20 * k);
        canvas.drawPath(phone, line);
        canvas.drawCircle(o(10.3, 23.6), 0.9 * k, Paint()..color = color);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(14.4 * k, 8 * k, 25.2 * k, 23.9 * k), 1.9 * k),
          line,
        );
        canvas.drawCircle(o(19.8, 12.6), 1.1 * k, line);
        canvas.drawCircle(o(19.8, 18.4), 2.5 * k, line);
      case SpGlyphKind.shuffle:
        // Two crossing curves ending in arrows; the one going down breaks
        // where it passes under the other.
        Offset bez(Offset a, Offset b, Offset c, Offset d, double t) {
          final u = 1 - t;
          return a * (u * u * u) +
              b * (3 * u * u * t) +
              c * (3 * u * t * t) +
              d * (t * t * t);
        }
        void curve(Offset a, Offset b, Offset c, Offset d,
            {double gapFrom = 2, double gapTo = 2}) {
          Path? path;
          for (var i = 0; i <= 24; i++) {
            final t = i / 24;
            final pt = bez(a, b, c, d, t);
            if (t > gapFrom && t < gapTo) {
              if (path != null) canvas.drawPath(path, line);
              path = null;
              continue;
            }
            if (path == null) {
              path = Path()..moveTo(pt.dx, pt.dy);
            } else {
              path.lineTo(pt.dx, pt.dy);
            }
          }
          if (path != null) canvas.drawPath(path, line);
        }
        curve(o(4.4, 22.8), o(14.5, 22.8), o(16.5, 10), o(26.4, 10));
        curve(o(4.4, 10), o(14.5, 10), o(16.5, 22.8), o(26.4, 22.8),
            gapFrom: 0.4, gapTo: 0.62);
        for (final y in [10.0, 22.8]) {
          canvas.drawPath(
            Path()
              ..moveTo(23.3 * k, (y - 3.3) * k)
              ..lineTo(26.6 * k, y * k)
              ..lineTo(23.3 * k, (y + 3.3) * k),
            line,
          );
        }
      case SpGlyphKind.flag:
        // A pennant on a pole, notched at its free end.
        canvas.drawLine(o(9.5, 7), o(9.5, 26.5), line);
        canvas.drawPath(
          Path()
            ..moveTo(9.5 * k, 7.5 * k)
            ..lineTo(24.5 * k, 7.5 * k)
            ..lineTo(19.8 * k, 12.9 * k)
            ..lineTo(24.5 * k, 18.3 * k)
            ..lineTo(9.5 * k, 18.3 * k),
          line,
        );
      case SpGlyphKind.queue:
        // A rounded bar over two lines.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(9 * k, 10.9 * k, 23.4 * k, 15.1 * k), 2.1 * k),
          line,
        );
        canvas.drawLine(o(9, 18.4), o(23.4, 18.4), line);
        canvas.drawLine(o(9, 23.1), o(23.4, 23.1), line);
    }
  }

  /// A quarter-circle turn from [from] to [to] around the corner [vertex],
  /// drawn as the usual cubic approximation of a circle.
  static void _corner(Path p, Offset from, Offset vertex, Offset to) {
    const c = 0.5523;
    p.lineTo(from.dx, from.dy);
    p.cubicTo(
      from.dx + (vertex.dx - from.dx) * c,
      from.dy + (vertex.dy - from.dy) * c,
      to.dx + (vertex.dx - to.dx) * c,
      to.dy + (vertex.dy - to.dy) * c,
      to.dx,
      to.dy,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.kind != kind || old.color != color;
}

/// A round button: a filled circle with a glyph in its centre.
class SpCircleButton extends StatelessWidget {
  const SpCircleButton({
    super.key,
    required this.diameter,
    required this.color,
    required this.child,
    this.onTap,
  });

  final double diameter;
  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// The green tick of a saved song; a ring when it is not saved.
class SpLikedButton extends StatelessWidget {
  const SpLikedButton({super.key, this.diameter = 30});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final player = SpotifyPlayer.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: player.liked,
      builder: (_, liked, __) => GestureDetector(
        onTap: player.toggleLiked,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: liked ? kSpGreen : const Color(0x00000000),
            shape: BoxShape.circle,
            border: liked ? null : Border.all(color: kSpMuted, width: 1.5),
          ),
          alignment: Alignment.center,
          child: liked
              ? CustomPaint(
                  size: Size(diameter, diameter),
                  painter: const _CheckPainter(),
                )
              : Icon(CupertinoIcons.plus,
                  size: diameter * 0.62, color: kSpMuted),
        ),
      ),
    );
  }
}

/// The tick inside the green circle: a heavy black check.
class _CheckPainter extends CustomPainter {
  const _CheckPainter();

  @override
  void paint(Canvas canvas, Size s) {
    final d = s.width;
    canvas.drawPath(
      Path()
        ..moveTo(d * 0.29, d * 0.51)
        ..lineTo(d * 0.44, d * 0.65)
        ..lineTo(d * 0.71, d * 0.36),
      Paint()
        ..color = kSpBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = d * 0.085
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => false;
}

/// The outlined pill of Follow and Save.
class SpPillButton extends StatefulWidget {
  const SpPillButton({
    super.key,
    required this.label,
    this.activeLabel,
    this.icon,
    this.width = 73.3,
    this.height = 34,
  });

  final String label;
  final String? activeLabel;
  final IconData? icon;
  final double width;
  final double height;

  @override
  State<SpPillButton> createState() => _SpPillButtonState();
}

class _SpPillButtonState extends State<SpPillButton> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final label = _on ? (widget.activeLabel ?? widget.label) : widget.label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _on = !_on);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(color: kSpOutline, width: 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(_on ? CupertinoIcons.checkmark_circle_fill : widget.icon!,
                  size: 18, color: _on ? kSpGreen : kSpWhite),
              const SizedBox(width: 8),
            ],
            Text(label, style: spText(13.7, weight: 'Bold')),
          ],
        ),
      ),
    );
  }
}
