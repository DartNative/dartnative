/// Gallery demo — the second half of dartnative_media_picker.
///
/// The picker screen next door hands the job to the system. This one reads
/// the library itself and draws the grid, which is what you do when the
/// system picker's look is not the one your app wants.
///
/// It exercises every call in the layer: permission, albums, a page of
/// assets, a thumbnail per tile, the full file behind one, saving a copy
/// back, and deleting.
library;

import 'dart:async';
import 'dart:io';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_media_picker/gallery.dart';

/// How many assets one page asks for.
const int _kPageSize = 60;

class GalleryDemo extends StatefulWidget {
  const GalleryDemo({super.key});

  @override
  State<GalleryDemo> createState() => _GalleryDemoState();
}

class _GalleryDemoState extends State<GalleryDemo> {
  GalleryPermission _permission = GalleryPermission.notDetermined;
  List<MediaAlbum> _albums = const [];
  MediaAlbum? _album;
  final List<MediaAsset> _assets = [];

  /// Thumbnail paths as they land, keyed by asset id. A tile shows its
  /// photo once its entry appears; asking twice for the same one is free
  /// anyway, since the native side reuses the rendered file.
  final Map<String, String> _thumbs = {};

  final Set<String> _selected = {};

  /// Drives the endless grid: the next page loads while the last rows are
  /// still coming into view, so the user never waits at the bottom.
  final ScrollController _scroll = ScrollController();

  bool _busy = false;
  String _status = '';

  /// A full page means there is probably another one. Asking the album for
  /// its count instead would tie scrolling to the album list, which loads
  /// later than the photos do.
  bool _lastPageFull = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _refresh(request: false);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_busy || !_hasMore) return;
    // Two rows ahead of the end, which is enough to hide the fetch.
    if (_scroll.remainingScroll < 600) _loadPage();
  }

  bool get _hasMore => _lastPageFull;

  bool get _hasAccess =>
      _permission == GalleryPermission.granted ||
      _permission == GalleryPermission.limited;

  Future<void> _refresh({required bool request}) async {
    // Breadcrumb for the "why did it ask?" question: this is the only
    // place the example touches the permission, and mounting passes false.
    dnLog('[GalleryDemo] permission(request: $request)');
    setState(() => _busy = true);
    try {
      final permission = await MediaGallery.permission(request: request);
      if (!mounted) return;
      setState(() => _permission = permission);
      if (!_hasAccess) {
        setState(() {
          _busy = false;
          _status = 'No access: $permission';
        });
        return;
      }
      // Open on the all-album, which needs no album list: the photos are
      // on screen while the albums are still being counted. Counting them
      // means one fetch per album, which a library of fifty thousand
      // photos makes slow enough to notice.
      setState(() => _album = _allAlbum);
      await _loadPage(reset: true);
      unawaited(_loadAlbums());
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The all-album before the real list arrives. Its name is filled in by
  /// [_loadAlbums], which reads the system's own word for it.
  static const MediaAlbum _allAlbum = MediaAlbum(
    id: MediaGallery.allAlbumId,
    name: '',
    count: 0,
    isAll: true,
  );

  Future<void> _loadAlbums() async {
    try {
      final albums = await MediaGallery.albums();
      if (!mounted || albums.isEmpty) return;
      setState(() {
        _albums = albums;
        // Keep whatever is selected; the all-album gains its real name.
        final current = _album;
        _album = albums.firstWhere(
          (a) => a.id == current?.id,
          orElse: () => albums.first,
        );
      });
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    }
  }

  /// Loads the next page of the selected album, or the first one again.
  Future<void> _loadPage({bool reset = false}) async {
    final album = _album;
    if (album == null) return;
    setState(() => _busy = true);
    try {
      if (reset) {
        _assets.clear();
        _selected.clear();
      }
      final page = await MediaGallery.assets(
        albumId: album.id,
        offset: _assets.length,
        limit: _kPageSize,
      );
      if (!mounted) return;
      setState(() {
        _assets.addAll(page);
        _lastPageFull = page.length == _kPageSize;
      });
      for (final asset in page) {
        _requestThumb(asset);
      }
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Fire and forget: the tile paints when the path arrives.
  Future<void> _requestThumb(MediaAsset asset) async {
    if (_thumbs.containsKey(asset.id)) return;
    try {
      final path = await MediaGallery.thumbnail(asset.id, width: 200, height: 200);
      if (!mounted || path.isEmpty) return;
      setState(() => _thumbs[asset.id] = path);
    } catch (_) {
      // One unreadable asset should not take the grid down with it.
    }
  }

  Future<void> _openFirstSelected() async {
    final id = _selected.isEmpty ? null : _selected.first;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final file = await MediaGallery.file(id);
      if (!mounted) return;
      await showAlert(
        context: context,
        title: file.name,
        message: '${file.isVideo ? 'Video' : 'Photo'}\n${file.path}',
      );
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Resolves the original and writes it back as a new asset, which is the
  /// round trip an editor makes.
  Future<void> _saveCopy() async {
    final id = _selected.isEmpty ? null : _selected.first;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final file = await MediaGallery.file(id);
      final newId = await MediaGallery.save(
        file.path,
        isVideo: file.isVideo,
        albumName: 'DartNative',
      );
      if (!mounted) return;
      setState(() => _status = 'Saved as $newId in DartNative');
      await _loadPage(reset: true);
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      // The system asks the user to confirm; an empty result means they
      // said no, which is an answer and not an error.
      final gone = await MediaGallery.delete(_selected.toList());
      if (!mounted) return;
      setState(() => _status = gone.isEmpty
          ? 'Nothing deleted'
          : 'Deleted ${gone.length} item(s)');
      await _loadPage(reset: true);
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gallery',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      // The Scaffold owns the background, not an inner Container: the
      // route reports this colour to the navigator, which paints the
      // transition backdrop with it. Painting inside the body instead
      // leaves the backdrop at the white default and flashes on push.
      backgroundColor: const Color(0xFF000000),
      body: SizedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_hasAccess) _accessBar() else _albumBar(),
            // Only what an action reports (saved, deleted, an error). No
            // row at all the rest of the time.
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _status,
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                ),
              ),
            Expanded(child: _grid()),
            if (_hasAccess) _actionBar(),
          ],
        ),
      ),
    );
  }

  Widget _accessBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Reading the library needs permission. The system picker next '
            'door does not, which is the whole reason the two are separate '
            'imports.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Button(
            title: 'Grant access',
            variant: ButtonVariant.filled,
            onPressed: () => _refresh(request: true),
          ),
        ],
      ),
    );
  }

  Widget _albumBar() {
    return Container(
      // The row reads as part of the bar above it, not as content.
      color: const Color(0xFF1C1C1E),
      height: 49,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 3, 12, 2),
        children: [
          // Counting the albums takes a moment on a big library, and a row
          // that appears seconds later reads as a glitch. The pills are
          // already there in their real shape, holding still; only the
          // names are missing, so only the names shimmer.
          if (_albums.isEmpty)
            for (final glyphs in const [7, 5, 8, 6, 9])
              _AlbumPlaceholder(glyphs: glyphs),
          for (final album in _albums)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _album = album);
                  _loadPage(reset: true);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // A step lighter than the row behind it: the unselected
                    // pill would otherwise vanish into the bar colour.
                    color: album.id == _album?.id
                        ? const Color(0xFF0A84FF)
                        : const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${album.name} (${album.count})',
                    style: const TextStyle(
                        color: Color(0xFFFFFFFF), fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _grid() {
    if (_assets.isEmpty) {
      // An album that really is empty must not say "Loading" forever.
      return Center(
        child: Text(
          _busy ? 'Loading…' : 'No media in this album...',
          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
        ),
      );
    }
    return GridView.builder(
      controller: _scroll,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      padding: const EdgeInsets.all(2),
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final asset = _assets[index];
        return _Tile(
          asset: asset,
          thumbPath: _thumbs[asset.id],
          selected: _selected.contains(asset.id),
          onTap: () => setState(() {
            if (!_selected.remove(asset.id)) _selected.add(asset.id);
          }),
        );
      },
    );
  }

  Widget _actionBar() {
    final enabled = _selected.isNotEmpty && !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
      child: Row(
        children: [
          Expanded(
            child: Button(
              title: 'Open',
              variant: ButtonVariant.tinted,
              onPressed: enabled ? _openFirstSelected : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Button(
              title: 'Save copy',
              variant: ButtonVariant.tinted,
              onPressed: enabled ? _saveCopy : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Button(
              title: 'Delete',
              variant: ButtonVariant.tinted,
              onPressed: enabled ? _deleteSelected : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// An album pill before its name is known: the same pill, holding still,
/// with the name shimmering in place.
///
/// The Presence app's trick, from its profile screen: the placeholder is a
/// real [Text] of ■ glyphs under `Shimmer.fromColors`. Because it is text,
/// it takes the label's size and baseline for free, so the pill is exactly
/// as tall and as centred as it will be once the name arrives.
class _AlbumPlaceholder extends StatelessWidget {
  const _AlbumPlaceholder({required this.glyphs});

  /// Roughly how long the name will be.
  final int glyphs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
        ),
        // The framework's Shimmer paints its gradient OVER the child, so
        // one shimmer around a Text is a shimmering block, not shimmering
        // letters. One small shimmer per glyph reads as a word instead —
        // and they sweep in unison, the view phase-locks them.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < glyphs; i++)
              Padding(
                padding: EdgeInsets.only(right: i == glyphs - 1 ? 0 : 3),
                child: Shimmer.fromColors(
                  baseColor: const Color(0xFF3A3A3C),
                  highlightColor: const Color(0xFF5A5A5C),
                  period: const Duration(seconds: 2),
                  child: const SizedBox(width: 9, height: 9),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One grid cell: the thumbnail once it arrives, with a selection badge.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.asset,
    required this.thumbPath,
    required this.selected,
    required this.onTap,
  });

  final MediaAsset asset;
  final String? thumbPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final path = thumbPath;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1C1C1E),
              child: path == null
                  ? const SizedBox()
                  : Image.file(File(path), fit: BoxFit.cover),
            ),
          ),
          if (asset.isVideo)
            Positioned(
              left: 4,
              bottom: 4,
              child: Text(
                _durationLabel(asset.duration),
                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 11),
              ),
            ),
          if (selected)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.checkmark,
                    color: Color(0xFFFFFFFF),
                    size: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _durationLabel(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
