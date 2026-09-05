/// FFI bindings for the dartnative_share native layer (iOS + Android).
///
/// On iOS the @_cdecl symbols are linked into the process binary via
/// CocoaPods, so we resolve them through `DynamicLibrary.process()`. On
/// Android the JNI bridge lives in `libdartnative_share.so`.
///
/// Call [ShareFFIBindings.loadSymbols] once at app start, before invoking
/// any `Share.*` method. Typically placed alongside dartnative core init:
///
/// ```dart
/// void main() {
///   ShareFFIBindings.loadSymbols();
///   // ...
/// }
/// ```
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:dartnative/dartnative.dart';

import 'share.dart' show ShareResult, ShareResultStatus;

// ── Native C typedefs ────────────────────────────────────────────────────────

typedef _DNShareTextC = Void Function(Pointer<Utf8>);
typedef _DNShareTextDart = void Function(Pointer<Utf8>);

typedef _DNShareFilesC =
    Void Function(
      Pointer<Pointer<Utf8>>, // paths
      Int32, //                  pathCount
      Pointer<Pointer<Utf8>>, // mimeTypes  (nullable, length == pathCount)
      Int32, //                  mimeCount   (0 if mimeTypes is null)
      Pointer<Utf8>, //          text        (nullable)
    );
typedef _DNShareFilesDart =
    void Function(
      Pointer<Pointer<Utf8>>,
      int,
      Pointer<Pointer<Utf8>>,
      int,
      Pointer<Utf8>,
    );

// Result-reporting variants: same payloads, prefixed with a request token.
typedef _DNShareSetDispatcherC = Void Function(Int64);
typedef _DNShareSetDispatcherDart = void Function(int);

typedef _DNShareTextResultC = Void Function(Int64, Pointer<Utf8>);
typedef _DNShareTextResultDart = void Function(int, Pointer<Utf8>);

typedef _DNShareFilesResultC =
    Void Function(
      Int64,
      Pointer<Pointer<Utf8>>,
      Int32,
      Pointer<Pointer<Utf8>>,
      Int32,
      Pointer<Utf8>,
    );
typedef _DNShareFilesResultDart =
    void Function(
      int,
      Pointer<Pointer<Utf8>>,
      int,
      Pointer<Pointer<Utf8>>,
      int,
      Pointer<Utf8>,
    );

// ── Result dispatcher (Option 3 — framework-invalidated, see
//    docs/plugin_async_callbacks.md) ─────────────────────────────────────────
//
// ONE Pointer.fromFunction dispatcher for the whole plugin. Native stores its
// address in a framework-registered slot (iOS: DNRegisterAsyncDispatcherSlot;
// Android: pointer + DN_IsolateGen generation gate), reads it FRESH before
// every fire, and always fires on the main thread — so a share sheet still
// open across a hot restart can never invoke a freed trampoline.
//   (token, status, raw) — status: 0 dismissed, 1 success, 2 unavailable;
//   raw: chosen activity/component id, or "".
typedef _ShareResultDispatchC = Void Function(Int64, Int32, Pointer<Utf8>);

void _dispatchShareResult(int token, int status, Pointer<Utf8> raw) {
  ShareFFIBindings._completeResult(
    token,
    status,
    raw == nullptr ? '' : raw.toDartString(),
  );
}

final Pointer<NativeFunction<_ShareResultDispatchC>> _shareResultDispatchPtr =
    Pointer.fromFunction<_ShareResultDispatchC>(_dispatchShareResult);

// ── Bindings class ────────────────────────────────────────────────────────────

/// Internal FFI loader for the native share sheet — apps use the [Share] API instead.
class ShareFFIBindings {
  ShareFFIBindings._();

  static late final _DNShareTextDart _shareText;
  static late final _DNShareFilesDart _shareFiles;

  // Result-reporting variants (guarded: absent on older native builds).
  static _DNShareTextResultDart? _shareTextWithResult;
  static _DNShareFilesResultDart? _shareFilesWithResult;

  static bool _loaded = false;

  // ── Result plumbing ────────────────────────────────────────────────────────

  /// token → completer for in-flight *WithResult requests.
  static final Map<int, Completer<ShareResult>> _pending = {};
  static int _nextToken = 1;

  /// Android only: the chooser reports *selection*, never dismissal. We
  /// approximate dismissal Dart-side: the chooser pauses the app, so when the
  /// app RESUMES with a request still pending and no result arrives within a
  /// short grace window, the user closed the sheet without picking a target.
  /// iOS never uses this — its completion handler is authoritative.
  static final _ShareLifecycleObserver _lifecycleObserver =
      _ShareLifecycleObserver();
  static bool _observerAdded = false;

  static void _completeResult(int token, int status, String raw) {
    final completer = _pending.remove(token);
    if (completer == null || completer.isCompleted) return;
    final shareStatus = switch (status) {
      1 => ShareResultStatus.success,
      2 => ShareResultStatus.unavailable,
      _ => ShareResultStatus.dismissed,
    };
    completer.complete(ShareResult(shareStatus, raw: raw));
  }

  static void _onAppResumed() {
    if (!Platform.isAndroid || _pending.isEmpty) return;
    final tokens = _pending.keys.toList();
    Timer(const Duration(milliseconds: 600), () {
      for (final t in tokens) {
        _completeResult(t, 0, ''); // still pending after grace → dismissed
      }
    });
  }

  /// Load all symbols. Call once at app startup.
  static void loadSymbols() {
    if (_loaded) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    final lib = Platform.isAndroid
        ? DynamicLibrary.open('libdartnative_share.so')
        : DynamicLibrary.process();
    _shareText = lib.lookupFunction<_DNShareTextC, _DNShareTextDart>(
      'DNShareText',
    );
    _shareFiles = lib.lookupFunction<_DNShareFilesC, _DNShareFilesDart>(
      'DNShareFiles',
    );

    // Result-reporting variants + dispatcher registration. Guarded so a
    // stale native build (older Pod / .so without the symbols) degrades to
    // "unavailable" results instead of crashing symbol lookup.
    try {
      final setDispatcher = lib
          .lookupFunction<_DNShareSetDispatcherC, _DNShareSetDispatcherDart>(
            'DNShareSetDispatcher',
          );
      _shareTextWithResult = lib
          .lookupFunction<_DNShareTextResultC, _DNShareTextResultDart>(
            'DNShareTextWithResult',
          );
      _shareFilesWithResult = lib
          .lookupFunction<_DNShareFilesResultC, _DNShareFilesResultDart>(
            'DNShareFilesWithResult',
          );
      setDispatcher(_shareResultDispatchPtr.address);
    } catch (e) {
      // ignore: avoid_print
      print('[DNShare] loadSymbols: share-result symbols unavailable: $e');
    }

    _loaded = true;
  }

  /// Present the native share sheet with [text].
  static void shareText(String text) {
    assert(_loaded, 'Call ShareFFIBindings.loadSymbols() first.');
    final ptr = text.toNativeUtf8();
    try {
      _shareText(ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// Like [shareText], but resolves with the outcome (shared / dismissed).
  static Future<ShareResult> shareTextWithResult(String text) {
    assert(_loaded, 'Call ShareFFIBindings.loadSymbols() first.');
    final fn = _shareTextWithResult;
    if (fn == null) {
      return Future.value(const ShareResult(ShareResultStatus.unavailable));
    }
    final token = _beginRequest();
    final ptr = text.toNativeUtf8();
    try {
      fn(token, ptr);
    } finally {
      calloc.free(ptr);
    }
    return _pending[token]!.future;
  }

  static int _beginRequest() {
    final token = _nextToken++;
    _pending[token] = Completer<ShareResult>();
    if (!_observerAdded) {
      _observerAdded = true;
      WidgetsBinding.instance.addObserver(_lifecycleObserver);
    }
    return token;
  }

  /// Present the native share sheet with one or more files.
  ///
  /// - [paths] absolute filesystem paths, at least one.
  /// - [mimeTypes] optional per-file MIME hints. If provided, length must
  ///   equal [paths].length. On iOS it's ignored (the share sheet infers
  ///   from extension); on Android it drives `Intent.type` and the
  ///   MIME-reduction rules for multi-file shares.
  /// - [text] optional caption; becomes `Intent.EXTRA_TEXT` on Android
  ///   (e.g. the WhatsApp photo caption) and an additional `String`
  ///   activity item on iOS.
  ///
  /// Single file ⇒ `Intent.ACTION_SEND` on Android, single `NSURL`
  /// activity item on iOS.
  /// Multiple files ⇒ `Intent.ACTION_SEND_MULTIPLE` on Android, array of
  /// `NSURL` activity items on iOS.
  static void shareFiles(
    List<String> paths, {
    List<String>? mimeTypes,
    String? text,
  }) {
    assert(_loaded, 'Call ShareFFIBindings.loadSymbols() first.');
    if (paths.isEmpty) return;
    _withFileArgs(paths, mimeTypes, text, (pathArr, mimeArr, textPtr) {
      _shareFiles(pathArr, paths.length, mimeArr, mimeTypes?.length ?? 0, textPtr);
    });
  }

  /// Like [shareFiles], but resolves with the outcome (shared / dismissed).
  static Future<ShareResult> shareFilesWithResult(
    List<String> paths, {
    List<String>? mimeTypes,
    String? text,
  }) {
    assert(_loaded, 'Call ShareFFIBindings.loadSymbols() first.');
    final fn = _shareFilesWithResult;
    if (fn == null || paths.isEmpty) {
      return Future.value(const ShareResult(ShareResultStatus.unavailable));
    }
    final token = _beginRequest();
    _withFileArgs(paths, mimeTypes, text, (pathArr, mimeArr, textPtr) {
      fn(token, pathArr, paths.length, mimeArr, mimeTypes?.length ?? 0, textPtr);
    });
    return _pending[token]!.future;
  }

  /// Marshal (paths, mimeTypes, text) into native arrays, run [body], free
  /// everything. Each individual Utf8 pointer is owned and must be freed on
  /// the way out, alongside the arrays themselves — the native side copies
  /// synchronously during the call.
  static void _withFileArgs(
    List<String> paths,
    List<String>? mimeTypes,
    String? text,
    void Function(
      Pointer<Pointer<Utf8>> pathArr,
      Pointer<Pointer<Utf8>> mimeArr,
      Pointer<Utf8> textPtr,
    ) body,
  ) {
    if (mimeTypes != null && mimeTypes.length != paths.length) {
      throw ArgumentError(
        'mimeTypes.length (${mimeTypes.length}) must equal paths.length '
        '(${paths.length}) when provided',
      );
    }

    final pathArr = calloc<Pointer<Utf8>>(paths.length);
    final pathPtrs = <Pointer<Utf8>>[];
    for (var i = 0; i < paths.length; i++) {
      final p = paths[i].toNativeUtf8();
      pathPtrs.add(p);
      pathArr[i] = p;
    }

    Pointer<Pointer<Utf8>> mimeArr = nullptr;
    final mimePtrs = <Pointer<Utf8>>[];
    if (mimeTypes != null) {
      mimeArr = calloc<Pointer<Utf8>>(mimeTypes.length);
      for (var i = 0; i < mimeTypes.length; i++) {
        final m = mimeTypes[i].toNativeUtf8();
        mimePtrs.add(m);
        mimeArr[i] = m;
      }
    }

    final Pointer<Utf8> textPtr =
        (text == null) ? nullptr : text.toNativeUtf8();

    try {
      body(pathArr, mimeArr, textPtr);
    } finally {
      for (final p in pathPtrs) calloc.free(p);
      for (final m in mimePtrs) calloc.free(m);
      calloc.free(pathArr);
      if (mimeArr != nullptr) calloc.free(mimeArr);
      if (textPtr != nullptr) calloc.free(textPtr);
    }
  }
}

/// Routes app-resume events to [ShareFFIBindings._onAppResumed] — the
/// Android dismissed-detection grace window (see the field's doc).
class _ShareLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ShareFFIBindings._onAppResumed();
    }
  }
}
