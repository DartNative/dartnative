# Notes

## Dependencies added

| Package | Why |
|---|---|
| `url_launcher` 6.3.2 | Flutter has no in-app browser. Opens `checkoutUrl` with `LaunchMode.inAppBrowserView` (SFSafariViewController on iOS, Custom Tabs on Android). |

The template's dev dependencies `flutter_test` and `flutter_lints` were left as generated. They are not part of the app binary. Everything else uses the Flutter SDK and `dart:io` (`HttpClient` for GraphQL, `ChangeNotifier`/`ValueNotifier` for state, `Navigator` for stacks, `CustomPainter` for icons).

## Decisions where the spec is silent

### Networking
- Each request sends the full `spec/storefront.graphql` document, verbatim, as `query`, and selects the operation with `operationName`. Variables are as specified (`first: 24`, sort keys and so on).
- The body is sent with an explicit `Content-Length`. Dart's `HttpClient` otherwise uses chunked encoding, which a simple replay server may not accept. Timeouts: 15 s to connect, 30 s for the response.
- A response without `data`, or with a non-2xx status, counts as a failed request and shows the error state.
- Endpoint resolution: on iOS the `SHOP_API_URL` launch environment variable is read natively (`ProcessInfo` in `AppDelegate.swift`) and passed to Dart over a method channel. In testing, Dart's `Platform.environment` did not include variables passed with `SIMCTL_CHILD_…`. Next comes the `--dart-define=SHOP_API_URL` build-time value (the Android mechanism), then the default endpoint.

### Navigation
- Each tab has its own nested `Navigator` inside an `IndexedStack`, so switching tabs keeps each stack. The tab bar is hidden while the active tab's top route is a Product screen. Re-tapping the current tab does nothing.
- Android system back pops the active tab's stack, and exits the app at a tab root.
- Page transitions are the platform defaults of `MaterialPageRoute` (Cupertino slide plus edge-swipe back on iOS).

### Home
- The "Everbloom" header scrolls with the content ("the whole screen scrolls").
- The design's "See all" link next to "Collections" is omitted. The spec does not list it and gives it no destination.

### Collection
- The nav bar is fixed. The description, sort chips and grid scroll together inside the `product-grid` scroll view.
- Changing the sort jumps back to the top and discards any in-flight page from the previous sort.
- If a later page fails, a small "Retry" button (`error-retry`) appears at the end of the list. A failed first page shows the full error state.

### Product
- The round back button sits on the image carousel and scrolls with it, as drawn in the design. While loading or on error, it is fixed at the top-left instead.
- The page dots can also be tapped to jump to an image.
- Selecting a pill picks the variant whose `selectedOptions` exactly match the new combination. If none matches, it picks the first variant that has the tapped value. Option pills wrap onto more lines when there are many.
- On-sale prices use the `sale` color with the compare-at price struck through. This applies everywhere a price and a higher compare-at price exist: cards, recommendations, search rows and the product price.
- "Add to cart" switches to the Cart tab only when the request succeeds with no `userErrors`. Otherwise an alert shows the message and the app stays on the product.
- No product in the catalog has variants with different prices, so the price update on variant change was only checked in code. Variant selection itself was verified: the label, the pill state, and the variant title in the cart.

### Search
- The query is trimmed. Clearing the field immediately clears the results and discards in-flight responses. Autocorrect and suggestions are off for the field.
- The "`N` results" line stays fixed above the scrolling list.
- Loading shows a spinner. A failed first page shows the error state.

### Cart
- While any cart request is in flight, the stepper buttons are disabled, which avoids racing updates.
- If a cart request fails at the network level, an alert says "Couldn't update your cart. Check your connection and try again."
- If a response has `userErrors` and no `cart`, the displayed cart stays as it was.
- The empty-cart "Start shopping" button switches to the Home tab.

### States and visuals
- Spinners are `CircularProgressIndicator.adaptive` (the Cupertino activity indicator on iOS).
- The error title uses the spec's straight apostrophe: "Couldn't load products".
- Typography uses Flutter's default platform font (SF Pro on iOS, Roboto on Android), with sizes, weights and line heights from the tokens.
- Icons (home, search, cart, back, plus the stepper minus/plus and the error glyph from the design) are drawn as vector paths with `CustomPainter`, copied from the design's SVG.

### Benchmark hooks
- Identifiers use `Semantics(identifier: …)`, which Flutter maps to `accessibilityIdentifier` on iOS and resource-id on Android. All identifiers in the table were confirmed visible to XCUITest on the simulator, using a temporary UI-test project that is not included.
- The semantics tree is not forced on with `ensureSemantics()`. Flutter's iOS engine turns on its accessibility bridge itself: always on the simulator, and on a device as soon as XCUITest queries the view. When the framework was forced to build semantics before the bridge existed, the first full tree update was dropped and XCUITest saw an empty hierarchy.
- `SHOPBENCH home_ready` is written with `NSLog` in `AppDelegate.swift`, triggered once per process over the method channel after the first frame that shows loaded Home content. It is iOS only. The app does no other logging.

### Platform configuration
- iOS: iPhone only (`TARGETED_DEVICE_FAMILY = 1`), portrait only, `UIUserInterfaceStyle = Light` (no dark mode), ATS `NSAllowsArbitraryLoads` and `NSAllowsLocalNetworking`, `NSLocalNetworkUsageDescription` (needed for LAN access on iOS 14+), `CADisableMinimumFrameDurationOnPhone = true`. The launch screen is the template's white storyboard, and the app icon is the default Flutter icon.
- The `DEVELOPMENT_TEAM` that `flutter create` wrote into the Xcode project was removed. The team comes only from the `xcodebuild` command line.
- Android: `INTERNET` permission in the main manifest, `usesCleartextTraffic="true"`, portrait only, the night-mode launch theme removed (plain white launch screen), and an `https` VIEW `<queries>` entry for Custom Tabs.

## Not met or not verified
- **iOS Simulator mode:** Flutter supports only debug (JIT) builds on the simulator, so the simulator app is a debug build. The benchmarked device build is release (AOT).
- **Signed device build:** the `DEVELOPMENT_TEAM` command could not be verified here. The machine's Xcode account login is rejected and there are no provisioning profiles. The unsigned `CODE_SIGNING_ALLOWED=NO` device build succeeds. No physical device was available.
