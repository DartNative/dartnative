# dartnative_webview

An in-app web view rendered by the platform's own engine — `WKWebView` on iOS,
`android.webkit.WebView` on Android — embedded as a real native view in your DartNative
layout. iOS and Android.

## Why you'll like it

- **The platform's real web engine** — WebKit on iOS, the system WebView on Android, so
  pages render, scroll, and run JavaScript exactly like the OS browser.
- **A real native view, not a texture** — the web view lives in the native view hierarchy
  and fills its slot in your layout.
- **A familiar surface** — `WebViewController` + `WebViewWidget`, matching `webview_flutter`,
  so it's a drop-in if you're coming from Flutter.

## Highlights

- **`WebViewWidget(controller: …)`** — drops the native web view into any layout (e.g. `Expanded`).
- **`WebViewController`** — `loadRequest(Uri)`, `goBack()` / `goForward()` / `reload()`,
  `canGoBack()` / `canGoForward()`, `getTitle()`.
- **`setJavaScriptMode(JavaScriptMode…)`** and **`setBackgroundColor(Color)`** — configure inline.
- **`NavigationDelegate(onProgress:, onPageStarted:, onPageFinished:)`** — load progress (0–100) + page lifecycle.

## Install

```yaml
dependencies:
  dartnative_webview: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'package:dartnative_webview/dartnative_webview.dart';
```

Show a page and let it fill the available space:

```dart
final controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..loadRequest(Uri.parse('https://youtube.com'));

// in your layout:
Expanded(child: WebViewWidget(controller: controller));
```

Track loading and the page title:

```dart
controller.setNavigationDelegate(NavigationDelegate(
  onProgress: (percent) => print('loading $percent%'),
  onPageFinished: (url) async => print(await controller.getTitle()),
));
```

Navigate, then clean up:

```dart
if (await controller.canGoBack()) controller.goBack();
controller.reload();
// when the view is removed:
controller.dispose();
```

## Platform setup

Loading a remote URL needs network access:

### iOS

Nothing for HTTPS. For an **HTTP** URL, add an App Transport Security exception in `Info.plist`.

### Android

Add the internet permission to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## Example

The [`example/`](./example) app loads pages with nav controls, URL shortcuts, and a live
progress + title readout — borrow from it freely.

Run it with the `dn` CLI (always use `dn` — not the underlying SDK CLI — for
run/build/pub commands):

```sh
cd example
dn pub get
dn run -d <device-id>
```

The example is an official demo — free to run, no license setup.

## Credits & license

Adapted from Flutter's official [`webview_flutter`](https://pub.dev/packages/webview_flutter)
(`webview_flutter_wkwebview` / `webview_flutter_android`, BSD-3-Clause), reworked to run
natively on DartNative.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
