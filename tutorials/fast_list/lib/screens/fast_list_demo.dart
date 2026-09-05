/// FastList demo — native scrolling + the full bounded-memory recipe, with
/// live perf numbers.
///
/// Starts at 50 rows (fast mount) and paginates to 10,000 via onScroll.
/// Two flavors:
///  - "Text"   — plain text rows: the classic smooth-scroll case.
///  - "Images" — photo rows decoded at CELL size (`cacheWidth`, ~0.3 MB each)
///    with `keepAliveCount: 30` (content windowing): held content is bounded
///    to O(visible + 2·keepAliveCount), independent of itemCount, so RSS
///    stays flat AND small scrolling end-to-end. Scroll back up: rows rebuild
///    ahead of arrival — no seam.
///
/// Flip [_fullRes] to stress-test windowing with full-resolution 800² bitmaps
/// (~2.5 MB decoded each): RSS then plateaus at the window's cost
/// (held rows × ~2.4 MiB) instead of
/// accumulating every bitmap toward OOM.
///
/// The result line + [DN-BENCH] log show mount time and resident memory;
/// [DN-ka] (verbose) traces the window's rebuild/dispose batches.
///
/// ⚠️ When judging scroll smoothness, run with `verbose: false` (see
/// `DartNativeLogger` in main.dart) — verbose framework logging prints dozens
/// of lines per page load on the main thread and creates jank that has
/// nothing to do with the list itself. Profile/release mode for real numbers.
import 'dart:io' show ProcessInfo;

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class FastListDemo extends StatefulWidget {
  const FastListDemo({super.key});

  @override
  State<FastListDemo> createState() => _FastListDemoState();
}

class _FastListDemoState extends State<FastListDemo> {
  // Pagination (the third lever): start with 50 rows — still a fast mount —
  // and grow from onScroll as the user nears the end, up to 10,000 (picsum's
  // seed/ URLs accept any string, so the URL space is unbounded). Initial 50
  // + a 4-viewport fetch threshold keeps pages ready ahead of the scroll even
  // on slow debug-mode Android.
  static const int _initial = 50;
  static const int _page = 50;
  static const int _max = 10000;
  int _count = _initial;
  bool _growing = false;

  String _type = 'Text';
  int _buildId = 0;
  String _result = 'Pick a flavor — mount time & RSS appear here.';

  // Memory harness: flip to decode Images rows at FULL resolution (no
  // cacheWidth) — the heavy-bitmap stress test for content windowing. Off =
  // production-correct sizing (decode at cell size).
  static const bool _fullRes = false;

  // Index-based programmatic scrolling (ScrollTo #4 in the topbar) — the
  // Fast-family replacement for a pixel ScrollController.
  final _listController = FastListController();

  // Process RSS at screen entry, BEFORE any list content mounts. The absolute
  // RSS is dominated by everything that isn't the list (app baseline: debug
  // VM, verbose logging, Skia, plugins, home screen) — the Δ against this
  // measured snapshot is what the list actually costs. A measured reference,
  // not a magic constant: it travels with device/mode/session automatically.
  late int _baselineRssBytes;

  /// "RSS=219MB (Δ+24MB)" — absolute + measured-baseline delta.
  String _rssLabel() {
    final rss = ProcessInfo.currentRss;
    final mb = (rss / 1048576).toStringAsFixed(0);
    final deltaMb = ((rss - _baselineRssBytes) / 1048576).round();
    final sign = deltaMb < 0 ? '−' : '+';
    return 'RSS=${mb}MB (Δ$sign${deltaMb.abs()}MB)';
  }

  @override
  void initState() {
    super.initState();
    // Make Δ reproducible: clear the in-memory image caches BEFORE capturing
    // the RSS baseline. Otherwise a revisit measures against a baseline that
    // already contains the caches retained by the previous visit, and Δ
    // under-reports the list's true cost. The disk cache is untouched, so
    // images still load in ~1 ms. Do the same in your own memory harnesses.
    ImageCache.clearMemory();
    _baselineRssBytes = ProcessInfo.currentRss;
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
  }

  // Remount the list (new key) and measure setState → first-frame (the
  // user-visible build cost) plus resident memory after.
  void _run(String type) {
    // Re-baseline on every run (same clear-then-snapshot as entry). This also
    // self-heals the reading after a hot restart, where the entry baseline is
    // captured mid-teardown of the previous session's memory and Δ would
    // otherwise over-report by the re-attributed baseline (~20-30MB).
    ImageCache.clearMemory();
    _baselineRssBytes = ProcessInfo.currentRss;
    final sw = Stopwatch()..start();
    setState(() {
      _type = type;
      _count = _initial;
      _buildId++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sw.stop();
      if (!mounted) return;
      final line =
          '$type · N=$_count · mount=${sw.elapsedMilliseconds}ms · ${_rssLabel()}';
      dnLog('[DN-BENCH] $line');
      setState(() => _result = line);
    });
  }

  // Load-more — grow the count when within 4 viewports of the end (early, so
  // pages are built before the scroll reaches them). Guarded + deferred past
  // the scroll frame (mirrors the grid demo's pattern).
  void _onScroll(double offset, double maxExtent, double viewport, bool drag) {
    if (_growing || _count >= _max) return;
    if (maxExtent - offset > 4.0 * viewport) return;
    _growing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _count = (_count + _page).clamp(0, _max);
        _growing = false;
        _result = '$_type · N=$_count · ${_rssLabel()}';
      });
    });
  }

  Widget _cell(int i) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
        ),
        alignment: Alignment.centerLeft,
        child: Text('Item $i',
            style: TextStyle(fontSize: 16, color: kTextPrimary)),
      );

  // Photo row. Production-correct decode sizing: cacheWidth ≈ 3× the 92-pt
  // cell (~0.3 MB decoded). With [_fullRes] the 800² source decodes whole
  // (~2.5 MB) — the windowing stress test.
  Widget _imgCell(int i) => Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: Image.network(
                // seed/ URLs always resolve (id/ has gaps → HTTP 404s).
                // Recycle ~100 distinct URLs — a fresh seed per row would
                // force a CDN-cold generation (~1-2 s) for every image,
                // which reads as endless shimmer.
                'https://picsum.photos/seed/dn${i % 100}/800/800',
                fit: BoxFit.cover,
                cacheWidth: _fullRes ? null : 280,
                cacheHeight: _fullRes ? null : 280,
                // Production recipe: rows beyond the thumb-cache recency
                // shimmer while their ~ms disk decode lands, instead of
                // flashing the bare cell background.
                // kTileBg, not kRowBg — on the dark row surface a kRowBg
                // shimmer is near-invisible and the thumb reads as empty.
                placeholder: Shimmer.fromColors(
                  baseColor: kTileBg,
                  highlightColor: kChipBg,
                  child: Container(color: kTileBg),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('Item $i',
                style: TextStyle(fontSize: 16, color: kTextPrimary)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final key = ValueKey('$_type-$_buildId');
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'FastList',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
        // FastListController.jumpToItem — scroll to item #4 by INDEX
        actions: [
          BarButtonItem(
            title: 'ScrollTo #4',
            titleStyle: TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            onPressed: () => _listController.jumpToItem(4),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedControl(
                  segments: const ['Text', 'Images'],
                  backgroundColor: kSegBg,
                  indicatorColor: kSegTint,
                  selectedIndex: _type == 'Images' ? 1 : 0,
                  onValueChanged: (i) => _run(i == 0 ? 'Text' : 'Images'),
                  labelFontStyle: TextStyle(color: kTextSecondary),
                  selectedLabelFontStyle: TextStyle(color: kTextPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  _result,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _type == 'Images'
                      ? 'Image rows on the platform\'s native list: decoded '
                          'at cell size (cacheWidth) + keepAliveCount: 30 '
                          'content windowing. Δ = the list\'s true cost '
                          '(RSS minus a baseline captured at entry, after '
                          'clearing the memory image caches — so every '
                          'visit reads the same). Bounded by the live '
                          'window plus two small fixed caches. Typical: '
                          '14-20MB after a short fling, ~25-35MB after '
                          'browsing; a deep fast scroll plateaus — at any '
                          'depth. The leak signal is Δ that keeps '
                          'climbing past the plateau, not reaching it.'
                      : '50 → 10,000 rows via onScroll, recycled by the '
                          'platform\'s native list. RSS is the whole app — '
                          'mostly baseline (VM, plugins, home screen). '
                          'Δ = what THIS list adds since screen entry. '
                          'Text rows are featherweight: Δ stays a few MB '
                          'even at N=10,000.',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _type == 'Images'
                // The full long-image-list recipe: pagination (onScroll) +
                // content windowing (keepAliveCount): visible + 30 rows each
                // side stay built; farther rows release their content (slot
                // pinned at its measured height) and rebuild as you scroll
                // back. [DN-ka] traces the window.
                ? FastList(
                    key: key,
                    controller: _listController,
                    itemCount: _count,
                    keepAliveCount: 30,
                    stableItems: true, // append-only → O(page) load-more
                    onScroll: _onScroll,
                    itemBuilder: (_, i) => _imgCell(i),
                  )
                : FastList(
                    key: key,
                    controller: _listController,
                    itemCount: _count,
                    stableItems: true, // append-only → O(page) load-more
                    onScroll: _onScroll,
                    itemBuilder: (_, i) => _cell(i),
                  ),
          ),
        ],
      ),
    );
  }
}
