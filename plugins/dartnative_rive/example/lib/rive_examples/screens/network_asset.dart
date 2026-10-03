// Ported from rive-flutter's example/lib/examples/network_asset.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Upstream: FileLoader.fromUrl('https://cdn.rive.app/animations/vehicles.riv')
// Ours:     Rive(url: …) — the same URL, fetched by the platform runtime.
//
// Upstream's RiveWidgetBuilder switches over RiveLoading / RiveFailed /
// RiveLoaded. The fetch and decode happen on the platform side, with the
// view, so the view mounts at once and their loading spinner sits over it
// until the controller reports the file's artboards, as rive_widget.dart
// does. A failed fetch reports nothing, so there is no error state to
// render: the spinner stays. That difference is worth seeing, which is why
// the note below is on screen rather than only in this comment.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';

Widget buildNetworkAsset(BuildContext context) => const _NetworkAsset();

class _NetworkAsset extends StatefulWidget {
  const _NetworkAsset();

  @override
  State<_NetworkAsset> createState() => _NetworkAssetState();
}

class _NetworkAssetState extends State<_NetworkAsset> {
  /// Upstream's URL, unchanged.
  static const _url = 'https://cdn.rive.app/animations/vehicles.riv';

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

  // Kept clear of the home indicator; upstream's page runs under it.
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Rive(url: _url, fit: RiveFit.contain, controller: controller),
                  if (!isLoaded)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    _url,
                    style: TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 11,
                      fontFamily: monoFont,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The platform runtime fetches and decodes this. The '
                    'spinner shows until it reports the file; a failed fetch '
                    'reports nothing, so there is no error state to render.',
                    style: TextStyle(
                  color: Color(0xFF9A9A9A),
                  fontSize: 12,
                  fontFamily: monoFont,
                ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
