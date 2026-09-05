// Port of a production Flutter app's story-composer image-crop screen.
//
// dartnative adaptations only — the widget shape, state fields, layout
// constants, and control flow stay 1:1 with the pure-Flutter original.
// Replaced pieces:
//   • `extended_image` (`ExtendedImage` editor + `ExtendedFileImageProvider`
//     + `ExtendedImageEditorState`)        →  this plugin's [Crop] widget.
//   • `image_editor` (`ImageEditor.editImage`, `ClipOption`, `FlipOption`,
//     `RotateOption`)                      →  [DartNativeImageCrop.cropImage].
//   • `HitTestButton`                      →  GestureDetector(opaque).
//   • `Image.asset(icRotateLeft, …)`       →  `Icon(MaterialSymbolsRounded.X)`.
//   • app theme constants                  →  inline values.
//   • `S().cancel` / `S().done`            →  string literals.
//   • File-from-constructor                →  a small "Load Image" landing
//                                             that picks via showMediaPicker.
//
// Rotation + flip baking into the final crop is not yet wired through the
// native bridge — the buttons drive [Transform] for visual feedback only.

import 'dart:io';
import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_image_crop/dartnative_image_crop.dart';

class _CropAspectRatios {
  static const double? custom = null;
  static const double ratio9_16 = 9 / 16;
  static const double ratio3_4 = 3 / 4;
  static const double ratio1_1 = 1.0;
}

class ImageCropFull extends StatefulWidget {
  const ImageCropFull({super.key});

  @override
  State<ImageCropFull> createState() => _ImageCropFullState();
}

class _ImageCropFullState extends State<ImageCropFull> {
  final _editorKey = GlobalKey<CropState>();
  double? _aspectRatio = _CropAspectRatios.custom;
  bool _cropOptionShow = false;

  File? _imageFile;
  File? _sample;
  int _rotationQuarterTurns = 0;
  bool _flipHorizontal = false;
  bool _isLoading = false;

  /// Cropped output file. Non-null after the user taps Done — drives the
  /// in-screen result preview (same UX as image_crop_demo's overlay).
  File? _result;

  @override
  void dispose() {
    _imageFile?.delete();
    _sample?.delete();
    _result?.delete();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final picked = await showMediaPicker(
      context: context,
      type: MediaPickerType.images,
      maxSelection: 1,
    );
    if (picked.isEmpty) return;
    final file = File(picked.first.path);
    final longestSide = MediaQuery.of(context).size.longestSide.ceil();
    File sample;
    try {
      sample = await DartNativeImageCrop.sampleImage(
        file: file,
        preferredSize: longestSide,
      );
    } catch (_) {
      sample = file;
    }
    _imageFile?.delete();
    _sample?.delete();
    if (!mounted) return;
    setState(() {
      _imageFile = file;
      _sample = sample;
      _rotationQuarterTurns = 0;
      _flipHorizontal = false;
      _aspectRatio = _CropAspectRatios.custom;
      _cropOptionShow = false;
    });
  }

  void _cancel() {
    _imageFile?.delete();
    _sample?.delete();
    _result?.delete();
    setState(() {
      _imageFile = null;
      _sample = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return App(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          // The result preview overlays the editor as a Positioned.fill so
          // the Crop widget underneath stays mounted (its pan/zoom state
          // survives "Crop Again"). Mirrors image_crop_demo's approach.
          child: Stack(
            fit: StackFit.expand,
            children: [
              _imageFile == null ? _buildLoadScreen() : _buildEditor(),
              if (_result != null)
                Positioned.fill(child: _buildResultPreview()),
            ],
          ),
        ),
      ),
    );
  }

  // "Load Image" initial state — replaces the original's File-via-constructor.
  Widget _buildLoadScreen() {
    return Column(
      children: [
        const Expanded(child: SizedBox()),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Button(
            title: 'Load Image',
            variant: ButtonVariant.filled,
            onPressed: _loadImage,
          ),
        ),
      ],
    );
  }

  // Direct port of the original screen's `build()` body (the Column under SafeArea).
  Widget _buildEditor() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            Padding(
              // Original theme constant: MARGIN_OF_CROP_SCREEN_TITLE.
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _cancel,
                    // Generous tap target around the text — easy to hit
                    // without aiming for the 6-letter glyph.
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final state = _editorKey.currentState!;
                      final rect = state.area;
                      // The original captures rotate/flip from `editAction`;
                      // here we keep them as local state. Not yet baked
                      // into the output (see header note).
                      // ignore: unused_local_variable
                      final bool flipHorizontal = _flipHorizontal;
                      // ignore: unused_local_variable
                      final int rotationTurns = _rotationQuarterTurns;

                      if (rect == null || _imageFile == null) return;

                      setState(() => _isLoading = true);
                      try {
                        final hires = await DartNativeImageCrop.sampleImage(
                          file: _imageFile!,
                          preferredSize: (2000 / state.scale).round(),
                        );
                        final result = await DartNativeImageCrop.cropImage(
                          file: hires,
                          area: rect,
                        );
                        hires.delete();
                        _result?.delete();
                        if (!mounted) return;
                        setState(() {
                          _result = result;
                          _isLoading = false;
                        });
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _isLoading = false);
                        showAlert(
                          context: context,
                          title: 'Crop Error',
                          message: e.toString(),
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                // fit:expand is required in dartnative to pass TIGHT
                // constraints to the non-positioned Transform → Crop
                // child. Without it the Crop's ImageView measures 0×0,
                // never attaches with real bounds, and Coil's load
                // listener never fires (image stays black).
                fit: StackFit.expand,
                children: [
                  // ExtendedImage(editor)  →  Crop, with Transform for the
                  // visual rotate/flip preview.
                  Transform.rotate(
                    angle: _rotationQuarterTurns * math.pi / 2,
                    child: Transform.scale(
                      scaleX: _flipHorizontal ? -1.0 : 1.0,
                      scaleY: 1.0,
                      child: Crop(
                        // Use the GlobalKey directly so [_editorKey.currentState]
                        // resolves to the live CropState when Done is tapped.
                        // Crop already reacts to `aspectRatio` changes via
                        // `didUpdateWidget` (see lib/src/crop.dart), so we
                        // don't need a ValueKey to force a rebuild.
                        key: _editorKey,
                        file: _sample!,
                        aspectRatio: _aspectRatio,
                        alwaysShowGrid: true,
                      ),
                    ),
                  ),
                  Positioned(
                    // Original theme constants: BOTTOM_MARGIN_OF_ASPECT_RATIO_SELECTION /
                    // HORIZONTAL_MARGIN_OF_ASPECT_RATIO_SELECTION.
                    bottom: 16,
                    left: 24,
                    right: 24,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _cropOptionShow ? 1 : 0,
                      curve: Curves.easeIn,
                      child: IgnorePointer(
                        ignoring: !_cropOptionShow,
                        child: Container(
                          // Original theme constant: PADDING_OF_ASPECT_RATIO_SELECTION.
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.black,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _aspectRatioOptionButton(
                                label: 'Original',
                                onTap: () => setState(
                                  () => _aspectRatio = _CropAspectRatios.custom,
                                ),
                              ),
                              _aspectRatioOptionButton(
                                label: '16:9',
                                onTap: () => setState(
                                  () => _aspectRatio =
                                      _CropAspectRatios.ratio9_16,
                                ),
                              ),
                              _aspectRatioOptionButton(
                                label: '4:3',
                                onTap: () => setState(
                                  () =>
                                      _aspectRatio = _CropAspectRatios.ratio3_4,
                                ),
                              ),
                              _aspectRatioOptionButton(
                                label: '1:1',
                                onTap: () => setState(
                                  () =>
                                      _aspectRatio = _CropAspectRatios.ratio1_1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              // Original theme constant: MARGIN_OF_CROP_SCREEN_BOTTOM_CONTROLS.
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      _rotationQuarterTurns = (_rotationQuarterTurns + 3) % 4;
                    }),
                    child: const Padding(
                      // Larger hit-target than the icon glyph — 16pt
                      // around a 28pt icon gives a ~60pt tap region,
                      // matching the iOS HIG / Material guidance for
                      // touch targets.
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        MaterialSymbolsRounded.rotate_left,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _flipHorizontal = !_flipHorizontal),
                    child: const Padding(
                      // Larger hit-target than the icon glyph — 16pt
                      // around a 28pt icon gives a ~60pt tap region,
                      // matching the iOS HIG / Material guidance for
                      // touch targets.
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        MaterialSymbolsRounded.flip,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _cropOptionShow = !_cropOptionShow),
                    child: const Padding(
                      // Larger hit-target than the icon glyph — 16pt
                      // around a 28pt icon gives a ~60pt tap region,
                      // matching the iOS HIG / Material guidance for
                      // touch targets.
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        MaterialSymbolsRounded.crop_rotate,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
                    }),
                    child: const Padding(
                      // Larger hit-target than the icon glyph — 16pt
                      // around a 28pt icon gives a ~60pt tap region,
                      // matching the iOS HIG / Material guidance for
                      // touch targets.
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        MaterialSymbolsRounded.rotate_right,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: const Color.fromRGBO(0, 0, 0, 0.54),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Cropping image...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Direct port of the original screen's `_aspectRatioOptionButton`.
  Widget _aspectRatioOptionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _cropOptionShow = false;
        onTap.call();
      },
      child: Padding(
        // Larger hit-target around the label so it's harder to miss-tap.
        // The original used vertical:8 only (icons + finger-on-icon) — we
        // add horizontal:12 since these are text labels with a tighter
        // glyph footprint.
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// In-screen result preview shown after the user taps Done. Mirrors the
  /// overlay UX of image_crop_demo's `_buildCroppedImage` so the user can
  /// see exactly what was cropped (instead of a path-only alert). "Crop
  /// Again" clears `_result` and returns to the editor with all state
  /// (pan / zoom / aspect ratio / rotate / flip) preserved.
  Widget _buildResultPreview() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Plain "Back" text label — no chevron. Without UIKit's
                // own back-indicator art (only available inside a real
                // UINavigationBar via [AppBar.leading: BackButton(...)]),
                // a hand-rolled chevron never quite matches; the label
                // alone is the cleanest fallback.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _cancel,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                'Cropped Result',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Two Spacers center the bordered image vertically between the
          // title and the filename caption — same layout as
          // image_crop_demo so the two examples look consistent.
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.file(_result!, fit: BoxFit.contain),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                'Saved: ${_result!.path.split('/').last}',
                style: const TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 0.6),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
