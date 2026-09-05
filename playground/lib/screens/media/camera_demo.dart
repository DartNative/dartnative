// Full-screen camera UI example for dartnative_camera.
//
// Layout (top → bottom on a black background):
//   • Top bar:  back ‹ • REC ● (recording) • aspect ratio • flash ⚡
//   • Preview filling most of the screen, tap-to-focus
//   • Shutter centered over the preview, above the control row
//   • Control row: round thumb • Photo|Video segmented control • round flip ⟳
//
// Hidden behind the simple UX:
//   • Camera enumeration runs on first build — the first camera is opened
//     automatically. Flip toggles front ↔ back.
//   • Photo mode: shutter takes a JPEG, thumbnail updates.
//   • Video mode: tap shutter to start, tap again to stop. Last MP4 path
//     shows under the bottom bar.
//
// Modelled after a production camera screen but trimmed for dartnative (no
// Material widgets, no audio/PhotoManager dependencies, no native-orientation
// rotation lock — CameraX/AVFoundation handle that in v0.2).

import 'dart:async';
import 'dart:io';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_audio/dartnative_audio.dart';
import 'package:dartnative_camera/dartnative_camera.dart';
import 'package:dartnative_compressor/dartnative_compressor.dart';
import 'package:dartnative_image_crop/dartnative_image_crop.dart';

/// Shared fill for the Photo|Video segmented track and the round thumb / flip
/// buttons.
const Color _kControlFill = Color(0xFF1F1F21);

String _ts() {
  final t = DateTime.now();
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  final s = t.second.toString().padLeft(2, '0');
  final ms = t.millisecond.toString().padLeft(3, '0');
  return '$h:$m:$s.$ms';
}

enum _Mode { photo, video }

/// Display aspect ratio for the preview (visual clip — the underlying preview
/// stream stays whatever the SDK chose; we just letterbox / pillarbox in the
/// Dart layer).
///
/// Photos support all three values: after capture we re-encode the JPEG to
/// the selected aspect via `dartnative_image_crop` (a cheap, lossless-ish
/// pixel-domain crop on a single frame).
///
/// Video supports only 16:9 and 4:3. CameraX's `Recorder` exposes
/// `ASPECT_RATIO_16_9` and `ASPECT_RATIO_4_3` natively — there is no 1:1
/// recorder option. Matching the preview aspect on the saved MP4 for 1:1
/// would require a full post-record MediaCodec re-encode of every frame
/// (seconds of processing per minute of footage, possible quality loss,
/// and a heavyweight code path). Major consumer camera apps don't bother:
/// Telegram hardcodes 16:9 for video; WhatsApp / YouTube / Snapchat /
/// Instagram all save at native sensor aspect and crop only at the
/// consumption step. So we mirror that convention: 1:1 is offered in the
/// aspect-ratio selector only when the mode is `photo`. Switching to video
/// mode with 1:1 selected auto-snaps to 16:9 (see `_setMode`).
enum _AspectRatio {
  ratio16_9(9 / 16, '16:9'), // 9/16 because portrait
  ratio4_3(3 / 4, '4:3'),
  ratio1_1(1 / 1, '1:1'); // photo-only — see enum doc

  final double aspect;
  final String label;
  const _AspectRatio(this.aspect, this.label);
}

class CameraDemo extends StatefulWidget {
  const CameraDemo({super.key});

  @override
  State<CameraDemo> createState() => _CameraDemoState();
}

class _CameraDemoState extends State<CameraDemo> {
  List<CameraDescription> _cameras = const [];
  int _activeIndex = 0;
  CameraController? _controller;
  String? _error;
  bool _busy = false;

  /// Snapshotted at initState and updated on each orientation change.
  /// Read at shutter-tap time so the native capture use-case gets the
  /// correct EXIF / AVCaptureConnection orientation before takePicture().
  DeviceOrientation _captureOrientation = DeviceOrientationListener.current;

  _Mode _mode = _Mode.photo;
  FlashMode _flash = FlashMode.off;
  _AspectRatio _aspect = _AspectRatio.ratio16_9;

  // One persistent AudioPlayer per clip so playback latency is just `play()`
  // (no per-tap setAsset + decoding). Lazy init via `??=` races with
  // setAsset's native load + crashes on stop-recording, so init eagerly here.
  // Both iOS and Android are supported.
  final AudioPlayer _shutterPlayer = AudioPlayer()
    ..setAsset('assets/audios/camera/camera_shutter.mp3');
  final AudioPlayer _startRecPlayer = AudioPlayer()
    ..setAsset('assets/audios/camera/start_recording.mp3');
  final AudioPlayer _stopRecPlayer = AudioPlayer()
    ..setAsset('assets/audios/camera/stop_recording.mp3');

  /// Last captured photo (shown as a thumb in the bottom-left).
  String? _lastPhotoPath;

  // Recording-duration ticker. Stored in a ValueNotifier so the per-second
  // tick only rebuilds the small REC duration label, NOT the whole widget
  // tree (which would re-register every gesture handler's NativeCallable and
  // crash any in-flight tap event with "Callback invoked after deleted").
  DateTime? _recordingStartedAt;
  Timer? _recordingTicker;
  final ValueNotifier<Duration> _recordingElapsed = ValueNotifier<Duration>(
    Duration.zero,
  );

  // Stable identities for gesture callbacks. The dartnative reconciler
  // re-registers (and schedules close of) a GestureDetector's NativeCallable
  // whenever the onTap closure identity changes across setState. Method
  // tear-offs like `_onShutter` create a new bound-method instance each
  // rebuild — caching them in `late final` fields keeps identity stable so
  // the underlying NativeCallable is never recycled.
  late final VoidCallback _onShutterStable = _onShutter;
  late final VoidCallback _openGalleryStable = _openGallery;
  late final VoidCallback _flipCameraStable = _flipCamera;
  late final VoidCallback _toggleFlashStable = _toggleFlash;
  late final ValueChanged<int> _onModeChangedStable =
      (i) => _setMode(i == 0 ? _Mode.photo : _Mode.video);
  late final VoidCallback _onBackStable = _onBack;

  @override
  void initState() {
    super.initState();
    // Dark-by-design screen: pin dark chrome regardless of the app theme.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    // PORTRAIT-PINNED like Apple's Camera app: only the SCREEN stays put.
    // Rotating the device still captures landscape photos and videos — the
    // capture pipeline follows the physical orientation via
    // DeviceOrientationListener below.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    DeviceOrientationListener.currentNotifier.addListener(_onOrientation);
    _bootstrap();
    // Request the Photos "add" permission up front.
    unawaited(DartNativeCamera.requestGalleryAddPermission());
  }

  void _onOrientation() {
    _captureOrientation = DeviceOrientationListener.current;
    // Apply the new orientation to the capture pipeline EAGERLY (not on
    // shutter tap). The first AVCaptureConnection.videoOrientation change
    // costs ~400ms on iOS because AVFoundation internally reconfigures the
    // session — pausing preview frame delivery. Doing it here at rotation
    // time keeps the brief preview freeze paired with rotation (where the
    // user expects a transition) instead of with the shutter tap (where
    // the user expects an instant response). By the time the user taps
    // shutter, FLTCam's `if (_lockedCaptureOrientation != orientation)`
    // guard makes setCaptureOrientation a no-op.
    _controller?.setCaptureOrientation(
      _toCaptureOrientation(_captureOrientation),
    );
  }

  Future<void> _bootstrap() async {
    try {
      final cams = await DartNativeCamera.availableCameras();
      if (!mounted) return;
      if (cams.isEmpty) {
        setState(() => _error = 'No cameras on this device.');
        return;
      }
      setState(() => _cameras = cams);
      await _openCamera(0);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to enumerate cameras: $e');
    }
  }

  Future<void> _openCamera(int index) async {
    dnLog(
      '[CameraDemo ${_ts()}] _openCamera(index=$index)  previousActiveIndex=$_activeIndex  '
      'cameras=${_cameras.length}  lens=${_cameras[index].lensDirection}',
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      dnLog(
        '[CameraDemo ${_ts()}] _openCamera — disposing old controller (was=${_controller != null})',
      );
      _controller?.dispose();
      dnLog('[CameraDemo ${_ts()}] _openCamera — constructing new controller');
      final c = CameraController(_cameras[index], ResolutionPreset.high);
      dnLog('[CameraDemo ${_ts()}] _openCamera — calling initialize()');
      await c.initialize();
      dnLog('[CameraDemo ${_ts()}] _openCamera — initialize() returned OK');
      if (!mounted) {
        c.dispose();
        return;
      }
      // Re-apply current flash mode on the new controller.
      c.setFlashMode(_flash);
      setState(() {
        _controller = c;
        _activeIndex = index;
      });
      // Pre-warm the Recorder for the currently selected aspect so the very
      // first shutter tap in video mode doesn't pay the rebind cost. (For
      // newly-opened cameras the Recorder was built with VideoAspectRatio
      // .defaultRatio = -1, which CameraX maps to whatever it likes — so
      // even matching 16:9 in the UI would otherwise trigger a rebind.)
      _prewarmVideoAspect();
      // Force the Camera2 HAL through its one-time video-sensor-mode
      // transition NOW (silent ~250ms warmup recording, discarded) so the
      // user's first real shutter tap doesn't cause a visible preview
      // quality/brightness shift. Qualcomm/MediaTek HALs are the main
      // offenders; CONTROL_CAPTURE_INTENT=VIDEO_RECORD doesn't help on
      // those. Android-only; iOS is a no-op. Fire-and-forget — any error
      // surfaces in the controller's log.
      unawaited(c.warmupVideoSensor());
      dnLog(
        '[CameraDemo ${_ts()}] _openCamera — setState done  newPreviewHandle=${c.previewHandle}',
      );
    } catch (e) {
      // Surface a friendlier hint when the failure is permission-related —
      // on Android CameraX throws CameraUnavailableException("Camera access
      // permission denied"), on iOS AVFoundation raises an AVError.
      final msg = e.toString();
      final isPermission = msg.contains('permission') ||
          msg.contains('Permission') ||
          msg.contains('denied') ||
          msg.contains('PermissionDenied') ||
          msg.contains('NotPermitted');
      setState(
        () => _error = isPermission
            ? 'Camera permission denied — open Settings → App permissions → Camera'
            : 'Open camera failed: $e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _flipCamera() {
    if (_cameras.length < 2) return;
    // Toggle front ↔ back (devices expose several back lenses).
    final target =
        _cameras[_activeIndex].lensDirection == CameraLensDirection.back
            ? CameraLensDirection.front
            : CameraLensDirection.back;
    final next = _cameras.indexWhere((c) => c.lensDirection == target);
    if (next < 0 || next == _activeIndex) return;
    _openCamera(next);
  }

  void _toggleFlash() {
    final c = _controller;
    if (c == null) return;
    final next = switch (_flash) {
      FlashMode.off => FlashMode.always,
      FlashMode.always => FlashMode.auto,
      FlashMode.auto => FlashMode.off,
      FlashMode.torch => FlashMode.off,
    };
    setState(() => _flash = next);
    c.setFlashMode(next);
  }

  void _setMode(_Mode m) {
    if (_controller?.isRecordingVideo == true) return;
    if (m == _Mode.video) {
      // Request mic permission before recording.
      unawaited(DartNativeCamera.requestMicrophonePermission());
    }
    setState(() {
      _mode = m;
      // Demo policy: video mode only offers 16:9. We snap any other
      // selected aspect to 16:9 when entering video mode.
      //
      //  • 1:1 → 16:9 — CameraX's Recorder only exposes
      //    ASPECT_RATIO_16_9 / ASPECT_RATIO_4_3 (see the `_AspectRatio`
      //    enum doc), so the selector + recorder stay consistent.
      //  • 4:3 → 16:9 — iOS AVFoundation's only 4:3 video preset is VGA
      //    (640×480); switching to it on a running session triggers a
      //    `relayoutSession` that pauses preview frame delivery (~few
      //    hundred ms of black). Apple's own Camera.app + most pro 3rd-
      //    party iOS camera apps (Halide, Camera+, Obscura) don't offer
      //    4:3 video either — photo is 4:3 sensor-native, video is 16:9
      //    cropped from the same sensor.
      //    The plugin still supports `VideoAspectRatio.ratio4_3` for
      //    apps that want it (with the one-time flicker trade-off).
      //    The demo just chooses not to expose itt for the cleanest UX.
      if (m == _Mode.video &&
          (_aspect == _AspectRatio.ratio1_1 ||
              _aspect == _AspectRatio.ratio4_3)) {
        _aspect = _AspectRatio.ratio16_9;
      }
    });
    // Pre-warm the Recorder for the new (post-snap) aspect so the next
    // shutter tap doesn't pay the rebind cost. See `_onAspectChanged`.
    _prewarmVideoAspect();
  }

  void _onAspectChanged(_AspectRatio a) {
    setState(() => _aspect = a);
    _prewarmVideoAspect();
  }

  /// Rebuilds CameraX's Recorder + VideoCapture for the currently selected
  /// `_aspect` so the saved MP4 matches the preview. Costly (~1s rebind
  /// flicker) so we run it eagerly here, when the user changes the aspect or
  /// the mode — NOT inside `_startRecording`, where it would delay the
  /// shutter feedback by a full second.
  ///
  /// No-op outside video mode, while a recording is in flight, or if the
  /// underlying Recorder is already on the requested aspect (the controller
  /// short-circuits in that case).
  void _prewarmVideoAspect() {
    final c = _controller;
    if (c == null) return;
    if (_mode != _Mode.video) return;
    if (c.isRecordingVideo) return;
    if (_aspect == _AspectRatio.ratio1_1) return; // see _AspectRatio enum doc
    final ratio = _aspect == _AspectRatio.ratio16_9
        ? VideoAspectRatio.ratio16_9
        : VideoAspectRatio.ratio4_3;
    // Fire-and-forget: any error surfaces on the next shutter tap.
    c.setVideoAspectRatio(ratio);
  }

  Future<void> _onShutter() async {
    final c = _controller;
    if (c == null || _busy) return;
    if (_mode == _Mode.photo) {
      await _takePhoto();
    } else {
      if (c.isRecordingVideo) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
    }
  }

  /// Maps dartnative [DeviceOrientation] to the camera plugin's [CaptureOrientation].
  /// Index order is identical between the two enums, so a direct index cast works.
  CaptureOrientation _toCaptureOrientation(DeviceOrientation o) =>
      CaptureOrientation.values[o.index];

  Future<void> _takePhoto() async {
    final c = _controller;
    if (c == null) return;
    setState(() => _busy = true);
    // Fire-and-forget shutter sound — runs in parallel with the capture so
    // the click is heard at the moment the user taps, not after the JPEG is
    // written. Rewind first so repeat taps replay from the start.
    _shutterPlayer.stop();
    _shutterPlayer.play();
    try {
      // Snapshot orientation at shutter time so EXIF / AVCaptureConnection
      // reflects where the device is pointing right now, not at init time.
      c.setCaptureOrientation(_toCaptureOrientation(_captureOrientation));
      final rawPath = await c.takePicture();
      if (!mounted) return;
      // Post-crop to the user-selected aspect ratio via dartnative_image_crop
      // (a pure dartnative plugin). 16:9 is the camera's typical native
      // ratio so we skip the crop in that case to save a JPEG re-encode.
      final pathToSave = await _cropToSelectedAspect(rawPath);
      setState(() => _lastPhotoPath = pathToSave);
      // Save to the device gallery (Android: MediaStore.Images; iOS: PHPhotoLibrary).
      final saved = await c.saveToGallery(pathToSave);
      if (!saved) {
        dnLog(
          '[CameraDemo ${_ts()}] saved to cache but failed to add to gallery: $pathToSave',
        );
      }
    } catch (e) {
      setState(() => _error = 'Capture failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Crop the captured JPEG to the user-selected display aspect ratio.
  ///
  /// dartnative_image_crop takes a Rect in normalized (0..1) coordinates.
  /// `_AspectRatio.aspect` is width/height in portrait sense (e.g. 9/16
  /// for ratio16_9). The captured JPEG's pixel dimensions are in the
  /// camera's NATIVE orientation (landscape for iPhone sensors) — so we
  /// must invert the target aspect for landscape captures, otherwise a
  /// landscape source ends up cropped to a tall portrait strip (logs:
  /// 1280x720 source → 406x720 saved). Match the source's actual
  /// orientation, not a hard-coded portrait assumption.
  ///
  /// Returns the same path if the source already matches the aspect (within
  /// 1%) or if the crop fails — the gallery still gets a valid file.
  Future<String> _cropToSelectedAspect(String srcPath) async {
    final isLandscape =
        _captureOrientation == DeviceOrientation.landscapeLeft ||
            _captureOrientation == DeviceOrientation.landscapeRight;
    // `_aspect.aspect` is w/h in portrait sense. In landscape we want the
    // reciprocal so a 16:9 capture (srcAspect = 1.778) matches a 16:9
    // target (also 1.778) and the crop is skipped instead of producing a
    // wrong-shaped output.
    final targetAspect = isLandscape ? 1.0 / _aspect.aspect : _aspect.aspect;
    try {
      final file = File(srcPath);
      final src = await DartNativeImageCrop.getImageOptions(file: file);
      final srcAspect = src.width / src.height;
      if ((srcAspect - targetAspect).abs() < 0.01) return srcPath;
      double w, h;
      if (srcAspect > targetAspect) {
        // Source is wider than target — crop sides.
        h = src.height.toDouble();
        w = h * targetAspect;
      } else {
        // Source is taller than target — crop top/bottom.
        w = src.width.toDouble();
        h = w / targetAspect;
      }
      final left = (src.width - w) / 2 / src.width;
      final top = (src.height - h) / 2 / src.height;
      final rectW = w / src.width;
      final rectH = h / src.height;
      final cropped = await DartNativeImageCrop.cropImage(
        file: file,
        area: Rect.fromLTWH(left, top, rectW, rectH),
      );
      return cropped.path;
    } catch (e) {
      dnLog('[CameraDemo ${_ts()}] crop failed (using uncropped): $e');
      return srcPath;
    }
  }

  Future<void> _startRecording() async {
    final c = _controller;
    if (c == null) return;
    setState(() => _busy = true);
    try {
      // Play the start-recording cue and wait for it to finish BEFORE starting
      // the capture — otherwise the tail of the sound leaks into the recorded
      // video's audio track (the cue plays through the speaker while CameraX
      // has already opened the mic).
      final cueDone = _startRecPlayer.events
          .firstWhere((e) => e.type == AudioPlayerEvent.completed)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => AudioPlayerEventData(AudioPlayerEvent.completed),
          );
      // Rewind to 0 before play — Android (ExoPlayer) leaves the position at
      // end-of-media after first playback, so a bare play() is a no-op the
      // second time and the cue is silent. `stop()` seeks to 0 + pauses.
      _startRecPlayer.stop();
      _startRecPlayer.play();
      await cueDone;

      // NOTE: The CameraX Recorder is pre-warmed with the matching aspect by
      // `_prewarmVideoAspect` (called from `_onAspectChanged` and `_setMode`),
      // so by the time we reach here the use cases are already bound for the
      // selected aspect — no rebind, no 1s preview flicker on the shutter tap.

      // Snapshot orientation at record-start time so the video track carries
      // the correct rotation metadata (Android MediaRecorder / iOS AVAssetWriter).
      c.setCaptureOrientation(_toCaptureOrientation(_captureOrientation));
      await c.startVideoRecording();
      _recordingStartedAt = DateTime.now();
      _recordingElapsed.value = Duration.zero;
      _recordingTicker?.cancel();
      _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _recordingStartedAt == null) return;
        _recordingElapsed.value = DateTime.now().difference(
          _recordingStartedAt!,
        );
      });
    } catch (e) {
      setState(() => _error = 'Recording start failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopRecording() async {
    final c = _controller;
    if (c == null) return;
    setState(() => _busy = true);
    _stopRecPlayer.stop();
    _stopRecPlayer.play();
    try {
      final path = await c.stopVideoRecording();
      // Save the recorded MP4 to the gallery (Android: MediaStore.Video; iOS: PHPhotoLibrary).
      final saved = await c.saveToGallery(path, isVideo: true);
      if (!saved) {
        dnLog(
          '[CameraDemo ${_ts()}] recorded to cache but failed to add to gallery: $path',
        );
      }
      // Extract a frame-0 JPEG via dartnative_compressor so the shutter
      // row's thumbnail reflects the just-recorded video (same way the
      // photo path updates `_lastPhotoPath` after a still capture). The
      // thumb widget renders any JPEG path, so we reuse `_lastPhotoPath`.
      final thumb = await DartNativeCompressor.getVideoThumbnail(File(path));
      if (thumb != null && mounted) {
        setState(() => _lastPhotoPath = thumb.path);
      }
    } catch (e) {
      setState(() => _error = 'Recording stop failed: $e');
    } finally {
      _recordingTicker?.cancel();
      _recordingTicker = null;
      _recordingStartedAt = null;
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    // Release the portrait pin taken in initState.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    DeviceOrientationListener.currentNotifier.removeListener(_onOrientation);
    _recordingTicker?.cancel();
    _shutterPlayer.dispose();
    _startRecPlayer.dispose();
    _stopRecPlayer.dispose();
    _controller?.dispose();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ───────────────────────────────────────────────────────────────

  void _openGallery() => _controller?.openGallery();

  void _onBack() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final previewHeight = mq.width / _aspect.aspect;

    // Bottom control row (thumb • Photo|Video segmented • flip); shutter,
    // preview and top bar anchor off it.
    const controlsRowBottom = 35.0;
    const controlsRowHeight = 45.0;
    const shutterBottom = controlsRowBottom + controlsRowHeight + 35;
    const shutterButtonHeight = 72.0;
    // Top bar lives at Positioned(top: 12) inside SafeArea, ~40px tall.
    const topBarTopInset = 12.0;
    const topBarHeight = 40.0;

    // 16:9 → preview bottom sits just above the controls row.
    // 4:3 → preview centers in the band between the top bar and the shutter,
    //   so it never overlaps either.
    const previewBottomAnchor16x9 = controlsRowBottom + controlsRowHeight + 20;
    final bandCenterFromTop = (safe.top +
            topBarTopInset +
            topBarHeight +
            mq.height -
            shutterBottom -
            shutterButtonHeight) /
        2;
    final previewBottom = _aspect == _AspectRatio.ratio16_9
        ? previewBottomAnchor16x9
        : mq.height - bandCenterFromTop - previewHeight / 2;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      // Bottom SafeArea off: `bottom:` offsets measure from the physical
      // screen edge (controlsRowBottom clears the home indicator).
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (_controller != null)
              _buildPreviewSurface(previewBottom, previewHeight),

            // ── Top bar: REC (left) • aspect ratio (centered) • flash (right) ─
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _AspectRatioSelector(
                    current: _aspect,
                    // Video is 16:9-only (Apple Camera.app convention; see
                    // `_setMode` for the auto-snap). Photo offers all three.
                    options: _mode == _Mode.video
                        ? const [_AspectRatio.ratio16_9]
                        : _AspectRatio.values,
                    onChanged: _onAspectChanged,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TopRoundButton(
                          icon: CupertinoIcons.chevron_back,
                          onTap: _onBackStable,
                        ),
                        if (_controller?.isRecordingVideo == true) ...[
                          const SizedBox(width: 10),
                          Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xCCCC0000),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ValueListenableBuilder<Duration>(
                              valueListenable: _recordingElapsed,
                              builder: (_, elapsed, __) => Text(
                                '● ${_fmtDuration(elapsed)}',
                                style: const TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_controller != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _FlashButton(
                        mode: _flash,
                        onTap: _toggleFlashStable,
                      ),
                    ),
                ],
              ),
            ),

            // ── Shutter — centered over the preview, above the controls row ──
            Positioned(
              left: 0,
              right: 0,
              bottom: shutterBottom,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShutterButton(
                    mode: _mode,
                    isRecording: _controller?.isRecordingVideo ?? false,
                    busy: _busy,
                    onTap: _onShutterStable,
                  ),
                ],
              ),
            ),

            // ── Bottom bar controls: thumb • Photo|Video • flip ──────────────
            Positioned(
              left: 24,
              right: 24,
              bottom: controlsRowBottom,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ThumbBox(path: _lastPhotoPath, onTap: _openGalleryStable),
                  SizedBox(
                    width: 190,
                    height: 44,
                    child: SegmentedControl(
                      segments: const ['Photo', 'Video'],
                      selectedIndex: _mode == _Mode.photo ? 0 : 1,
                      onValueChanged: _onModeChangedStable,
                      backgroundColor: _kControlFill,
                      indicatorColor: const Color(0xFFFFEB3B),
                      labelFontStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w600,
                      ),
                      selectedLabelFontStyle: const TextStyle(
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _FlipCameraButton(
                    onTap: _cameras.length > 1 ? _flipCameraStable : null,
                  ),
                ],
              ),
            ),

            // ── Error caption (real errors only; no loading placeholder) ─────
            if (_error != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: shutterBottom + shutterButtonHeight + 16,
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSurface(double previewBottom, double previewHeight) {
    // Aspect-ratio-aware preview sizing, bottom-anchored a fixed distance above
    // the controls row (caller computes bottom/height — see `build()`).
    //
    // We use Positioned(bottom, left, right, height) — NOT AspectRatio + Center
    // — because dartnative's AspectRatio collapses the NativeElement-backed
    // CameraPreview to 0×0 at first attach, which makes the PreviewView's
    // SurfaceTexture never appear and CameraX times out after 5s with
    // "Cannot complete surfaceList within 5000". Explicit Positioned bounds
    // bypass that chain entirely.
    return Positioned(
      bottom: previewBottom,
      left: 0,
      right: 0,
      height: previewHeight,
      // Pinch-to-zoom + tap-to-focus are handled inside the native preview
      // view (DNCameraPreviewView on iOS, DNCameraContainerView on Android) —
      // no Dart GestureDetector needed.
      child: CameraPreview(controller: _controller!),
    );
  }
}

// ── Small components ─────────────────────────────────────────────────────

/// 40×40 dark circle hosting a CupertinoIcons bolt glyph that swaps by
/// [FlashMode]:
///   • off   → bolt_slash    (crossed-out bolt)
///   • auto  → bolt_badge_a  (bolt with "A" badge)
///   • always → bolt_fill    (solid bolt)
///   • torch → light_max     (constant-light flashlight)
class _FlashButton extends StatelessWidget {
  final FlashMode mode;
  final VoidCallback? onTap;
  const _FlashButton({required this.mode, required this.onTap});

  IconData get _icon => switch (mode) {
        FlashMode.off => CupertinoIcons.bolt_slash,
        FlashMode.auto => CupertinoIcons.bolt_badge_a,
        FlashMode.always => CupertinoIcons.bolt_fill,
        FlashMode.torch => CupertinoIcons.light_max,
      };

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      _icon,
      size: 20,
      color: onTap == null ? const Color(0x88FFFFFF) : const Color(0xFFFFFFFF),
    );
    // iOS 26: the system Camera look — an interactive Liquid Glass disc.
    // Everywhere else: the translucent-dark circle (glass is 26-only by
    // design here; no fallback material wanted).
    return GestureDetector(
      onTap: onTap,
      child: isIOS26
          ? GlassEffectContainer(
              borderRadius: BorderRadius.circular(20),
              interactive: true,
              brightness: Brightness.dark, // dark-by-design screen
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(child: icon),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: icon,
            ),
    );
  }
}

/// 40×40 translucent-dark circle for the top bar (back button).
class _TopRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _TopRoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: 22, color: const Color(0xFFFFFFFF));
    return GestureDetector(
      onTap: onTap,
      child: isIOS26
          ? GlassEffectContainer(
              borderRadius: BorderRadius.circular(20),
              interactive: true,
              brightness: Brightness.dark, // dark-by-design screen
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(child: glyph),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: glyph,
            ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final _Mode mode;
  final bool isRecording;
  final bool busy;
  final VoidCallback? onTap;
  const _ShutterButton({
    required this.mode,
    required this.isRecording,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Outer ring (white). The onTap reference is kept stable across rebuilds
    // — `_onShutter` self-guards with an `if (_busy) return;` early-exit, so
    // we MUST NOT pass `null` here when busy. Toggling onTap between null and
    // a callback churns the framework's gesture NativeCallable, leaving the
    // native View with a stale lambda capturing a dead callbackPtr → SIGABRT
    // on the next tap.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFFFFF), width: 4),
        ),
        alignment: Alignment.center,
        child: Container(
          width: isRecording ? 30 : 56,
          height: isRecording ? 30 : 56,
          decoration: BoxDecoration(
            color: mode == _Mode.video
                ? (isRecording
                    ? const Color(0xFFCC0000)
                    : const Color(0xFFCC0000))
                : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(isRecording ? 4 : 28),
          ),
        ),
      ),
    );
  }
}

/// 48px grey circle hosting a camera-flip glyph — same size as [_ThumbBox]
/// and the same fill as the Photo|Video segmented control.
class _FlipCameraButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _FlipCameraButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      CupertinoIcons.camera_rotate,
      size: 22,
      color: onTap == null ? const Color(0x88FFFFFF) : const Color(0xFFFFFFFF),
    );
    // iOS 26: interactive Liquid Glass disc, matching the top-bar chrome.
    // Everywhere else: the grey control circle.
    return GestureDetector(
      onTap: onTap,
      child: isIOS26
          ? GlassEffectContainer(
              borderRadius: BorderRadius.circular(24),
              interactive: true,
              brightness: Brightness.dark, // dark-by-design screen
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(child: icon),
              ),
            )
          : Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _kControlFill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: icon,
            ),
    );
  }
}

class _ThumbBox extends StatelessWidget {
  final String? path;
  final VoidCallback? onTap;
  const _ThumbBox({required this.path, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasThumb = path != null && File(path!).existsSync();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _kControlFill,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFFFFF), width: 1),
        ),
        child: hasThumb
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(File(path!), fit: BoxFit.cover),
              )
            : null,
      ),
    );
  }
}

/// Horizontal aspect ratio picker — full-black pill, spaceEvenly layout.
class _AspectRatioSelector extends StatelessWidget {
  final _AspectRatio current;
  final List<_AspectRatio> options;
  final ValueChanged<_AspectRatio> onChanged;
  const _AspectRatioSelector({
    required this.current,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map(_pill).toList(),
    );
    // iOS 26: a static Liquid Glass capsule hosts the ratio pills (the
    // per-pill taps stay Dart GestureDetectors). Elsewhere: the black pill.
    return isIOS26
        ? GlassEffectContainer(
            borderRadius: BorderRadius.circular(100),
            brightness: Brightness.dark, // dark-by-design screen
            child: row,
          )
        : Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(100),
            ),
            child: row,
          );
  }

  Widget _pill(_AspectRatio ar) {
    final active = ar == current;
    return GestureDetector(
      onTap: () => onChanged(ar),
      // `opaque` makes the full padded area register taps even where the
      // background is transparent — without it, hits only land on the text
      // glyph bounds, which makes these short labels finicky to tap.
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
        child: Text(
          ar.label,
          style: TextStyle(
            color: active ? const Color(0xFFFFEB3B) : const Color(0xFFFFFFFF),
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
