import 'dart:io';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_image_crop/dartnative_image_crop.dart';

/// Demo app for the dartnative image_crop plugin.
///
/// Layout (always — no state-dependent restructuring, so child widget state
/// like the [Crop]'s pan/zoom survives across re-renders):
///   ┌──────────────────────────────┐
///   │                              │  ← image area (Expanded). Empty
///   │      [crop / preview]        │    placeholder when nothing is
///   │                              │    picked yet; [Crop] widget after
///   │                              │    a pick; cropped-result preview
///   └──────────────────────────────┘    after a successful crop.
///   │  [Crop Image]   [Open Image] │  ← always visible.
///   └──────────────────────────────┘
class ImageCropBasic extends StatefulWidget {
  const ImageCropBasic({super.key});

  @override
  State<ImageCropBasic> createState() => _ImageCropBasicState();
}

class _ImageCropBasicState extends State<ImageCropBasic> {
  final GlobalKey<CropState> _cropKey = GlobalKey<CropState>();

  /// Original picked file — kept around so we can re-sample at full
  /// resolution when cropping (mirrors the upstream example's `_file`).
  File? _file;

  /// Down-sampled version fed to [Crop] for fast on-screen editing.
  File? _sample;

  /// Cropped result currently overlaid on top of the [Crop] widget.
  File? _lastCropped;

  bool _isLoading = false;

  @override
  void dispose() {
    _file?.delete();
    _sample?.delete();
    _lastCropped?.delete();
    super.dispose();
  }

  Future<void> _openImage() async {
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
    _sample?.delete();
    _file?.delete();
    _lastCropped?.delete();
    setState(() {
      _file = file;
      _sample = sample;
      _lastCropped = null;
    });
  }

  Future<void> _cropImage() async {
    // No-op if nothing's been picked yet — keeps the button always tappable
    // (both buttons stay visible regardless of state).
    if (_sample == null) return;
    final state = _cropKey.currentState;
    final area = state?.area;
    final original = _file;
    if (area == null || original == null) return;

    setState(() => _isLoading = true);
    try {
      final s = state!.scale;
      final hires = await DartNativeImageCrop.sampleImage(
        file: original,
        preferredSize: (2000 / s).round(),
      );
      final result = await DartNativeImageCrop.cropImage(
        file: hires,
        area: area,
      );
      hires.delete();
      _lastCropped?.delete();
      // Diagnostic: confirm the cropped file actually exists with content
      // before we hand it to Image.file. A 0-byte file would render as a
      // black box because the native decoder silently fails.
      final exists = await result.exists();
      final size = exists ? await result.length() : 0;
      // ignore: avoid_print
      print(
        '[ImageCropBasic] cropped → path=${result.path} '
        'exists=$exists bytes=$size area=$area',
      );
      // Diagnostic: confirm the cropped file's native pixel dimensions
      // match the requested aspect ratio. Useful for catching EXIF /
      // orientation surprises before they reach the preview.
      try {
        final opts = await DartNativeImageCrop.getImageOptions(file: result);
        // ignore: avoid_print
        print(
          '[ImageCropBasic] cropped dimensions=${opts.width}x${opts.height} '
          'aspect=${(opts.width / opts.height).toStringAsFixed(3)} '
          '(crop area=$area)',
        );
      } catch (_) {
        // ignored — diagnostic only
      }
      if (!mounted) return;
      setState(() {
        _lastCropped = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAlert(context: context, title: 'Crop Error', message: e.toString());
    }
  }

  void _resetCrop() {
    _lastCropped?.delete();
    setState(() {
      _lastCropped = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasCropped = _lastCropped != null;
    return App(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          // Stack must fit:expand so its children (the main Column and the
          // loading overlay) receive the SafeArea's full size as TIGHT
          // constraints. Without this, dartnative treats the first non-
          // Positioned child as a "Yoga flow" child and the inner LayoutBuilder
          // in Crop ends up measuring 0x0.
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Expanded(child: _buildImageArea()),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Button(
                            title: 'Open Image',
                            variant: ButtonVariant.filled,
                            onPressed: _openImage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Button(
                            title: hasCropped ? 'Crop Again' : 'Crop Image',
                            // Same filled-blue variant as "Open Image" so
                            // the two primary actions feel uniform.
                            variant: ButtonVariant.filled,
                            onPressed: (hasCropped || _sample != null)
                                ? (hasCropped ? _resetCrop : _cropImage)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isLoading) Positioned.fill(child: _buildLoadingOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  /// The image area: an inner Stack so the cropped preview can overlay the
  /// (still-mounted) Crop widget — keeps Crop's internal state alive across
  /// Crop / Crop Again cycles.
  Widget _buildImageArea() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _sample == null
            ? _buildEmptyPlaceholder()
            : Crop(
                key: _cropKey,
                file: _sample!,
                // Set aspectRatio to null to allow the user to drag corner handles to
                // make the crop rect any width/height they want.
                // aspectRatio: 1.0, // 1.0 for square-only cropping
                alwaysShowGrid: true,
              ),
        if (_lastCropped != null) Positioned.fill(child: _buildCroppedImage()),
      ],
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.12),
          width: 1,
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tap "Open Image" to pick a photo,\nthen drag the corners to crop.',
            style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCroppedImage() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // SizedBox(width: infinity) forces the Text to fill the column's
          // cross-axis so `textAlign: TextAlign.center` has a wide canvas to
          // center within. Without it the Text would shrink to its content
          // width and visually align with the Column's `crossAxisAlignment`
          // default (center) — same visual centering, but textAlign would be
          // a no-op.
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
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.file(_lastCropped!, fit: BoxFit.contain),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                'Saved: ${_lastCropped!.path.split('/').last}',
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

  Widget _buildLoadingOverlay() {
    return Container(
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
    );
  }
}

