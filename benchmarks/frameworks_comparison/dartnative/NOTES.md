# Notes

This app is a port of the Flutter app (`apps/flutter`) to DartNative: the same screens, operations,
variables, image `width` values, identifiers and decisions, on DartNative's native views. Where the
Flutter app's decision is kept, it is not repeated here; see its `NOTES.md`. This file lists what is
DartNative-specific and what differs.

## Dependencies added

| Package | Why |
|---|---|
| `dartnative_http` 1.1.0 | GraphQL over HTTP on NSURLSession (iOS) and OkHttp (Android). Every request is `client.post(endpoint, headers: {'content-type': 'application/json'}, body: <UTF-8 JSON bytes>)`; the body bytes carry their own length, so no chunked encoding. Brings package:http (its `Client` interface) and package:web_socket as its own dependencies. |
| `dartnative_url_launcher` 1.0.1 | Opens `checkoutUrl`. It has no in-app browser: it opens the system browser (see "Not met"). |

`dartnative`, `dartnative_ios` and `dartnative_android` are the framework itself. `lints` is a dev
dependency from the project template, not part of the app binary. Nothing else: JSON is decoded with
DartNative's `jsonDecodeNative`, state is `ChangeNotifier`/`ValueNotifier`, icons are `CustomPaint`.

## DartNative mechanism for each Flutter construct

| Flutter app | This app | Why |
|---|---|---|
| `MaterialApp`, `MaterialPageRoute` | `App`; no routes (see Navigation) | DartNative names |
| `IndexedStack` of three nested `Navigator`s, own tab bar | `IndexedStack` of three tab stacks, own tab bar; each tab stack is an `IndexedStack` of its screens kept in Dart (`lib/nav.dart`) | DartNative's `Navigator` is not a widget: it is one native stack for the whole app (UINavigationController / the Activity back stack), so a tab cannot hold a `Navigator` of its own. Screens below the top one stay mounted and hidden, so they keep their state and scroll position as routes do. |
| Home: `CustomScrollView` of `SliverToBoxAdapter`s and a `SliverGrid` | the same | A `CustomScrollView` whose slivers are `SliverToBoxAdapter`, `SliverPadding` and a fixed-column `SliverGrid` is lazy in DartNative: it is built as rows on the platform's list (UICollectionView with cell recycling / RecyclerView), a row of two cards per grid row, built as they near the screen and let go off it. |
| Collection grid (`CustomScrollView` + `SliverGrid`, `SliverLayoutBuilder` for the cell extent) | the same lazy `CustomScrollView`; the cell extent from `MediaQuery` width (`(width − 32 − 12) / 2 × 4/3 + 8 + 36 + 8 + 22`) | The description and sort chips scroll with the grid, which `FastGrid`/`GridView.builder` cannot hold (no header); the lazy `CustomScrollView` is the mechanism that recycles native cells for this layout. `SliverLayoutBuilder` is not needed: the cross extent is the screen width less the padding. |
| Search results `ListView.builder` | `ListView.builder` (`padding: EdgeInsets.zero`) | Lowered by DartNative to `FastList`: UICollectionView / RecyclerView with cell recycling, rows built as they near the screen. The "N results" line stays fixed above it. |
| Horizontal `ListView.separated` (chips, collections, sort chips, recommendations) | `ListView.separated` (horizontal lazy list) through `horizontalList()` in `lib/widgets.dart` | See "DartNative gaps": its `padding` is laid out by the helper. |
| `Image.network` in `ColoredBox(surface)` + `ClipRRect` | the same; `fit: BoxFit.cover` | DartNative's native image pipeline caches in memory and on disk (NSURLCache-backed, honours `Cache-Control`). `cacheWidth` is not set, as in the Flutter app: the server already sizes each image with the spec's `width` (480 px for a ≈ 170 pt card, 240 px for 64–80 pt thumbnails, 1080 px for full-width images), so a decode size would change little. |
| `CustomPainter` icons | `CustomPaint` with the same paths | DartNative's `CustomPaint` is native (Core Graphics on iOS, `android.graphics.Canvas` on Android) at no binary cost: the cheapest faithful option. Icon fonts do not have the design's glyphs, and `dartnative_svg` would add SVGKit / AndroidSVG. DartNative's `Path` has no `arcToPoint`, so the SVG arcs (`a1 1 …`, `a3 3 …`) are drawn with `arcTo` on the arc's circle, the same geometry. |
| `dart:io` `HttpClient` + `jsonDecode` | `dartnative_http` `NativeHttpClient.post` + `jsonDecodeNative` | Native networking off the UI thread; native JSON decoding on the calling isolate (responses are 2–30 KB; `jsonDecodeInBackground` would add an isolate hop for no gain at that size). Timeout 15 s (the client's per-request idle timeout; the Flutter app had 15 s to connect and 30 s for the response). |
| `Semantics(identifier: …)` | the same | Maps to `accessibilityIdentifier` (iOS) / resource-id (Android). DartNative's `Semantics` has no `explicitChildNodes`: a `Semantics` that sets only an identifier keeps its children as separate elements anyway. |
| `SHOPBENCH home_ready` through a method channel to `NSLog` | `print('SHOPBENCH home_ready')` once per process, in a post-frame callback after Home's content is built | DartNative's engine writes `print` to the unified log in every build mode (`Logger_PrintString` → `FlutterLogger.logDirect` → `vsyslog`, not gated by build mode); the line reads `dartnative: SHOPBENCH home_ready`. No native code. |
| Endpoint read natively in `AppDelegate` over a method channel | `Platform.environment`, then the C library's `getenv` over `dart:ffi` (iOS), then `String.fromEnvironment('SHOP_API_URL')`, then the default | The Dart VM's `Platform.environment` is always empty on iOS, so `SIMCTL_CHILD_SHOP_API_URL` / `devicectl --environment-variables` never reach it; `getenv` from `DynamicLibrary.process()` reads the launch environment with no native code in the Runner. |
| `showAdaptiveDialog` | `showAlert` (UIAlertController / Material dialog) | DartNative's native alert. |
| `CircularProgressIndicator.adaptive` | `CircularProgressIndicator` | UIActivityIndicatorView on iOS. |
| `url_launcher` `LaunchMode.inAppBrowserView` | `DartNativeUrlLauncher.launch(checkoutUrl)` | System browser (see "Not met"). |

## Decisions where the spec is silent (DartNative-specific)

- No push/pop transition: a tab's screens are shown and hidden in place (the tab stacks above), so
  there is no slide animation and no edge-swipe back on iOS; the back button and Android's system back
  pop the active tab's stack.
- The tab bar is hidden while the active tab's top screen is a Product screen, as in the Flutter app.
- The cart badge is laid beside the tab's element (not inside it) so XCUITest sees `cart-badge` as an
  element of its own; touches on it reach the tab under it (`IgnorePointer`).
- Light mode: `UIUserInterfaceStyle = Light`, `App(themeMode: ThemeMode.light)`,
  `Scaffold(brightness: Brightness.light)`.
- Project: from DartNative's tutorial skeleton (`tutorials/navigation`), with its splash logo removed
  (plain white launch screen on both platforms), the default DartNative app icon, iPhone only
  (`TARGETED_DEVICE_FAMILY = 1`), portrait only, `DEVELOPMENT_TEAM = ""` everywhere. `dn` raised the
  iOS deployment target to 15.0 on the first build.
- iOS: ATS `NSAllowsArbitraryLoads` and `NSAllowsLocalNetworking`, `NSLocalNetworkUsageDescription`,
  `CADisableMinimumFrameDurationOnPhone = true`. Android: `INTERNET`, `usesCleartextTraffic="true"`,
  `screenOrientation="portrait"`, an `https` VIEW query for the browser.

## DartNative gaps met

| What | Where | What the app does instead |
|---|---|---|
| No `Navigator` widget, so no nested navigators | Tab stacks | Dart-side stacks in `IndexedStack`s; no push transition, no edge-swipe back |
| A horizontal lazy list ignores `ListView.padding` on iOS and gives each item the list's full height (`DNFlexSetPadding` handles the vertical list and the grid, not `DNHorizontalFastListDataSource`) | Home chips and collections, sort chips, recommendations | `horizontalList()`: the top and bottom padding outside the list (the list is the content's height), the start and end padding on the first and last items, where it scrolls with them as a list's padding does |
| No in-app browser in `dartnative_url_launcher` | Check out | Opens the system browser, which the spec allows when the framework has none |
| On iOS 27 with the iOS 27 SDK, UIKit draws the status bar's scroll edge effect over the top ≈ 102 pt of the screen on any scroll view there; DartNative offers its style (`automatic`, `soft`, `hard`) but no way to hide it | Home: the "Everbloom" header scrolls with the content, so at rest it sits partly under the fade | Left at the system's `automatic` (a light fade over the header's upper half); `hard` blurred the whole header |
| `Platform.environment` empty on iOS (Dart VM) | Endpoint override | `getenv` over `dart:ffi` |
| `Path.arcToPoint`, `InputDecoration.collapsed`, `TextField.enableSuggestions`, `Row.textBaseline`, `Semantics.explicitChildNodes`, `MediaQuery.textScalerOf`, `SliverLayoutBuilder` not available | Icons, search field, price rows | `arcTo`; `InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero)`; `autocorrect: false` only; `CrossAxisAlignment.baseline` alone; identifier-only `Semantics`; `textScaleFactor`; `MediaQuery` width |

## Verification on the iOS Simulator (iPhone 17 Pro, iOS 27.2, debug build, replay server in `serve` mode)

Driven by the benchmark's XCUITest runner (a scratch copy with extra checks added), against
`replay.py serve`; no request missed the recordings.

- Home loads; `SHOPBENCH home_ready` appears once per launch in `log stream`; the endpoint from
  `SIMCTL_CHILD_SHOP_API_URL` is used.
- Collection: scrolled to `product-card-83` (all 84 products, 4 pages); each of the four sorts reloads
  page one and selects its chip (first cards: Linen Blend Jacket / Minimalist thermal work vest /
  Oversized Sand Dune Blazer).
- Product: option pills switch the selected variant (`option-Finish-Water-repellent` selected after a
  tap); the tab bar is hidden; a recommendation pushes another product.
- Add to cart switches to Cart with `cart-badge` 1; `qty-inc-0` makes it 2 and doubles the subtotal;
  Check out opened the checkout URL (the replay server served `/checkout` to Safari); two `qty-dec-0`
  remove the line and show the empty state.
- The runner's `testJourney` passed launch, the Home scroll and the first collection scroll cycle before
  the run was stopped (time).
- Identifiers seen by XCUITest: all of the table's except `error-retry`, `search-input`,
  `search-results` and `search-result-<i>`, which were not reached in the runs.

Observed: images are served from DartNative's image cache across launches without revalidation, even
after the replay server's `max-age=60` has passed (a journey after an earlier run requested only the
API). The replay server's image request count (N1) will be lower after the first journey.

## Not met or not verified

- **iOS Simulator mode:** debug (JIT) only, as with Flutter. The benchmarked device build is release (AOT).
- **In-app browser:** checkout opens Safari, not an in-app browser.
- **Device:** the signed release build was launched and measured on an iPhone 16 Pro with the
  benchmark's `tools/measure.py`, launch only; the walk through the app was not run on the device.
- **Not checked:** search (results, scroll, stale-response discard), the error state and Retry against an
  unreachable endpoint, the Android build and an Android emulator run (none was running).
