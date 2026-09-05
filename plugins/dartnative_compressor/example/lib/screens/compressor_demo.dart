/// Media compression demo — standalone example for dartnative_compressor.
///
/// Tests compression APIs:
///   Video tab:
///     1. Pick a video from the device via native media picker
///     2. Choose quality and max bitrate
///     3. Compress with real-time progress
///     4. See before/after file sizes and reduction
///     5. Play the compressed video via dartnative_video_player
///   Image tab:
///     1. Pick an image from the device
///     2. Choose quality, max dimension, and optional square crop
///     3. Compress with bicubic-quality native resizing
///     4. See before/after file sizes and reduction
///
/// No backend needed. All compression is performed locally using native codecs.
library;

import 'dart:io';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_compressor/dartnative_compressor.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

class CompressorDemo extends StatefulWidget {
  const CompressorDemo({super.key});

  @override
  State<CompressorDemo> createState() => _CompressorDemoState();
}

class _CompressorDemoState extends State<CompressorDemo> {
  int _tabIndex = 0;

  // ── Video state ──────────────────────────────────────────────────────────
  MediaFile? _mediaFile;
  int? _sourceSize;
  bool _isPicking = false;

  bool _isCompressing = false;
  double _progress = 0;
  File? _outputFile;
  int? _outputSize;
  Duration? _compressionDuration;
  String _status = '';

  VideoPlayerController? _playerController;
  bool _showPlayer = false;

  final List<String> _qualityLabels = ['480p', '720p', '1080p', '1440p'];
  final List<VideoQuality> _qualityValues = VideoQuality.values;
  int _qualityIndex = 1; // 720p

  final List<String> _bitRateLabels = ['2', '5', '8'];
  int _bitRateIndex = 1; // 5 Mbps

  // ── Image state ──────────────────────────────────────────────────────────
  MediaFile? _imageMediaFile;
  int? _imageSourceSize;
  int _imageSourceWidth = 0;
  int _imageSourceHeight = 0;
  bool _imageIsPicking = false;

  bool _imageIsCompressing = false;
  double _imageProgress = 0;
  File? _imageOutputFile;
  int? _imageOutputSize;
  int _outputImageWidth = 0;
  int _outputImageHeight = 0;
  Duration? _imageCompressionDuration;
  String _imageStatus = '';

  final List<String> _imageQualityLabels = ['60', '80', '95'];
  final List<int> _imageQualityValues = [60, 80, 95];
  int _imageQualityIndex = 1; // 80

  final List<String> _maxDimPercentLabels = ['25%', '50%', '75%', '100%'];
  final List<int> _maxDimPercentValues = [25, 50, 75, 100];
  int _maxDimPercentIndex = 3; // 100%

  bool _squareCrop = false;
  bool _showImageViewer = false;

  // ── Thumbnail state ────────────────────────────────────────────────────────
  File? _thumbnailFile;
  bool _showThumbnailViewer = false;
  bool _isCreatingThumbnail = false;

  // ── Gallery save state ─────────────────────────────────────────────────────
  String _gallerySaveStatus = '';
  bool _isSavingToGallery = false;
  bool _imageSavedToGallery = false;
  bool _videoSavedToGallery = false;
  String _thumbnailGalleryStatus = '';
  bool _isSavingThumbnail = false;
  bool _thumbnailSavedToGallery = false;

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  // ── Video actions ─────────────────────────────────────────────────────────

  Future<void> _pickVideo() async {
    // ignore: avoid_print
    print('[Demo] _pickVideo: opening native media picker…');
    setState(() => _isPicking = true);
    try {
      final files = await showMediaPicker(
        context: context,
        type: MediaPickerType.videos,
      );
      if (files.isEmpty) {
        // ignore: avoid_print
        print('[Demo] _pickVideo: user cancelled');
        return;
      }
      final file = File(files.first.path);
      final size = file.lengthSync();
      // ignore: avoid_print
      print('[Demo] _pickVideo: selected ${files.first.name} ($size bytes)');
      setState(() {
        _mediaFile = files.first;
        _sourceSize = size;
        _outputFile = null;
        _outputSize = null;
        _compressionDuration = null;
        _status = '';
        _showPlayer = false;
        _thumbnailFile = null;
        _thumbnailSavedToGallery = false;
        _thumbnailGalleryStatus = '';
        _videoSavedToGallery = false;
        _gallerySaveStatus = '';
      });
    } catch (e) {
      // ignore: avoid_print
      print('[Demo] _pickVideo error: $e');
      setState(() => _status = 'Error picking video: $e');
    } finally {
      setState(() => _isPicking = false);
    }
  }

  void _playCompressedVideo() {
    if (_outputFile == null) return;

    // Dispose previous controller
    _playerController?.dispose();

    final controller = VideoPlayerController(
      dataSource: VideoDataSource.file(_outputFile!.path),
      autoPlay: true,
      autoDispose: false,
    );
    controller.initialize();
    _playerController = controller;

    setState(() => _showPlayer = true);
  }

  void _closePlayer() {
    _playerController?.dispose();
    _playerController = null;
    setState(() => _showPlayer = false);
  }

  Future<void> _compressVideo() async {
    if (_mediaFile == null) return;

    final file = File(_mediaFile!.path);
    final quality = _qualityValues[_qualityIndex];
    final bitRate = int.parse(_bitRateLabels[_bitRateIndex]);

    // ── Get video info before compression ──────────────────────────
    // ignore: avoid_print
    print('\n📄 INPUT FILE INFO:');
    // ignore: avoid_print
    print('  • Path: ${file.path}');
    // ignore: avoid_print
    print('  • File exists: ${file.existsSync()}');
    // ignore: avoid_print
    print(
      '  • File size: ${(file.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    try {
      final videoInfo = await DartNativeCompressor.getVideoInfo(file);
      // ignore: avoid_print
      print(
        '  • Video info: width=${videoInfo.width}, height=${videoInfo.height}, duration=${videoInfo.duration}ms, title=${videoInfo.title}, author=${videoInfo.author}',
      );
      // ignore: avoid_print
      print('  • Width: ${videoInfo.width}');
      // ignore: avoid_print
      print('  • Height: ${videoInfo.height}');
      // ignore: avoid_print
      print('  • Duration: ${videoInfo.duration}ms');
      if (videoInfo.filesize != null) {
        // ignore: avoid_print
        print(
          '  • Filesize from metadata: ${(videoInfo.filesize! / 1024 / 1024).toStringAsFixed(2)} MB',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('  ⚠️ Could not get video info: $e');
    }

    // ── Compression parameters ─────────────────────────────────────
    // ignore: avoid_print
    print('\n⚙️ COMPRESSION PARAMETERS:');
    // ignore: avoid_print
    print('  • Quality: ${quality.name} (${_qualityLabels[_qualityIndex]})');
    // ignore: avoid_print
    print('  • Custom bitrate: $bitRate Mbps');
    // ignore: avoid_print
    print('  • Source size: ${_formatSize(_sourceSize ?? 0)}');

    setState(() {
      _isCompressing = true;
      _progress = 0;
      _status = 'Compressing…';
    });

    final startTime = DateTime.now();

    try {
      // ignore: avoid_print
      print('\n🔄 Starting compression...\n');

      final output = await DartNativeCompressor.compressVideo(
        file,
        quality: quality,
        customBitRate: bitRate,
        onProgress: (double p) {
          // ignore: avoid_print
          print('📊 Compression progress: ${(p * 100).toStringAsFixed(1)}%');
          if (mounted) setState(() => _progress = p);
        },
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (output != null && output.existsSync()) {
        // ignore: avoid_print
        print('\n═══════════════════════════════════════════════════');
        // ignore: avoid_print
        print('✅ COMPRESSION SUCCESSFUL');
        // ignore: avoid_print
        print('═══════════════════════════════════════════════════');
        // ignore: avoid_print
        print('📤 OUTPUT FILE INFO:');
        // ignore: avoid_print
        print('  • Path: ${output.path}');
        // ignore: avoid_print
        print('  • File exists: ${output.existsSync()}');
        // ignore: avoid_print
        print(
          '  • File size: ${(output.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
        );
        // ignore: avoid_print
        print(
          '  • Original size: ${(file.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
        );
        final reduction =
            ((file.lengthSync() - output.lengthSync()) /
            file.lengthSync() *
            100);
        // ignore: avoid_print
        print('  • Size reduction: ${reduction.toStringAsFixed(1)}%');
        // ignore: avoid_print
        print(
          '  • Duration: ${duration.inSeconds}s (${duration.inMinutes}m ${duration.inSeconds % 60}s)',
        );
        // ignore: avoid_print
        print('═══════════════════════════════════════════════════\n');

        // Try to get output video info
        try {
          final outputInfo = await DartNativeCompressor.getVideoInfo(output);
          // ignore: avoid_print
          print('📹 OUTPUT VIDEO INFO:');
          // ignore: avoid_print
          print(
            '  • width=${outputInfo.width}, height=${outputInfo.height}, duration=${outputInfo.duration}ms, filesize=${outputInfo.filesize}',
          );
        } catch (e) {
          // ignore: avoid_print
          print('⚠️ Could not get output video info: $e');
        }

        setState(() {
          _outputFile = output;
          _outputSize = output.lengthSync();
          _compressionDuration = duration;
          _isCompressing = false;
          _status = 'Compression complete ✓';
        });
      } else {
        // ignore: avoid_print
        print('\n⚠️ Compression returned null output file');
        setState(() {
          _isCompressing = false;
          _status = 'Compression failed — no output file';
        });
      }
    } catch (e, stackTrace) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // ignore: avoid_print
      print('\n═══════════════════════════════════════════════════');
      // ignore: avoid_print
      print('❌ GENERAL EXCEPTION');
      // ignore: avoid_print
      print('═══════════════════════════════════════════════════');
      // ignore: avoid_print
      print('  • Error: $e');
      // ignore: avoid_print
      print('  • Type: ${e.runtimeType}');
      // ignore: avoid_print
      print('  • Duration before error: ${duration.inSeconds}s');
      // ignore: avoid_print
      print('  • Stack trace:\n$stackTrace');
      // ignore: avoid_print
      print('═══════════════════════════════════════════════════\n');

      setState(() {
        _isCompressing = false;
        _status = 'Error: $e';
      });
    }
  }

  // ── Image actions ─────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    // ignore: avoid_print
    print('[Demo] _pickImage: opening native media picker…');
    setState(() => _imageIsPicking = true);
    try {
      final files = await showMediaPicker(
        context: context,
        type: MediaPickerType.images,
      );
      if (files.isEmpty) {
        // ignore: avoid_print
        print('[Demo] _pickImage: user cancelled');
        return;
      }
      final file = File(files.first.path);
      final size = file.lengthSync();
      // ignore: avoid_print
      print('[Demo] _pickImage: selected ${files.first.name} ($size bytes)');

      // Get image dimensions
      int srcW = 0, srcH = 0;
      try {
        final info = await DartNativeCompressor.getImageInfo(file);
        srcW = info.width ?? 0;
        srcH = info.height ?? 0;
        // ignore: avoid_print
        print('[Demo] _pickImage: dimensions ${srcW}x${srcH}');
      } catch (_) {
        // ignore: avoid_print
        print('[Demo] _pickImage: could not read dimensions');
      }

      setState(() {
        _imageMediaFile = files.first;
        _imageSourceSize = size;
        _imageSourceWidth = srcW;
        _imageSourceHeight = srcH;
        _imageOutputFile = null;
        _imageOutputSize = null;
        _imageCompressionDuration = null;
        _imageStatus = '';
        _imageSavedToGallery = false;
        _gallerySaveStatus = '';
        _outputImageWidth = 0;
        _outputImageHeight = 0;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[Demo] _pickImage error: $e');
      setState(() => _imageStatus = 'Error picking image: $e');
    } finally {
      setState(() => _imageIsPicking = false);
    }
  }

  Future<void> _compressImage() async {
    if (_imageMediaFile == null) return;

    final filePath = _imageMediaFile!.path;
    final quality = _imageQualityValues[_imageQualityIndex];
    final percent = _maxDimPercentValues[_maxDimPercentIndex];

    // Compute maxDimension from source dimensions + percentage
    int? maxDim;
    if (percent < 100) {
      final longerSide = _imageSourceWidth > 0 && _imageSourceHeight > 0
          ? (_imageSourceWidth > _imageSourceHeight
                ? _imageSourceWidth
                : _imageSourceHeight)
          : null;
      if (longerSide != null) {
        maxDim = (longerSide * percent / 100).round();
        // ignore: avoid_print
        print(
          '[Demo] _compressImage: source longerSide=$longerSide, ${percent}% → maxDim=$maxDim',
        );
      }
    } else {
      maxDim = null; // 100% = no resize
    }

    setState(() {
      _imageIsCompressing = true;
      _imageProgress = 0;
      _imageStatus = 'Compressing…';
    });

    final startTime = DateTime.now();

    try {
      // ignore: avoid_print
      print('\n🖼️ Starting image compression...\n');

      final output = await DartNativeCompressor.compressImage(
        filePath,
        quality: quality,
        maxDimension: maxDim,
        cropAspectRatio: _squareCrop
            ? CropAspectRatio.square
            : CropAspectRatio.original,
        onProgress: (double p) {
          // ignore: avoid_print
          print(
            '📊 Image compression progress: ${(p * 100).toStringAsFixed(1)}%',
          );
          if (mounted) setState(() => _imageProgress = p);
        },
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (output != null && output.existsSync()) {
        final srcFile = File(filePath);
        final reduction =
            ((srcFile.lengthSync() - output.lengthSync()) /
            srcFile.lengthSync() *
            100);
        // ignore: avoid_print
        print(
          '✅ Image compression complete: '
          '${(srcFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB → '
          '${(output.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB '
          '(${reduction.toStringAsFixed(1)}% smaller) '
          'in ${duration.inSeconds}s',
        );

        // Get output image dimensions
        int outW = 0, outH = 0;
        try {
          final outInfo = await DartNativeCompressor.getImageInfo(output);
          outW = outInfo.width ?? 0;
          outH = outInfo.height ?? 0;
          // ignore: avoid_print
          print('  • Output dimensions: ${outW}x${outH}');
        } catch (_) {
          // ignore: avoid_print
          print('  • Could not read output dimensions');
        }

        setState(() {
          _imageOutputFile = output;
          _imageOutputSize = output.lengthSync();
          _outputImageWidth = outW;
          _outputImageHeight = outH;
          _imageCompressionDuration = duration;
          _imageIsCompressing = false;
          _imageStatus = 'Compression complete ✓';
        });
      } else {
        // ignore: avoid_print
        print('\n⚠️ Image compression returned null output file');
        setState(() {
          _imageIsCompressing = false;
          _imageStatus = 'Compression failed — no output file';
        });
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('❌ Image compression error: $e\n$stackTrace');
      setState(() {
        _imageIsCompressing = false;
        _imageStatus = 'Error: $e';
      });
    }
  }

  // ── Formatting ──────────────────────────────────────────────────────────

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes >= 1) {
      final rem = d.inSeconds % 60;
      return '${d.inMinutes}m ${rem}s';
    }
    if (d.inSeconds >= 1) return '${d.inSeconds}s';
    return '${d.inMilliseconds} ms';
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // If player is shown, render fullscreen player
    if (_showPlayer && _playerController != null) {
      return _buildPlayerView();
    }

    // If image viewer is shown, render fullscreen image viewer
    if (_showImageViewer && _imageOutputFile != null) {
      return _buildImageViewer();
    }

    // If thumbnail viewer is shown, render fullscreen thumbnail viewer
    if (_showThumbnailViewer && _thumbnailFile != null) {
      return _buildThumbnailViewer();
    }

    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'Compressor Demo',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: SegmentedControl(
              segments: const ['Image', 'Video'],
              selectedIndex: _tabIndex,
              onValueChanged: (i) {
                setState(() => _tabIndex = i);
              },
              labelFontStyle: const TextStyle(color: Color(0xFF8E8E93)),
              selectedLabelFontStyle: const TextStyle(color: Color(0xFFFFFFFF)),
            ),
          ),
          Expanded(child: _tabIndex == 0 ? _buildImageTab() : _buildVideoTab()),
        ],
      ),
    );
  }

  // ── Video tab ─────────────────────────────────────────────────────────────

  Widget _buildVideoTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Intro ─────────────────────────────────────────────────
        const _SectionHeader('How it works'),
        const SizedBox(height: 8),
        const Text(
          'Pick a video from your device, then compress it using native '
          'platform codecs (AVFoundation on iOS, MediaCodec on Android). '
          'Progress is reported in real time via FFI callbacks.',
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
        ),
        const SizedBox(height: 24),

        // ── Pick video ───────────────────────────────────────────
        const _SectionHeader('1 · Pick a Video'),
        const SizedBox(height: 12),
        _ActionButton(
          label: _mediaFile != null ? 'Change Video' : 'Pick Video',
          isLoading: _isPicking,
          onTap: _isCompressing || _isPicking ? () {} : _pickVideo,
        ),
        if (_mediaFile != null) ...[
          const SizedBox(height: 10),
          _ResultRow(
            label: 'Source',
            value:
                '${_mediaFile!.name} '
                '(${_formatSize(_sourceSize ?? 0)})',
          ),
        ],
        const SizedBox(height: 24),

        // ── Quality settings ──────────────────────────────────────
        const _SectionHeader('2 · Quality'),
        const SizedBox(height: 12),
        _ChipSelector(
          items: _qualityLabels,
          selectedIndex: _qualityIndex,
          onChanged: _isCompressing
              ? null
              : (i) => setState(() => _qualityIndex = i),
        ),
        const SizedBox(height: 16),
        const _SectionHeader('3 · Max Bitrate'),
        const SizedBox(height: 12),
        _ChipSelector(
          items: _bitRateLabels.map((b) => '$b Mbps').toList(),
          selectedIndex: _bitRateIndex,
          onChanged: _isCompressing
              ? null
              : (i) => setState(() => _bitRateIndex = i),
        ),
        const SizedBox(height: 24),

        // ── Compress ──────────────────────────────────────────────
        _ActionButton(
          label: _isCompressing
              ? 'Compressing… ${(_progress * 100).toStringAsFixed(0)}%'
              : 'Compress Video',
          isLoading: _isCompressing,
          onTap: _mediaFile != null && !_isCompressing ? _compressVideo : () {},
        ),

        // ── Progress bar ──────────────────────────────────────────
        if (_isCompressing) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _progress,
            color: const Color(0xFF0A84FF),
            backgroundColor: const Color(0xFF2C2C2E),
          ),
        ],

        // ── Thumbnail ────────────────────────────────────────────
        if (_mediaFile != null) ...[
          const SizedBox(height: 16),
          _ActionButton(
            label: _thumbnailFile != null
                ? '🖼  Display Thumbnail'
                : '🖼  Create Thumbnail',
            isLoading: _isCreatingThumbnail,
            onTap: _isCreatingThumbnail
                ? () {}
                : _thumbnailFile != null
                ? () => setState(() => _showThumbnailViewer = true)
                : _createThumbnail,
          ),
          if (_thumbnailFile != null) ...[
            const SizedBox(height: 12),
            _ActionButton(
              label: _thumbnailSavedToGallery
                  ? '✓  Saved to Gallery'
                  : '💾  Save to Gallery',
              isLoading: _isSavingThumbnail,
              onTap: !_thumbnailSavedToGallery && !_isSavingThumbnail
                  ? () => _saveToGallery(
                      _thumbnailFile!,
                      mediaType: 'image',
                      isThumbnail: true,
                    )
                  : () {},
            ),
            if (_thumbnailGalleryStatus.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _thumbnailGalleryStatus,
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
              ),
            ],
          ],
        ],

        // ── Result ────────────────────────────────────────────────
        if (_outputFile != null) ...[
          const SizedBox(height: 16),
          _ResultRow(
            label: 'Output',
            value:
                '${_outputFile!.path.split('/').last} '
                '(${_formatSize(_outputSize ?? 0)})',
          ),
          if (_sourceSize != null && _outputSize != null) ...[
            const SizedBox(height: 4),
            _ResultRow(
              label: 'Reduction',
              value: _sourceSize! > 0
                  ? '${((1 - _outputSize! / _sourceSize!) * 100).toStringAsFixed(1)}% smaller'
                  : '—',
            ),
          ],
          if (_compressionDuration != null) ...[
            const SizedBox(height: 4),
            _ResultRow(
              label: 'Compression time',
              value: _formatDuration(_compressionDuration!),
            ),
          ],
          const SizedBox(height: 12),
          // ── Play Video button ───────────────────────────────────
          _ActionButton(
            label: '▶  Play Compressed Video',
            isLoading: false,
            onTap: _isCompressing ? () {} : _playCompressedVideo,
          ),
          const SizedBox(height: 12),
          // ── Save to Gallery button ──────────────────────────────
          _ActionButton(
            label: _videoSavedToGallery
                ? '✓  Saved to Gallery'
                : '💾  Save to Gallery',
            isLoading: _isSavingToGallery,
            onTap: !_videoSavedToGallery && !_isSavingToGallery
                ? () => _saveToGallery(_outputFile!, mediaType: 'video')
                : () {},
          ),
          if (_gallerySaveStatus.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _gallerySaveStatus,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
          ],
        ],

        // ── Status ────────────────────────────────────────────────
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _status,
            style: TextStyle(
              color: _status.contains('Error')
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFF8E8E93),
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  // ── Image tab ─────────────────────────────────────────────────────────────

  Widget _buildImageTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Intro ─────────────────────────────────────────────────
        const _SectionHeader('How it works'),
        const SizedBox(height: 8),
        const Text(
          'Pick an image from your device, then compress it using bicubic '
          'native resizing (Catmull-Rom filter). EXIF orientation is '
          'automatically preserved.',
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
        ),
        const SizedBox(height: 24),

        // ── Pick image ───────────────────────────────────────────
        const _SectionHeader('1 · Pick an Image'),
        const SizedBox(height: 12),
        _ActionButton(
          label: _imageMediaFile != null ? 'Change Image' : 'Pick Image',
          isLoading: _imageIsPicking,
          onTap: _imageIsCompressing || _imageIsPicking ? () {} : _pickImage,
        ),
        if (_imageMediaFile != null) ...[
          const SizedBox(height: 10),
          _ResultRow(
            label: 'Source',
            value:
                '${_imageMediaFile!.name} '
                '(${_formatSize(_imageSourceSize ?? 0)})',
          ),
          if (_imageSourceWidth > 0 && _imageSourceHeight > 0) ...[
            const SizedBox(height: 4),
            _ResultRow(
              label: 'Dimensions',
              value: '${_imageSourceWidth} × $_imageSourceHeight px',
            ),
          ],
        ],
        const SizedBox(height: 24),

        // ── Quality settings ──────────────────────────────────────
        const _SectionHeader('2 · JPEG Quality'),
        const SizedBox(height: 12),
        _ChipSelector(
          items: _imageQualityLabels.map((q) => '$q%').toList(),
          selectedIndex: _imageQualityIndex,
          onChanged: _imageIsCompressing
              ? null
              : (i) => setState(() => _imageQualityIndex = i),
        ),
        const SizedBox(height: 16),
        const _SectionHeader('3 · Resize Dimension (% of source)'),
        const SizedBox(height: 12),
        _ChipSelector(
          items: _maxDimPercentLabels.toList(),
          selectedIndex: _maxDimPercentIndex,
          onChanged: _imageIsCompressing
              ? null
              : (i) => setState(() => _maxDimPercentIndex = i),
        ),
        if (_imageSourceWidth > 0 && _imageSourceHeight > 0) ...[
          const SizedBox(height: 6),
          Text(
            '100% = ${_imageSourceWidth > _imageSourceHeight ? _imageSourceWidth : _imageSourceHeight}px (longer side)',
            style: const TextStyle(color: Color(0xFF636366), fontSize: 11),
          ),
        ],
        const SizedBox(height: 16),
        const _SectionHeader('4 · Square Crop'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Checkbox(
              value: _squareCrop,
              onChanged: _imageIsCompressing
                  ? null
                  : (v) => setState(() => _squareCrop = v ?? false),
            ),
            const SizedBox(width: 10),
            const Text(
              'Crop to square',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Compress ──────────────────────────────────────────────
        _ActionButton(
          label: _imageIsCompressing
              ? 'Compressing… ${(_imageProgress * 100).toStringAsFixed(0)}%'
              : 'Compress Image',
          isLoading: _imageIsCompressing,
          onTap: _imageMediaFile != null && !_imageIsCompressing
              ? _compressImage
              : () {},
        ),

        // ── Progress bar ──────────────────────────────────────────
        if (_imageIsCompressing) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _imageProgress,
            color: const Color(0xFF0A84FF),
            backgroundColor: const Color(0xFF2C2C2E),
          ),
        ],

        // ── Result ────────────────────────────────────────────────
        if (_imageOutputFile != null) ...[
          const SizedBox(height: 16),
          _ResultRow(
            label: 'Output',
            value:
                '${_imageOutputFile!.path.split('/').last} '
                '(${_formatSize(_imageOutputSize ?? 0)})',
          ),
          if (_outputImageWidth > 0 && _outputImageHeight > 0) ...[
            const SizedBox(height: 4),
            _ResultRow(
              label: 'Dimensions',
              value: '$_outputImageWidth × $_outputImageHeight px',
            ),
          ],
          if (_imageSourceSize != null && _imageOutputSize != null) ...[
            const SizedBox(height: 4),
            _ResultRow(
              label: 'Reduction',
              value: _imageSourceSize! > 0
                  ? '${((1 - _imageOutputSize! / _imageSourceSize!) * 100).toStringAsFixed(1)}% smaller'
                  : '—',
            ),
          ],
          if (_imageCompressionDuration != null) ...[
            const SizedBox(height: 4),
            _ResultRow(
              label: 'Compression time',
              value: _formatDuration(_imageCompressionDuration!),
            ),
          ],
          const SizedBox(height: 12),
          _ActionButton(
            label: '🖼  Display Compressed Image',
            isLoading: false,
            onTap: _imageIsCompressing
                ? () {}
                : () => setState(() => _showImageViewer = true),
          ),
          const SizedBox(height: 12),
          // ── Save to Gallery button ──────────────────────────────
          _ActionButton(
            label: _imageSavedToGallery
                ? '✓  Saved to Gallery'
                : '💾  Save to Gallery',
            isLoading: _isSavingToGallery,
            onTap: !_imageSavedToGallery && !_isSavingToGallery
                ? () => _saveToGallery(_imageOutputFile!, mediaType: 'image')
                : () {},
          ),
          if (_gallerySaveStatus.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _gallerySaveStatus,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
          ],
        ],

        // ── Status ────────────────────────────────────────────────
        if (_imageStatus.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _imageStatus,
            style: TextStyle(
              color: _imageStatus.contains('Error')
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFF8E8E93),
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  // ── Image viewer ──────────────────────────────────────────────────────────

  void _closeImageViewer() => setState(() => _showImageViewer = false);

  // ── Thumbnail actions ─────────────────────────────────────────────────────

  Future<void> _createThumbnail() async {
    if (_mediaFile == null) return;
    final srcFile = File(_mediaFile!.path);
    setState(() => _isCreatingThumbnail = true);
    try {
      final thumb = await DartNativeCompressor.getVideoThumbnail(
        srcFile,
        quality: 90,
      );
      if (thumb != null) {
        // ignore: avoid_print
        print('[Demo] _createThumbnail: success at ${thumb.path}');
      }
      setState(() => _thumbnailFile = thumb);
    } catch (e) {
      // ignore: avoid_print
      print('[Demo] _createThumbnail error: $e');
    } finally {
      setState(() => _isCreatingThumbnail = false);
    }
  }

  void _closeThumbnailViewer() => setState(() => _showThumbnailViewer = false);

  // ── Gallery save actions ───────────────────────────────────────────────────

  Future<void> _saveToGallery(
    File file, {
    String mediaType = 'image',
    bool isThumbnail = false,
  }) async {
    // ignore: avoid_print
    print(
      '[Demo] _saveToGallery: path=${file.path} exists=${file.existsSync()} mediaType=$mediaType size=${file.lengthSync()} isThumbnail=$isThumbnail',
    );
    setState(() {
      if (isThumbnail) {
        _isSavingThumbnail = true;
        _thumbnailGalleryStatus = 'Saving…';
      } else {
        _isSavingToGallery = true;
        _gallerySaveStatus = 'Saving…';
      }
    });
    try {
      final success = await DartNativeCompressor.saveToGallery(
        file,
        mediaType: mediaType,
      );
      // ignore: avoid_print
      print('[Demo] _saveToGallery: success=$success');

      if (success) {
        setState(() {
          if (isThumbnail) {
            _thumbnailSavedToGallery = true;
            _isSavingThumbnail = false;
            _thumbnailGalleryStatus = '';
          } else if (mediaType == 'video') {
            _videoSavedToGallery = true;
            _isSavingToGallery = false;
            _gallerySaveStatus = '';
          } else {
            _imageSavedToGallery = true;
            _isSavingToGallery = false;
            _gallerySaveStatus = '';
          }
        });
      } else {
        setState(() {
          if (isThumbnail) {
            _thumbnailGalleryStatus = 'Failed to save to gallery';
            _isSavingThumbnail = false;
          } else {
            _gallerySaveStatus = 'Failed to save to gallery';
            _isSavingToGallery = false;
          }
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('[Demo] _saveToGallery threw: $e');
      setState(() {
        if (isThumbnail) {
          _thumbnailGalleryStatus = 'Error: $e';
          _isSavingThumbnail = false;
        } else {
          _gallerySaveStatus = 'Error: $e';
          _isSavingToGallery = false;
        }
      });
    }
  }

  // ── Widget builders ────────────────────────────────────────────────────────

  Widget _buildImageViewer() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        leading: BackButton(
          iconColor: const Color(0xFFFFFFFF),
          onTap: _closeImageViewer,
        ),
        title: const Text(
          'Compressed Image',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            color: const Color(0xFF000000),
            child: Center(
              child: Image.file(
                _imageOutputFile!,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Thumbnail viewer ──────────────────────────────────────────────────────

  Widget _buildThumbnailViewer() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        leading: BackButton(
          iconColor: const Color(0xFFFFFFFF),
          onTap: _closeThumbnailViewer,
        ),
        title: const Text(
          'Video Thumbnail',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            color: const Color(0xFF000000),
            child: Center(
              child: Image.file(
                _thumbnailFile!,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Player view ──────────────────────────────────────────────────────────

  Widget _buildPlayerView() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        leading: BackButton(
          iconColor: const Color(0xFFFFFFFF),
          onTap: _closePlayer,
        ),
        title: const Text(
          'Compressed Video',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFF000000),
        child: VideoPlayerWithControls(
          controller: _playerController!,
          controlsMode: VideoControlsMode.overlay,
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3C)),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0A84FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF636366),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(items.length, (i) {
        final selected = i == selectedIndex;
        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(i) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF0A84FF)
                  : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? const Color(0xFF0A84FF)
                    : const Color(0xFF3A3A3C),
              ),
            ),
            child: Text(
              items[i],
              style: TextStyle(
                color: selected
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFFAEAEB2),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
