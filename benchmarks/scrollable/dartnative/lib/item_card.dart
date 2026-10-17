/// One card of the feed: the same layout, colours and interactions as
/// Legend List's example card (dark palette): an avatar, the author line, a
/// title, one to twelve sentences of text, a footer, tap to expand the text,
/// and a swipe to the left that reveals a "Complete" action.
library;
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import 'card_data.dart';

const Color kScreenBackground = Color(0xFF445566);
/// The React Native app's stack header follows the system theme with React
/// Navigation's card colour: #121212 in dark mode, white in light mode.
Color headerBackground(BuildContext context) =>
    MediaQuery.of(context).platformBrightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFFFFFFF);
const Color kHeaderBox = Color(0xFF456AAA);
const Color _outerBackground = Color(0xFF050505);
const Color _cardBackground = Color(0xFF141414);
const Color _border = Color(0xFF323232);
const Color _divider = Color(0xFF1F1F1F);
const Color _success = Color(0xFF22C55E);
const Color _textPrimary = Color(0xFFF4F4F5);
const Color _textSecondary = Color(0xFFD4D4D8);
const Color _textMuted = Color(0xFF9CA3AF);

/// The 100 × 100 box the example puts at the top of the list.
class ListHeaderBox extends StatelessWidget {
  const ListHeaderBox({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: kHeaderBox,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}

class ItemCard extends StatefulWidget {
  const ItemCard({
    super.key,
    required this.data,
    required this.width,
    this.advanced = false,
  });

  final CardData data;

  /// The width the card is drawn at: its column's width less the 12-point
  /// padding on each side. Given explicitly because DartNative's Stack does
  /// not stretch its child to the width as Flutter's does.
  final double width;

  /// The benchmark's advanced mode: one to forty sentences, a short card
  /// beside a long one, and a horizontal rail of ten images inside every
  /// card, a list inside a recycled list.
  final bool advanced;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _expanded = false;

  /// With `recycleItems`, a row's widgets are reused for the next item that
  /// scrolls in, so the expanded state belongs to the item, not the row: it
  /// resets when the row shows another card (the example's
  /// `useRecyclingState` does the same).
  @override
  void didUpdateWidget(ItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.index != widget.data.index) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    // The example's border is two hairlines: two device pixels.
    final borderWidth = 2 / MediaQuery.of(context).devicePixelRatio;
    return Container(
      color: _outerBackground,
      padding: const EdgeInsets.all(12),
      child: _SwipeToReveal(
        itemIndex: d.index,
        width: widget.width,
        child: GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border, width: borderWidth),
              // On Android the example's card has `elevation: 4`, Android's
              // own view shadow (React Native ignores the iOS shadow fields
              // there); this BoxShadow draws the same shadow. On iOS the
              // example's `overflow: hidden` clips its shadow away, so there
              // is none.
              boxShadow: Platform.isAndroid
                  ? const [
                      BoxShadow(
                        color: Color(0x38000000),
                        offset: Offset(0, 6),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Image.network(d.avatarUrl, fit: BoxFit.cover),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.authorName,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            d.timestamp,
                            style: const TextStyle(
                                color: _textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  d.title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.advanced
                      ? (_expanded ? '${d.longBody}${d.longBody}' : d.longBody)
                      : (_expanded ? '${d.body}${d.body}' : d.body),
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
                if (widget.advanced) ...[
                  const SizedBox(height: 12),
                  _ImageRail(urls: d.railUrls),
                ],
                // The example's footer has a 1-pt top border; DartNative's
                // Container draws uniform borders only, so the line is its
                // own 1-pt view.
                const SizedBox(height: 12),
                Container(height: 1, color: _divider),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Text('❤️ 42',
                        style: TextStyle(color: _textMuted, fontSize: 14)),
                    SizedBox(width: 16),
                    Text('💬 12',
                        style: TextStyle(color: _textMuted, fontSize: 14)),
                    SizedBox(width: 16),
                    Text('🔄 8',
                        style: TextStyle(color: _textMuted, fontSize: 14)),
                  ],
                ),
                if (widget.advanced) ...[
                  const SizedBox(height: 8),
                  _PerfLine(data: d),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Advanced mode: the result line of the example's PERF_TEST work, done
/// in this build as the example does it in its render.
class _PerfLine extends StatelessWidget {
  const _PerfLine({required this.data});

  final CardData data;

  @override
  Widget build(BuildContext context) {
    final (prime, fib) = data.perfTest();
    return Text(
      '🧮 Prime: ${prime ? '✓' : '✗'} | Fib: $fib',
      style: const TextStyle(color: _textMuted, fontSize: 14),
    );
  }
}

/// Advanced mode's rail: ten square images in a horizontal list, 80 points
/// a side with 8 between, scrolling on its own inside the card.
class _ImageRail extends StatelessWidget {
  const _ImageRail({required this.urls});

  final List<String> urls;

  static const double _side = 80;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _side,
        child: FastList(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          itemExtent: _side + _gap,
          itemBuilder: (context, i) => Padding(
            padding: EdgeInsets.only(right: i == urls.length - 1 ? 0 : _gap),
            child: Container(
              width: _side,
              height: _side,
              decoration: BoxDecoration(
                color: _divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.network(urls[i], fit: BoxFit.cover),
            ),
          ),
        ),
      );
}

/// Swipe left to reveal an 80-point "Complete" action, as the example's
/// `Swipeable` does. The action is built with the card. Released past half
/// the action's width, the card settles open, otherwise it settles closed,
/// and the drag may go past the action's width.
class _SwipeToReveal extends StatefulWidget {
  const _SwipeToReveal({
    required this.itemIndex,
    required this.width,
    required this.child,
  });

  /// The item shown; a reused row closes its action when this changes.
  final int itemIndex;
  final double width;
  final Widget child;

  @override
  State<_SwipeToReveal> createState() => _SwipeToRevealState();
}

class _SwipeToRevealState extends State<_SwipeToReveal>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 80;

  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..addListener(() => setState(() => _dx = _settleTween.evaluate(_settle)));
  Tween<double> _settleTween = Tween(begin: 0, end: 0);
  double _dx = 0;

  @override
  void didUpdateWidget(_SwipeToReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemIndex != widget.itemIndex && _dx != 0) {
      _settle.stop();
      _dx = 0;
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _dragUpdate(DragUpdateDetails details) {
    _settle.stop();
    setState(() => _dx = (_dx + details.delta.dx).clamp(double.negativeInfinity, 0));
  }

  void _dragEnd(DragEndDetails details) {
    final target = _dx < -_actionWidth / 2 ? -_actionWidth : 0.0;
    _settleTween = Tween(begin: _dx, end: target);
    _settle
      ..reset()
      ..animateTo(1, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _success,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: _actionWidth,
              child: GestureDetector(
                onTap: () => debugPrint('Marked as complete'),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(MaterialSymbolsRounded.check_circle_filled,
                        color: Color(0xFFFFFFFF), size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Complete',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: widget.width,
              child: GestureDetector(
                onHorizontalDragUpdate: _dragUpdate,
                onHorizontalDragEnd: _dragEnd,
                child: Transform.translate(
                  offset: Offset(_dx, 0),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      );
}
