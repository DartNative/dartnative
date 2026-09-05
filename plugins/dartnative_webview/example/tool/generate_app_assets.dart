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

  // iOS app icon — pt and the minimum pixel dimension for each scale
  // Format: (pt, 1×, 2×, 3×)
  // Only includes sizes present in Xcode 16 default AppIcon template.
  // Missing a size → App Store / Settings may show a placeholder.
  final iosIcon = <(int pt, int, int, int)>[
    (20, 20, 40, 60), // Notification
    (29, 29, 58, 87), // Settings
    (40, 40, 80, 120), // Spotlight
    (60, 60, 120, 180), // iPhone App
    (76, 76, 152, 228), // iPad App
    (84, 84, 167, 167), // iPad Pro (83.5pt @2×)
    (1024, 1024, 1024, 1024), // App Store
  ];

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

  // Each entry in Contents.json
  final entries = <Map<String, dynamic>>[];

  for (final (pt, oneX, twoX, threeX) in _kSizes.iosIcon) {
    final scales = <(int px, String idiom)>[
      (oneX, 'iphone'), // 1× → iPhone (legacy)
      (twoX, 'iphone'), // 2× → iPhone retina
      (threeX, 'iphone'), // 3× → iPhone 6+/6s+
    ];

    // iPad has different idiom for 1× and 2×
    // 76pt @2× → iPad
    // 83.5pt @2× → iPad Pro
    for (final (px, _) in scales) {
      final idiom = pt == 20 || pt == 29 || pt == 40
          ? 'iphone'
          : pt == 60
              ? 'iphone'
              : 'ipad';
      final scale = px == oneX ? '1x' : (px == twoX ? '2x' : '3x');

      final sizeStr = '${pt}x$pt';
      final filename = 'AppIcon-$pt@$scale.png';

      final icon = _renderIcon(src, px, bg);
      File('${dir.path}/$filename').writeAsBytesSync(img.encodePng(icon));
      print('  wrote $filename  (${icon.width}×${icon.height})');

      entries.add({
        'size': sizeStr,
        'idiom': idiom,
        'filename': filename,
        'scale': scale,
      });
    }
  }

  // App Store icon (1024pt @1× = 1024×1024)
  if (_kSizes.iosIcon.any((e) => e.$1 == 1024)) {
    entries.add({
      'size': '1024x1024',
      'idiom': 'ios-marketing',
      'filename': 'AppIcon-1024@1x.png',
      'scale': '1x',
    });
  }

  // Write Contents.json
  final contents = {
    'images': entries,
    'info': {'author': 'xcode', 'version': 1},
  };
  File('${dir.path}/Contents.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(contents));
  print('  wrote Contents.json (${entries.length} entries)');
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
