/// The photo library behind the ChatGPT Picker demo.
///
/// Modelled on the reference implementation's `usePhotoLibrary` hook: the
/// library is read when the SCREEN mounts, not when the panel opens, so
/// the grid has photos to draw the moment it appears. Waiting until the
/// panel opens is what puts a spinner in front of the user.
///
/// A notifier rather than screen state because two trees need it: the
/// demo screen, which primes it, and the panel, which lives in its own
/// reconciler and watches for assets as they land.
///
/// It holds the ASSETS and nothing else. Every tile is a [GalleryThumb],
/// which asks the photo library for the picture itself, so there is no
/// rendering a copy per photo and no file to read back.
library;

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_media_picker/gallery.dart';

/// Assets per page, the reference app's number. The grid asks for the
/// next one within 2.5 viewports of the end, which FastGrid reports.
const int kGptPageSize = 35 * 3;

class GptPhotoLibrary extends ChangeNotifier {
  final List<MediaAsset> assets = [];

  GalleryPermission permission = GalleryPermission.notDetermined;

  bool _priming = false;
  bool _loading = false;
  bool _lastPageFull = true;

  /// The size the grid's tiles ask for.
  int thumbSize = 128;

  /// True while a page is in flight, which is what keeps the scroll
  /// listener from asking for the same one several times over.
  bool get isFetching => _loading;
  StreamSubscription<void>? _changes;

  bool get hasAccess =>
      permission == GalleryPermission.granted ||
      permission == GalleryPermission.limited;

  /// True while the first page is still on its way, which is the only
  /// moment the panel has nothing to show.
  bool get isLoading => (_priming || _loading) && assets.isEmpty;

  bool get hasMore => _lastPageFull;

  /// Asks for the library and reads the first page. Called once, when the
  /// screen mounts.
  Future<void> prime() async {
    if (_priming || assets.isNotEmpty) return;
    _priming = true;
    notifyListeners();
    try {
      permission = await MediaGallery.permission(request: true);
      notifyListeners();
      if (hasAccess) {
        await loadMore();
        // Take a screenshot with the picker open and it belongs at the
        // front of the grid, which is what the app we are copying does.
        _changes ??= MediaGallery.changes.listen((_) => _absorbChange());
      }
    } finally {
      _priming = false;
      notifyListeners();
    }
  }

  /// Absorbs a library change by ADDING what is new, never by clearing.
  ///
  /// Clearing and re-reading makes the whole grid blink, which is what a
  /// screenshot taken with the picker open used to do. Reading the newest
  /// page and keeping only the ids we have never seen leaves every tile
  /// that is already on screen exactly where it is.
  Future<void> _absorbChange() async {
    if (!hasAccess) return;
    try {
      final page = await MediaGallery.assets(offset: 0, limit: kGptPageSize);
      final known = {for (final asset in assets) asset.id};
      final fresh = [
        for (final asset in page)
          if (!known.contains(asset.id)) asset,
      ];
      // A change we already have (an edit, a favourite) rebuilds nothing.
      if (fresh.isEmpty) return;
      assets.insertAll(0, fresh);
      notifyListeners();
    } catch (_) {
      // A failed refresh must not empty a grid that is working.
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> loadMore() async {
    if (_loading || !hasAccess || !_lastPageFull) return;
    _loading = true;
    try {
      final page = await MediaGallery.assets(
        offset: assets.length,
        limit: kGptPageSize,
      );
      assets.addAll(page);
      _lastPageFull = page.length == kGptPageSize;
      notifyListeners();
    } catch (_) {
      _lastPageFull = false;
    } finally {
      _loading = false;
    }
  }
}
