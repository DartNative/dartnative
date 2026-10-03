// Ported from rive-flutter's example/lib/examples/out_of_band_assets_audio.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   File.asset(…, assetLoader:) + RiveWidgetController
//                                    →  Rive(asset:, assetLoader:)
//   rootBundle.load(path)           →  loadAssetBytes(path)   (sync)
//
// Their `_loading` flag is `!isLoaded`: the file loads on the platform side,
// with the view, so there is no File to await; the view mounts at once and
// their spinner sits over it until the controller reports the file's
// artboards, as rive_widget.dart does. The clips live under assets/audio, as
// upstream's do, named as the file references them.
//
// An example showing how to load audio assets.
//
// See: https://rive.app/docs/runtimes/loading-assets

import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

Widget buildOutOfBandAssetsAudio(BuildContext context) =>
    const ExampleOutOfBandAssetAudioLoading();

class ExampleOutOfBandAssetAudioLoading extends StatefulWidget {
  const ExampleOutOfBandAssetAudioLoading({Key? key}) : super(key: key);

  @override
  State<ExampleOutOfBandAssetAudioLoading> createState() =>
      _ExampleOutOfBandAssetAudioLoadingState();
}

class _ExampleOutOfBandAssetAudioLoadingState
    extends State<ExampleOutOfBandAssetAudioLoading> {
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

  void _loadAudio(AudioAsset asset) {
    final bytes = loadAssetBytes('assets/audio/${asset.uniqueFilename}');
    if (bytes == null) {
      debugPrint('no bundled clip for ${asset.uniqueFilename}');
      return;
    }
    asset.decode(bytes);

    // Alternatively, if you know the names you can preload the audio files
    // before loading the Rive file.

    // AudioSource? audioSource = await RiveFactory.decodeAudio(bytes);
    // if (audioSource != null) {
    //   asset.audio(audioSource);
    // }
  }

  bool _assetLoader(FileAsset asset, Uint8List? bytes) {
    if (asset is AudioAsset && bytes == null) {
      _loadAudio(asset);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Rive(
          asset: 'assets/rive/ping_pong_audio_demo.riv',
          assetLoader: _assetLoader,
          controller: controller,
        ),
        if (!isLoaded) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
