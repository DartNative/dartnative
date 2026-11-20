---
name: dart-native-porting
description: "Playbook for porting an existing Flutter app to DartNative. Use when: migrating a Flutter project or screen, a port doesn't compile, the app launches to a white screen, iOS builds fail with pod/deployment-target/Swift-symbol errors, or a package crashes at startup with 'Setting a message handler before the FlutterEngine has been run'. Covers the Dart migration, package replacements, and the iOS project surgery for in-place ports. Pair with the dart-native skill for the widget-level API differences."
---

# Porting a Flutter app to DartNative

DartNative is *almost* Flutter-compatible: most widget code ports unchanged,
the differences are enumerated (see the `dart-native` skill), and the
project-level work is mechanical. This playbook is ordered by leverage — do
the steps in sequence and most ports never reach the surgery section.

## Choose the porting path

**Path A — fresh shell (recommended).** `dn create` a new project and move
your `lib/` and assets into it. The scaffold already contains the correct
native projects, plugin registrant, fonts, and build settings — you only do
the Dart-side migration. Prefer this for whole apps.

**Path B — in-place port.** Keep the existing Flutter project and convert
its native side. Required when the iOS/Android projects carry significant
custom native code. Everything in "iOS project surgery" below applies.

Either way, the Dart migration is the same.

## 1. pubspec.yaml

```yaml
dependencies:
  dartnative: ^1.0.0
  dartnative_ios: ^1.0.0
  dartnative_android: ^1.0.0
  # dartnative_skia: ^1.0.0   # GPU canvas, about 9 MB on iPhone; two steps, see docs/skia.md
```

- [ ] Remove `flutter:` sdk dependency and `flutter_test:` (and delete the
      scaffold `test/widget_test.dart`).
- [ ] Remove packages that reach into Flutter's renderer or web layer —
      they cannot work: `go_router` (use `Navigator` + `registerRoutes`),
      anything importing `RenderObject`/`flutter_web_plugins`.
- [ ] Replace **method-channel plugins** with the first-party equivalents.
      A method-channel plugin crashes at launch with
      `NSInternalInconsistencyException: Setting a message handler before
      the FlutterEngine has been run`. The mapping:

      | Flutter package | DartNative replacement |
      |---|---|
      | `sqflite` | `dartnative_sqlite` (or `sqflite_common_ffi`) |
      | `shared_preferences` | `dartnative_shared_preferences` `^1.1.0` (it reads what Flutter's plugin saved, so an app updated in place under the same app id keeps its values) |
      | `flutter_secure_storage` | `dartnative_secure_storage` |
      | `hive` / cache stores | `dartnative_hive` |
      | `path_provider` | `dartnative_path_provider` |
      | `video_player` | `dartnative_video_player` |
      | `audioplayers` / `just_audio` | `dartnative_audio` |
      | `camera` | `dartnative_camera` |
      | `mobile_scanner` | `dartnative_camera` (`startCodeScan`) |
      | `image_picker` | `dartnative_media_picker` (the photo library); `ImageSource.camera` is a capture screen with `dartnative_camera`: `CameraPreview(controller:)` and `await controller.takePicture()`, which returns the file path |
      | `flutter_svg` | `dartnative_svg` |
      | `lottie` | `dartnative_lottie` |
      | `rive` | `dartnative_rive` |
      | `flutter_image_compress` | `dartnative_compressor` |
      | `image_cropper` | `dartnative_image_crop` |
      | `url_launcher` | `dartnative_url_launcher` |
      | `share_plus` | `dartnative_share` |
      | `permission_handler` | `dartnative_permissions` |
      | `connectivity_plus` | `dartnative_connectivity` |
      | `firebase_core` / `firebase_messaging` | `dartnative_firebase` |
      | `flutter_local_notifications` | `dartnative_notifications` |
      | `sign_in_with_apple` / `google_sign_in` | `dartnative_social_sign_in` |
      | `passkeys` (restore credentials only) | `dartnative_passkeys` |
      | `supabase_flutter` | `dartnative_supabase` |
      | `in_app_purchase` / `purchases_flutter` | `dartnative_revenuecat` |
      | `google_maps_flutter` | `dartnative_google_maps` |
      | `webview_flutter` | `dartnative_webview` |
      | `flutter_native_splash` | `dartnative_splash` |
      | `home_widget` | `dartnative_home_widget` (the widget is designed in Dart, no Swift or Kotlin) |
      | `live_activities` | `dartnative_live_activities` |
      | `intl` codegen flows | `dartnative_intl` |

      More on dartpub.dev/explore (system, background, crypto, on-device
      AI: `dartnative_onnxruntime`, TTS). Pure-Dart packages (http, state,
      models, json) port unchanged.
- [ ] `dn pub get`.

## 2. main.dart

```dart
import 'package:dartnative/dartnative.dart';
import 'dartnative_plugin_registrant.dart';

void main() {
  DartNativePluginRegistrant.registerAll(); // FIRST line — or white screen
  registerRoutes({
    '/detail': (_) => const DetailScreen(),
  });
  runApp(const HomeScreen()); // the screen, or App(home: ..., theme: ...)
}
```

- [ ] The registrant file is generated by `dn create` (Path A) and
      regenerated by every `dn pub get` when the plugin set changes.
- [ ] `runApp` takes the root screen, or an `App(home: ..., theme: ...)` as
      in Flutter; `App` mounts `home`.
- [ ] Remove `WidgetsFlutterBinding.ensureInitialized()`,
      `ProviderScope`/`MultiProvider` roots, and
      `AnnotatedRegion<SystemUiOverlayStyle>` wrappers (SystemChrome +
      `Scaffold` handle chrome natively).
- [ ] Add the OTHER registrations the app needs (after `registerAll()`;
      see the dart-native skill's startup anatomy): `registerSkiaFactories()`
      if `dartnative_skia` is used (`CanvasSurface`), plugin initializers
      (`Firebase.initializeApp()`, `Sqlite.ensureInitialized()`, …), and an
      app-wide `SystemChrome.defaultStyle` for the chrome baseline. Custom
      fonts need nothing: the `flutter: fonts:` block of pubspec.yaml carries
      over as it is, and the app loads those fonts itself.

## 3. Per-file Dart migration

Swap the import in every file:

```dart
import 'package:flutter/material.dart';   // remove (also cupertino/services)
import 'package:dartnative/dartnative.dart';
```

Then apply the known diffs proactively — don't wait for the analyzer:

| Flutter | DartNative |
|---|---|
| `Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => X()))` | `Navigator.push(ctx, PageRoute(builder: (_) => X()))` |
| `PageRouteBuilder` + `transitionsBuilder` | `PageRoute(builder:, transition: RouteTransition.x, duration:)` — custom transition curves have no equivalent |
| `showDialog` + `AlertDialog` | `await showAlert(context: context, title:, message:, actions: [...])` → index of tapped action |
| `showModalBottomSheet` | Unchanged; `showModalSheet` for a native detent sheet, `showActionSheet` for action lists |
| `ScaffoldMessenger.showSnackBar` | Unchanged (routes to a native toast) |
| `Material(child: InkWell(...))` with no colour of its own, `Material(type: MaterialType.transparency, child: X)`, or a transparent `color` | Drop the `Material`: `InkWell(...)` / `X`. An `InkWell` needs no `Material` around it |
| `Material(color: c, child: InkWell(...))` | `Container(color: c, child: InkWell(...))` |
| `Material(color: c, child: page)` at a route's root | `Scaffold(backgroundColor: c, body: page)` |
| `Material(color:, elevation:, borderRadius: or shape:, clipBehavior:, child:)` as a surface | `Container(decoration: BoxDecoration(color:, borderRadius:, border: Border.all(...) for a side, shape: BoxShape.circle for a circle, boxShadow: [BoxShadow(color: Color(0x1F000000), blurRadius: 3 * elevation, offset: Offset(0, elevation))]), clipBehavior:, child:)`; `Card` for the platform's card |
| `Ink(color: or decoration:, width:, height:, padding:, child:)` | `Container(...)` with the same fields |
| `Ink.image(...)` | Not offered: the `Image` as the `InkWell`'s child (on iPhone the press highlight sits behind an opaque image) |
| `InputDecoration(filled:, border: OutlineInputBorder(...))` | Unchanged: the field draws its own border and fill (side colour and width, one radius; `focusedBorder` / `enabledBorder` / `disabledBorder`) |
| `AnimationController..duration = d` (mutation) | The field is final: set it in the constructor, or pass `duration:` to `animateTo()` / `animateBack()` |
| `await controller.reverse(); teardown();` and other awaited runs | Works as in Flutter, with one difference: a run that is stopped, or whose value is set, completes its future at once (Flutter's never completes), so guard what follows with `if (!mounted) return;` or a state check. A run replaced by another completes when the new one arrives |
| `animateTo(lowerBound)` / `animateBack(upperBound)` status listeners | DartNative reports the bound's own status (`dismissed` / `completed`); Flutter reports `completed` / `dismissed` by the method |
| `Theme.of(ctx).x` | Works via `App(theme: ThemeData.dark())` (ColorScheme + TextTheme) and `Theme(data:, child:)` for a part of the app; otherwise pass explicit styles |
| `InteractiveViewer(transformationController: ...)` | Not offered: the zoom stays in the native view. Drop the controller; to start again at 1x, give the viewer a new `key` |
| `ColorScheme.fromSeed(seedColor: ...)` | Not offered: native widgets take the platform's colours, not the app's scheme. Drop it; give your own boxes your own colours, or on Android read the device's scheme with `DynamicColor.colorScheme(brightness:)` |
| `ColorFiltered(colorFilter: ...)`, `Image(color:, colorBlendMode:)` | Unchanged around images: every `BlendMode` and `ColorFilter.matrix` work, and the filter reaches each `Image` below it. Text, boxes and other widgets below a `ColorFiltered` are drawn unfiltered: to grey out a whole card, filter its image and give its text a grey colour |
| `BoxDecoration(image: DecorationImage(image: ..., fit: BoxFit.cover))` | Not offered: a `Stack` with `Positioned.fill(child: Image(..., fit: BoxFit.cover))` first and the content after it; `ClipRRect(borderRadius: ...)` around the `Stack` for rounded corners, `ClipOval` for a circle |
| `WidgetSpan(child: ...)` in `Text.rich` / `RichText` | Keep it when the child is an `Icon` or an `Image`: they sit in the line as in Flutter. Any other widget is left out: put it beside the text in a `Row` (one line) or a `Wrap` |
| `InputDecoration(prefixText: ..., suffixText: ...)` | Not offered: a currency or unit as `prefixIcon` / `suffixIcon` (`Icon(Icons.attach_money)`), or a `Text` beside the field in a `Row` |
| `color.a`, `color.r`, `color.g`, `color.b` | Whole numbers 0 to 255 in DartNative (Flutter's are 0.0 to 1.0): divide by 255 where the code expects Flutter's; `color.opacity` is the alpha as 0.0 to 1.0. `color.withValues(alpha: x)` works as in Flutter |
| `color.withValues(red: ..., green: ..., blue: ...)` | `Color.fromARGB(color.alpha, r, g, b)` with whole numbers 0 to 255 |
| `context.watch<T>()` / `ref.watch(p)` | `store.field.watch(context)` (see the dart-native skill, State) |
| `ExcludeSemantics` | Remove — native accessibility applies |
| `rootBundle.load(...)` | `loadAssetBytes('assets/...')` — sync, returns `Uint8List?` |
| `Isolate.run(() => work(x))` | `runInBackground(() => work(x))` — same rules, less work on the UI thread; `compute` ports unchanged and already runs on it |

Keep `Platform.isIOS`/`isAndroid` checks — DartNative is cross-platform and
they work as expected. Code that reads the iOS version to choose between
Liquid Glass and a fallback becomes `isIOS26`.

Leave these as the Flutter app has them; they behave as in Flutter, so add
no wrapper or workaround: `double.infinity` sizes and `SizedBox.expand()`
(in a `Stack` too), nested `Transform`s, the `GestureDetector` tap
callbacks (`onTapDown`, `onTapUp`, `onTap`, `onTapCancel`), `async`
callbacks that `await`, `ScrollController` on horizontal lists, and pubspec
font families with a file per weight (`w800` and `w900` included).

## 4. Run and verify

```sh
dn clean && dn pub get && dn run
```

Screen-by-screen: layout should match Flutter (parity is engineered). Where
a widget differs on purpose — bars, text fields, sheets — adopt the
DartNative form rather than recreating the Flutter one. Then bank the free
upgrades: check the keyboard on input screens (`Scaffold.bottomInputBar`
for chat-style bars), declare `brightness: Brightness.dark` on
dark-by-colors screens. `ListView.builder` and `GridView.builder` are
already lazy, as in Flutter; consider `FastList` for very long feeds that
want its extras (`keepAliveCount`, `recycleItems`, reordering, paging).

## 5. Failure modes → fixes

| Symptom | Cause | Fix |
|---|---|---|
| White screen, no crash | `registerAll()` missing or not first | §2 |
| White screen after in-place port | Flutter's `AppDelegate` still in `ios/` | §6 |
| `Setting a message handler before the FlutterEngine has been run` | A method-channel plugin, or `UIMainStoryboardFile` still in Info.plist | §1 replacements; §6 |
| Swift errors about missing DartNative symbols, pod conflicts, deployment-target warnings | `ios/` still carries Flutter's project setup | §6 |
| Rotation / status-bar APIs silently do nothing | The scaffold's delegates are not in use | §6 |

## 6. iOS project surgery (Path B only)

Make `ios/` match a `dn create` scaffold; generate one and diff against it
when stuck.

- [ ] `Runner/AppDelegate.swift` subclasses `DartNativeAppDelegate` and
      `Runner/SceneDelegate.swift` subclasses `DartNativeSceneDelegate` — each
      a few lines, as in the scaffold. They build the window and start the
      runtime; do not keep Flutter's delegate.
- [ ] `Info.plist`: keep the `UIApplicationSceneManifest` block (the scaffold
      uses a scene); delete `UIMainStoryboardFile` (the storyboard instantiates
      a `FlutterViewController` before your delegate runs — the classic
      message-handler crash); keep `UILaunchStoryboardName` (splash).
- [ ] `Podfile`: take the scaffold's. It requires the SDK podhelper and installs
      every DartNative pod with `dartnative_install_all_ios_pods`; never add
      `pod` lines by hand.
- [ ] `IPHONEOS_DEPLOYMENT_TARGET = 15.0` in all three build configurations of
      `project.pbxproj` (Debug/Release/Profile), matching the scaffold's
      `platform :ios, '15.0'`.

Icon fonts and the Skia option need no project changes: the framework
registers its fonts at launch, and Skia needs the dependency and the
`registerSkiaFactories()` call, no Xcode or Gradle changes.

## 7. Let the diffs be mechanical

Everything in §1–§3 and §6 is deterministic — exactly what a coding
assistant executes well with this playbook loaded. Human judgment belongs in
§4: which screens should adopt the DartNative-specific forms (native bars,
`bottomInputBar`, glass, `FastList`) rather than merely compiling.
