// dn-stub: ship-docs
/// Presents the native iOS / Android share sheet.
///
/// Drop-in replacement for the `share_plus` package's `Share.share` and
/// `Share.shareXFiles` APIs (simplified to plain-text + one-or-many files
/// with an optional caption).
///
/// ```dart
/// // Text share
/// Share.share('Join with my code: ABC123\n\nhttps://dartnative.com');
///
/// // Single image + caption (e.g. WhatsApp photo + caption)
/// Share.shareFile(
///   '/path/to/photo.jpg',
///   mimeType: 'image/jpeg',
///   text: 'Check out this photo!',
/// );
///
/// // Multiple files (Android: ACTION_SEND_MULTIPLE; iOS: array of NSURLs)
/// Share.shareFiles(
///   ['/tmp/a.jpg', '/tmp/b.mp4'],
///   mimeTypes: ['image/jpeg', 'video/mp4'],
///   text: 'Trip recap',
/// );
/// ```
library;

import 'share_ffi_bindings.dart';

/// How a `*withResult` share ended.
enum ShareResultStatus {
  /// The user picked a share target.
  success,

  /// The user closed the sheet without picking a target.
  ///
  /// iOS reports this exactly (the sheet's completion handler). Android's
  /// chooser only reports *selections*, so dismissal is detected when the
  /// app resumes with the request still unanswered — reliable in practice,
  /// but the timing is approximate.
  dismissed,

  /// The share could not be presented (no UI to attach to), or this build
  /// of the native library predates result reporting.
  unavailable,
}

/// Outcome of a `*withResult` share.
class ShareResult {
  const ShareResult(this.status, {this.raw = ''});

  final ShareResultStatus status;

  /// Platform identifier of the chosen target when [status] is [ShareResultStatus.success]:
  /// the `UIActivity.ActivityType` raw value on iOS (e.g.
  /// `com.apple.UIKit.activity.CopyToPasteboard`), the flattened
  /// `ComponentName` on Android (e.g. `com.whatsapp/.ContactPicker`).
  /// Empty otherwise — and may be empty on success too (iOS reports some
  /// targets, e.g. AirDrop, with a null activity type).
  final String raw;

  @override
  String toString() => 'ShareResult($status${raw.isEmpty ? '' : ', $raw'})';
}

class Share {
  Share._();

  /// Present the system share sheet for [text].
  ///
  /// On iPad the popover is anchored to the top-safe-area; no source rect
  /// is needed for the basic text-share use case.
  static void share(String text) {
    ShareFFIBindings.shareText(text);
  }

  /// Present the system share sheet for the file at [path], optionally
  /// accompanied by a [mimeType] hint and a caption [text]. Convenience
  /// wrapper around [shareFiles] for the common single-file case.
  static void shareFile(String path, {String? mimeType, String? text}) {
    ShareFFIBindings.shareFiles(
      [path],
      mimeTypes: mimeType == null ? null : [mimeType],
      text: text,
    );
  }

  /// Present the system share sheet for one or more files in [paths],
  /// optionally accompanied by per-file [mimeTypes] hints and a caption
  /// [text].
  ///
  /// **iOS**: file URLs are passed as activity items to
  /// `UIActivityViewController`. `mimeTypes` is accepted for API parity
  /// but ignored — the OS infers the type from each file extension.
  ///
  /// **Android**: files are copied into the host app's cache dir and
  /// vended via a `FileProvider`. Single file ⇒ `Intent.ACTION_SEND`;
  /// multiple ⇒ `Intent.ACTION_SEND_MULTIPLE` with a reduced common MIME
  /// type. The optional `text` becomes `Intent.EXTRA_TEXT` — on
  /// WhatsApp it appears as the photo/video caption.
  ///
  /// Throws [ArgumentError] if `mimeTypes` is non-null and its length
  /// does not equal `paths.length`.
  static void shareFiles(
    List<String> paths, {
    List<String>? mimeTypes,
    String? text,
  }) {
    ShareFFIBindings.shareFiles(paths, mimeTypes: mimeTypes, text: text);
  }

  // ── Result-reporting variants ─────────────────────────────────────────────

  /// Like [share], but resolves with the outcome once the sheet closes:
  ///
  /// ```dart
  /// final result = await Share.shareWithResult('Join me: https://…');
  /// if (result.status == ShareResultStatus.success) {
  ///   analytics.log('shared_via', result.raw);
  /// }
  /// ```
  static Future<ShareResult> shareWithResult(String text) =>
      ShareFFIBindings.shareTextWithResult(text);

  /// Like [shareFile], but resolves with the outcome once the sheet closes.
  static Future<ShareResult> shareFileWithResult(
    String path, {
    String? mimeType,
    String? text,
  }) =>
      ShareFFIBindings.shareFilesWithResult(
        [path],
        mimeTypes: mimeType == null ? null : [mimeType],
        text: text,
      );

  /// Like [shareFiles], but resolves with the outcome once the sheet closes.
  static Future<ShareResult> shareFilesWithResult(
    List<String> paths, {
    List<String>? mimeTypes,
    String? text,
  }) =>
      ShareFFIBindings.shareFilesWithResult(
        paths,
        mimeTypes: mimeTypes,
        text: text,
      );
}
