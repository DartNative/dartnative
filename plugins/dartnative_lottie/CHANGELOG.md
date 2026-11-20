## 1.3.4

- On iPhone, a list scrolls more smoothly while `RenderCache.raster`
  animations play.

## 1.3.3

- A `LottiePreWarm.warmAssets` call that finishes after a hot restart no
  longer stops the app.

## 1.3.2

- On iOS, a list scrolling past looping animations no longer pauses while
  each one starts.
- On Android, animations in rows that scrolled away before showing no longer
  keep running and using memory.

## 1.3.1

- Your app's logs no longer show the plugin's lines unless verbose logging is
  on.

## 1.3.0

- With `RenderCache.raster`, every animation in a grid now shows at once and
  plays the frames drawn so far while the rest are drawn.
- An animation that scrolls out of view finishes drawing in the background,
  so it is whole when it comes back.
- The renderer's measurements now print only when verbose logging is on.

## 1.2.1

- With `RenderCache.raster`, detailed animations no longer lose parts of the
  picture, such as a sticker's eyes.

## 1.2.0

- New `renderCache: RenderCache.raster` draws each frame once and replays it,
  for screens with many small animations like a sticker keyboard.
- Frames drawn this way are kept on disk, so the next launch shows them
  without drawing again.
- `LottiePreWarm.warmAssets` can draw those frames ahead of time through its
  `renderCache` argument.

## 1.1.0

- On iOS, a sheet full of animations now opens at once instead of a second
  late.
- On iOS, a grid of animations now fills in from the top left, the way it is
  read.
- On iOS, `LottiePreWarm.warmAssets` now takes the size the animations will
  show at.

## 1.0.0

- First release: play Lottie animations from an asset, a JSON string or a URL
  on iOS and Android.
