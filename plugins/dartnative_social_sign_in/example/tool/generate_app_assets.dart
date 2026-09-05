// ─────────────────────────────────────────────────────────────────────────────
// generate_app_assets.dart
//
// One-step asset generator for dartnative apps.
// Reads a high-resolution source image and produces:
//   1. Splash screen assets (iOS LaunchScreen + Android splash) via
//      dartnative_splash
//   2. App icon assets (iOS AppIcon.appiconset + Android mipmap)
//
// Usage:  dart run tool/generate_app_assets.dart --source=assets/dn-logo.png --bg=#000000
//         dart run tool/generate_app_assets.dart --source=/abs/path/logo.png --target=/path/to/consumer-app
//
// The source image should be at least 1024×1024 px (for the iOS App Store icon).
// The --bg color is used for the app icon background (default: #000000).
// The --target flag sets the app directory to write assets into (default: playground).
// The splash screen background color is set in pubspec.yaml under dartnative_splash:.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:convert';

import 'package:image/image.dart' as img;

// ── Configuration ─────────────────────────────────────────────────────────────

final _kSizes = _ImageSizes();

class _ImageSizes {
  // iOS splash (LaunchImage) — 260 logical points at 1×, 2×, 3×
  final iosSplash = <int>[260, 520, 780];

  // iOS app icon is a SINGLE 1024×1024 image (Apple's Xcode 14+ default — the
  // asset compiler generates every size/idiom at build). No per-slot table.

  // Android mipmap launcher icons
  final androidIcon = <(String density, int px)>[
    ('mdpi', 48),
    ('hdpi', 72),
    ('xhdpi', 96),
    ('xxhdpi', 144),
    ('xxxhdpi', 192),
  ];
}

// ── CLI ───────────────────────────────────────────────────────────────────────

void main(List<String> args) async {
  // Resolve the playground directory from the script's own location.
  final playgroundDir = File(Platform.script.toFilePath()).parent.parent;

  // --target lets callers write assets into a different consumer app directory.
  // Defaults to the playground itself.
  final targetArg = _arg(args, 'target');
  final targetDir = targetArg != null ? Directory(targetArg) : playgroundDir;

  if (!targetDir.existsSync()) {
    print('ERROR: target directory not found: ${targetDir.path}');
    exit(1);
  }

  // Change working directory so relative --source paths and splash setup resolve.
  Directory.current = targetDir;

  final source = _arg(args, 'source');
  if (source == null) {
    print(
        'Usage: dart run tool/generate_app_assets.dart --source=<path> [--target=<app-dir>]');
    exit(1);
  }

  final _ = _arg(args, 'source-dark');
  final bgHex = _arg(args, 'bg') ?? '#000000';
  final bgColor = _parseHexColor(bgHex);

  if (!File(source).existsSync()) {
    print('ERROR: source image not found: $source');
    print('Run from the playground directory or use --source=<absolute-path>');
    exit(1);
  }

  final srcImage = img.decodeImage(File(source).readAsBytesSync());
  if (srcImage == null) {
    print(
        'ERROR: could not decode source image — ensure it is a valid PNG/JPEG');
    exit(1);
  }
  print('Loaded source: ${srcImage.width}×${srcImage.height}');

  // ── 1. Splash screen ────────────────────────────────────────────────────
  print('\n═══ 1. Splash screen ═══');
  final splashResult = await Process.run(
    'dart',
    ['run', 'dartnative_splash:setup'],
    workingDirectory: Directory.current.path,
  );
  print(splashResult.stdout.toString().trim());
  if (splashResult.exitCode != 0) {
    print('WARNING: dartnative_splash exit code ${splashResult.exitCode}');
    print(splashResult.stderr.toString().trim());
  }

  // ── 2. iOS app icon ────────────────────────────────────────────────────
  print('\n═══ 2. iOS app icon ═══');
  await _generateIosAppIcon(srcImage, bgColor);

  // ── 3. Android app icon ─────────────────────────────────────────────────
  print('\n═══ 3. Android app icon ═══');
  await _generateAndroidAppIcon(srcImage, bgColor);

  print('\n✓ Done. Rebuild from Xcode / Android Studio to see the changes.');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String? _arg(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('--$name=')) return a.substring('--$name='.length);
  }
  return null;
}

img.ColorRgba8 _parseHexColor(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.parse(h, radix: 16);
  return img.ColorRgba8(
    (v >> 16) & 0xFF,
    (v >> 8) & 0xFF,
    v & 0xFF,
    (v >> 24) & 0xFF,
  );
}

/// Resize [src] to [targetPx] square and composite onto a solid [bg] canvas.
img.Image _renderIcon(img.Image src, int targetPx, img.ColorRgba8 bg) {
  final resized = _resize(src, targetPx);
  final canvas = img.Image(width: targetPx, height: targetPx);
  img.fill(canvas, color: bg);
  img.compositeImage(canvas, resized, dstX: 0, dstY: 0);
  return canvas;
}

// ── iOS App Icon ──────────────────────────────────────────────────────────────

const _iosIconDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

Future<void> _generateIosAppIcon(img.Image src, img.ColorRgba8 bg) async {
  final dir = Directory(_iosIconDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // Apple's default since Xcode 14: ship a SINGLE 1024×1024 icon and let the
  // asset compiler (actool) generate every size/idiom at build time. This
  // removes the whole class of wrong-size / duplicate-slot bugs a hand-kept
  // per-slot table produces.
  //
  // The icon MUST be fully opaque — actool rejects an app icon that carries an
  // alpha channel ("can't have alpha"). _renderIcon composites over the solid
  // bg, and convert(numChannels: 3) drops the now-unused alpha channel.
  final icon = _renderIcon(src, 1024, bg).convert(numChannels: 3);
  File('${dir.path}/AppIcon.png').writeAsBytesSync(img.encodePng(icon));
  print('  wrote AppIcon.png  (1024×1024, opaque)');

  // Remove any stale multi-slot icons from an older generator run so the
  // catalog isn't left referencing orphaned AppIcon-*.png files.
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (name.startsWith('AppIcon-') && name.endsWith('.png')) f.deleteSync();
  }

  final contents = <String, Object?>{
    'images': [
      {
        'filename': 'AppIcon.png',
        'idiom': 'universal',
        'platform': 'ios',
        'size': '1024x1024',
      },
    ],
    'info': {'author': 'xcode', 'version': 1},
  };
  File('${dir.path}/Contents.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(contents));
  print('  wrote Contents.json (single-size — Xcode generates the variants)');
}

// ── Android App Icon ──────────────────────────────────────────────────────────

Future<void> _generateAndroidAppIcon(img.Image src, img.ColorRgba8 bg) async {
  for (final (density, px) in _kSizes.androidIcon) {
    final dir = Directory('android/app/src/main/res/mipmap-$density');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final icon = _renderIcon(src, px, bg);
    final path = '${dir.path}/ic_launcher.png';
    File(path).writeAsBytesSync(img.encodePng(icon));
    print(
        '  wrote mipmap-$density/ic_launcher.png  (${icon.width}×${icon.height})');
  }

  // Adaptive icon foreground (Android 8+, 108×108 dp)
  final adaptiveDir = Directory('android/app/src/main/res/mipmap-anydpi-v26');
  if (!adaptiveDir.existsSync()) adaptiveDir.createSync(recursive: true);
  final adaptive = _renderIcon(src, 108, bg);
  File('${adaptiveDir.path}/ic_launcher_foreground.png')
      .writeAsBytesSync(img.encodePng(adaptive));
  print('  wrote mipmap-anydpi-v26/ic_launcher_foreground.png  '
      '(${adaptive.width}×${adaptive.height})');
}

// ── Image resizing ────────────────────────────────────────────────────────────

img.Image _resize(img.Image src, int targetPx) {
  // Never upscale (preserve sharpness on small source images)
  if (targetPx > src.width || targetPx > src.height) return src;
  return img.copyResize(src, width: targetPx, height: targetPx);
}
