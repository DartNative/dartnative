// dn-stub: ship-docs
/// dartnative_share — Native share sheet for DartNative apps.
///
/// Presents `UIActivityViewController` on iOS and the `ACTION_SEND` chooser on
/// Android, over FFI — no Flutter platform channels required.
///
/// **Usage:**
/// ```dart
/// import 'package:dartnative_share/dartnative_share.dart';
///
/// Share.share('Check this out: https://example.com');
/// ```
library dartnative_share;

export 'src/share.dart';
export 'src/share_ffi_bindings.dart';
