/// The cards under the player: About the artist, Explore, Credits, the live
/// event and Merch.
///
/// A text's vertical position is given by the centre of its capitals, the
/// way it was measured; Figtree puts that centre in the middle of its line
/// box, so a centre `c` for a text of line height `l` is a top of `c - l/2`.
library;

import 'package:dartnative/dartnative.dart';

import 'spotify_data.dart';
import 'spotify_widgets.dart';

/// [child] positioned with its first line's centre at [center].
Widget _textAt({
  required double left,
  double? right,
  required double center,
  required double lineHeight,
  required Widget child,
}) =>
    Positioned(
      left: left,
      right: right,
      top: center - lineHeight / 2,
      child: child,
    );

class _Card extends StatelessWidget {
  const _Card(
      {required this.height, required this.child, this.color = kSpCard});

  final double height;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // The page's colour across the full width: the video lies behind the
    // column and must not show beside the card.
    final layout = SpLayout.of(context);
    return Container(
      height: height,
      color: kSpBg,
      padding: EdgeInsets.only(
        left: layout.left + kSpMargin,
        right: layout.right + kSpMargin,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kSpCardRadius),
        child: Container(color: color, child: child),
      ),
    );
  }
}

/// A card's heading, with an optional green link on the right.
List<Widget> _heading(String title, double center, {String? link}) => [
      _textAt(
        left: kSpPad,
        center: center,
        lineHeight: 16.6 * 1.2,
        child: Text(title, style: spText(16.6, weight: 'Bold')),
      ),
      if (link != null)
        _textAt(
          left: 0,
          right: 17.3,
          center: center,
          lineHeight: 13.4 * 1.2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(link,
                style: spText(13.4, weight: 'Bold', color: kSpGreen)),
          ),
        ),
    ];

// ── About the artist ────────────────────────────────────────────────────────

class SpAboutCard extends StatelessWidget {
  const SpAboutCard({super.key});

  static const double _image = 225;

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 380,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: _image,
            child: Image.asset(kSpArtistPhoto, fit: BoxFit.cover),
          ),
          ..._heading('About the artist', 27),
          _textAt(
            left: kSpPad,
            center: _image + 33,
            lineHeight: 20.5 * 1.2,
            child: Text(kSpArtist, style: spText(20.5, weight: 'Bold')),
          ),
          _textAt(
            left: kSpPad,
            center: _image + 54,
            lineHeight: 13.9 * 1.2,
            child: Text(kSpListeners, style: spText(13.9, color: kSpGrey)),
          ),
          const Positioned(
            right: 17.3,
            top: _image + 25.3,
            child: SpPillButton(label: 'Follow', activeLabel: 'Following'),
          ),
          Positioned(
            left: kSpPad,
            right: kSpPad,
            top: _image + 89 - 18.3 / 2,
            child: const _Bio(),
          ),
        ],
      ),
    );
  }
}

/// Three lines of the biography ending in "see more".
class _Bio extends StatelessWidget {
  const _Bio();

  static const double _size = 13.9;
  static const double _line = 18.3;

  @override
  Widget build(BuildContext context) {
    final width = SpLayout.of(context).cardWidth - kSpPad * 2;
    final regular = spText(_size, color: kSpGrey, height: _line / _size);
    final bold = spText(_size, weight: 'Bold', height: _line / _size);
    return RichText(
      text: TextSpan(children: [
        TextSpan(text: _cut(kSpBio, width, regular), style: regular),
        TextSpan(text: 'see more', style: bold),
      ]),
    );
  }

  /// The longest start of [text] that leaves room for "... see more" on the
  /// third line.
  static String _cut(String text, double width, TextStyle style) {
    bool fits(String s) {
      final tp = TextPainter(
        // The bold "see more" runs wider than the regular face; the two
        // extra letters stand in for the difference.
        text: TextSpan(text: '$s... see moreMM', style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      return (tp.height / _line).round() <= 3;
    }

    if (fits(text)) return '$text ';
    var lo = 0, hi = text.length;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (fits(text.substring(0, mid))) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return '${text.substring(0, lo).trimRight()}... ';
  }
}

// ── Explore ─────────────────────────────────────────────────────────────────

class SpExploreCard extends StatelessWidget {
  const SpExploreCard({super.key});

  static const double _tileTop = 65;
  static const double _tileHeight = 257 - _tileTop - kSpPad;
  static const double _tileGap = 17.2;

  @override
  Widget build(BuildContext context) {
    final inner = SpLayout.of(context).cardWidth - kSpPad * 2;
    final tile = (inner - _tileGap * 2) / 3;
    return _Card(
      height: 257,
      child: Stack(
        children: [
          ..._heading('Explore $kSpArtist', 31),
          for (var i = 0; i < kSpExplore.length; i++)
            Positioned(
              left: kSpPad + i * (tile + _tileGap),
              top: _tileTop,
              width: tile,
              height: _tileHeight,
              child: _ExploreTile(kSpExplore[i]),
            ),
        ],
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile(this.tile);

  final SpExploreTile tile;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(tile.image, fit: BoxFit.cover)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 100,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x99000000)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 8,
            bottom: 12,
            child: Text(
              tile.label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: spText(14.6, weight: 'Bold', height: 18.3 / 14.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Credits ─────────────────────────────────────────────────────────────────

class SpCreditsCard extends StatelessWidget {
  const SpCreditsCard({super.key});

  static const double _firstRow = 66;
  static const double _rowPitch = 57.5;

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 235,
      child: Stack(
        children: [
          ..._heading('Credits', 27.5, link: 'Show all'),
          for (var i = 0; i < kSpCredits.length; i++) ...[
            _textAt(
              left: kSpPad,
              center: _firstRow + i * _rowPitch,
              lineHeight: 17 * 1.2,
              child: Text(kSpCredits[i].name, style: spText(17)),
            ),
            _textAt(
              left: kSpPad,
              center: _firstRow + i * _rowPitch + 21,
              lineHeight: 13.8 * 1.2,
              child: Text(kSpCredits[i].roles,
                  style: spText(13.8, color: kSpGrey)),
            ),
            if (kSpCredits[i].followable)
              Positioned(
                right: 17.3,
                top: _firstRow + i * _rowPitch - 8,
                child: const SpPillButton(
                    label: 'Follow', activeLabel: 'Following'),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Live event ──────────────────────────────────────────────────────────────

class SpEventCard extends StatelessWidget {
  const SpEventCard({super.key});

  static const double _image = 245.7;

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 344,
      color: kSpEventBody,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: _image,
            child: Image.asset(kSpEventImage, fit: BoxFit.cover),
          ),
          ..._heading('Live event', 27),
          _textAt(
            left: kSpPad,
            center: _image + 28,
            lineHeight: 20.5 * 1.2,
            child: Text(kSpEventArtist, style: spText(20.5, weight: 'Bold')),
          ),
          _textAt(
            left: kSpPad,
            center: _image + 53,
            lineHeight: 13.4 * 1.2,
            child: Text(kSpEventDate, style: spText(13.4)),
          ),
          _textAt(
            left: kSpPad,
            center: _image + 72,
            lineHeight: 13.8 * 1.2,
            child: Text(kSpEventVenue, style: spText(13.8, color: kSpGrey)),
          ),
          const Positioned(
            right: 17.3,
            top: _image + 31.5,
            child: SpPillButton(
              label: 'Save',
              activeLabel: 'Saved',
              icon: CupertinoIcons.plus_circle,
              width: 80.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Merch ───────────────────────────────────────────────────────────────────

class SpMerchCard extends StatelessWidget {
  const SpMerchCard({super.key});

  static const double _firstThumb = 63.4;
  static const double _rowPitch = 65.3;

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 194,
      child: Stack(
        children: [
          ..._heading('Merch', 31.7, link: 'Go to store'),
          for (var i = 0; i < kSpMerch.length; i++) ...[
            Positioned(
              left: kSpPad,
              top: _firstThumb + i * _rowPitch,
              width: 48,
              height: 48,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(kSpMerch[i].image, fit: BoxFit.cover),
              ),
            ),
            _textAt(
              left: kSpPad + 48 + 12,
              right: 48,
              center: _firstThumb + i * _rowPitch + 24,
              lineHeight: 16 * 1.2,
              child: Text(kSpMerch[i].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: spText(16)),
            ),
            Positioned(
              right: 22 - 5,
              top: _firstThumb + i * _rowPitch + 24 - 11,
              child: const Icon(CupertinoIcons.chevron_right,
                  size: 20, color: kSpWhite),
            ),
          ],
        ],
      ),
    );
  }
}
