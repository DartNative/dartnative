# Widget Reference

DartNative ships a widget set designed to be source-compatible with Flutter. In most cases, replacing `package:flutter/material.dart` with `package:dartnative/flutter_compat.dart` is all you need to do.

This reference covers what is available, what isn't, and what to use instead when a Flutter widget has no native equivalent.

---

## Layout

| Widget | Status | Notes |
|---|---|---|
| `Column` | ✅ | |
| `Row` | ✅ | |
| `Flex` | ✅ | |
| `Expanded` | ✅ | |
| `Flexible` | ✅ | |
| `Spacer` | ✅ | |
| `Stack` | ✅ | |
| `Positioned` | ✅ | |
| `Padding` | ✅ | |
| `Container` | ✅ | |
| `SizedBox` | ✅ | |
| `ConstrainedBox` | ✅ | |
| `DecoratedBox` | ✅ | |
| `Align` / `Center` | ✅ | |
| `SafeArea` | ✅ | |
| `Divider` / `VerticalDivider` | ✅ | On iPhone the table separator: one pixel in the separator grey. |
| `AspectRatio` | ✅ | |
| `Opacity` | ✅ | |
| `Visibility` | ✅ | Default flags match Flutter (hidden child is replaced and its state disposed). The full `maintain*` set is supported: with `maintainState: true` the child stays mounted and is hidden natively — pair with `maintainSize` to keep its layout slot |
| `Offstage` | ⚠️ | The offstage child is unmounted (state lost) — Flutter keeps it mounted at zero size. For state-preserving show/hide, use `IndexedStack` |
| `ClipRRect` | ✅ | Rounded rect clip via `Container(decoration: BoxDecoration(borderRadius: ...))` |
| `ClipRSuperellipse` | ✅ | iOS squircle clip — wraps child in `ShapeDecoration(shape: RoundedSuperellipseBorder(...))` |
| `ClipOval` | ✅ | Circle clip via `BoxDecoration(shape: BoxShape.circle)` |
| `ClipRect` | ✅ | Rectangular clip — `clipsToBounds` on the child |
| `Wrap` | ✅ | flex-wrap |
| `FractionallySizedBox` | ✅ | |
| `IntrinsicWidth` / `IntrinsicHeight` | ✅ | |
| `FittedBox` | ✅ | `BoxFit.cover`, `.contain`, `.fill`, `.scaleDown` |
| `ColoredBox` | ✅ | Prefer over `Container(color:…)` for simple fills |
| `IgnorePointer` / `AbsorbPointer` | ✅ | Blocks hit testing for the subtree. Decided when a pointer goes down: a drag already in progress keeps flowing when `ignoring` flips mid-gesture |
| `IndexedStack` | ✅ | One child visible at a time; all children stay mounted (state + scroll position preserved — the tab-switcher pattern). Sizing note: fills its parent (Flutter sizes to the largest child) — wrap in a `SizedBox` when you need an intrinsic size |
| `LayoutBuilder` | ✅ | Provides parent `BoxConstraints` to the builder |
| `Directionality` | ✅ | `Directionality.of(context)` works everywhere: every screen starts from the direction the platform lays the app out in, which is right-to-left only when the app declares a right-to-left language (`CFBundleLocalizations` on iOS, `android:supportsRtl` on Android). Wrap a subtree to override it. `MediaQueryData.textDirection` carries the same value |
| `EdgeInsetsDirectional` / `AlignmentDirectional` | ✅ | `start` and `end` follow the nearest `Directionality`; `AlignmentDirectional` is its own type, as in Flutter, and `AlignmentGeometry.resolve` gives the physical `Alignment` |
| `TextAlign.start` / `TextAlign.end` | ✅ | Follow `Text.textDirection` when given, else the nearest `Directionality`. `Row`, `Column` and `Wrap` mirror on their own under right-to-left |
| Right-to-left chrome | ✅ | The `AppBar` mirrors with the rest of the app: the back arrow, the title, a search field and the actions swap sides, the back chevron points the way back, and `actionsPadding`'s start and end follow the reading direction. The bar's own items are placed by the framework, so this holds on both hosts and on both platforms |
| `Card` | ✅ | Without a `color`, the platform's card: Material's outlined card on Android (the surface colour with a thin edge, no shadow), white with a shadow on iOS. `elevation` left out is that default; a `color` of your own drops the edge. |
| `ListTile` | ✅ | Leading / title / subtitle / trailing row. On Android the title and subtitle wear Material's list item type and colours unless you style them. On iPhone the subtitle is 15 pt in the secondary style, the text colour at half opacity, and the row is the 70 pt row of a plain list, 15 pt above and below the two lines. |
| `Table` | ✅ | Column-sized grid layout |
| `BackdropFilter` | ✅ | Native backdrop blur (Gaussian) — `UIVisualEffectView` (iOS) / `RenderEffect` (Android) |
| `ImageFiltered` | ✅ | Blurs the child's own content (Gaussian) |
| `SnackBar` | ✅ | Shown via `ScaffoldMessenger.of(context).showSnackBar`; `content`, `backgroundColor`, `duration`, and `action: SnackBarAction(label:, onPressed:)` |
| `RepaintBoundary` | ✅ | Accepted but no-op — no Skia layer boundaries needed |

---

## Measuring Widgets

| API | Status | Notes |
|---|---|---|
| `context.mounted` | ✅ | False once the widget has left the tree and its `State` has been disposed. Check it after an `await` before using the context again, the same as in Flutter |
| `GlobalKey.currentContext` | ✅ | Resolves to the mounted element for that key |
| `findRenderObject()` | ✅ | Returns a `RenderBox` — but only for a widget that owns a native view (`Container`, `Icon`, `Text`, …). Wrappers such as `Opacity`, `Expanded`/`Flexible` and `Transform` return null, so key a real view when you need to measure |
| `RenderBox.size` | ✅ | The native view's size, in logical pixels |
| `RenderBox.localToGlobal` | ✅ | Converts to screen coordinates. Use it whenever the answer has to be the truth rather than a calculation — a bar that follows the keyboard does not sit where inset arithmetic says |

---

## Text & Input

| Widget | Status | Notes |
|---|---|---|
| `Text` | ✅ | `UILabel`. A `Text` with no colour takes the platform's default text colour: the label colour on iOS; on Android the colour a `TextView` with no style has, the theme's secondary text colour. A `ListTile` title and the bar title use the primary text colour, as Material's styles do. Under a screen with a forced `Scaffold.brightness`, or in a sheet or dialog opened over it, it is the primary colour of that brightness. |
| `RichText` / `TextSpan` | ✅ | `NSMutableAttributedString` — per-span font, color, weight, italic, underline, strikethrough. `TextSpan.recognizer: TapGestureRecognizer` supported for tappable spans. `TextSpan` is not `const` — remove `const` from all `TextSpan(...)` calls |
| `TextField` | ✅ | `UITextField` / `UITextView`. `style.letterSpacing` spaces the field's text the way it spaces a `Text`, on both platforms. `autofillHints` (the `AutofillHints` strings), `AutofillGroup` and `TextInput.finishAutofillContext()` work as in Flutter: the one-time code from Messages above the keyboard, the password manager's entries and its offer to save. On Android, `labelText` is Material's floating label: it sits in the field and moves up onto the box's edge when the field is focused. `labelText`, `helperText`, an `OutlineInputBorder` or `filled` give the field Material's box; a field with only `hintText` is Android's plain field, whose hint stays in place and clears as the user types, the kind a chat screen uses. If `InputDecoration.contentPadding` is omitted, the field uses the platform's own inset: 14 all round on iOS, and on Android the plain field's 4dp beside and 10dp above and below the text, or Material's 16dp for a Material field (override explicitly to customize). `inputFormatters` run on every edit before the keystroke is drawn, caret included: `FilteringTextInputFormatter` (`digitsOnly`, `allow`, `deny`), `LengthLimitingTextInputFormatter`, or your own `TextInputFormatter` over `TextEditingValue` / `TextSelection` `onSubmitted` fires when the user taps the keyboard's action key — the key itself is chosen by `textInputAction` (Done, Go, Search, Send, Next) — and receives the field's current text. As in Flutter, only single-line fields report a submission: in a multiline field that key inserts a newline. **The field owns its box:** `InputDecoration.border` given as an `OutlineInputBorder` (its side's colour and width, one radius), `focusedBorder`, `enabledBorder` and `disabledBorder` by Flutter's precedence, and `filled` with a `fillColor`, are drawn by the native field itself, so a decorated field is one native view: the keyboard reveals the whole box, and the focused outline follows focus. `InputBorder.none`, an `UnderlineInputBorder` and no border leave the platform's own look. A box an app draws around a field is not the field, and the keyboard keeps only the field visible, as a native Android field does. On Android, a decoration with `labelText`, `helperText`, an `OutlineInputBorder` or `filled` is drawn by Material's own text field: the label floats onto the edge when the field takes focus, the helper line sits below, and the outlined or filled box has Material's colours and its 56dp height; an explicit border side, corner radius or `fillColor` still applies, and `hintText` is the placeholder. A field with none of those is Android's plain field with its underline; `InputBorder.none` removes it. On iOS the field stays bare and `labelText`/`helperText` are not drawn. `errorBorder` is not drawn. On iPhone a field whose `OutlineInputBorder` keeps its default side is the platform's own rounded field, 34 pt with its grey bezel; `labelText` stands in for a missing `hintText` there; a bare field is the text line alone, with no inset. |
| `TextEditingController` | ✅ | `text`, `value`, `selection`, `clear()`. Typing updates the controller before `onChanged`; setting `selection` or `value` moves the caret, setting `text` keeps it where the field has it |

> **Font size units.** dartnative renders text using real native APIs, so `TextStyle.fontSize` follows each platform's conventional unit — **UIKit points** on iOS (fixed, does not scale with Dynamic Type) and **SP** on Android (scales with the user's font-size accessibility setting). This is identical to what you get writing native UIKit or Android code directly.
| `TextPainter` | ✅ | Drop-in replacement backed by the platform's text measurement — call `layout(maxWidth:)` then read `.size` |
| `RenderParagraph` | ✅ | Drop-in replacement — `layout(BoxConstraints)` + `.size`; no RenderObject tree required |
| `SelectableText` | ✅ | Covered by `Text(selectable: true)` — long-press to select/copy on BOTH platforms. Plain `Text` stays `UILabel` / `TextView`; the flag swaps in a read-only `UITextView` (iOS) / read-only `EditText` (Android), so use plain `Text` when selection isn't needed. A dedicated `SelectableText` class is not exported; pass the flag. |
| `ValueListenableBuilder<T>` | ✅ | Full `StatefulWidget` — subscribes via `addListener`, passes typed `value` to builder, cleans up on `dispose`. Drop-in from Flutter. |
| `StreamBuilder<T>` | ✅ | Full `StatefulWidget` — manages `StreamSubscription`, full `ConnectionState` lifecycle (none → waiting → active → done). Drop-in from Flutter. |
| `FutureBuilder<T>` | ✅ | Full `StatefulWidget` — a completion after the builder left the tree, or after its future was replaced, is ignored. Drop-in from Flutter. |

---

## Scrolling

### Drop-in Flutter replacements

All of these are backed by `UIScrollView` with Yoga-managed content. Every child is a live native view — suitable for short, bounded lists.

| Widget | Status | Notes |
|---|---|---|
| `ListView` | ✅ | |
| `ListView.builder` | ✅ | All items built eagerly — use `FastList` for large datasets |
| `SingleChildScrollView` | ✅ | |
| `RefreshIndicator` | ✅ | Pull to refresh on the vertical scrollable inside it: `onRefresh`, `color`, `backgroundColor`; start a refresh from code with `GlobalKey<RefreshIndicatorState>` and `show()`. `style: RefreshStyle.pullDown` (default): the content follows the finger and a spinner shows in the band the pull opens above it (`UIRefreshControl` on iOS, a Material spinner on Android), turning once the pull passes the threshold; `color` is the spinner's colour and `backgroundColor` the band's, and left out the spinner is drawn for the screen's brightness. For content that runs under a header (a feed's tabs, the status bar), `edgeOffset` keeps the spinner in the band below it, never over the content, `displacement` is how far below that edge the content rests while the refresh runs, and `triggerDistance` how far the band opens before letting go refreshes. In this style the spinner is the platform's own, recoloured with `color`; give a `builder` and the platform's spinner stays hidden while the content still follows the finger: the builder gets the pull (phase, the band's height as `distance`, progress), through the refresh and the way back so what it draws follows the content, and draws in the band, a `PullDownIndicator` restyled or with a `child` of your own in the spinner's place, a logo or an arrow turning with the pull, riding with the content a `gap` above its edge and sliding under the header's edge as the band closes; the builder wraps the whole child, so it may keep the pull's look through the refresh and show the loading anywhere on the page, your `onRefresh` future being the loading state; `RefreshStyle.pullOver` holds the content still and draws the indicator over it: by default a video feed's: a gradient darkens the top of the screen while the pull lasts, and the line, `label` ("Pull down to refresh"), fades in under the top safe area and slides down a little with the pull, playing back when you let go, with a spinner in its place while the refresh runs, a `child` of your own there instead (an animated icon, beside the line while you pull and in its place while the refresh runs), or none with `showSpinner: false`; or give a `builder(context, child, state)` and draw your own from the state's phase, distance and progress, placing a `PullOverIndicator` where you like. `triggerDistance` is the release threshold. Works on `ListView`, `SingleChildScrollView`, `FastList`, a vertical `PageView`, the grids and `CustomScrollView`; the control sits at the top, so a horizontal or reversed scrollable has none |
| `CustomScrollView` | ✅ | |
| `SliverList` / `SliverList.builder` | ✅ | |
| `SliverFixedExtentList` | ✅ | `.builder` and `.list`; every item takes `itemExtent` |
| `SliverGrid` | ✅ | `.count` and `.extent` constructors |
| `SliverToBoxAdapter` | ✅ | |
| `SliverPadding` | ✅ | |
| `SliverFillRemaining` | ✅ | |
| `SliverAppBar` | ✅ | Every named parameter of Flutter's widget is accepted. In a `NestedScrollView` header it collapses natively: `expandedHeight`, `collapsedHeight`, `pinned`, `floating`, `snap`, `bottom`, `toolbarHeight`, the title, leading and actions, `backgroundColor`, and a `FlexibleSpaceBar.background` behind the bar. In a `CustomScrollView` it is a bar at the top of the content; its collapse there and the `FlexibleSpaceBar` title are not available yet |
| `GridView` | ✅ | `.count` and `.builder`; Yoga flex-wrap rows |
| `PageView` | ✅ | `PageView`, `.builder`, `.custom` and `PageController`; each swipe settles on one page on the platform's own paging. A page is always the whole viewport (`viewportFraction` other than 1 is not supported) |
| `NestedScrollView` | ✅ | Flutter's API: `headerSliverBuilder`, `body`, `floatHeaderSlivers`, `NestedScrollViewState` through a `GlobalKey`, `sliverOverlapAbsorberHandleFor`, `SliverOverlapAbsorber` and `SliverOverlapInjector`. The header (a `SliverAppBar`) sits over the body's top and its height follows the body's scroll natively: it shrinks away as the body scrolls, comes back when the content returns (at once when `floating`), keeps its collapsed height when `pinned`, and `snap` animates it open or shut when a drag ends, moving the content with it. The header always floats over the content; `controller`, `physics` and the other scroll-view knobs are accepted and not honoured yet; only a `SliverAppBar` renders among the header slivers |
| `ReorderableListView` | ✅ | Flutter's API on the platform's own reordering: the table's row move on iOS, the recycler's touch helper on Android, each with its lift, auto-scroll and haptics. `children` (every item keyed) and `.builder`; `onReorder` in Flutter's index convention. A long press lifts a row by default; with `buildDefaultDragHandles: false` a `ReorderableDragStartListener` starts the drag on Android and iOS shows the table's own reorder control on every row. `FastList` offers the same through `onReorder`. Every named parameter of Flutter's widget is accepted, so Flutter code compiles unchanged; not honoured yet: `header`/`footer`, `proxyDecorator`, `onReorderStart`/`End`, `scrollController`, `shrinkWrap`, `cacheExtent` and the other scroll-view knobs, a horizontal list. |

### High-performance native lists

These are DartNative-specific widgets built directly on the platform's own list machinery — the scroll physics, momentum and rubber-banding are `UITableView`'s / `RecyclerView`'s, not a re-implementation. That buys three things that are hard to get elsewhere:

- **Native scrolling feel** — the platform draws only on-screen cells (cell-container recycling), so scrolling stays smooth at any list length, even with heavy cells.
- **Exact index jumps** — `jumpToItem(5000)` lands precisely on item 5000 via the platform's own index APIs (`scrollToRow` / `scrollToPosition`), instantly, no pixel-offset guessing. This is notoriously hard to achieve with offset-based scroll controllers.
- **Rows are built as they near the viewport** — the mount builds the rows that fill the first screen and a margin beyond it, and each further row is built as the scroll approaches it, so `itemCount` is a number, not a cost: a list of ten thousand rows launches like one of thirty. Give `itemExtent` when every row has the same height and the list's geometry is exact from the start; otherwise an unbuilt row takes the average of the rows measured so far, as Flutter's estimated extents do.
- **Bounded memory (content windowing)** — set `keepAliveCount` and the list only keeps built content for the visible rows plus `keepAliveCount` on each side: **built content is O(visible + 2·keepAliveCount), independent of `itemCount`**. Rows leaving the window release everything they built (images, animations, native views) while keeping their exact height — scroll position never moves; rows re-entering rebuild *before* they reach the screen, so there's no visible seam. Give rows an `Image.placeholder` (e.g. `Shimmer`) to cover deep scroll-back reloads.

| Widget | Status | iOS | Android |
|---|---|---|---|
| `FastList` | ✅ | `UITableView` with cell recycling | `RecyclerView` |
| `FastGrid` | ✅ | `UICollectionView` with cell recycling | `RecyclerView` |
| `MasonryFastGrid` | ✅ | Staggered Pinterest-style grid; heights from `itemHeightBuilder`. `UICollectionView` with a custom staggered layout | `RecyclerView` (`StaggeredGridLayoutManager`) |

**Paging.** `FastList(pagingEnabled: true)` makes every swipe settle on exactly one item: a full-screen video feed, an onboarding carousel (`scrollDirection: Axis.horizontal`). The paging is the platform's own, so the feel is native and a fling moves one page. Each item is laid out at the list's own size, so a page is always one viewport. `PageView` is this with Flutter's names; use the `FastList` form when the feed also needs `keepAliveCount`, `onVisibleRange` or `stableItems`.

**When to use `FastList` vs `ListView.builder`:**

`ListView.builder` keeps every item as a live `UIView`. `FastList` delegates to `UITableView`, which **recycles cell containers** so only on-screen cells are *drawn* — smooth scrolling at any length, and instant index-based jumps. Rows are built as they near the viewport, so the mount costs the same at any `itemCount`. Without `keepAliveCount`, a row once built stays built, so memory grows with the rows the user has scrolled past; **with `keepAliveCount` set, content memory is bounded by the window instead — use it for any long or image-heavy list.** Paginate when the data comes from a server — grow `itemCount` from the `onScroll` callback as the user nears the end — for the data's sake, not the list's.

**The recipe for a long image list:**

```dart
FastList(
  itemCount: photos.length,
  keepAliveCount: 30,                       // bound held content (the OOM killer)
  itemBuilder: (_, i) => Image.network(
    photos[i].url,
    cacheWidth: 300, cacheHeight: 300,      // bound each decoded bitmap
    fit: BoxFit.cover,
  ),
  onScroll: (offset, maxExtent, viewport, dragging) {
    if (maxExtent - offset < 2 * viewport) loadMore(); // bound itemCount
  },
)
```

> ⚠️ Like Flutter's lazy lists beyond `cacheExtent`: a row outside the
> `keepAliveCount` window loses any cell-local `State` (a checkbox, text being
> typed). Keep item state in your model, not in the cell. Tuning: placeholders
> on hard flings → raise `keepAliveCount`; memory too high → lower it or set
> `cacheWidth`/`cacheHeight`.

### FastList properties

FastList mirrors the `ListView.builder` API with the following configuration options:

| Property | Type | Default | Description |
|---|---|---|---|
| `itemCount` | `int` | (required) | Total number of items in the list |
| `itemBuilder` | `Widget Function(BuildContext, int)` | (required) | Called for each visible index; returns a native widget |
| `scrollDirection` | `Axis` | `Axis.vertical` | Scroll axis; `horizontal` lays the children out in a row |
| `reverse` | `bool` | `false` | If `true`, list starts from the bottom |
| `showScrollBar` | `bool` | `false` | Show/hide the scroll indicator along the scroll axis |
| `padding` | `EdgeInsets?` | `null` | Content inset around the list |
| `physics` | `ScrollPhysics?` | `null` | `NeverScrollableScrollPhysics` to disable scrolling; `BouncingScrollPhysics` / `ClampingScrollPhysics` for scroll behaviour |
| `keepAliveCount` | `int?` | `null` | Content windowing: keep built content only for visible rows + this many on each side (memory becomes independent of `itemCount`). `null` keeps a row built once it has been built |
| `itemExtent` | `double?` | `null` | The main-axis size of every row when all rows are the same size, as Flutter's `ListView.itemExtent`: rows not built yet then take exactly that size, so the scroll bar and a jump to a far index are exact. Without it an unbuilt row takes the average of the rows measured so far |
| `onScroll` | `FastScrollCallback?` | `null` | Fires `(offset, maxExtent, viewport, dragging)` on scroll — load-more, hide-on-scroll, progress |

> **Off-screen item retention is managed by the native platform** (`UITableView` /
> `RecyclerView`). Both ship with built-in cell-reuse pools and prefetch windows
> tuned for smooth scrolling, so dartnative does **not** expose a Flutter-style
> `cacheExtent` knob. Long-distance navigation is O(1): use
> [`FastListController.jumpToItem`](#fastlistcontroller) /
> `scrollToItem` / `animateToItem` to jump to **any** index instantly,
> regardless of how far it is off-screen. For scroll position (load-more,
> hide-on-scroll, progress), use the `onScroll(offset, maxExtent, viewport,
> dragging)` callback rather than a Flutter `ScrollController`.
> `ScrollController` works on every scrollable: `offset` and
> `position.pixels`/`maxScrollExtent` update live, and `jumpTo`/`animateTo`
> drive the native scroll view. The dedicated Fast controllers add what a
> pixel offset cannot express — jumping to an item by index
> (`jumpToItem`) inside recycled content.

```dart
FastList(
  itemCount: items.length,
  itemBuilder: (context, index) => Text(items[index].title),
  showScrollBar: false,   // hide the scroll indicator
)
```

### FastGrid properties

FastGrid is the grid counterpart, backed by `UICollectionView` (iOS) /
`RecyclerView` (Android). Same build-on-approach and recycle model as `FastList`,
with its own index-based `FastGridController` (`jumpToItem` / `scrollToItem`) and
the same `onScroll` callback. (`MasonryFastGrid` shares the `FastGridController`.)

| Property | Type | Default | Description |
|---|---|---|---|
| `itemCount` | `int` | (required) | Total number of items |
| `itemBuilder` | `Widget Function(BuildContext, int)` | (required) | Called for each visible index |
| `crossAxisCount` | `int` | `2` | Number of columns |
| `mainAxisSpacing` / `crossAxisSpacing` | `double` | `0.0` | Spacing between items |
| `padding` | `EdgeInsets?` | `null` | Content inset |

Like `FastList`, the native view recycles cell containers for smooth scrolling,
cells are built as they near the viewport (a cell's size comes from the grid's
own configuration, so an unbuilt cell needs nothing and `itemCount` is not a
cost), and both grids support **`keepAliveCount` content windowing** (same
semantics as `FastList`): content memory is O(visible + 2·keepAliveCount),
independent of `itemCount`. Note the value counts **items, not rows** — multiply
by your column count (a 3-column grid wants ~3× a list's value). Combine with
`Image.cacheWidth`/`cacheHeight` for the full recipe.

```dart
FastGrid(
  itemCount: photos.length,
  itemBuilder: (context, index) => Image.network(photos[index].url),
  crossAxisCount: 3,
  mainAxisSpacing: 2,
  crossAxisSpacing: 2,
)
```

---

## Navigation & Scaffold

| Widget | Status | Notes |
|---|---|---|
| `Scaffold` | ✅ | `backgroundColor` is the route's colour: on iOS 26 a push draws both screens as rounded cards over a backdrop painted with it, so a page colour painted deeper in the body than its root flashes the white default at the corners (a plain colour box at the body's root is read as the page) — see [The screen's background belongs on the Scaffold](#the-screens-background-belongs-on-the-scaffold). `brightness` declares the screen's light/dark trait (inherited by the body, bottom bars and keyboards, by the bar's title and items over the screen, by the defaults computed in Dart such as a card's surface or a list item's subtitle, and by a sheet or dialog opened from the screen; `MediaQuery.of(context).platformBrightness` reports it under the scaffold; applies from the first build). Declare it on dark-styled screens: system effects like the iOS 26 scroll-edge fades render in the trait, so a dark-by-colors screen on a light-mode device gets white flashes without it. `bottomAccessory` — any-widget strip above the bottom bar (iOS 26 tabbed pattern → native `UITabAccessory`, slides inline on minimize; composed elsewhere) — see [Bottom accessory](#bottom-accessory-scaffoldbottomaccessory-ios-26) Without a colour the screen is the platform's own page: the system background on iPhone, white in light and black in dark, and the theme's surface on Android. |
| `AppBar` | ✅ | `automaticallyImplyLeading` (default `true`) auto-shows back button when screen can pop. `leading`, `title`, and `actions` all accept **arbitrary widgets** (`actions` takes several — each its own glass capsule on iOS 26) — see [Custom widgets in AppBar.title and AppBar.actions](#custom-widgets-in-appbartitle-and-appbaractions). Title placement and spacing: [`centerTitle`](#appbarcentertitle) and [`titleSpacing`](#appbartitlespacing); trailing-group padding: [`actionsPadding`](#appbaractionspadding) — each has its own section below. `subtitle` renders a secondary line under the title. `largeTitle` renders a large title under the bar that **collapses natively on scroll** into the bar title (`largeTitleSize` picks the Android M3 variant: medium/large flexible) — see [Large title & the see-through bar](#large-title--the-see-through-bar-ios-26). iOS 26 bar surfaces: a **translucent `backgroundColor`** (alpha < 1) = frosted glass (content faintly visible behind); **no `backgroundColor`** = a fully clear bar where content stays visible scrolling beneath, kept legible by the system scroll-edge blur ramp. On Android, **no `backgroundColor`** = the bar takes the screen's colour (`Scaffold.backgroundColor`) and a title and back arrow with no colour of their own turn white or black to stay readable against it. `searchBar` makes the bar region the search pill itself (the `SearchBar` row below); `title` is skipped when set — the pill owns the region. `actionsGlassBackground: false` (iOS 26) removes the glass capsule behind a self-designed action widget (an avatar circle keeps just its circle). On iOS 26, a bar using only plain native features is hosted on the **system navigation bar** and its buttons **morph between screens** — see [Morphing bar buttons](#morphing-bar-buttons-ios-26-appbarios) (`ios: AppBarIOSConfig(systemBar:)` selects the host explicitly) On Android the bar is Material's 64dp top app bar with a 22sp regular title; `toolbarHeight` still sets your own. `bottom` places a widget under the toolbar, a `TabBar` normally; it shares the bar's surface and the body starts below it. |
| `BackButton` | ✅ | **Semantic back preset** for `AppBar.leading` — see details below. `leading` also accepts any other widget (e.g. a `Button`), which replaces the auto back button |
| `BarButtonItem` | ✅ | Convenience trailing action for `AppBar.actions` — text (`title`), SF Symbol (`icon`, iOS) or font glyph (`fontIcon`, both platforms); iOS 26 Liquid Glass capsule via default `actionsGlassBackground`. With `menu: [MenuAction(...)]` the tap shows a **native anchored menu** (capsule→UIMenu morph on iOS 26; M3 popup on Android) — see [Native menus on a bar action](#native-menus-on-a-bar-action-barbuttonitemmenu) |
| `App` | ✅ | Deprecated aliases: `MaterialApp`, `CupertinoApp` |
| `Navigator.push` / `pop` | ✅ | |
| `PageRoute` | ✅ | Accepts `transition` and `duration` parameters. Deprecated alias: `MaterialPageRoute` |
| `BottomNavigationBar` | ✅ | `UITabBar` — font glyph rendered directly on both platforms; no SF Symbol mapping needed. iOS 26: renders as the floating Liquid Glass pill — `backgroundColor` is ignored there and the bar manages its own home-indicator offset; pair with `Scaffold(extendBody: ...)` so content scrolls behind it — the system fade under the pill is applied automatically (declare `Scaffold.brightness` on dark screens; the fade renders in the trait). `scrollBehavior: TabBarScrollBehavior.minimizeOnScrollDown` minimizes the pill on scroll (real `UITabBarController` lowering — see [Minimize on scroll](#minimize-on-scroll-scrollbehavior-ios-26)); `BottomNavigationBarItem.search()` = the system search pill; item `subtitle`/`enabled`/`activeIcon` supported |
| `TabBar` / `TabBarView` | ✅ | Flutter's API: `TabBar` (and `.secondary`) under the app bar (`AppBar.bottom`) or on its own, `Tab` with text, an icon or both, `TabBarView`, `TabController` and `DefaultTabController`. The bar is a native strip in the Material shape on both platforms (drawn by the framework on iOS, Material's own tab layout on Android); the pages swipe on the platform's paging, and the indicator follows a swipe as it happens. A tap animates to the page; `isScrollable`, `indicatorColor`, `indicatorWeight`, `labelColor`, `unselectedLabelColor`, `dividerColor`, `dividerHeight`, the label's font size and `onTap` are honoured; every other named parameter is accepted, so Flutter code compiles unchanged (`indicator`, `indicatorSize`, `padding`, `labelPadding`, `overlayColor`, `tabAlignment` and the other style knobs have no effect yet) |
| `SegmentedControl` | ✅ | `UISegmentedControl` (iOS); Material's segmented buttons on Android, sized to their labels unless the control is given a width. |
| `Drawer` / `DrawerHeader` | ✅ | `Scaffold.drawer` — an opinionated slide drawer, no scrim. `drawerStyle` picks the reveal:<br>• **`DrawerStyle.push`** (default) — drawer and screen move **together** as one flat plane: the screen slides aside while the panel slides in from behind it, no shadow, no depth (Gmail / Spotify).<br>• **`DrawerStyle.slideOver`** — the drawer is a **static layer underneath, it never moves**; the screen lifts and slides over it as a floating card with an edge shadow and corners that round in as it travels (X / Twitter). Tune via `Scaffold.slideOverStyle` — `SlideOverStyle(shadow:, corner: straight/rounded, radius:)` — ignored under `push`.<br>Swipe to open (`drawerEnableOpenDragGesture`) or `Scaffold.of(context).openDrawer()`; tap the moved content or swipe back to close. `onDrawerChanged` fires on open/close; `Drawer.width` sets the panel width. Android tip: if the screen colors the system navigation-bar strip (bottom-bar screens), set it transparent while the drawer is open via `onDrawerChanged` — otherwise it draws over the sliding card's shadow. A manual AppBar hamburger wraps the button in a `Builder` so `Scaffold.of(context)` resolves below the drawer. `GlobalKey<ScaffoldState>` is not supported — drive the drawer via `Scaffold.of(context)`, or use `SliderMenuContainer` directly for key-driven control. **Release feel is native per platform:** iOS follows Apple's projection rule, Android the Material flick rule; `SliderMenuContainer.settleCurve` shapes the settle, and a new drag catches a still-moving panel. |

### The screen's background belongs on the Scaffold

Set `Scaffold.backgroundColor` rather than wrapping the body in a coloured
`Container`. The two look identical at rest, and differ during a route
transition.

A push does not slide two opaque rectangles: on iOS 26 both screens become
cards with the display's corner radius, so the surface behind them shows at
the corners and in the gap between routes. That surface is a **backdrop the
navigator owns**, not part of either screen, and it is painted with the
DESTINATION route's background colour — which the Scaffold reports. With no
`backgroundColor`, the Scaffold reads one thing from the body: a plain
full-bleed colour box at its ROOT (a `Container` or `ColoredBox` with a
colour and no size, margin, constraints, alignment, radius, border, shadow
or gradient) is the page at rest, and the route reports that colour. Nothing
deeper is read, since the first coloured container inside might be a card, a
header or a section, so a dark screen that paints black below its root
reports the white default and flashes a white frame on every push and pop.

```dart
// Reported: the body's root is a plain colour box, so the route is black.
Scaffold(body: Container(color: Colors.black, child: content))

// Not reported: the colour box is below the root. Flashes white at the corners.
Scaffold(body: SafeArea(child: Container(color: Colors.black, child: content)))

// Correct everywhere: the route says what it is.
Scaffold(backgroundColor: Colors.black, body: content)
```

Use containers inside the body for cards and sections. A screen with no
Scaffold, or a deliberately transparent one, reports nothing and keeps the
system backdrop.

### `extendBody` and transparent backgrounds

With `extendBody: true` (or `extendBodyBehindAppBar: true`) and no
`Scaffold.backgroundColor`, the screen's surface is transparent, and a
transparent surface does not capture scroll gestures over empty areas — a list
inside it then only scrolls when the drag *starts* on opaque content (e.g. a
chat bubble), not on the gaps around it.

**Set an explicit opaque `Scaffold.backgroundColor`** (for a dark screen,
`Colors.black`). It's the background you usually want anyway, and the body still
renders in front of it, so the visual result is identical — and the list scrolls
everywhere:

```dart
Scaffold(
  extendBody: true,
  backgroundColor: Colors.black, // a transparent root won't capture scroll gestures
  // ...
)
```

If you genuinely need a **see-through** background, use a near-transparent
`Colors.black.withOpacity(0.01)`: it reads as transparent but still captures gestures. Avoid a fully
`Colors.transparent` background. (`extendBody: false` is unaffected — its default
is already opaque.)

### `GlassEffectContainer` — Liquid Glass material

Wraps a `child` in the iOS 26 **Liquid Glass** material, rendered behind the
child. On **iOS < 26 and Android** it is a
no-op pass-through (a plain transparent container) — there is deliberately no blur
fallback; Liquid Glass is an iOS-26-only material.

| Prop | Type | Notes |
|---|---|---|
| `child` | `Widget` | Rendered on top of the glass. |
| `borderRadius` | `BorderRadius?` | Rounds the glass; passive glass clips its child to it. `null` → square. |
| `tint` | `Color?` | Colour layered into the glass. `null` / transparent → untinted. |
| `interactive` | `bool` | The glass reacts to touch, with the system press. |
| `brightness` | `Brightness?` | Pins the capsule's light/dark tone — see below. |
| `shadow` | `BoxShadow?` | Shadow the glass casts from its own rounded shape. Set it here, not on a rounded box around the glass: the box clips its child, and interactive glass must not be clipped or the press eats its padding. |

```dart
GlassEffectContainer(
  borderRadius: BorderRadius.circular(20),
  tint: const Color(0xFF007AFF),
  interactive: true,
  child: const Icon(CupertinoIcons.arrow_up),
)
```

**Sizing.** `GlassEffectContainer` sizes like `Container`: a child that declares
an explicit width (`SizedBox(width: …)` / `Container(width: …)` — the glass
circle/pill idiom) is hugged; otherwise the glass fills the available width
under a vertical parent, exactly like a width-less `Container`. Swapping a
`Container` for a `GlassEffectContainer` never changes layout.

**`brightness` — pin the glass tone.** iOS 26 Liquid Glass takes its tone from the
**trait** (the system theme), NOT from a background colour. So on a *dark-by-design*
surface in a **Light** system theme the glass goes light/white and washes out dark
content — and a wrapped textfield's keyboard goes light too. Set `brightness`
(`Brightness?`, default `null` = follow system) to pin the capsule — and any wrapped
text field's keyboard, which inherits this trait — to `Brightness.dark` /
`Brightness.light` regardless of the device theme:

```dart
GlassEffectContainer(
  brightness: Brightness.dark, // dark glass + dark keyboard, even in Light Mode
  borderRadius: BorderRadius.circular(16),
  child: myTextField,
)
```

No effect on iOS < 26 / Android (no Liquid Glass).

**`interactive: true` and text fields.** Inside interactive glass, buttons
and gesture handlers work normally, and a multiline field stays fully native
(set `minLines`/`maxLines`; the single-line default loses caret taps inside
interactive glass). The system's press grows the glass and its content past
the container's bounds, the way a glass button grows under a finger, so leave
it room in the layout. Passive glass clips its child to the corner radius.

#### Capsule colours — `GlassEffectContainer` vs native glass `Button`

A circular Liquid Glass capsule with an icon (a back button, a top-bar control)
can be built two ways: a native glass `Button` (`ButtonVariant.glass` /
`clearGlass`, `color:` for the tint, `foregroundColor` for the icon) or a
`GlassEffectContainer` (`tint:` for the tint, the child icon's own colour for
the foreground). They differ in one way: on a **frosted** native `glass()` /
`prominentGlass()` capsule the glass vibrancy auto-contrasts the icon and washes
a saturated `foregroundColor` (clear variants don't). `Button.automaticTint`
(default `false`) keeps the colour you asked for on every variant; set it `true`
to opt back into Apple's auto-contrast. `GlassEffectContainer` has no such
limit, because its icon is a separate child view, so reach for it whenever you
need a **tinted capsule with an explicit (e.g. white) icon**, and use the native
glass `Button` for the clear-capsule look.

### `GlassEffectGroup` — merging / morphing glass (iOS 26)

Wrap a subtree in `GlassEffectGroup` and the Liquid Glass elements inside it
**merge into one fluid blob** when they come closer than `spacing` — animated
or gesture-driven, with tints blending — and split apart again as they
separate (Apple's group morph):

```dart
GlassEffectGroup(
  spacing: 40,          // merge distance (pt); default 40
  child: Row(
    children: [
      GlassEffectContainer(borderRadius: ..., child: Icon(...)),
      const SizedBox(width: 12),   // < spacing → the two capsules fuse
      GlassEffectContainer(borderRadius: ..., child: Icon(...)),
    ],
  ),
)
```

Glass elements anywhere in the subtree participate (they don't need to be
direct children). On iOS < 26 and Android the group is a transparent
pass-through — children render normally, nothing merges.

### Badges on tabs and bar actions (`Badge`)

`Badge` composes anywhere (a plain overlay counter), but in two places the
framework detects it and lowers to the REAL platform badge:

- **Tab icons**: `BottomNavigationBarItem(icon: Badge(count: 3, child:
  Icon(...)))` → `UITabBarItem.badgeValue` on iOS, an M3 badge on Android.
- **AppBar actions**: `actions: [Badge(count: 3, child: BarButtonItem(...))]`
  → a badge pinned to the action's corner (the iOS 26 glass capsule / the
  Android toolbar action).

Counts above 99 render as "99+" on both platforms; text `label`s work too;
updating `count` live animates in place. No new API — wrap and it's native.

### BottomNavigationBar

A native tab bar (`UITabBar` on iOS, `BottomNavigationView` on Android).

```dart
BottomNavigationBar(
  currentIndex: _selectedTab,
  onTap: (i) => setState(() => _selectedTab = i),
  labelFontStyle: const TextStyle(
    fontSize: 13,
    color: Color(0xFF8E8E93),
  ),
  selectedLabelFontStyle: const TextStyle(
    color: Color(0xFFFFFFFF),
  ),
  iconColor: const Color(0xFF8E8E93),
  selectedIconColor: const Color(0xFFFFFFFF),
  indicatorColor: const Color(0xFFFF3B30),
  items: [
    BottomNavigationBarItem(label: 'Home', icon: Icon(CupertinoIcons.house_fill)),
    BottomNavigationBarItem(label: 'Search', icon: Icon(CupertinoIcons.search)),
    BottomNavigationBarItem(label: 'Profile', icon: Icon(CupertinoIcons.person_fill)),
  ],
)
```

| Property | Type | Default | Description |
|---|---|---|---|
| `currentIndex` | `int` | `0` | Selected tab index |
| `onTap` | `ValueChanged<int>?` | `null` | Tab selection callback |
| `items` | `List<BottomNavigationBarItem>` | (required) | Tab items: `label`, `icon`, `activeIcon` (selected-state glyph, iOS), `subtitle` (iOS 26 — note: the iPhone's compact pill doesn't display tab subtitles; they surface in wide layouts such as the iPad sidebar), `enabled: false` (disabled tab, both platforms). `BottomNavigationBarItem.search()` = the search destination (below) |
| `labelFontStyle` | `TextStyle?` | `null` | Base label style: `color` → unselected text/icon fallback, `fontSize`/`fontWeight` → all labels |
| `selectedLabelFontStyle` | `TextStyle?` | `null` | Selected label style: `color` → selected text, `fontSize`/`fontWeight` override |
| `iconColor` | `Color?` | `null` | Unselected icon tint |
| `selectedIconColor` | `Color?` | `null` | Selected icon tint (falls back to `selectedLabelFontStyle.color`) |
| `indicatorColor` | `Color?` | `null` | Selected tab background highlight (Android: `itemActiveIndicatorColor`) |
| `backgroundColor` | `Color?` | `null` | Tab bar background |
| `scrollBehavior` | `TabBarScrollBehavior` | `.none` | iOS 26: minimize the floating pill on scroll — see below |
| `onSearchQueryChanged` | `ValueChanged<String>?` | `null` | Query text from a `.search()` destination's native field — see [Search destination](#search-destination-bottomnavigationbaritemsearch-ios-26) |

#### Minimize on scroll (`scrollBehavior`, iOS 26)

Set `scrollBehavior: TabBarScrollBehavior.minimizeOnScrollDown` (or
`.minimizeOnScrollUp`) and on iOS 26 the floating pill **minimizes into a
compact capsule** as the selected tab's content scrolls, restoring on the
opposite scroll — the system behavior, driven natively by your lists:

```dart
Scaffold(
  bottomNavigationBar: BottomNavigationBar(
    scrollBehavior: TabBarScrollBehavior.minimizeOnScrollDown,
    currentIndex: _tab,
    onTap: (i) => setState(() => _tab = i),
    items: [...],
  ),
  body: IndexedStack(index: _tab, children: [...]),  // required shape
)
```

Under the hood this opts the Scaffold's tab pattern into a real
`UITabBarController` — which is why the **body must be (or contain) an
`IndexedStack`**: each stack child becomes a native tab. Everything else is
unchanged (`onTap`/`currentIndex`, item badges, icons, colors). **On
Android** the same field drives Material's hide-on-scroll: the body
automatically extends behind the bar and the bar slides away as content
scrolls down, revealing content underneath — returning on scroll-up (M3
motion). The bar renders edge-to-edge: its background fills the system
navigation area under the items, the Material convention. Give scrolling content roughly a bar's height of bottom padding
so nothing hides behind the bar at rest, just like the iOS 26 pill. On
iOS < 26 the bar stays static.

> Current limitation: the lowering is decided when the screen mounts —
> toggle a gated capability only between screen pushes. Programmatic
> `currentIndex` changes and live badge/icon updates work normally.

#### Search destination (`BottomNavigationBarItem.search()`, iOS 26)

Make one destination the system SEARCH tab: on iOS 26 it renders as the
**separated search pill** beside the bar; tapping it activates the native
search field (living in the pill), and the query streams to Dart:

```dart
BottomNavigationBar(
  onSearchQueryChanged: (q) => setState(() => _query = q),
  items: [
    BottomNavigationBarItem(label: 'Feed', icon: Icon(CupertinoIcons.list_bullet)),
    BottomNavigationBarItem.search(),   // label/icon optional
  ],
)
```

The search tab's `IndexedStack` child is the **results content** — filter
it from `onSearchQueryChanged`. `automaticallyActivatesSearch` (default
`true`) opens the field as soon as the tab is selected. A search item is
an opt-in to the `UITabBarController` lowering (same `IndexedStack`
requirement). On iOS < 26 and Android it renders as a plain tab.

#### Bottom accessory (`Scaffold.bottomAccessory`, iOS 26)

A strip above the bottom bar — Apple's Music-style now-playing accessory.
Pass **any widget**; taps and live updates work normally:

> The accessory hosts your widget **transparently** on the system
> platter — don't give the root widget its own full-size background
> (it renders as a box-inside-a-box on the strip). Backgrounds belong
> only on elements that should read as content on the strip.

```dart
Scaffold(
  bottomAccessory: GestureDetector(
    onTap: _openPlayer,
    child: Container(height: 44, child: Row(children: [...])),
  ),
  bottomNavigationBar: BottomNavigationBar(
    scrollBehavior: TabBarScrollBehavior.minimizeOnScrollDown,
    items: [...],
  ),
  body: IndexedStack(index: _tab, children: [...]),
)
```

On iOS 26 with the tabbed pattern this lowers to the native
`UITabAccessory`: the strip **floats above the Liquid Glass pill** and —
when the bar minimizes on scroll — **slides inline beside the capsule**,
the system morph. Using `bottomAccessory` is itself an opt-in to the
`UITabBarController` lowering (same requirements as `scrollBehavior`:
an `IndexedStack` body). On iOS < 26, Android, or without the tabbed
pattern, the same widget renders composed — a full-width strip between
the body and the bottom bar.

### Button sizing

A bare `Button` is the platform's own button. On iOS: the label with
12 pt beside it and 7 pt above and below, the 34 pt pill of a SwiftUI
bordered button; a `plain` button is its label alone, the height of one
line, as a borderless button. On Android: Material's button, the label with
24 dp beside it, a 40 dp pill inside a 48 dp touch target (4 dp of
transparent inset above and below it, so stacked buttons sit 8 dp
apart with no spacing of your own), and at least 88 dp wide when it
carries a label (an icon-only button is as wide as its icon). Sizing
props change the design on both platforms:

| Prop | Effect |
|---|---|
| `width:` / `height:` | Exact size — overrides insets and the minimum; on Android the pill is drawn to `height` with no inset. |
| `padding:` | Replaces the default insets. |
| `fontSize:` | Label size — drives the intrinsic size together with the insets. |

```dart
Button(title: 'Add')                              // the platform's own size
Button(title: 'Add', height: 40)                  // exact height (e.g. match a text field)
Button(title: 'Add', padding: EdgeInsets.all(6))  // content-driven compact
```

`IconButton` always keeps a 48 pt hit area even when its glyph is
smaller.

### SegmentedControl

A native segmented control (`UISegmentedControl` on iOS, `MaterialButton` toggle group on Android).

```dart
// Colors unset → PLATFORM defaults: Apple's trait-adaptive white-thumb-on-
// grey-track appearance on iOS, Material's outlined segmented buttons on
// Android (the selected segment on the theme's secondary container).
SegmentedControl(
  segments: ['Grid', 'Masonry'],
  selectedIndex: _tabIndex,
  onValueChanged: (i) => setState(() => _tabIndex = i),
)

// Or fully custom:
SegmentedControl(
  segments: ['Grid', 'Masonry'],
  selectedIndex: _tabIndex,
  onValueChanged: (i) => setState(() => _tabIndex = i),
  indicatorColor: const Color(0xFF007AFF),
  backgroundColor: const Color(0xFF2C2C2E),
  labelFontStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
  selectedLabelFontStyle: const TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 14,
    fontWeight: FontWeight.bold,
  ),
)
```

| Property | Type | Default | Description |
|---|---|---|---|
| `segments` | `List<String>` | (required) | Segment titles |
| `selectedIndex` | `int` | `0` | Selected segment index |
| `onValueChanged` | `ValueChanged<int>?` | `null` | Segment change callback |
| `indicatorColor` | `Color?` | `null` = platform default | Selected segment tint (iOS: `selectedSegmentTintColor`; unset keeps Apple's white/grey thumb — Android keeps Material's secondary container) |
| `backgroundColor` | `Color?` | `null` | Control background |
| `labelFontStyle` | `TextStyle?` | `null` | Base label style: `color` → unselected text, `fontSize`/`fontWeight` → all segments |
| `selectedLabelFontStyle` | `TextStyle?` | `null` | Selected label style: `color` → selected text, `fontSize`/`fontWeight` override |

### Overlays & dialogs

| Widget / API | Status | Notes |
|---|---|---|
| `FloatingActionButton` | ✅ | Circular `UIButton` (iOS) — `child` font glyph rendered directly on both platforms |
| `BottomSheet` / `showModalBottomSheet` | ✅ | Content-sized bottom sheet hosting a native widget tree: the system sheet on iOS 16 and later, floating in from the edges on iOS 26, and Material's `BottomSheetDialog` on Android, with the dim, tap-outside and drag dismiss of each. Rides the keyboard natively: the card stays glued above it through open/close and rotation, and its height caps to the available space (content clips rather than pushing off-screen) A `PopScope` inside works as it does on a screen: `canPop: false` keeps it up against the swipe, the scrim tap and the system back, and `onPopInvokedWithResult` hears every attempt and every close, with the result passed to `Navigator.pop`, before the Future completes. |
| `showModalSheet` / `SheetDetent` / `SheetHeader` | ✅ | Native detent sheet — `UISheetPresentationController` (iOS 15+): `medium`/`large`/`adaptive`/`fitContent`, native spring physics, swipe-to-dismiss, the grabber on `showDragHandle: true`. `fitContent` sizes to the measured content height, floating in from the edges on iOS 26 as the platform's partial sheets do (iOS 15 presents it as a bottom overlay). On Android every detent is Material's modal bottom sheet: `fitContent` sized to its content, `medium`/`adaptive` resting at half height (adaptive drags to full), `large` at full height below the status bar, the content laid out at the sheet's height. A `SheetHeader` lowers by default to real bar items on the sheet's own navigation bar (`systemBar: false` composes glass buttons instead): centred title, system close, up to two trailing actions. Adjacent actions share one Liquid Glass capsule; a `SizedBox(width:)` between them splits them, as in `AppBar.actions`. `SheetHeaderController.update` re-declares a live header as sheet state changes. It works the same whether the header sits on the sheet's own bar or is drawn by the framework, which is what Android and `fitContent` sheets on iOS 15 get. Content is padded below the bar automatically. Without `systemBar` the header renders as composed glass buttons. A `PopScope` inside works as it does on a screen: `canPop: false` keeps it up against the swipe, the scrim tap and the system back, and `onPopInvokedWithResult` hears every attempt and every close, with the result passed to `Navigator.pop`, before the Future completes. |
| `Dialog` / `AlertDialog` | ✅ | Imperative `showAlert()` → `UIAlertController` |
| `showKeyboardOverlay` | ✅ | A full-screen transparent surface that draws over the keyboard, where a normal overlay stops at its top edge. What you put inside is ordinary layout: position, corners, animation, tap-outside-to-dismiss. Touches that miss your views pass through to the keyboard. `Navigator.pop` closes it. Measure any geometry in the screen that opens the overlay, not inside it: the overlay's tree is in another window and does not know the app's keyboard inset. iOS puts the surface in the keyboard's own window; Android adds it to the `WindowManager`, above the app's windows. |

### Screen transitions

Pass a `RouteTransition` to `PageRoute` to control how screens enter and exit:

```dart
Navigator.push(context, PageRoute(
  builder: (_) => const SettingsScreen(),
  transition: RouteTransition.slideFromBottom,
  duration: const Duration(milliseconds: 400), // optional, default 350ms
));
```

| Constant | Description |
|---|---|
| `RouteTransition.slideFromRight` | Standard iOS push via `UINavigationController` (default) |
| `RouteTransition.slideFromBottom` | Modal / sheet-style |
| `RouteTransition.slideFromLeft` | Reverse push |
| `RouteTransition.slideFromTop` | From top |
| `RouteTransition.fade` | Cross-fade |
| `RouteTransition.none` | Instant |

Pop automatically reverses the transition used during push.

### Back button behaviour (`AppBar`, `BackButton`)

When a screen is pushed via `Navigator.push`, dartnative can show a leading
back-chevron button in the `AppBar` automatically. The logic is:

| Condition | Behaviour |
|---|---|
| `BackButton(...)` passed as `AppBar.leading` | The custom `BackButton` is shown with your icon, size, weight, colour, padding, and `onTap`. |
| **Any other widget** passed as `AppBar.leading` (e.g. a `Button`) | The widget is hosted in the native **left** bar slot and **replaces** the auto-implied back button. A leading `Button` renders as the same Liquid Glass control as a top-bar action/home capsule. On iOS a screen whose bar has such a leading has no back button, and iOS then refuses the edge swipe back on that screen; this is how any iOS app behaves with a custom left bar item, and on iOS 26.2 and 26.3 the refusal holds even though the screen can still pop from your widget. Keep the back button (a `BackButton`, or no `leading`) on screens that should swipe back. |
| `automaticallyImplyLeading: true` (default) **and** the screen can pop **and** no `leading` supplied | The default chevron-left back button appears with no extra code. |
| `automaticallyImplyLeading: false` **or** the screen cannot pop | No back button is shown (unless an explicit `leading` is provided). |

The `BackButton` widget accepts all optional properties — unset values fall back
to the platform defaults:

| Property | Type | Default | Description |
|---|---|---|---------|
| `icon` | `String?` | `chevron.left` | SF Symbol name for the button image |
| `iconSize` | `double?` | `17` | Point size of the icon |
| `iconWeight` | `FontWeight?` | `FontWeight.semiBold` | SF Symbol weight |
| `iconColor` | `Color?` | System accent blue | Tint colour of the icon |
| `title` | `String?` | `null` (icon-only) | Text shown next to the icon, e.g. `"Back"` |
| `titleStyle` | `TextStyle?` | Platform default | Style for the title text (color, fontSize, fontWeight) |
| `onTap` | `VoidCallback?` | Route's pop handler | Custom callback — when provided it **replaces** the default `Navigator.pop` |
| `padding` | `EdgeInsetsDirectional?` | Platform convention | Padding around the back item (RTL-aware). `null` → Android `start: 11, end: 4` (matched against native bars); iOS system placement. Non-null **fully overrides** on Android and offsets from the system placement on iOS. Vertical values nudge within the bar's fixed height. |
| `tint` | `Color?` | `null` (untinted) | **iOS 26:** tints the glass capsule (`baseBackgroundColor`). |
| `glassVariant` | `ButtonVariant?` | `.glass()` | **iOS 26:** which `UIButton.Configuration` glass config the capsule uses — `ButtonVariant.glass` (default) / `clearGlass` / `prominentGlass` / `prominentClearGlass`. |

On **iOS 26** the back chevron is **always** wrapped in a **Liquid Glass**
capsule — rendered as a custom `UIButton.Configuration` glass button. You can't
turn the glass *off*, but you choose its **style** with `glassVariant`
(`glass` / `clearGlass` / `prominentGlass` / `prominentClearGlass`) and tint it
with `tint`. The title and actions ARE
controllable: `AppBar.titleGlassBackground` (default `false`) and
`AppBar.actionsGlassBackground` (default `true`); the title capsule is
available on the system bar as well (see "A title in a capsule" under
[Morphing bar buttons](#morphing-bar-buttons-ios-26-appbarios)). The capsules only
render as real glass when the bar uses the iOS 26 glass material — opt in with a
**translucent** `AppBar.backgroundColor` (e.g. `myColor.withOpacity(0.5)`); an
opaque (especially light) colour makes them a flat white fill. Colour the page
via `Scaffold.backgroundColor` and let the glass bar refract it.

**`AppBar.brightness` (`Brightness?`)** forces the bar's glass **tone** instead of
the automatic luminance pick. `null` (default) keeps the auto behavior (opaque dark
bar → dark glass; see-through → device theme). `Brightness.light` / `.dark` pin it
— use it when your app uses its *own* theme independent of the device light/dark
mode (e.g. a coloured theme that should always wear the light glass; a saturated
mid-luminance bar colour like fuchsia/green otherwise flips to dark glass).

```dart
// Default auto-back — no code needed
AppBar(title: Text('Detail'))

// Custom back-button appearance
AppBar(
  leading: BackButton(
    title: 'Back',
    iconColor: Colors.white,
  ),
  title: Text('Chat'),
)

// Custom back-button inset (e.g. deeper start padding)
AppBar(
  leading: BackButton(
    title: 'Back',
    padding: EdgeInsetsDirectional.only(start: 24, end: 4),
  ),
  title: Text('Chat'),
)

// Custom action instead of pop (e.g. confirm-before-leave)
AppBar(
  leading: BackButton(
    onTap: () => _showExitDialog(),
  ),
  title: Text('Editor'),
)

// No back button at all
AppBar(
  automaticallyImplyLeading: false,
  title: Text('Home'),
)

// A custom leading control that is NOT a back button (replaces the auto back
// button). A leading Button renders identically to a top-bar action/home capsule.
AppBar(
  leading: Button(
    icon: 'line.3.horizontal',
    variant: ButtonVariant.glass,
    onPressed: _openDrawer,
  ),
  title: Text('Home'),
)
```

> **`AppBar.leading` accepts any widget.** A `BackButton` is the **semantic back
> preset** (chevron + optional "Back" title + auto-show when the route can pop +
> the iOS-26 long-press morph) and keeps its own native path. **Any other** widget
> is hosted in the native left slot and replaces the auto-implied back button —
> use a leading `Button` when you want a left control that's visually identical to
> a home/action capsule (no "Back" text, no morph). `BackButton` used *outside* an
> `AppBar` is still silently ignored.

### Large title & the see-through bar (iOS 26)

**`AppBar.largeTitle`** gives you the Apple large-title pattern: a large
title rendered under the bar that collapses into the normal bar title as you
scroll — driven **natively** by your list's scroll position, with no Dart
work per frame. While the large title is visible the bar title is hidden;
as it collapses, the bar title fades in (one title, two representations —
never both, exactly like the system).

**On Android the same field is the M3 collapsing top app bar**: the large
title renders in a surface-colored band under the toolbar and collapses
with your scroll — band slides under the bar and fades while the bar title
fades in, reversal tracking your finger, and a gesture that settles
mid-collapse **snaps** to the nearest edge. One field, both design
languages. (On iOS < 26 the large title renders as a static header above
the body.)

Pick the Material size with **`AppBar.largeTitleSize`** — Google's two
current ("flexible") collapsing variants:

- `MaterialAppBarSize.medium` (default) — 112dp expanded container; pair
  with a ~28sp regular title for the native type scale.
- `MaterialAppBarSize.large` — 120dp expanded container; ~36sp regular.

Give your scrolling content top clearance matching the container (plus the
status inset). iOS ignores the field — the system large-title metrics
always apply there.

**`AppBar.subtitle`** adds a secondary line under the title (e.g. an
"online" presence line) — style it yourself with a smaller/secondary
`TextStyle`. With `largeTitle` also set, Android renders the subtitle in
the expanded band under the headline (the M3 with-subtitle containers:
136dp medium / 152dp large — clear that much instead), collapsing into the
bar's composed title+subtitle block.

The large title pairs naturally with the **see-through bar** — the
much-requested look where your content stays visible scrolling beneath a
fully transparent bar, kept readable by iOS 26's progressive blur ramp
(the *scroll-edge effect*, which the framework attaches for you). The whole
recipe is three choices, all defaults:

```dart
Scaffold(
  extendBodyBehindAppBar: true,        // 1. content runs under the bar
  appBar: AppBar(
    title: Text('Chats'),              //    fades in as the large title collapses
    largeTitle: Text(
      'Chats',
      style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
    ),
    // 2. NO backgroundColor → a fully clear bar surface.
    //    (A translucent colour gives the frosted bar instead — content only
    //    faintly visible. An opaque colour hides it completely.)
  ),
  body: ListView(
    // 3. clear the bar + large-title band at the top, then scroll under it
    padding: EdgeInsets.only(
      top: MediaQuery.paddingOf(context).top + 108,
    ),
    children: [...],
  ),
)
```

On iOS 26 this renders the full native behavior: the large title slides up
under the bar and fades as you scroll (tracking the finger, flings, and the
pull-down stretch), the bar title fades in, and rows passing beneath the
clear bar get the system blur/fade ramp. On Android the same code drives
the M3 collapsing band; with no color the Android bar takes the screen's
color, and a title with no color of its own turns white or black to stay
readable. On iOS < 26 the `largeTitle` renders as a plain header above
your body and the bar title stays always visible — same API, graceful
fallback.

The two numbers in the padding: on iOS, `MediaQuery.paddingOf(context).top`
is the status bar's inset (62 points on an iPhone with the Dynamic Island),
and 108 is the bar plus the large-title band. Together they put the first
row where a SwiftUI large-title screen puts it. Text on iOS keeps its point
size under Dynamic Type, the large title included, so the same clearance
holds at every text size.

### The frosted (opaque glass) bar vs the see-through bar

Two popular looks, one knob — `AppBar.backgroundColor` — and they are
**different designs**, so pick by intent:

- **Frosted / opaque glass** — the bar is a real glass *surface*: blurred
  material + your colour as tint, with the UI beneath only *slightly*
  visible through it (the WhatsApp-style bar). Opt in with a
  **translucent** colour; the alpha is the opacity knob:

  ```dart
  Scaffold(
    extendBodyBehindAppBar: true,     // content runs under the frost
    appBar: AppBar(
      title: Text('Lisa'),
      subtitle: Text('Online'),
      backgroundColor: Color(0xD91C1C1E),   // alpha < 1 → native frost
    ),
    body: ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 66,
      ),
      children: [...],
    ),
  )
  ```

- **See-through** — the bar has *no* surface at all: content stays fully
  visible scrolling beneath, and iOS 26's scroll-edge blur ramp provides
  the legibility. Opt in by setting **no `backgroundColor`** — the full
  recipe is in [Large title & the see-through bar](#large-title--the-see-through-bar-ios-26)
  above (it pairs naturally with `largeTitle`, but works with any bar).

Don't combine the two expectations: a translucent colour gives you the
frost (no crisp content, no need for the ramp); no colour gives you the
clear bar + ramp. An opaque colour is the third option — a solid bar that
fully hides what passes beneath.

### Right bar buttons (`AppBar.actions`)

`AppBar.actions` accepts **any widget** — each is inflated and installed as a
custom native bar item. A widget's text renders in the bar button's default
(`barButtonTextStyle`: the size, weight and colour the platform gives its own
bar buttons) unless
the widget styles it, so a plain `Text` reads as a bar button; the same holds
for `leading`. For a text action, use **`BarButtonItem`**: on
**iOS 26** it renders inside the system Liquid Glass capsule (via the default
`actionsGlassBackground`) with the native interactive press response, like a
native `UIBarButtonItem`; on iOS < 26 / Android it's a plain text action.
`titleStyle` is merged over `barButtonTextStyle`, so passing only a color
keeps the native size:

```dart
AppBar(
  title: Text('Report Bug'),
  actions: [
    BarButtonItem(
      title: 'Send',
      titleStyle: const TextStyle(color: Colors.white), // optional
      onPressed: _send,
    ),
  ],
)
```

**Custom action widgets — no padding needed.** The bar provides the spacing
natively on every OS: the iOS 26 glass capsule grows ~12pt around text-like
content (taps on the capsule ring count as taps on your widget), pre-26 iOS
uses UIKit's bar-item margins, Android its own bar metrics. A hand-rolled
action is just the tappable content:

```dart
GestureDetector(
  onTap: _send,
  behavior: HitTestBehavior.opaque,
  child: const Text('Send', style: TextStyle(color: Colors.blue, fontSize: 17)),
)
```

If you *do* wrap your action in `Padding`, it simply adds to the native
default — the capsule grows around the bigger widget. Square (icon/avatar)
content is left unpadded so the 44×44 capsule stays a circle; self-decorated
widgets can drop the capsule with `actionsGlassBackground: false`.

**Spacing between actions** is also bar-owned: 10pt between capsules on
iOS 26, UIKit's system item spacing pre-26, 8dp on Android. To widen a
specific pair, drop a **`SizedBox(width: N)` between them** — an invisible
fixed-width slot (never gets a capsule), so you add space without padding
any button:

```dart
actions: [
  BarButtonItem(fontIcon: CupertinoIcons.phone, onPressed: _call),
  const SizedBox(width: 5), // widen just this pair
  BarButtonItem(fontIcon: CupertinoIcons.videocam, onPressed: _video),
  BarButtonItem(title: 'Mute', onPressed: _mute),
]
```

Multiple actions are supported — list them **leading→trailing** (the last
entry lands rightmost, matching Flutter). On iOS 26 each action gets its own
Liquid Glass capsule stacked from the trailing edge, with the system's
interactive glass press response on tap; pre-26 iOS and Android stack plain
items the same way. Actions can be added/removed live from
`setState`. The bar title behaves like a native one: it compresses, shifts
and tail-truncates automatically in whatever space the actions leave (keep
titles short, per Apple's guidance — there is no alignment flag on iOS). Two notes for multi-action bars: a `Badge` wrapper renders its
own composed badge (the native capsule badge applies to single-action bars),
and `BarButtonItem.menu` requires being the only action.

#### Native menus on a bar action (`BarButtonItem.menu`)

Give a `BarButtonItem` a `menu` instead of `onPressed` and tapping it shows
a **native anchored menu**: on iOS 26 the glass capsule *morphs* into a
`UIMenu` (the WhatsApp ⋯ behavior); pre-26 iOS shows a plain native menu
button; Android anchors a Material `PopupMenu` to the action (its light/dark
tone follows your bar colour). Item callbacks are plain Dart closures and
stay fresh across rebuilds:

```dart
AppBar(
  actions: [
    BarButtonItem(
      icon: 'ellipsis',        // SF Symbol → ⋯ on iOS; Android shows its ⋮
      menu: [
        MenuAction(
          title: 'Select chats',
          icon: Platform.isAndroid
              ? MaterialSymbolsRounded.check_circle
              : CupertinoIcons.checkmark_circle,
          onTap: _selectChats,
        ),
        MenuAction(
          title: 'Delete',
          icon: CupertinoIcons.trash,
          destructive: true,   // red, on both platforms
          onTap: _delete,
        ),
      ],
    ),
  ],
)
```

**Icons, one model everywhere:**

- `MenuAction.icon` takes any **`IconData`** — `MaterialSymbolsRounded.*`,
  `CupertinoIcons.*`, or your own registered icon font (font glyphs are the
  supported custom-icon mechanism). Rendered natively next to the item on
  both platforms.
- The **button** itself: `icon` (an SF Symbol *name* — iOS-only, the premium
  native look), `fontIcon` (any `IconData`, renders on both platforms), or
  `title` text. **Set `icon` + `fontIcon` together for per-platform
  control**: iOS uses the SF Symbol, Android the font glyph. With a `menu`
  and none of these, Android shows its standard ⋮ overflow glyph
  automatically.
- Need something the presets can't express? Pass **any widget** in
  `actions:` / `leading:` — e.g. a custom back button is just
  `leading: GestureDetector(onTap: () => Navigator.pop(context),
  child: Icon(MyIcons.back))`, hosted in the native slot with the same
  Liquid Glass treatment.

#### `AppBar.actionsPadding`

Row-level padding for the **whole trailing actions group** (Flutter's field
name). `EdgeInsetsDirectional?`, RTL-aware. `null` (default) → platform
placement (Android: 16dp end inset; iOS: system bar-item margins). Non-null is
a full override:

```dart
AppBar(
  title: Text('Chat'),
  actionsPadding: EdgeInsetsDirectional.only(end: 24, top: 2),
  actions: [
    GestureDetector(onTap: _edit, child: const Text('Edit')),
  ],
)
```

#### `AppBar.centerTitle`

Where the title sits in the bar (Flutter's field name).
`bool?`. `null` (default) → each platform's own convention, matching
Flutter's fallback: **iOS centers** the title while there are fewer than two
`actions`; **Android** places it flush after the nav icon. Explicit
`true`/`false` forces the placement on both platforms:

```dart
AppBar(
  centerTitle: false, // chat-style: avatar + name hug the back button
  title: Row(mainAxisSize: MainAxisSize.min, children: [avatar, name]),
)
```

On Android the rule covers a plain `Text` title too: with no
`centerTitle` it starts where Material's top app bar puts it, 16dp from the
edge or 4dp after the navigation icon, and `centerTitle: true` centers it.
On iOS a plain `Text` title uses the system's title rendering, which UIKit
places itself.

#### `AppBar.titleSpacing`

The gap on the **leading side** of a custom-widget title, in points
(Flutter's field name). `double?`. `null` (default) → each platform keeps its
own spacing, exactly as before the knob existed: iOS 26 uses the bar's
standard 10pt hop after the leading/back item (15pt from the edge with
neither); Android places the title flush after the nav icon (12dp edge inset
with none). Set it to control that gap precisely:

```dart
AppBar(
  centerTitle: false,
  titleSpacing: 4, // logo sits 4pt after the leading menu button
  leading: menuButton,
  title: logo,
)
```

> **Note:** ignored on iOS 18 and older. Apple's bar places the title there
> and enforces its own minimum spacing between bar items, so the value can't
> be honored. On iOS 26 and Android the framework places the title itself,
> so it can.

Plain `Text` titles always use the native title rendering and ignore it.

#### Morphing bar buttons (iOS 26, `AppBar.ios`)

On iOS 26, a bar built from native features (a title and subtitle, text
or widget, actions, a bar colour or none) is hosted on the **system
navigation bar** — its actions are real system bar buttons — and bar
buttons **morph between screens** on push/pop: buttons that persist
glide to their new place, related ones blur-merge into a single capsule,
and the rest dissolve. The transition is the system's own and matches
buttons automatically; popping plays it in reverse. A bar that uses
something the system bar has no place for (a badge on an action, a menu
button, search, a large title, `brightness`, `titleSpacing`,
`actionsPadding`, `toolbarHeight`) is hosted on the standard per-screen
bar instead, and so is a screen whose `Scaffold` has a `drawer` or sets
`extendBodyBehindAppBar`: the system bar stays put while a drawer slides
the screen aside, and it does not let the body run underneath it.

The two hosts serve different intents: the system bar is the one to use,
morphing included, and the standard bar carries the few features above
for the screen that needs one of them.

`AppBar(ios: AppBarIOSConfig(systemBar: true/false))` selects the host
explicitly. Asking for the system bar with a feature it cannot express
keeps the screen on the standard bar, and the console says which feature,
once per screen. A bar's host is fixed for the screen's lifetime, so a bar
whose feature set changes across rebuilds should pin it (`false` keeps
the screen on the standard bar); a rebuild that would change the host is
reported on the console and the host stays.

On a system-hosted bar:

- every action becomes a bar item: a `BarButtonItem` with an SF-symbol
  `icon` or a `title` is the platform's own bar button (a text one is
  styled by `titleStyle` when you set one and by the system otherwise),
  a `SizedBox(width:)` splits capsules, and any other widget rides in its
  own capsule as a custom view, resizing with its content; a widget in
  `leading` does the same on the left and takes the place of the back
  button; `actionsGlassBackground: false` removes the capsules;
- **adjacent actions share one glass capsule** (the system default) — a
  `SizedBox(width: 8)` between actions splits them into separate capsules;
- `BarButtonItem(prominent: true)` renders the **filled, tinted capsule**
  (the bar's primary action; tint from `titleStyle.color`);
- any title: a plain `Text` is the bar's own title, with its own colour,
  size and weight if you style it, and a widget title
  (an avatar beside a name and a status line, say) rides in the bar's
  title slot, centred, or at its start with `centerTitle: false`, the
  chat screen shape;
- `backgroundColor` works as on any bar: none is the clear bar, a
  translucent colour the frosted bar, a solid colour the opaque bar, and
  the buttons keep their capsules and morph on each; the other bar
  styling fields (`brightness`, `titleSpacing`, `actionsPadding`,
  `toolbarHeight`) keep a screen on the standard bar.

**A title in a capsule.** The system draws a bare title. Set
`titleGlassBackground: true` and the title, with its subtitle, sits in a
glass capsule of its own, in the same fonts the bar gives a bare title;
the buttons keep morphing.

```dart
AppBar(
  title: const Text('Today'),
  subtitle: const Text('15:10'),
  titleGlassBackground: true,
  actions: [BarButtonItem(icon: 'ellipsis', onPressed: _more)],
)
```

```dart
// Screen A — camera and a green ⊕ in separate capsules.
AppBar(
  title: const Text('Chats'),
  actions: [
    BarButtonItem(icon: 'camera.fill', onPressed: _camera),
    const SizedBox(width: 8),
    BarButtonItem(
      icon: 'plus',
      prominent: true,
      titleStyle: const TextStyle(color: Color(0xFF30D158)),
      onPressed: _compose,
    ),
  ],
)

// Screen B — one shared capsule; pushing A → B merges camera+⊕ into it.
AppBar(
  title: const Text('Saved Messages'),
  subtitle: const Text('You'),
  actions: [
    BarButtonItem(icon: 'video.fill', onPressed: _call),
    BarButtonItem(icon: 'chevron.down', onPressed: _callOptions),
  ],
)
```

iOS 18 and older and Android always use their regular bar — no morph.
Demo: playground → Liquid Glass → Morphing Buttons.

### Custom widgets in `AppBar.title` and `AppBar.actions`

Both slots accept **any widget tree**, not just `Text`. Use this when you need an avatar + name + status row in the title, or a non-text trailing action.

| Slot | Where it renders | How it sizes |
|---|---|---|
| `title` | Immediately after the back button (left-aligned on both iOS and Android — same look) | Intrinsic content size, capped at the **leftover width** between back button and actions (bar items always win — the UIKit/Toolbar rule) |
| `actions[last]` | Trailing edge with 16dp end-padding | Intrinsic content size |

- The framework adds **no leading padding** between the back button and the `title` widget — add your own `SizedBox(width: …)` at the start of the widget if you want more breathing room.
- **Crowded bars degrade gracefully on their own.** When actions crowd the bar, the title is re-laid at the leftover width (never overlapped), and content that still doesn't fit **fades out at the slot edge** — no requirements on your widget. Optionally, wrap the text part in `Flexible` with `maxLines: 1, overflow: TextOverflow.ellipsis` to get true truncation ("Li…") instead of the fade.
- Custom `actions` widgets need **no internal padding** — the bar provides the default spacing natively (the iOS 26 capsule grows around your widget; pre-26/Android use their own bar metrics). Wrapping in `Padding` still works and adds to the default. See [Right bar buttons](#right-bar-buttons-appbaractions).

```dart
AppBar(
  backgroundColor: Colors.black,
  title: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset('assets/avatar.jpg', width: 38, height: 38, fit: BoxFit.cover),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Text('Lisa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 4),
            Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.blue, size: 16),
          ]),
          Text('Online', style: TextStyle(color: Colors.green, fontSize: 12)),
        ],
      ),
    ],
  ),
  actions: [
    BarButtonItem(
      title: 'ScrollTo #2',
      titleStyle: const TextStyle(color: Colors.blue, fontSize: 17),
      onPressed: _scrollToTop,
    ),
  ],
)
```

For a classic blue system-style text button, use a `GestureDetector` wrapping a `Text` styled with the system blue (`Color(0xFF007AFF)`).

### Keyboard avoidance in `Scaffold`

`Scaffold` in dartnative handles keyboard avoidance without resizing the layout — different from Flutter's resize semantics. Here's what you need to know.

#### How it works

**Only the `bottomInputBar` rides the keyboard.** A `bottomNavigationBar` stays at the bottom and the keyboard covers it, the way a native tab bar does on both platforms and the way Flutter's `Scaffold` behaves too. Put a composer in `bottomInputBar` when it must stay above the keyboard.

**iOS.** The `bottomInputBar` and the body ride the keyboard's **own** animations — show, hide, and rotation — the way Apple Messages' input bar does. That makes the avoidance rotation-proof: iOS 26 dismisses and re-presents the keyboard around a rotation, and anything driven from keyboard notifications visibly drops and rises in that gap, while DartNative's views stay glued above the keyboard.

When the focused field is in the **body** (a form, not a chat), the body is lifted by exactly the amount the field is obscured, demand-driven — a field that already has clearance above the keyboard doesn't move at all, and the body's bottom edge never rises past the keyboard's top.

**Android** lifts the body the same demand-driven way.

**The gap above the keyboard differs by where the field lives, and this is
the current, deliberate behaviour.** A field inside a bottom bar rides the
keyboard directly: on iOS 26 the bar keeps a small distance above the
floating keyboard (4 points, which the bar's own padding adds to, so a
bar with 8 points of padding puts its field 12 above the keyboard as
Messages does), and elsewhere the only visible space is the bar's own
padding. A field in the body is lifted with a clearance the framework adds
(16 points on iOS, 8dp on Android), so it floats a little higher. Native
apps behave the same way: a chat input bar sits close to the keyboard
while a scrolled form field gets breathing room. If the two ever need to look the same on a
screen, the knob is that screen's bar padding, not the framework. Revisit
only if a real screen makes the difference look wrong.

```
┌──────────────────────┐      ┌──────────────────────┐
│      AppBar          │      │      AppBar          │  ← stays at top
├──────────────────────┤      ├──────────────────────┤
│                      │      │   body (lifted)      │  ← moves up
│       body           │  →   │                      │
│                      │      │  ┌────────────────┐  │
│                      │      │  │ bottomInputBar │  │  ← lifted by keyboard
├──────────────────────┤      │  └────────────────┘  │
│   bottomInputBar     │      └──────────────────────┘
└──────────────────────┘      ◄── keyboard ──────────►
```

The `AppBar` always stays at the top — it is never moved.

#### Why not resize (Flutter semantics)?

| Aspect | Keyboard-attached (dartnative) | Resize (Flutter) |
|---|---|---|
| **Animation curve** | ✅ **100% native** — the views ride the keyboard's own animation. | ❌ Would need custom Dart-driven animation that never fully matches the native curve. |
| **Performance** | ✅ **Almost free** — no layout pass on any keyboard frame. | ❌ Requires full Yoga re-layout + native `setFrame`/`layoutParams` on every keyboard animation frame. |
| **Content reflow** | ❌ No reflow — but not needed for lists / scroll views. The scroll view handles its own content. | ✅ Content reflows — helpful for text-heavy layouts. |
| **Rotation with keyboard open** | ✅ The views stay glued through the iOS 26 keyboard dismiss/re-present cycle. | ❌ Relayout races the keyboard's hide/show notifications. |

**The keyboard-attached approach was chosen because it provides native-quality keyboard animation at zero performance cost.** Most screens (`ListView`, `FastList`, `CustomScrollView`) don't need content reflow — the scroll view handles resizing its viewport naturally.

#### Required: use `appBar` and `bottomInputBar` fields

For keyboard avoidance to work correctly, you **must** use the dedicated `Scaffold` fields:

```dart
Scaffold(
  appBar: AppBar(title: const Text('Chat')),     // ✅ sticks at top
  body: _buildList(),                               // ✅ moves up when keyboard opens
  bottomInputBar: _BottomBar(...),                  // ✅ lifted by keyboard
)
```

❌ **Do not** embed the app bar or input bar inside `body`:
```dart
// Wrong — keyboard avoidance will not work
Scaffold(
  body: Column(children: [
    AppBar(title: const Text('Chat')),   // ❌ will move up with body
    _buildList(),
    _BottomBar(...),        // ❌ will be double-lifted
  ]),
)
```

**Why?** The `Scaffold` attaches exactly the `body` and `bottomInputBar` to the keyboard. Widgets inlined in `body` move with the body as a whole: an inlined app bar leaves the screen top, an inlined input bar gets the body's lift instead of its own.

#### `resizeToAvoidBottomInset`

`Scaffold` accepts `resizeToAvoidBottomInset` (default `true`). When set to `false`, the body does not move when the keyboard opens — use this for full-screen layouts that manage keyboard themselves (e.g. a camera preview).

## Controls

### Android extras — the `android:` setting

Some widgets take an optional `android:` setting, carrying options that only
exist on Android — Material offers dials iOS has no equivalent for. It adjusts
the control you already have; it never changes which control you get.

```dart
Slider(value: v, onChanged: f)                              // Material 3, as Google ships it
Slider(value: v, onChanged: f,
       android: const AndroidSliderStyle(trackHeight: 24))  // ...with a thicker track
```

Anything you leave out keeps Google's own value, and the setting is ignored on
iPhone — it never needs a platform check.

Takers: `Slider`, `Switch`, `LinearProgressIndicator`, `CircularProgressIndicator`.

#### Why is there no `ios:`?

Apple exposes almost nothing to configure — a `UISwitch` gives you its state and
two colours, which the ordinary parameters already cover. Material is a styling
system: its slider alone has around twenty settings. Those need somewhere to
live, and that is `android:`.

If Apple ever exposes something with no Android equivalent, it gets an `ios:`
setting in the same shape, named after the feature rather than the iOS version.

| Widget | Status | Notes |
|---|---|---|
| `ElevatedButton` | ✅ | `flutter_compat` wrapper over `Button(variant: ButtonVariant.filled, elevation: 2)` |
| `TextButton` | ✅ | `flutter_compat` wrapper over `Button(variant: ButtonVariant.plain)` |
| `OutlinedButton` | ✅ | `flutter_compat` wrapper over `Button(variant: ButtonVariant.bordered)` |
| `FilledButton` / `FilledButton.tonal` | ✅ | `flutter_compat` wrappers over `Button(variant: ButtonVariant.filled/tinted)` |
| `IconButton` | ✅ | 48×48 minimum hit target (Flutter `kMinInteractiveDimension` parity) |
| `NativeButton` | ✅ | `UIButton.Configuration` — filled, tinted, gray, bordered, plain. For new DN code, prefer `Button` directly. |
| `GestureDetector` | ✅ | The full gesture surface, all wired to native recognizers: taps (`onTap`, `onDoubleTap`, `onLongPress`, `onTapDown`, `onTapUp`, `onTapCancel`), pan (`onPanStart/Update/End`), axis-locked drags (`onHorizontalDragStart/Update/End`, `onVerticalDragStart/Update/End`) and pinch (`onScaleStart/Update/End` — focal point and scale factor; the end velocity is `0.0` on Android, which doesn't expose pinch velocity). Drag and tap details carry both `globalPosition` and `localPosition`, so scrubbers, trim handles and pinch-zoom UIs are all buildable in Dart. `HitTestBehavior.translucent` fires the view's own callback **and** forwards the tap to overlapping siblings drawn beneath it whose bounds contain the touch point |
| `Listener` | ✅ | Raw pointer events |
| `InkWell` | ✅ | `UIButton`-style press highlight |
| `Checkbox` | ✅ | `UIButton` + SF Symbols; tristate supported |
| `DropdownButton` | ✅ | The platform's own picker for one of a few values, in place: on iPhone a button showing the current item that opens the system menu anchored to it, the current item checked; on Android Material's exposed dropdown menu. `value`, `items` (`DropdownMenuItem(value:, child: Text(...))`), `onChanged`, `hint`, `isExpanded`, `style`. It keeps showing `value` until a rebuild changes it, as in Flutter. |
| `Radio<T>` | ✅ | `UIButton` + SF Symbols on iPhone, Material 3's radio button on Android — matching the checkbox beside it |
| `Switch` / `CupertinoSwitch` | ✅ | `UISwitch` on iPhone, Google's Material 3 switch on Android — nothing to turn on. The four colour parameters work on both. `android: AndroidSwitchStyle(checkIcon: true)` adds the tick mark inside the knob |
| `Slider` / `CupertinoSlider` | ✅ | `UISlider` on iPhone, Google's Material 3 slider on Android — a slim upright handle with a gap either side and a dot at the end. Size it with `android: AndroidSliderStyle(...)`: `trackHeight`, `thumbWidth`, `thumbHeight`, `thumbTrackGap`, `stopIndicatorSize`, `trackCornerSize` (all in dp; set the last three to 0 for a plain bar). Colors resolve Flutter's way: the widget's `activeColor`/`inactiveColor`/`thumbColor` win, else the ambient `SliderTheme(data: SliderThemeData(...))` supplies `activeTrackColor`/`inactiveTrackColor`/`thumbColor` (reactive — sliders restyle when the theme changes). Slider geometry stays native: `SliderThemeData`'s shape classes compile for source compatibility but the track and thumb shapes are the platform's own (`android:` is the geometry knob) |
| `CircularProgressIndicator` | ✅ | `UIActivityIndicatorView` on iPhone. On Android, `android: AndroidProgressIndicatorStyle(wavy: true)` gives Google's wavy spinner Without a colour it is the system's grey spinner. |
| `LinearProgressIndicator` | ✅ | `UIProgressView` on iPhone, Google's Material 3 bar on Android (rounded ends, a gap before the dot at the end). `value` 0.0–1.0, or `null` while you don't know how long it takes; `android: AndroidProgressIndicatorStyle(wavy: true)` for the wave Without colours it is the system's blue bar on the system's grey track. |
| `Dismissible` | ❌ | Not available |

---

## Platform Services

| API | Status | Notes |
|---|---|---|
| `SystemChrome.setPreferredOrientations` | ✅ | Per-screen orientation lock. Lock in `initState()`, unlock in `dispose()`. |
| `SystemChrome.setSystemUIOverlayStyle` | ✅ | Status bar text: `SystemUiOverlayStyle.light` (white) or `.dark` (dark). |
| `SystemChrome.defaultStyle` | ✅ | App-level default chrome (assign once in `main()`): every pushed screen starts from it; a screen overrides via `setSystemUIOverlayStyle` in `initState`, and the Navigator restores the previous style automatically when the screen pops — no dispose cleanup needed. |
| `SystemChrome.setEnabledSystemUIMode` | ✅ | Status bar visibility: `.edgeToEdge` (visible), `.immersive` (hidden), `.immersiveSticky` (swipe to reveal). |
| `Clipboard` | ✅ | Flutter's call shapes: `Clipboard.setData(ClipboardData(text: ...))` writes, `Clipboard.getData(Clipboard.kTextPlain)` reads (returns `null` when the clipboard holds no text; plain text is the only format). On iPhone, reading the clipboard from code makes the system show the user a short notice — for example "YourApp pasted from Safari" — and it may first ask their permission; the clipboard can hold private data like passwords, so no app can read it silently. Read when the user asked to paste, not in the background. |
| `DynamicColor` (Material You) | ✅ | `DynamicColor.colorScheme(brightness:)` builds the M3 `ColorScheme` from the device's wallpaper-derived palette (Android 12+); `DynamicColor.corePalette()` exposes the raw five tonal palettes. Returns `null` where there's no device palette (iOS, Android < 12) — theme from your own seed: `scheme ?? fallback`. |
| `SearchBar` | ✅ Android · iOS | The M3 search app bar: the docked search pill expands into the native full-screen search surface (the system morph, back and keyboard handling are the platform's own). `hintText` (per the M3 spec, always include the word "Search" — plain or scoped like "Search inbox"), `onChanged` streams the query as the user types, `onSubmitted` fires on the search action, `onClosed` fires when the user leaves search with the platform's own control (Cancel on iOS, the back arrow on Android) so a "search is open" flag in your state can follow it, and `suggestions` is your own widget tree rendered live inside the expanded surface. The field's clear control is a text change: the query became empty, so `onChanged` reports an empty string. `backgroundColor` recolors the search field itself (defaults to the neutral field grey, the same on both platforms), and `surfaceColor` the active search surface — on Android the expanded search screen (defaults to the screen background), on iOS the suggestions overlay shown while searching. Place it in the body for in-content search, or pass it to **`AppBar.searchBar`** to make the bar region itself the search pill — alone (the home-page look) or between `leading` and `actions` (the Gmail look); expanding covers the whole bar and restores it on collapse automatically, and the bar's `title` steps aside while the pill is present and returns when you remove it. On iOS the same widget is a real `UISearchBar` and search happens in place — the App Store pattern: the field stays where it is (in the bar with `AppBar.searchBar`, between the back button and your actions), Cancel appears beside it, the rest of the bar steps aside so the field takes the full width, and your `suggestions` tree overlays the content while typing — Cancel puts everything back, animated. One widget, both platforms' native search. |
| `SystemChrome.setStatusBarColor` | ✅ | Status bar background color. Pass a `Color` or `null` to remove the overlay. |
| `SystemChrome.setNavigationBarColor` | ✅ | Bottom safe-area background color. Pass a `Color` or `null` to remove the overlay. |
| `WidgetsBinding.instance.addPostFrameCallback` | ✅ | Fires callback as a microtask after the current Dart turn. |
| `DartNativePerformance.addFrameTimingCallback` | ✅ | Per-frame timing from the display. Import from `dartnative`. |
| `getApplicationDocumentsDirectory()` | ✅ | Synchronous `String`; replaces `path_provider`. Import from `dartnative_path_provider`. |

---

## System UI

| Widget / API | Status | Notes |
|---|---|---|
| `showAlert()` | ✅ | `UIAlertController`; on a screen with a forced `brightness` the alert takes it too |
| `showActionSheet()` | ✅ | iOS: `UIAlertController` action sheet. Android: `ModalBottomSheet` — opens a `showModalBottomSheet` panel with rounded corners and dim background. |
| `showModalSheet()` | ✅ | Native detent sheet (`UISheetPresentationController`, iOS 15+): `SheetDetent.medium`/`large`/`adaptive`/`fitContent`, native spring physics, swipe-to-dismiss, the grabber on `showDragHandle: true`. `fitContent` sizes to the measured content height, floating in from the edges on iOS 26 as the platform's partial sheets do (iOS 15 presents it as a bottom overlay). Returns `Future<T?>` resolved by `Navigator.pop(context, value)`. On Android, `fitContent` lowers to the modal bottom sheet; the other detents no-op (use `showModalBottomSheet` for those). An optional `SheetHeader` declares the header; by default it lowers to real bar items on the sheet's own navigation bar, and adjacent trailing actions share one Liquid Glass capsule. A `PopScope` inside works as it does on a screen: `canPop: false` keeps it up against the swipe, the scrim tap and the system back, and `onPopInvokedWithResult` hears every attempt and every close, with the result passed to `Navigator.pop`, before the Future completes. |
| `showModalBottomSheet()` | ✅ | Content-sized bottom sheet with a dim background and dismiss-on-tap outside: the system sheet on iOS 16 and later, floating in from the edges on iOS 26, and Material's bottom sheet on Android; `showDragHandle: true` adds the drag handle (off by default, as the platform's own sheet). Without a colour it wears the system's sheet material on iOS and Material's sheet surface on Android; the dim is the platform's own, and `dimOpacity` changes it where the framework draws it, on Android and iOS 15. The parent screen stays visible behind the dim on both platforms. A `PopScope` inside works as it does on a screen: `canPop: false` keeps it up against the swipe, the scrim tap and the system back, and `onPopInvokedWithResult` hears every attempt and every close, with the result passed to `Navigator.pop`, before the Future completes. |
| `showDialog()` | ✅ | **Centered** modal dialog hosting a full dartnative widget tree (the centered sibling of `showModalBottomSheet`). For **custom** dialogs — styled inputs, forms, branded layout. `showAlert()` is for plain title/message/buttons only. On iOS the card is the alert's own look when no colour is set: Liquid Glass on iOS 26, the system material before, 320pt wide with the alert's rounded corners; `ios: DialogIOSConfig(glass: false)` gives a solid card in the platform's dialog colour, and `backgroundColor` a solid card in yours. On Android it is Material's dialog surface. A `PopScope` inside works as it does on a screen: `canPop: false` keeps it up against the swipe, the scrim tap and the system back, and `onPopInvokedWithResult` hears every attempt and every close, with the result passed to `Navigator.pop`, before the Future completes. |
| `showDatePicker()` | ✅ | `UIDatePicker` in a sheet sized to the picker; date, time, dateAndTime, countDown. `confirmText` labels the confirm control; unset, each platform shows its own (the checkmark capsule on iOS 26, "Done" on earlier iOS, "OK" on Android) |
| `showMediaPicker()` | ✅ | Replaces `image_picker` plugin. `PHPickerViewController` (iOS 14+) / `UIImagePickerController` fallback; images, videos, multi-select. Returns `Future<List<MediaFile>>`. No extra package. |

### `showMediaPicker` — replacing `image_picker`

dartnative ships a native media picker built-in. Remove the `image_picker` pub.dev package and use `showMediaPicker` instead — it is part of `dartnative.dart`, no extra dependency.

```dart
// ✗ Flutter — remove from pubspec and delete this import
import 'package:image_picker/image_picker.dart';

// ✓ dartnative — already imported
import 'package:dartnative/dartnative.dart';

// Single image
final files = await showMediaPicker(context: context);
if (files.isNotEmpty) print(files.first.path);

// Multi-image (unlimited)
final files = await showMediaPicker(
  context,
  type: MediaPickerType.images,
  maxSelection: 0,   // 0 = no limit
);

// Video
final files = await showMediaPicker(
  context,
  type: MediaPickerType.videos,
);
```

| Flutter `image_picker` | dartnative |
|---|---|
| `ImagePicker().pickImage(source: ImageSource.gallery)` | `showMediaPicker(context: context)` |
| `ImagePicker().pickMultiImage()` | `showMediaPicker(context: context, maxSelection: 0)` |
| `ImagePicker().pickVideo(...)` | `showMediaPicker(context: context, type: MediaPickerType.videos)` |
| Returns `XFile?` | Returns `Future<List<MediaFile>>` |
| `xFile.path` | `mediaFile.path` (absolute path to app temp dir) |

`MediaFile` fields: `path` (absolute), `name` (original filename e.g. `IMG_0042.HEIC`), `type` (`"image"` or `"video"`).

> **iOS Info.plist:** `NSPhotoLibraryUsageDescription` must be present — same requirement as `image_picker`.
> **Camera:** `ImageSource.camera` has no equivalent in `showMediaPicker`. Use `dartnative_camera` for camera capture.

---

### `showModalBottomSheet` — bottom sheet with native widget tree

Presents a draggable bottom sheet that hosts a full dartnative widget tree: the system sheet sized to its content on iOS 16 and later, floating in from the edges on iOS 26, and Material's bottom sheet on Android. The sheet has a dim background, an optional drag handle (`showDragHandle: true`), and can contain any combination of native widgets — including `TextField` inputs with keyboard interaction.

```dart
import 'package:dartnative/dartnative.dart';

final result = await showModalBottomSheet<String>(
  context: context,
  backgroundColor: const Color(0xFF1C1C1E),
  cornerRadius: 12.0,
  dimOpacity: 0.2,                   // Android and iOS 15; the system sheet keeps its own
  builder: (context) => Column(
    children: [
      Text("Title"),
      TextField(
        controller: TextEditingController(),
        decoration: InputDecoration(labelText: "Enter text"),
      ),
      SizedBox(height: 16),
      CupertinoButton(
        child: Text("Done"),
        onPressed: () => Navigator.of(context).pop("done"),
      ),
    ],
  ),
);
```

**Keyboard:** the panel rides the keyboard on both platforms. On Android 11+ panel and keyboard move together during a drag; on older Android the keyboard hides when the panel is dragged past a threshold and returns when it snaps back. A `TextField` inside opens the keyboard when tapped, and fields stay tappable while the panel is draggable. The parent screen stays visible behind the dim, and tapping the dim dismisses the panel.

---

### `showDialog` — centered alert/dialog with native widget tree

Presents a **centered** modal that hosts a full dartnative widget tree, with a dim
backdrop and dismiss-on-tap-outside. It is the centered sibling of
`showModalBottomSheet` — same "host any widget tree" capability, but anchored in
the middle of the screen like a classic dialog/alert. On iOS the card is the
alert's own look when no colour is set: Liquid Glass on iOS 26 and the system
material before, 320pt wide with the alert's rounded corners, in either
brightness. `ios: DialogIOSConfig(glass: false)` makes it a solid card in the
platform's dialog colour, `backgroundColor` a solid card in yours. On Android
it is Material's dialog surface.

```dart
import 'package:dartnative/dartnative.dart';

final result = await showDialog<String>(
  context: context,
  backgroundColor: Colors.white,
  cornerRadius: 16,
  dimOpacity: 0.2,                   // the platform's own unless set
  builder: (context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Enter code'),
        const SizedBox(height: 12),
        TextField(
          autofocus: true,                       // keyboard opens with the dialog
          controller: TextEditingController(),
        ),
        const SizedBox(height: 16),
        CupertinoButton(
          child: const Text('Apply'),
          onPressed: () => Navigator.of(context).pop('DONE'), // returns to caller
        ),
      ],
    ),
  ),
);
// result == 'DONE' if applied, null if dismissed by tapping outside.
```

**Constructor**

```dart
Future<T?> showDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,   // the widget tree hosted in the card
  Color? backgroundColor,           // card fill (defaults to system background)
  double cornerRadius = 15,         // card corner radius
  double dimOpacity = -1,           // backdrop dim alpha; -1 = the platform's own
});
```

- The card is **content-fit**: its height wraps the `builder`'s widget tree (give it
  a `Column(mainAxisSize: MainAxisSize.min)`); its width is a fixed centered card.
- Returns a `Future<T?>` — `Navigator.of(context).pop(value)` inside the `builder`
  resolves it with `value`; tapping the dim area (or back, on Android) resolves it
  with `null`.
- An `autofocus: true` field opens the keyboard automatically when the dialog
  appears.

**Why this exists alongside `showAlert()`**

`showAlert()` maps to the platform's **native** alert (`UIAlertController` on
iOS, `AlertDialog` on Android): a title, a message, and a fixed row of buttons. It
is the right choice for simple confirmations — but it **cannot host custom
content**: no styled text field, no multi-field form, no custom layout or branding.

`showDialog()` fills that gap. It is a centered modal that renders an
arbitrary dartnative widget tree — exactly like `showModalBottomSheet`, just
centered — so you get a dialog that looks and behaves like the rest of your app
(custom inputs, validation UI, brand colors), while still being a real native
overlay window (dim, focus, keyboard, dismiss). Reach for `showAlert()` for
plain OK/Cancel prompts, and `showDialog()` when the dialog needs its
own UI.

---

## Images

| Widget | Status | Notes |
|---|---|---|
| `Image.network` | ✅ | |
| `Image.asset` | ✅ | |
| `Image.file` | ✅ | |
| `Image.memory` | ✅ | |
| `CircleAvatar` | ✅ | `Container` + `BoxDecoration(shape: BoxShape.circle)` |
| `VideoPlayer` | ✅ (plugin) | Available via `dartnative_video_player` — native `AVPlayer` + `AVPlayerLayer`, zero-copy. Supports `aspectRatio`, controls, caching, HLS. |

---

## Focus & Keyboard

| Widget | Status | Notes |
|---|---|---|
| `FocusNode` | ✅ | Real platform focus |
| `Focus` | ✅ | |
| `FocusScope` / `FocusScopeNode` | ✅ | |

---

## Animation

DartNative supports Flutter's full animation API in Tier 1 (no Skia required):

| Widget / Type | Status |
|---|---|
| `AnimationController` | ✅ — incl. `fling(velocity:, spring:)` |
| `CurvedAnimation` | ✅ |
| `Tween<T>` / `ColorTween` / `SizeTween` | ✅ |
| `AnimatedWidget` | ✅ |
| `AnimatedBuilder` | ✅ |
| `TweenAnimationBuilder<T>` | ✅ |
| `SlideTransition` | ✅ |
| `SizeTransition` | ✅ |
| `RotationTransition` | ✅ |
| `AnimatedOpacity` | ✅ |
| `AnimatedContainer` | ✅ |
| `AnimatedSwitcher` | ✅ |
| `AnimatedAlign` | ✅ |
| `AnimatedPadding` | ✅ |
| `AnimatedPositioned` | ✅ |
| `AnimatedScale` | ✅ |
| `AnimatedRotation` | ✅ |
| `AnimatedSlide` | ✅ |
| `AnimatedSize` | ✅ |
| `AnimatedCrossFade` | ✅ |
| `AnimatedDefaultTextStyle` | ✅ |
| `FadeTransition` | ✅ |
| `ScaleTransition` | ✅ |
| `Transform` | ✅ |
| `SingleTickerProviderStateMixin` | ✅ |
| `TickerProviderStateMixin` | ✅ |

`Hero` is supported in core on both platforms — no `dartnative_skia` needed.
Its limits: one `Hero` per tag per route, and `flightShuttleBuilder` / custom
rect tweens are not available.

---

## Styling & Painting

| Type | Status | Notes |
|---|---|---|
| `BoxDecoration` | ✅ | color, borderRadius, border, gradient, shadows |
| `BoxShadow` | ✅ | |
| `LinearGradient` | ✅ | |
| `RadialGradient` | ✅ | |
| `ShapeDecoration` | ✅ | |
| `RoundedRectangleBorder` | ✅ | |
| `CircleBorder` | ✅ | |
| `StadiumBorder` | ✅ | Pill shape |
| `RoundedSuperellipseBorder` | ✅ | iOS squircle (`CALayer.cornerCurve = .continuous`). Use directly via `ShapeDecoration` or via `ClipRSuperellipse` |

---

## Theme

| Type | Status |
|---|---|
| `ThemeData` | ✅ `.light()`, `.dark()` |
| `ColorScheme` | ✅ |
| `TextTheme` | ✅ 15 text style slots |
| `MediaQuery.of(context)` | ✅ Queries native `devicePixelRatio`, `platformBrightness`, `textScaleFactor`, `size`, `padding`; `viewInsets.bottom` tracks keyboard height live |

**Why it differs from Flutter:** dartnative reads these values directly from the platform, so they are always live and reflect the current device state. `viewInsets.bottom` is **live keyboard-aware**: everything that depends on it rebuilds as the keyboard opens and closes, exactly like Flutter's `MediaQuery.viewInsets`. Common uses like `MediaQuery.sizeOf(context).width * 0.70` (e.g. chat bubble width) work identically to Flutter.
| `TextStyle` | ✅ color, font, weight, italic, spacing, decoration |

---

## Custom Drawing

`CustomPaint` is native: your `CustomPainter` paints through Core Graphics on
iOS and `android.graphics.Canvas` on Android, at zero binary cost, with the
Flutter-compatible `size` parameter. Use it for shapes, paths, lines, simple
charts and text.

For GPU work — SkSL shaders, particle systems, pixel-identical output across
platforms — use `CanvasSurface` from `dartnative_skia`, a GPU Skia canvas that
sits in any DartNative view tree:

```dart
import 'package:dartnative_skia/dartnative_skia.dart';

CanvasSurface(
  painter: MyCustomPainter(),
)
```

See [skia.md](skia.md) for when to use which.

---

## Icons

Four icon classes are available:

| Class | Style | Source |
|---|---|---|
| `MaterialSymbolsRounded` | Rounded (default) | Google Material Symbols (4,229 icons) |
| `MaterialSymbolsSharp` | Sharp | Google Material Symbols (4,229 icons) |
| `MaterialSymbolsOutlined` | Outlined | Google Material Symbols (4,229 icons) |
| `CupertinoIcons` | Apple SF-style | ~1,240 icons |

```dart
Icon(MaterialSymbolsRounded.send)   // rounded
Icon(MaterialSymbolsSharp.send)     // sharp
Icon(CupertinoIcons.gear_alt)       // iOS-style
```

Browse all Material icons at <https://fonts.google.com/icons> — switch between
Rounded and Sharp styles in the top-right dropdown. The same icon name works
across `MaterialSymbolsRounded`, `MaterialSymbolsSharp` and
`MaterialSymbolsOutlined`.

---

## Distribution

dartnative is **closed-source**, distributed as compiled artifacts — **not** a pub
registry. The framework ships as compiled binaries via the `dn` CLI; plugins as
prebuilt binaries via **dartpub.dev** (`dn pub get`).

**Free to try, subscribe to ship.** Run the official demos and plugin examples free to
evaluate the framework. Shipping your own apps needs a developer subscription
([dartpub.dev](https://dartpub.dev)) — see
[pricing](https://dartnative.com/#pricing).

See [Getting Started](getting_started.md) to set up a project. The Zero engine is
fetched from our CDN by the `dn` CLI — not pub.dev; only ordinary
third-party Dart packages (e.g. `http`) resolve from pub.dev.
