// Ported from rive-flutter's example/lib/examples/out_of_band_assets.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   File.asset(…, assetLoader:) + RiveWidgetController
//                                    →  Rive(asset:, assetLoader:)
//   http.get(url).bodyBytes         →  getBytes(url)   (dart:io HttpClient)
//   RiveWidget(controller:, fit:)   →  the same Rive widget
//   the image caption's Colors.black →  white: the image fits inside the
//                                       view, so the caption sits on the
//                                       dark page (black is unreadable in
//                                       the reference app too)
//
// The loader callback is upstream's, line for line: `asset is ImageAsset &&
// bytes == null` picks the out-of-band image, `asset.decode(bytes)` hands it
// the download. Their `_loadFiles` goes: the file loads on the platform
// side, with the view, so there is no File to await; the view mounts at once
// and their loading spinner sits over it until the controller reports the
// file's artboards, as rive_widget.dart does. The `setState` "force rebuild"
// after decode is not needed either; the runtime redraws with the new asset.
//
// An example showing how to load image or font assets dynamically.
//
// In this example you'll note that there is a delay in the assets
// loading/refreshing when you tap the back/forward buttons.
// This is because the assets are being loaded asynchronously.
// If you want to avoid this delay you can cache the assets in memory
// and provide them instantly.
//
// See `out_of_band_assets_cached.dart` for an example of this.
//
// See: https://rive.app/docs/runtimes/loading-assets

import 'dart:math';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';
import 'http_bytes.dart';

Widget buildOutOfBandAssets(BuildContext context) =>
    const ExampleOutOfBandAssetLoading();

class ExampleOutOfBandAssetLoading extends StatefulWidget {
  const ExampleOutOfBandAssetLoading({Key? key}) : super(key: key);

  @override
  State<ExampleOutOfBandAssetLoading> createState() =>
      _ExampleOutOfBandAssetLoadingState();
}

class _ExampleOutOfBandAssetLoadingState
    extends State<ExampleOutOfBandAssetLoading> {
  var _index = 0;
  void next() => setState(() {
        _index += 1;
      });

  void previous() => setState(() {
        _index -= 1;
      });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        children: [
          GestureDetector(
            onTap: previous,
            child: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: (_index % 2 == 0)
                ? const _RiveRandomImage()
                : const _RiveRandomFont(),
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

/// Loads a random image as an asset.
class _RiveRandomImage extends StatefulWidget {
  const _RiveRandomImage();

  @override
  State<_RiveRandomImage> createState() => _RiveRandomImageState();
}

class _RiveRandomImageState extends State<_RiveRandomImage> {
  final controller = RiveController();

  bool get isLoaded => controller.artboardNames.isNotEmpty;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onController);
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onController);
    controller.dispose();
    super.dispose();
  }

  bool _assetLoader(FileAsset asset, Uint8List? bytes) {
    if (asset is ImageAsset && bytes == null) {
      getBytes('https://picsum.photos/500/500').then((res) {
        if (mounted) {
          asset.decode(res);
        }
      });
      return true; // Tell the runtime not to load the asset automatically
    } else {
      // Tell the runtime to proceed with loading the asset if it exists
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Rive(
          asset: 'assets/rive/image_out_of_band.riv',
          assetLoader: _assetLoader,
          controller: controller,
        ),
        if (!isLoaded) const Center(child: CircularProgressIndicator()),
        const Positioned(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'This example loads a random image dynamically and asynchronously.\n\nHover to zoom.',
              style: TextStyle(color: Color(0xFFFFFFFF), fontFamily: monoFont),
            ),
          ),
        )
      ],
    );
  }
}

/// Loads a random font as an asset.
class _RiveRandomFont extends StatefulWidget {
  const _RiveRandomFont();

  @override
  State<_RiveRandomFont> createState() => _RiveRandomFontState();
}

class _RiveRandomFontState extends State<_RiveRandomFont> {
  final controller = RiveController();

  bool get isLoaded => controller.artboardNames.isNotEmpty;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onController);
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onController);
    controller.dispose();
    super.dispose();
  }

  bool _assetLoader(FileAsset asset, Uint8List? bytes) {
    // Replace font assets that are not embedded in the rive file
    if (asset is FontAsset && bytes == null) {
      final urls = [
        'https://cdn.rive.app/runtime/flutter/IndieFlower-Regular.ttf',
        'https://cdn.rive.app/runtime/flutter/comic-neue.ttf',
        'https://cdn.rive.app/runtime/flutter/inter.ttf',
        'https://cdn.rive.app/runtime/flutter/inter-tight.ttf',
        'https://cdn.rive.app/runtime/flutter/josefin-sans.ttf',
        'https://cdn.rive.app/runtime/flutter/send-flowers.ttf',
      ];

      // pick a random url from the list of fonts
      getBytes(urls[Random().nextInt(urls.length)]).then((res) {
        if (mounted) {
          asset.decode(res);
        }
      });
      return true; // Tell the runtime not to load the asset automatically
    } else {
      // Tell the runtime to proceed with loading the asset if it exists
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Rive(
          asset: 'assets/rive/acqua_text_out_of_band.riv',
          fit: RiveFit.cover,
          assetLoader: _assetLoader,
          controller: controller,
        ),
        if (!isLoaded) const Center(child: CircularProgressIndicator()),
        const Positioned(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'This example loads a random font dynamically and asynchronously.\n\nClick to change drink.',
              style: TextStyle(color: Color(0xFF000000), fontFamily: monoFont),
            ),
          ),
        )
      ],
    );
  }
}
