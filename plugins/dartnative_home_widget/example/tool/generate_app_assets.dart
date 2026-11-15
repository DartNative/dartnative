// ─────────────────────────────────────────────────────────────────────────────
// generate_app_assets.dart
//
// One-step asset generator for dartnative apps.
// Reads a high-resolution source image and produces:
//   1. Splash screen assets (iOS LaunchScreen + Android splash) via
//      dartnative_splash
//   2. App icon assets (iOS AppIcon.appiconset; Android mipmap and the
//      adaptive icon: background, foreground and monochrome layers)
//
// Usage:  dn pub run tool/generate_app_assets.dart --source=assets/dn-logo.png --bg=#000000
//         dn pub run tool/generate_app_assets.dart --source=/abs/path/logo.png --target=/path/to/consumer-app
//
// The source image should be at least 1024×1024 px (for the iOS App Store icon).
// Give it a transparent background: Android draws the logo on the --bg colour
// inside each device's icon shape, so an opaque square logo shows as a square.
// The --bg color is used for the app icon background (default: #000000).
// The --target flag sets the app directory to write assets into (default: this app).
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
  // This app's directory: the one the command runs in. Not the script's own
  // location: `dn pub run` starts a compiled copy kept under
  // .dart_tool/pub/bin/, so that location is not the app.
  final appDir = Directory.current;

  // --target lets callers write assets into a different consumer app directory.
  // Defaults to this app.
  final targetArg = _arg(args, 'target');
  final targetDir = targetArg != null ? Directory(targetArg) : appDir;

  if (!targetDir.existsSync()) {
    print('ERROR: target directory not found: ${targetDir.path}');
    exit(1);
  }

  // Change working directory so relative --source paths and splash setup resolve.
  Directory.current = targetDir;

  final source = _arg(args, 'source');
  if (source == null) {
    print(
      'Usage: dn pub run tool/generate_app_assets.dart --source=<path> [--target=<app-dir>]',
    );
    exit(1);
  }

  final _ = _arg(args, 'source-dark');
  final bgHex = _arg(args, 'bg') ?? '#000000';
  final bgColor = _parseHexColor(bgHex);

  if (!File(source).existsSync()) {
    print('ERROR: source image not found: $source');
    print('Run it from the app folder, or give --source an absolute path.');
    exit(1);
  }

  final srcImage = img.decodeImage(File(source).readAsBytesSync());
  if (srcImage == null) {
    print(
      'ERROR: could not decode source image — ensure it is a valid PNG/JPEG',
    );
    exit(1);
  }
  print('Loaded source: ${srcImage.width}×${srcImage.height}');

  // ── 1. Splash screen ────────────────────────────────────────────────────
  print('\n═══ 1. Splash screen ═══');
  // `dn run-tool`, not `dart run`: dartnative_splash ships without its
  // source, so its setup command runs from the compiled copy `dn pub get`
  // installs. `dn` is a .bat file on Windows, which only a shell can start.
  final splashResult = await Process.run(
    'dn',
    ['run-tool', 'dartnative_splash:setup'],
    workingDirectory: Directory.current.path,
    runInShell: Platform.isWindows,
  );
  print(splashResult.stdout.toString().trim());
  if (splashResult.exitCode != 0) {
    print(splashResult.stderr.toString().trim());
    print(
      'WARNING: the launch screen was not made '
      '(dn run-tool dartnative_splash:setup exited with ${splashResult.exitCode}). '
      'pubspec.yaml needs dartnative_splash under dependencies and a '
      'dartnative_splash: section with background_color and image (see the '
      "app's README). Then run dn pub get and run this again.",
    );
  }

  // ── 2. iOS app icon ────────────────────────────────────────────────────
  print('\n═══ 2. iOS app icon ═══');
  await _generateIosAppIcon(srcImage, bgColor);

  // ── 3. Android app icon ─────────────────────────────────────────────────
  print('\n═══ 3. Android app icon ═══');
  await _generateAndroidAppIcon(srcImage, bgColor);

  print('\n✓ Done. Run dn run again to see them.');
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
  File(
    '${dir.path}/Contents.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(contents));
  print('  wrote Contents.json (single-size — Xcode generates the variants)');
}

// ── Android App Icon ──────────────────────────────────────────────────────────

// An adaptive icon (Android 8 and later) is drawn on a 108 dp canvas; the
// launcher shows the central 72 dp in the device's own shape, and nothing in
// the central 66 dp is ever cut. The logo is drawn at 66 dp, centred.
const _adaptiveCanvasDp = 108;
const _adaptiveLogoDp = 66;
const _densityScales = <(String, double)>[
  ('mdpi', 1),
  ('hdpi', 1.5),
  ('xhdpi', 2),
  ('xxhdpi', 3),
  ('xxxhdpi', 4),
];

Future<void> _generateAndroidAppIcon(img.Image src, img.ColorRgba8 bg) async {
  const res = 'android/app/src/main/res';

  // The square icon, for launchers that ignore adaptive icons.
  for (final (density, px) in _kSizes.androidIcon) {
    final dir = Directory('$res/mipmap-$density');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final icon = _renderIcon(src, px, bg);
    final path = '${dir.path}/ic_launcher.png';
    File(path).writeAsBytesSync(img.encodePng(icon));
    print(
      '  wrote mipmap-$density/ic_launcher.png  (${icon.width}×${icon.height})',
    );
  }

  // The adaptive icon's layers at every density: the logo on transparent
  // (foreground), and its shape in white (monochrome), which Android 13 and
  // later tint for themed icons. The source needs a transparent background:
  // an opaque square logo shows as a square inside the shape.
  for (final (density, scale) in _densityScales) {
    final canvasPx = (_adaptiveCanvasDp * scale).round();
    final logoPx = (_adaptiveLogoDp * scale).round();
    final logo = img.copyResize(
      src.convert(numChannels: 4),
      width: logoPx,
      height: logoPx,
      interpolation: img.Interpolation.cubic,
    );
    final offset = (canvasPx - logoPx) ~/ 2;
    final foreground = img.Image(
      width: canvasPx,
      height: canvasPx,
      numChannels: 4,
    );
    img.compositeImage(foreground, logo, dstX: offset, dstY: offset);
    final monochrome = foreground.clone();
    for (final p in monochrome) {
      p
        ..r = 255
        ..g = 255
        ..b = 255;
    }
    final dir = Directory('$res/mipmap-$density');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File(
      '${dir.path}/ic_launcher_foreground.png',
    ).writeAsBytesSync(img.encodePng(foreground));
    File(
      '${dir.path}/ic_launcher_monochrome.png',
    ).writeAsBytesSync(img.encodePng(monochrome));
    print(
      '  wrote mipmap-$density/ic_launcher_foreground.png and '
      'ic_launcher_monochrome.png  ($canvasPx×$canvasPx)',
    );
  }

  final rgb = ((bg.r.toInt() << 16) | (bg.g.toInt() << 8) | bg.b.toInt())
      .toRadixString(16)
      .padLeft(6, '0')
      .toUpperCase();
  Directory('$res/values').createSync(recursive: true);
  File('$res/values/ic_launcher_background.xml').writeAsStringSync(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<resources>\n'
    '    <color name="ic_launcher_background">#$rgb</color>\n'
    '</resources>\n',
  );
  print('  wrote values/ic_launcher_background.xml  (#$rgb)');

  final adaptiveDir = Directory('$res/mipmap-anydpi-v26');
  if (!adaptiveDir.existsSync()) adaptiveDir.createSync(recursive: true);
  File('${adaptiveDir.path}/ic_launcher.xml').writeAsStringSync(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
    '</adaptive-icon>\n',
  );
  print('  wrote mipmap-anydpi-v26/ic_launcher.xml');

  // An earlier generator wrote a single foreground here, which nothing used.
  final stale = File('${adaptiveDir.path}/ic_launcher_foreground.png');
  if (stale.existsSync()) stale.deleteSync();
}

// ── Image resizing ────────────────────────────────────────────────────────────

img.Image _resize(img.Image src, int targetPx) {
  // Never upscale (preserve sharpness on small source images)
  if (targetPx > src.width || targetPx > src.height) return src;
  return img.copyResize(src, width: targetPx, height: targetPx);
}
