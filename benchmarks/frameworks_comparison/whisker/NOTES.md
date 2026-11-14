# Notes

## Project layout

- `src/lib.rs`: entry point, router (tabs layout + per-tab stacks), tab bar, cart badge.
- `src/api.rs`: GraphQL documents (copied verbatim from `spec/storefront.graphql`), models, transport.
- `src/state.rs`: in-memory cart (`AppState`, provided through context).
- `src/ui.rs`: design tokens, icons, shared components (product card, price, skeletons, spinner, error state, nav bar).
- `src/screens/`: Home, Collection, Product, Search, Cart.
- `shop-native/`: app-private Whisker module (Swift + Kotlin) and generation plugin, see below.
- `whisker.rs`: app configuration (name, bundle id, portrait-only iOS, white background).

## Dependencies added

Rust crates (app):

- `whisker`, `whisker-cng`: the framework and its project generator (required by every Whisker app).
- `whisker-router`: first-party navigation (tabs + stacks, back gesture).
- `whisker-image`: first-party network image element (aspect-fill, caching).
- `whisker-svg`: first-party vector rendering for the design's icons.
- `whisker-input`: first-party native text field (search).
- `whisker-keyboard`: first-party keyboard height / dismiss (search results stay above the keyboard; drag dismisses it).
- `whisker-safe-area`: first-party safe-area insets.
- `whisker-web-browser`: first-party in-app browser (SFSafariViewController / Custom Tabs) for Check out.
- `serde`, `serde_json`: JSON encoding/decoding of GraphQL requests and responses. Whisker itself already depends on both, so they add no new code to the binary.

`shop-native` (local module) build-time-only crates: `whisker-plugin` (Whisker's plugin API), `anyhow` (required by the `Plugin` trait signature). They are used by the generation plugin binary, not by the app at runtime.

No third-party UI kit, state library, GraphQL client, or HTTP client. No third-party native (Swift/Kotlin) dependencies were added beyond what the first-party Whisker modules bring (Kingfisher via `whisker-image` on iOS, Coil on Android, androidx.browser via `whisker-web-browser`).

## Why a local module (`shop-native`)

Whisker has no HTTP client, timer, alert, or system-log API. Rather than adding Rust HTTP/TLS crates, the app uses the platform's own facilities through a small Whisker module:

- `post` (async): HTTP POST with URLSession (iOS) / HttpURLConnection (Android). All GraphQL requests go through it.
- `sleep` (async): main-loop timer, used for the 300 ms search debounce.
- `alert`: native alert (UIAlertController / AlertDialog) for cart `userErrors` and failed cart requests.
- `log`: `NSLog` (iOS unified log) / `Log.i` (Android) — used only for the single `SHOPBENCH home_ready` line.
- `tagTextField` (iOS): sets `search-input` as the accessibility identifier of the native `UITextField`, because `whisker-input` does not expose the common `accessibility` prop, and the identifier must be on the text field itself for `app.textFields["search-input"]`.
- Generation plugin (auto-discovered, like `whisker-router`'s): adds `NSAppTransportSecurity` (`NSAllowsArbitraryLoads`, `NSAllowsLocalNetworking`) and `CADisableMinimumFrameDurationOnPhone = true` to Info.plist. Android's generated manifest already sets `usesCleartextTraffic="true"`.

## Decisions where the spec is silent

- **Endpoint**: iOS reads `SHOP_API_URL` from the process environment at launch; otherwise the value of `SHOP_API_URL` at build time (Android); otherwise the default endpoint.
- **GraphQL documents**: each request sends its operation followed by the fragment definitions it spreads (`ProductCard` / `CartFields`), text unchanged from the spec file, so the document is valid. Responses with a non-empty top-level `errors` are treated as failures.
- **Routes**: `Product` is declared in both the Home and Search stacks, so each tab keeps its own history. Product and Collection screens are pushed (`push`), so a recommendation always adds a new Product screen. The tab bar is hidden whenever the current route is a Product screen.
- **Tab re-selection**: tapping the already-active tab pops that tab to its root (Whisker router default `PopToRoot`). Switching to another tab keeps each tab's stack.
- **Add to cart**: switches to the Cart tab only when the mutation succeeds with no `userErrors`. The button is disabled (50% opacity, taps ignored) while any cart mutation is in flight.
- **Quantity stepper**: one cart mutation at a time; taps while a mutation is in flight are ignored and the stepper is dimmed. Quantity and line total come from the server response.
- **Variant selection**: picks the variant matching the current options with the tapped value; if no exact match exists, the first variant having that value.
- **Price on cards**: `priceRange.minVariantPrice`, with `compareAtPriceRange.minVariantPrice` struck through when higher (also used for search rows and recommendations).
- **Collection header**: nav bar, description, and sort chips stay fixed; only the grid scrolls (`product-grid`). The nav-bar title shows the title from Home immediately and is replaced by the API title.
- **Infinite scroll**: the next page is requested when the scroll position is within one viewport height of the end (from `List`'s scroll events, with `on_end_reached` as a fallback). Failed next-page requests are silently retried on the next scroll.
- **Search**: an empty (or whitespace-only) field immediately shows the hint and cancels any in-flight query; other input is debounced by 300 ms. Stale responses are dropped with a generation counter. The results count is fixed above the list. The keyboard is dismissed when the results are dragged or Search is pressed, and the screen shrinks above the keyboard.
- **Loading states**: Home, Product, and Collection show skeletons; Search's first page and the next-page footer show a small rotating ring (CSS keyframe animation — the only animation in the app besides the router's default transitions).
- **Errors**: Home, Collection, Product, and Search show the design's error state with Retry. Cart request failures show an alert.
- **Empty cart**: the design's "Start shopping" button switches to the Home tab.
- **Design "See all" link** (Collections header): not implemented — the spec does not define a destination, and it says not to add features.
- **Accessibility**: tappable cards/buttons have role button plus a label; containers (`cart-line-<i>`, `home-scroll`, `product-grid`, `search-results`, `product-carousel`) carry only an identifier, so their children stay reachable. The cart badge is a sibling of the Cart tab button (not a child), so it stays its own element, labeled with the count. The router keeps covered screens mounted; a wrapper hides covered screens from accessibility (computed under the never-paused tab-layout owner) so identifiers such as `back` and `add-to-cart` are unique.
- **Orientation**: iOS is portrait-only via `whisker.rs`. Whisker's config has no Android orientation setting, so Android is not locked (no landscape layout is provided).
- **Launch screen**: Whisker's generated launch screen with the `#FFFFFF` app background. No app icon is configured.
- **Release profile**: `lto = true`, `codegen-units = 1` for smaller, faster release binaries.

## Spec items not fully met / caveats

- **Device signing** was not exercised (no Apple team available here). The device build is verified with `CODE_SIGNING_ALLOWED=NO`; the signed command follows Whisker's documented approach (`DEVELOPMENT_TEAM` + `CODE_SIGN_STYLE=Automatic` on the `xcodebuild` command line).
- **Android orientation** is not locked to portrait (see above).
- **Android endpoint override** is build-time only, as the spec allows.
- **`search-input` on iOS** is applied natively after the Search screen mounts (it retries for up to 2 s). On Android the search field has no test tag.
