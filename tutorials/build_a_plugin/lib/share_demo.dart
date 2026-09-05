/// Share demo — pick media via dartnative_media_picker, then share via
/// dartnative_share's native share sheet.
///
/// Exercises the public API on iOS and Android:
///   • Share.share(text)
///       — text-only share
///   • Share.shareFiles(paths, mimeTypes:, text:)
///       — one OR many files with optional caption;
///         single ⇒ Intent.ACTION_SEND / NSURL,
///         multi  ⇒ Intent.ACTION_SEND_MULTIPLE / [NSURL]
///   • Share.shareWithResult(text)
///       — same sheet, but the Future completes when the sheet CLOSES,
///         reporting the picked target (or that it was dismissed)
///
/// Visual chrome: Scaffold + AppBar (white title on a dark-gray bar) over
/// a black ListView body.
library;

import 'dart:async';
import 'dart:io';

import 'package:dartnative/dartnative.dart'
    hide showMediaPicker, MediaPickerType, MediaFile;
import 'package:dartnative_compressor/dartnative_compressor.dart';
import 'package:dartnative_share/dartnative_share.dart';
import 'package:dartnative_media_picker/dartnative_media_picker.dart';

/// Default caption used to initialise the TextField. The user can edit it
/// before sharing — the live controller value is what actually gets passed to
/// `Share.share` / `Share.shareFiles`.
const _defaultCaption =
    'Check out dartnative_share from DartNative! https://dartnative.com';

class ShareDemoApp extends StatelessWidget {
  const ShareDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App(
      title: 'dartnative_share',
      theme: ThemeData.dark(),
      home: const ShareDemoScreen(),
    );
  }
}

class ShareDemoScreen extends StatefulWidget {
  const ShareDemoScreen({super.key});

  @override
  State<ShareDemoScreen> createState() => _ShareDemoScreenState();
}

class _ShareDemoScreenState extends State<ShareDemoScreen> {
  List<MediaFile> _picked = const [];
  String _status = '';

  /// Video file path → extracted poster-frame path (JPG in tmp). The thumbnail
  /// strip reads this map and falls back to a play-icon placeholder while a
  /// frame is still being extracted. Cleared on `_clearPicked` / new pick.
  final Map<String, String> _videoThumbs = {};

  /// User-editable caption. Initialised with [_defaultCaption]; read live on
  /// every share button tap so edits are picked up without rebuilds.
  late final _captionController = TextEditingController(text: _defaultCaption);

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickMedia() async {
    try {
      // maxSelection > 1 selects the multi-pick path on Android
      // (PickMultipleVisualMedia); 0 falls back to single-pick.
      final files = await showMediaPicker(
        type: MediaPickerType.imagesAndVideos,
        maxSelection: 20,
      );
      setState(() {
        _picked = files;
        _videoThumbs.clear();
        _status = files.isEmpty
            ? 'Picker cancelled — nothing selected.'
            : 'Picked ${files.length} item(s).';
      });
      // Fire-and-forget thumbnail extraction for every video. Each callback
      // setState's the new thumb in; the row rebuilds as they resolve.
      for (final f in files.where((f) => f.type == 'video')) {
        _extractVideoThumb(f.path);
      }
    } catch (e) {
      setState(() => _status = 'Pick failed: $e');
    }
  }

  Future<void> _extractVideoThumb(String videoPath) async {
    // Uses dartnative_compressor (AVAssetImageGenerator on iOS,
    // MediaMetadataRetriever on Android). Defaults to the first frame.
    final out = await DartNativeCompressor.getVideoThumbnail(File(videoPath));
    if (out == null || !mounted) return;
    setState(() => _videoThumbs[videoPath] = out.path);
  }

  void _shareText() {
    final text = _captionController.text;
    if (text.trim().isEmpty) {
      setState(() => _status = 'Type a caption...');
      return;
    }
    Share.share(text);
    setState(() => _status = 'Presented share sheet with text.');
  }

  Future<void> _shareWithResult() async {
    final text = _captionController.text;
    if (text.trim().isEmpty) {
      setState(() => _status = 'Type a caption...');
      return;
    }
    setState(() => _status = 'Waiting for the share sheet…');
    // Unlike Share.share (fire-and-forget), this Future completes when the
    // sheet CLOSES — reporting the chosen target, or that the user swiped
    // the sheet away. See the plugin docs for how the result crosses the
    // FFI boundary without blocking the isolate.
    final result = await Share.shareWithResult(text);
    if (!mounted) return;
    setState(() {
      _status = switch (result.status) {
        ShareResultStatus.success =>
          'Shared ✓${result.raw.isEmpty ? '' : ' via ${result.raw}'}',
        ShareResultStatus.dismissed => 'Share sheet dismissed.',
        ShareResultStatus.unavailable => 'Share result unavailable.',
      };
    });
  }

  void _sharePicked() {
    if (_picked.isEmpty) {
      setState(() => _status = 'Pick at least one item first.');
      return;
    }
    final paths = [for (final f in _picked) f.path];
    // Map MediaFile.type ("image" / "video") to a coarse MIME — UIActivityVC
    // ignores it on iOS, Android uses it for the chooser type + grants.
    final mimes = [
      for (final f in _picked) f.type == 'video' ? 'video/*' : 'image/*',
    ];
    final count = paths.length;
    final caption = _captionController.text.trim();
    Share.shareFiles(
      paths,
      mimeTypes: mimes,
      text: caption.isEmpty ? null : caption,
    );
    // Reset the picker state — fire-and-forget API means we don't get a
    // completion callback from the OS share sheet, so we assume success
    // and clear immediately. User can pick again to share more.
    setState(() {
      _picked = const [];
      _videoThumbs.clear();
      _status = 'Presented share sheet with $count item(s) + caption.';
    });
  }

  void _clearPicked() {
    setState(() {
      _picked = const [];
      _videoThumbs.clear();
      _status = '';
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'dartnative_share',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // ── Subtitle ─────────────────────────────────────────────────
          const Text(
            'Share media or text from your DartNative app to other apps.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── 1. Pick media ─────────────────────────────────────────────
          const _SectionHeader('Media'),
          const SizedBox(height: 8),
          const Text(
            'Uses dartnative_media_picker to pick one or many images / '
            'videos from the gallery. Files are copied to a tmp dir.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActionButton(
                  label: 'Pick images / videos',
                  onTap: _pickMedia,
                ),
                if (_picked.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ThumbnailRow(items: _picked, videoThumbs: _videoThumbs),
                  const SizedBox(height: 12),
                  _ActionButton(
                    label: 'Clear selection',
                    onTap: _clearPicked,
                    emphasized: false,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 2. Share ─────────────────────────────────────────────────
          const _SectionHeader('Text'),
          const SizedBox(height: 8),
          const Text(
            'Type in a text that can be shared alone, or along with picked media.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 12),
          _Card(
            child: TextField(
              controller: _captionController,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                hintStyle: TextStyle(color: Color(0xFF636366)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActionButton(label: 'Share text only', onTap: _shareText),
                const SizedBox(height: 8),
                _ActionButton(
                  label: 'Share text with result',
                  onTap: _shareWithResult,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: _picked.isEmpty
                      ? 'Share picked items (pick first)'
                      : 'Share ${_picked.length} item(s) + caption',
                  onTap: _picked.isEmpty ? null : _sharePicked,
                ),
              ],
            ),
          ),

          // ── Status ───────────────────────────────────────────────────
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

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

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Horizontal row of small thumbnails — one per picked [MediaFile].
///
/// • Images render via `Image.file(File(f.path))`.
/// • Videos render a poster-frame thumbnail with a small "▶" marker.
class _ThumbnailRow extends StatelessWidget {
  const _ThumbnailRow({required this.items, required this.videoThumbs});
  final List<MediaFile> items;
  // Video path → extracted poster-frame path (may not yet contain an entry
  // while extraction is in-flight; _Thumb falls back to a solid colour then).
  final Map<String, String> videoThumbs;

  static const double _thumbSize = 64;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _thumbSize,
      child: FastList(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        // Container (not Padding) — the item gap needs a real layout node.
        itemBuilder: (_, i) {
          final f = items[i];
          return Container(
            padding: EdgeInsets.only(left: i == 0 ? 0 : _gap),
            child: _Thumb(
              file: f,
              size: _thumbSize,
              videoThumbPath: f.type == 'video' ? videoThumbs[f.path] : null,
            ),
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.file,
    required this.size,
    this.videoThumbPath,
  });
  final MediaFile file;
  final double size;
  // Pre-extracted JPG frame for videos (null while extraction is pending or
  // when [file] is an image).
  final String? videoThumbPath;

  @override
  Widget build(BuildContext context) {
    final isVideo = file.type == 'video';
    // Show the extracted frame when ready; before that, a solid placeholder.
    final imagePath = isVideo ? videoThumbPath : file.path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF2C2C2E),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imagePath != null)
              Image.file(
                File(imagePath),
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            else if (isVideo)
              const _VideoPlaceholder(),
            if (isVideo)
              Align(
                alignment: Alignment.center,
                // Dark translucent disc behind the glyph so the icon stays
                // readable against any video frame (bright sky, snow, etc.).
                child: Opacity(
                  opacity: 0.3,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF000000),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '▶',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFF5E5CE6));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.emphasized = true,
  });
  final String label;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: disabled
                ? const Color(0xFF48484A)
                : emphasized
                ? const Color(0xFF0A84FF)
                : const Color(0xFF8E8E93),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
