/// Grid demo — showcases GridView.count and GridView.builder.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class GridDemo extends StatefulWidget {
  const GridDemo({super.key});

  @override
  State<GridDemo> createState() => _GridDemoState();
}

class _GridDemoState extends State<GridDemo> {
  int _tabIndex = 0;

  /// Which tabs have been opened at least once — a tab builds on its FIRST
  /// visit and stays mounted after (see the IndexedStack comment below).
  final List<bool> _visitedTabs = [true, false, false];

  // ── Infinite scroll state ──────────────────────────────────────────────────
  final List<String> _imageUrls = [];
  int _nextPage = 1;
  bool _isLastPage = false;
  bool _isFetching = false;
  static const _pageSize = 20;

  // Masonry tab load-more — procedural (picsum ids/heights are generated), so it
  // just grows the count as you scroll. Mirrors the Infinite-Grid pattern and
  // depth (windowing keeps memory flat regardless of how deep it grows).
  int _masonryCount = 20;
  bool _masonryGrowing = false;
  static const _masonryMax = 1000;

  // Index controllers — scroll-to-item by INDEX (the platform-correct way),
  // driven by the "ScrollTo #4" topbar button. Shared FastGridController type
  // works for both FastGrid and MasonryFastGrid.
  final _gridController = FastGridController();
  final _masonryController = FastGridController();
  final _httpClient = HttpClient();

  // Decode target for grid images (px, longest edge). An UNSET image
  // decodes at FULL source resolution on both platforms — always set it for
  // image cells. ~2× the ~130dp cell ≈ crisp + tiny.
  // (The heavy-image / full-res memory harness lives in the FastList demo.)
  static const int _kCacheSize = 300;

  // Gate the [DN-RSS] memory readout — flip in code when profiling image memory.
  // (Uses the app-level dnLog, so it prints regardless of `verbose:` — keep it
  // OFF outside profiling sessions.)
  bool _logRss = false;
  Timer? _rssTimer;

  /// RSS at screen entry — [DN-RSS] reports Δ against this so the readout
  /// shows what the grids cost, not the app baseline (see fast_list_demo).
  late final int _baselineRssBytes;

  @override
  void initState() {
    super.initState();
    _baselineRssBytes = ProcessInfo.currentRss;
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
    // Pre-fetch TWO pages: a single page (20 items ≈ 2.3 viewports at
    // 3 columns) sits inside the 2.5-viewport fetch threshold, which would
    // make the very first fling fetch and append mid-flight.
    _fetchNextPage(pages: 2);
    // Periodic resident-memory readout for image-memory profiling. Gated by
    // _logRss so normal runs stay quiet.
    if (_logRss) {
      _rssTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (!WidgetsBinding.instance.isForeground) return;
        final rss = ProcessInfo.currentRss;
        final mb = (rss / 1048576).toStringAsFixed(0);
        final deltaMb = ((rss - _baselineRssBytes) / 1048576).round();
        final sign = deltaMb < 0 ? '−' : '+';
        dnLog('[DN-RSS] ${mb}MB (Δ$sign${deltaMb.abs()}MB) · '
            'grid=${_imageUrls.length} masonry=$_masonryCount');
      });
    }
  }

  @override
  void dispose() {
    _rssTimer?.cancel();
    _httpClient.close();
    super.dispose();
  }

  // FastGrid.onScroll — the Fast-family replacement for a ScrollController
  // listener. Fires natively with (offset, maxExtent, viewport, dragging); fetch
  // the next page when within 2.5 viewports of the end. Only the Infinite-Grid
  // tab passes onScroll, so no tab guard is needed.
  void _onGridScroll(
    double offset,
    double maxExtent,
    double viewport,
    bool dragging,
  ) {
    if (_isFetching || _isLastPage) return;
    final remaining = maxExtent - offset;
    if (remaining > 2.5 * viewport) return;
    _fetchNextPage();
  }

  // Masonry load-more — grow the procedural count when near the end. Guarded so
  // the per-frame onScroll flood grows it once, deferred past the scroll frame.
  void _onMasonryScroll(
    double offset,
    double maxExtent,
    double viewport,
    bool dragging,
  ) {
    if (_masonryGrowing || _masonryCount >= _masonryMax) return;
    if (maxExtent - offset > 2.5 * viewport) return;
    _masonryGrowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _masonryCount = (_masonryCount + 20).clamp(0, _masonryMax);
        _masonryGrowing = false;
      });
    });
  }

  Future<void> _fetchNextPage({int pages = 1}) async {
    if (_isFetching || _isLastPage) return;

    // setState (not a bare flag): it keeps the Dart event loop pumping
    // while native scroll callbacks flood in, so the HTTP futures progress.
    setState(() => _isFetching = true);

    // Fetch [pages] sequentially, append ONCE: one deferred setState means one
    // grid update, however many pages the call covers (initState asks for 2).
    final newUrls = <String>[];
    var reachedEnd = false;
    try {
      for (var p = 0; p < pages && !reachedEnd; p++) {
        final uri = Uri.parse(
          'https://picsum.photos/v2/list?page=$_nextPage&limit=$_pageSize',
        );
        final request = await _httpClient.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != 200) break;
        final body = await response.transform(const Utf8Decoder()).join();
        final data = jsonDecode(body) as List<dynamic>;
        final urls = [
          for (final item in data)
            'https://picsum.photos/id/${(item as Map<String, dynamic>)['id']}/400/400',
        ];
        newUrls.addAll(urls);
        _nextPage++;
        if (urls.length < _pageSize) reachedEnd = true;
      }
    } catch (_) {}
    if (!mounted) return;

    // Defer the visual update (adding images to grid) until after the current
    // scroll frame completes. This avoids jank during active scrolling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _imageUrls.addAll(newUrls);
        if (reachedEnd) _isLastPage = true;
        _isFetching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        // Scroll-to-top: the platform's own gesture — tap the status bar
        // on iOS — works here; windowed cells rebuild during the flight.
        title: Text(
          'Native GridView',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
        // Demo FastGridController.jumpToItem — scroll the active grid to item #4
        // by INDEX (no pixel math). Shown on the Masonry + Infinite-Grid tabs.
        actions: [
          if (_tabIndex == 1 || _tabIndex == 2)
            BarButtonItem(
              title: 'ScrollTo #4',
              titleStyle: TextStyle(
                color: kTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              onPressed: () =>
                  (_tabIndex == 1 ? _masonryController : _gridController)
                      .jumpToItem(4),
            ),
        ],
      ),
      body: Container(
        color: kHomeBg,
        child: Column(
          children: [
            Container(
              // 12 top = the playground's standard bar-to-header gap (matches
              // the FastList demo).
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _buildTabSelector(),
            ),
            Expanded(
              // NATIVE TAB SEMANTICS: visited tabs stay MOUNTED and switching
              // is an index flip — like UIKit container VCs, children stay
              // alive, so scroll position and pagination state persist per
              // tab.
              // MEMOIZED children: identical widget instances across
              // unrelated setStates let the reconciler skip whole subtrees —
              // each tab rebuilds only when ITS inputs change.
              // LAZY FIRST MOUNT: an IndexedStack mounts ALL children, so
              // hidden tabs would build (and load their images) during the
              // push transition. Each tab mounts on its first visit instead
              // (a SizedBox holds the slot until then).
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _tabGrid ??= _buildListViewContent(),
                  _visitedTabs[1] ? _memoMasonryTab() : const SizedBox(),
                  _visitedTabs[2] ? _memoInfiniteTab() : const SizedBox(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() => SegmentedControl(
      backgroundColor: kSegBg,
      indicatorColor: kSegTint,
        segments: const [
          'Grid',
          'Masonry',
          'Infinite Grid',
        ],
        selectedIndex: _tabIndex,
        onValueChanged: (i) {
          setState(() {
            _tabIndex = i;
            _visitedTabs[i] = true;
          });
        },
        labelFontStyle: TextStyle(color: kTextSecondary),
        selectedLabelFontStyle: TextStyle(color: kTextPrimary),
      );

  // ── Memoized tab children (see IndexedStack comment in build) ──
  Widget? _tabGrid;
  Widget? _tabMasonry;
  int _tabMasonryCountKey = -1;
  Widget? _tabInfinite;
  int _tabInfiniteCountKey = -1;

  Widget _memoMasonryTab() {
    if (_tabMasonry == null || _tabMasonryCountKey != _masonryCount) {
      _tabMasonryCountKey = _masonryCount;
      _tabMasonry = _buildMasonryFastGridContent();
    }
    return _tabMasonry!;
  }

  Widget _memoInfiniteTab() {
    if (_tabInfinite == null || _tabInfiniteCountKey != _imageUrls.length) {
      _tabInfiniteCountKey = _imageUrls.length;
      _tabInfinite = _buildFastGridContent();
    }
    return _tabInfinite!;
  }

  Widget _buildListViewContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: _buildGridTab(),
    );
  }

  /// Masonry tab — fully virtualized, O(visible) via MasonryFastGrid.
  Widget _buildMasonryFastGridContent() {
    return MasonryFastGrid(
      itemCount: _masonryCount,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(8),
      gridController: _masonryController, // ScrollTo #4 (index) from the topbar
      onScroll: _onMasonryScroll, // load-more (grows the procedural count)
      keepAliveCount: 90, // windowing (ITEMS not rows)
      itemHeightBuilder: (i) => _masonryHeights[i % _masonryHeights.length],
      itemBuilder: (_, i) {
        // seed/ URLs always resolve (id/ has gaps → HTTP 404s). Derive BOTH
        // the seed and the URL height from i%100 so there are ~100 distinct
        // URLs: a unique fresh seed per cell would force a slow CDN-cold
        // fetch (~1.5-2 s each) and the tab would drown in shimmer. The CELL
        // height (itemHeightBuilder) still varies per index; BoxFit.cover
        // absorbs the aspect difference.
        //
        // LESSON: when two lists shimmer differently on the same pipeline,
        // compare their image sources first — distinct-URL count, CDN
        // warmth, and per-request latency dominate what the user sees.
        final k = i % 100;
        final h = _masonryHeights[k % _masonryHeights.length].toInt();
        final url = 'https://picsum.photos/seed/dn$k/400/$h';
        return Image.network(
          url,
          fit: BoxFit.cover,
          // Always set for image cells: unset = full-res decode (no automatic
          // downsampling — see Image.cacheWidth docs).
          cacheWidth: _kCacheSize,
          cacheHeight: _kCacheSize,
          placeholder: Shimmer.fromColors(
            // kTileBg, not kRowBg: the row surface is near-black in dark
            // theme, and a wall of near-black shimmer during a hard fling
            // reads as a BLACK SCREEN. The tile surface stays visibly a
            // placeholder in both themes.
            baseColor: kTileBg,
            highlightColor: kChipBg,
            child: Container(color: kTileBg),
          ),
        );
      },
    );
  }

  /// Infinite grid tab — uses [FastGrid] (UICollectionView) for O(visible)
  /// cell recycling instead of the O(total) Yoga-based GridView.
  Widget _buildFastGridContent() {
    return FastGrid(
      // Honest count — no phantom placeholder cells: mounting placeholders
      // and shrinking the count on the first fetch is misleading UI and a
      // needless recycling stress.
      itemCount: _imageUrls.length,
      crossAxisCount: 3,
      childAspectRatio: 1.0,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridController: _gridController, // ScrollTo #4 (index) from the topbar
      onScroll: _onGridScroll, // infinite load-more (replaces ScrollController)
      keepAliveCount: 90, // windowing (ITEMS not rows)
      itemBuilder: (_, i) => _InfiniteImageTile(
        url: i < _imageUrls.length ? _imageUrls[i] : '',
        // Always set for image cells: unset = full-res decode (no automatic
        // downsampling — see Image.cacheWidth docs).
        cacheSize: _kCacheSize,
      ),
    );
  }

  List<Widget> _buildGridTab() => [
        // ── Section 1: GridView.count ─────────────────────────────────
        Text(
          'GridView.count — 3 columns',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < 9; i++)
              _GridTile(
                color: _tileColors[i % _tileColors.length],
                label: '${i + 1}',
              ),
          ],
        ),

        const SizedBox(height: 32),

        // ── Section 2: GridView.count — 2 columns, different ratio ───
        Text(
          'GridView.count — 2 columns, 16:9',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 16 / 9,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < 6; i++)
              _GridTile(
                color: _tileColors[(i + 3) % _tileColors.length],
                label: 'Tile ${i + 1}',
              ),
          ],
        ),

        const SizedBox(height: 32),

        // ── Section 3: GridView.builder ───────────────────────────────
        Text(
          'GridView.builder — 4 columns, 20 items',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemCount: 20,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, i) => _GridTile(
              color: _tileColors[i % _tileColors.length], label: '#$i'),
        ),

        const SizedBox(height: 32),

        // ── Section 4: Partial last row ──────────────────────────────
        Text(
          'Partial last row — 3 cols, 7 items',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < 7; i++)
              _GridTile(
                color: _tileColors[(i + 5) % _tileColors.length],
                label: '${i + 1}',
              ),
          ],
        ),

        const SizedBox(height: 48),
      ];
}
// ── Infinite image tile ──────────────────────────────────────────────────────

class _InfiniteImageTile extends StatelessWidget {
  const _InfiniteImageTile({required this.url, this.cacheSize});
  final String url;
  final int? cacheSize; // px; null = full-res decode

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Shimmer.fromColors(
        // kTileBg, not kRowBg — near-black shimmer reads as a black
        // screen at fling scale.
        baseColor: kTileBg,
        highlightColor: kChipBg,
        child: Container(color: kTileBg),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: cacheSize, // decode at this px size (null = full res)
      cacheHeight: cacheSize,
      placeholder: Shimmer.fromColors(
        baseColor: kTileBg,
        highlightColor: kChipBg,
        child: Container(color: kTileBg),
      ),
    );
  }
}
// ── Tile widget ──────────────────────────────────────────────────────────────

class _GridTile extends StatelessWidget {
  const _GridTile({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Masonry height palette ────────────────────────────────────────────────────

const _masonryHeights = [
  80.0,
  120.0,
  100.0,
  160.0,
  90.0,
  140.0,
  110.0,
  70.0,
  130.0,
  95.0,
];

// ── Color palette ────────────────────────────────────────────────────────────

const _tileColors = [
  Color(0xFFE74C3C), // red
  Color(0xFF3498DB), // blue
  Color(0xFF2ECC71), // green
  Color(0xFFF39C12), // orange
  Color(0xFF9B59B6), // purple
  Color(0xFF1ABC9C), // teal
  Color(0xFFE67E22), // dark orange
  Color(0xFF2980B9), // dark blue
  Color(0xFF27AE60), // dark green
];
