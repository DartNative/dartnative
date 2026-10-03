// Ported from rive-flutter's example/lib/examples/out_of_band_assets_cached.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   File.asset(…, assetLoader:) + RiveWidgetController
//                                    →  Rive(asset:, assetLoader:)
//   http.get(url).bodyBytes         →  getBytes(url)   (dart:io HttpClient)
//   Factory.rive.decodeImage/Font   →  RiveFactory.decodeImage/decodeFont
//   ElevatedButton                  →  a plain button in the example's style
//   CircularProgressIndicator       →  the text alone
//
// Their `_loadRiveFile` + spinner go: the file loads on the platform side
// and the view shows as soon as it does. Everything else — the warm-up, the
// asset references kept for swapping, `renderImage`/`font` on tap — is
// upstream's. One thing to know: our RenderImage/Font keep the encoded bytes
// and the runtime decodes when an asset takes them, so a swap costs a
// decode here where upstream's is a pointer swap.
//
// An example showing how to load image or font assets dynamically.
//
// In this example there is no delay in the assets loading, as they are
// cached in memory.
//
// The example also shows how to swap out the assets multiple times by
// keeping a reference to the asset and swapping it out.
//
// Note that this swaps out the image/font on the Rive File instance. All
// artboards created from this file will use the same asset reference. Meaning
// that if you swap out the image/font on the Rive File instance, all
// artboards created from this file will use the new asset reference.
//
// See: https://rive.app/docs/runtimes/loading-assets

import 'dart:math';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';
import 'http_bytes.dart';

Widget buildOutOfBandAssetsCached(BuildContext context) =>
    const ExampleOutOfBandCachedAssetLoading();

class ExampleOutOfBandCachedAssetLoading extends StatefulWidget {
  const ExampleOutOfBandCachedAssetLoading({Key? key}) : super(key: key);

  @override
  State<ExampleOutOfBandCachedAssetLoading> createState() =>
      _ExampleOutOfBandCachedAssetLoadingState();
}

class _ExampleOutOfBandCachedAssetLoadingState
    extends State<ExampleOutOfBandCachedAssetLoading> {
  var _index = 0;
  var _ready = false;
  final _imageCache = <RenderImage>[];
  final _fontCache = <Font>[];

  @override
  void initState() {
    super.initState();
    _warmUpCache();
  }

  /// Create a cache of images and fonts to swap out instantly.
  Future<void> _warmUpCache() async {
    final futures = <Future>[];
    loadImage() async {
      final body = await getBytes('https://picsum.photos/500/500');
      final image = await RiveFactory.decodeImage(body);
      if (image != null) {
        _imageCache.add(image);
      }
    }

    loadFont(url) async {
      final body = await getBytes(url);
      final font = await RiveFactory.decodeFont(body);

      if (font != null) {
        _fontCache.add(font);
      }
    }

    for (var i = 0; i <= 10; i++) {
      futures.add(loadImage());
    }

    for (var url in [
      'https://cdn.rive.app/runtime/flutter/IndieFlower-Regular.ttf',
      'https://cdn.rive.app/runtime/flutter/comic-neue.ttf',
      'https://cdn.rive.app/runtime/flutter/inter.ttf',
      'https://cdn.rive.app/runtime/flutter/inter-tight.ttf',
      'https://cdn.rive.app/runtime/flutter/josefin-sans.ttf',
      'https://cdn.rive.app/runtime/flutter/send-flowers.ttf',
    ]) {
      futures.add(loadFont(url));
    }

    await Future.wait(futures);

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  void next() {
    setState(() => _index += 1);
  }

  void previous() {
    setState(() => _index -= 1);
  }

  @override
  void dispose() {
    for (var image in _imageCache) {
      image.dispose();
    }
    for (var font in _fontCache) {
      font.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Warming up cache. Loading files from network...',
                style: TextStyle(color: Color(0xFFFFFFFF), fontFamily: monoFont),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Row(
        children: [
          GestureDetector(
            onTap: previous,
            child: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: (_index % 2 == 0)
                ? _RiveRandomCachedImage(imageCache: _imageCache)
                : _RiveRandomCachedFont(fontCache: _fontCache),
          ),
          GestureDetector(
            onTap: next,
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

class _RiveRandomCachedImage extends StatefulWidget {
  const _RiveRandomCachedImage({
    Key? key,
    required this.imageCache,
  }) : super(key: key);

  final List<RenderImage> imageCache;

  @override
  State<_RiveRandomCachedImage> createState() => __RiveRandomCachedImageState();
}

class __RiveRandomCachedImageState extends State<_RiveRandomCachedImage> {
  List<RenderImage> get _imageCache => widget.imageCache;

  // A reference to the Rive image. Can be use to swap out the image at any
  // point.
  ImageAsset? _imageAsset;

  bool _assetLoader(FileAsset asset, Uint8List? bytes) {
    if (asset is ImageAsset) {
      asset.renderImage(_imageCache[Random().nextInt(_imageCache.length)]);
      // Maintain a reference to the image asset
      // so we can swap it out later instantly.
      _imageAsset = asset;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _imageAsset?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Rive(
                asset: 'assets/rive/image_out_of_band.riv',
                fit: RiveFit.cover,
                assetLoader: _assetLoader,
              ),
              const Positioned(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'This example caches images and swaps them out instantly.\n\nHover to zoom.',
                    style: TextStyle(color: Color(0xFF000000), fontFamily: monoFont),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Kept clear of the home indicator; upstream's page runs under it.
        // The Container holds the SafeArea to its content: DartNative's
        // grows into a Column's free space, Flutter's does not.
        Container(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _Button(
                onPressed: () {
                  _imageAsset?.renderImage(
                      _imageCache[Random().nextInt(_imageCache.length)]);
                  setState(() {
                    // force rebuild for Rive widget to update the image
                  });
                },
                child: const Text('Random image'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RiveRandomCachedFont extends StatefulWidget {
  const _RiveRandomCachedFont({
    Key? key,
    required this.fontCache,
  }) : super(key: key);

  final List<Font> fontCache;

  @override
  State<_RiveRandomCachedFont> createState() => __RiveRandomCachedFontState();
}

class __RiveRandomCachedFontState extends State<_RiveRandomCachedFont> {
  List<Font> get _fontCache => widget.fontCache;

  final List<FontAsset?> _fontAssets = [];

  bool _assetLoader(FileAsset asset, Uint8List? bytes) {
    if (asset is FontAsset) {
      asset.font(_fontCache[Random().nextInt(_fontCache.length)]);
      _fontAssets.add(asset);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    for (var element in _fontAssets) {
      element?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Rive(
                asset: 'assets/rive/acqua_text_out_of_band.riv',
                fit: RiveFit.cover,
                assetLoader: _assetLoader,
              ),
              const Positioned(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'This example caches fonts and swaps them out instantly.\n\nClick to change drink.',
                    style: TextStyle(color: Color(0xFF000000), fontFamily: monoFont),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Kept clear of the home indicator; upstream's page runs under it.
        // The Container holds the SafeArea to its content: DartNative's
        // grows into a Column's free space, Flutter's does not.
        Container(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _Button(
                onPressed: () {
                  for (var element in _fontAssets) {
                    element?.font(_fontCache[Random().nextInt(_fontCache.length)]);
                    setState(() {
                      // force rebuild for Rive widget to update the image
                    });
                  }
                },
                child: const Text('Random font'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Upstream's ElevatedButton, in the example's own style.
class _Button extends StatelessWidget {
  const _Button({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontFamily: monoFont,
              fontSize: 14,
            ),
            child: child,
          ),
        ),
      );
}
