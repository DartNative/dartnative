// Flings the screen's list from inside the app, the same way in every app,
// when the app is launched with BENCH_AUTOSCROLL in its environment. It is
// built into the three iOS apps (the DartNative and React Native apps use
// the pod beside this file, the Swift app compiles this file directly) and
// does nothing in any other launch: without BENCH_AUTOSCROLL or BENCH_WATCH
// nothing here runs.
//
// Why the app flings itself: a UI test's swipes bring the test's own work
// into the app. Before and after each gesture XCTest reads the whole
// accessibility tree of the front app, and UIKit answers that for a
// UITableView by creating a cell for every row: a thousand cells the user
// never scrolled to, held in the reuse pool. Under a UI test, the Swift
// app's memory reflects those cells, not the app. A fling made by the app
// itself comes with none of those reads.
//
// One fling is a finger's travel and release: 0.1 s at the release speed
// (the drag), then UIKit's own deceleration curve from that speed, the
// velocity multiplied by UIScrollViewDecelerationRateNormal every
// millisecond. The scroll view's delegate is told what UIKit tells it for a
// finger (will begin dragging, will end dragging with the velocity, did end
// dragging, will begin and did end decelerating), so a list that waits for
// those events behaves as it does under a finger. The display link that
// moves the content asks for 120 Hz while the content is fast and for 60 Hz
// once it is slow, as UIKit's own scrolling does. A new fling starts every
// 2.5 s from wherever the content is, as when a user flings again; the last
// one slows down to a stop. Each fling is an os_signpost interval named
// "fling" under com.dartnative.benchmarks.scrollable. Its times also go to
// Documents/bench_flings.txt, with a "sync" line that matches a "sync"
// signpost made at the end of the run; trace_summary.py uses that pair to
// place the flings on the trace's time line. (The device's log daemon may
// leave a process's signposts out of the first tens of seconds of a
// recording, but the mark at the end of the run is always kept.)
//
//   BENCH_AUTOSCROLL=<n>       the number of flings (no flings without it)
//   BENCH_WATCH=1              no flings of its own: the driver finds the
//                              list and, in every frame the list moves
//                              under a finger (a UI test's, for instance),
//                              counts blank space as BENCH_BLANK does. It
//                              writes the count to Documents/bench_blank.txt
//                              once a second, so the file is there when the
//                              test ends the app; here the blank time is
//                              per second the list moved
//   BENCH_SPEED=<points/s>     the speed at which the finger lets go (4,000
//                              by default); every app gets the same curve
//                              from it
//   BENCH_UNIFORM=<seconds>    instead of flings, one scroll at a steady
//                              BENCH_SPEED for that many seconds, the
//                              content moved by the same amount every frame
//                              like a finger that keeps dragging. The trace
//                              shows it as one interval in place of the
//                              flings, so trace_summary.py reads it the
//                              same way (set BENCH_AUTOSCROLL=1 with it)
//   BENCH_DIRECTION=up|down|both
//                              up (the default): the content moves up, as
//                              under a finger swiping up; down: the other
//                              way (on the Chat screen, back through its
//                              history); both: n flings up, then n down
//   BENCH_BLANK=1              in every frame inside the flings, measure
//                              the share of the list's visible height that
//                              shows no content. The height is read in
//                              bands of 4 points, and an empty stretch
//                              taller than a row gap (24 points) is
//                              missing content: a row not drawn yet, or a
//                              sticker whose animation has not been built
//                              (coverBands below says what counts as
//                              drawn). Frames with the header box on
//                              screen are skipped, as in the Android
//                              recording. After the last fling, the mean,
//                              the worst frame and the blank time go to
//                              Documents/bench_blank.txt; the blank time is
//                              the share weighted by each frame's time on
//                              screen, in milliseconds per second of
//                              scrolling, the same unit as hitch time. The
//                              count costs the main thread about a
//                              millisecond a frame, so a blank run is never
//                              a timed run.
//                              BENCH_BLANK=2 also writes, for the first
//                              frames that are more than a tenth blank, the
//                              list's view tree six levels deep (at most
//                              four views per level) with each view's
//                              frame, contents and background, to check
//                              the count against
//   BENCH_MEMORY=1             ten seconds after the last fling, write what
//                              the app's memory is made of to
//                              Documents/bench_memory.txt: the footprint;
//                              the dirty memory by kind of allocation
//                              (malloc, image buffers, Core Animation
//                              backing stores, and so on) with the sizes of
//                              its regions; the footprint once the free
//                              malloc pages are given back; the malloc
//                              heap's blocks by class, by size and by how
//                              full their regions are; and the app's own
//                              report of its runtime heap when it writes
//                              one (Documents/bench_heap.txt, the
//                              DartNative app's Dart heap). trace.sh copies
//                              the file next to the trace. A screen with
//                              nothing to scroll (the Empty screen) gets
//                              this memory census ten seconds after the
//                              search for a list gives up
//
// The list is the largest scroll view on screen whose content is taller
// than it. A flipped list (a chat drawn upside down so that its newest
// row sits at the bottom) is moved the other way in its own coordinates,
// so that "down" shows older messages in every app.
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach/mach.h>
#import <malloc/malloc.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <os/signpost.h>
#import <sys/mman.h>

static const CGFloat kDefaultReleaseSpeed = 4000;   // points a second
static const NSTimeInterval kDrag = 0.1;     // seconds of travel before the release
static const NSTimeInterval kPeriod = 2.5;   // seconds between flings
static const NSTimeInterval kSettle = 8;     // seconds after launch before looking for the list
static const CGFloat kSlowSpeed = 160;       // points a second; UIKit's scrolling runs at 60 Hz below it
static const CGFloat kStopSpeed = 10;        // points a second; the deceleration ends below it
static const CGFloat HeaderRowHeight = 116;  // the Cards screen's header box row, drawn on the list background

@interface BenchAutoScroll : NSObject
@end

@implementation BenchAutoScroll {
  NSInteger _flings;
  BOOL _both;
  BOOL _down;
  BOOL _watch;                   // counting under a finger, no flings (BENCH_WATCH)
  BOOL _moving;                  // the list moved in the last watched frame
  CGFloat _releaseSpeed;         // points a second the finger lets go at (BENCH_SPEED)
  NSTimeInterval _uniform;       // seconds of steady scrolling instead of flings (BENCH_UNIFORM)
  UIScrollView *_view;
  CGFloat _flip;                 // -1 when the list is drawn upside down
  CADisplayLink *_link;
  os_log_t _log;
  os_signpost_id_t _run;
  os_signpost_id_t _fling;
  NSInteger _started;            // flings begun
  NSInteger _searches;           // times the screen was searched for a list
  BOOL _blank;                   // counting blank space (BENCH_BLANK)
  NSInteger _blankFrames;        // frames counted
  double _blankSum;              // the frames' blank shares, summed
  double _blankWorst;            // the largest share seen
  double _blankTime;             // the shares weighted by the frames' time on screen, in seconds
  double _blankSpan;             // the counted frames' time on screen, in seconds
  NSInteger _blankHalfFrames;    // frames more than half blank
  NSString *_blankWorstWhere;    // the worst frame: its offset and what the view walk found
  NSMutableString *_blankTrees;  // BENCH_BLANK=2: the trees of the first frames more than a tenth blank
  NSInteger _blankTreeFrames;    // frames written so far
  NSInteger _walkViews;          // views on screen the last walk saw
  NSInteger _walkDrawn;          // of them, the ones that draw
  NSInteger _walkHoles;          // stickers with nothing drawn it saw
  CGFloat _walkGap;              // the tallest empty stretch it found, in points
  CFTimeInterval _start;         // when the current fling began, on the display link's clock
  CFTimeInterval _began;         // the same, read when its signpost began
  NSMutableString *_flingTimes;  // one line per fling: its number, when it began and ended
  CGFloat _from;                 // the fling's starting offset
  CGFloat _travelled;            // the fling's travel applied so far, in points
  CGFloat _sign;                 // 1 when the fling increases the offset, -1 when it decreases it
  BOOL _released;                // the finger has let go
  BOOL _decelerating;
  BOOL _fast;                    // the display link currently asks for 120 Hz
}

static BenchAutoScroll *gRun;

+ (void)load {
  NSDictionary *env = NSProcessInfo.processInfo.environment;
  NSInteger flings = [env[@"BENCH_AUTOSCROLL"] integerValue];
  if (flings <= 0 && ![env[@"BENCH_WATCH"] boolValue]) return;
  [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                  object:nil queue:NSOperationQueue.mainQueue
                                              usingBlock:^(NSNotification *__unused note) {
    gRun = [[BenchAutoScroll alloc] initWithFlings:flings direction:env[@"BENCH_DIRECTION"]];
    [gRun performSelector:@selector(findList) withObject:nil afterDelay:kSettle];
  }];
}

- (instancetype)initWithFlings:(NSInteger)flings direction:(NSString *)direction {
  self = [super init];
  _flings = flings;
  _both = [direction isEqualToString:@"both"];
  _down = [direction isEqualToString:@"down"];
  _releaseSpeed = [NSProcessInfo.processInfo.environment[@"BENCH_SPEED"] doubleValue];
  if (_releaseSpeed <= 0) _releaseSpeed = kDefaultReleaseSpeed;
  _uniform = [NSProcessInfo.processInfo.environment[@"BENCH_UNIFORM"] doubleValue];
  if (_uniform > 0) { _flings = 1; _both = NO; }
  _log = os_log_create("com.dartnative.benchmarks.scrollable", "autoscroll");
  _watch = [NSProcessInfo.processInfo.environment[@"BENCH_WATCH"] boolValue];
  _blank = [NSProcessInfo.processInfo.environment[@"BENCH_BLANK"] boolValue] || _watch;
  if ([NSProcessInfo.processInfo.environment[@"BENCH_BLANK"] integerValue] >= 2) _blankTrees = [NSMutableString string];
  _flingTimes = [NSMutableString string];
  return self;
}

/// Whether a layer or one under it draws something: contents, a shape
/// with a path, a gradient with colours, text. A sticker's Lottie view
/// draws through such layers and not through subviews.
static BOOL layerDraws(CALayer *layer) {
  if (layer.hidden || layer.opacity < 0.01) return NO;
  if (layer.contents) return YES;
  if ([layer isKindOfClass:CAShapeLayer.class] && ((CAShapeLayer *)layer).path) return YES;
  if ([layer isKindOfClass:CAGradientLayer.class] && ((CAGradientLayer *)layer).colors.count > 0) return YES;
  if ([layer isKindOfClass:CATextLayer.class] && ((CATextLayer *)layer).string) return YES;
  for (CALayer *sub in layer.sublayers) {
    if (layerDraws(sub)) return YES;
  }
  return NO;
}

static BOOL isLottieView(UIView *view) {
  return [NSStringFromClass(view.class) containsString:@"LottieAnimationView"];
}

static const CGFloat kBand = 4;      // points; the count's resolution
static const CGFloat kRowGap = 24;   // points; an empty stretch taller than a row gap is missing content

/// Marks the bands a drawn view crosses. A view counts as drawn when it has
/// layer contents, or is a label with text, an image view with an image or
/// a Lottie view with drawn layers (a sticker whose animation is not built
/// yet draws nothing). A view narrower than the list also counts when it
/// has an opaque background other than the list's own: a card or a bubble
/// inset from the edges is content, while a view as wide as the list with
/// an opaque background is a row's canvas (an empty cell, for instance).
/// Views as tall as the content are the list's canvas and never count.
- (void)coverBands:(UIView *)view visible:(CGRect)visible bands:(uint8_t *)grid count:(NSInteger)count
     listBackground:(CGColorRef)listBackground {
  if (view.hidden || view.alpha < 0.01) return;
  CGRect frame = [view convertRect:view.bounds toView:nil];
  CGRect shown = CGRectIntersection(frame, visible);
  BOOL onScreen = !CGRectIsNull(shown) && !CGRectIsEmpty(shown);
  if (!onScreen && view.clipsToBounds) return;
  if (onScreen && view != _view && frame.size.height < 0.9 * _view.contentSize.height) {
    _walkViews++;
    BOOL draws;
    if (isLottieView(view)) {
      draws = layerDraws(view.layer);
      if (!draws) _walkHoles++;
    } else {
      draws = view.layer.contents != nil;
      if (!draws && [view isKindOfClass:UILabel.class]) draws = ((UILabel *)view).text.length > 0;
      if (!draws && [view isKindOfClass:UIImageView.class]) draws = ((UIImageView *)view).image != nil;
      if (!draws && frame.size.width < visible.size.width - 1) {
        CGColorRef background = view.backgroundColor.CGColor;
        draws = background && CGColorGetAlpha(background) > 0.99 && !(listBackground && CGColorEqualToColor(background, listBackground));
      }
    }
    if (draws) {
      _walkDrawn++;
      NSInteger r0 = MAX(0, (NSInteger)floor((shown.origin.y - visible.origin.y) / kBand));
      NSInteger r1 = MIN(count, (NSInteger)ceil((CGRectGetMaxY(shown) - visible.origin.y) / kBand));
      if (r1 > r0) memset(grid + r0, 1, (size_t)(r1 - r0));
    }
  }
  if (isLottieView(view)) return;
  for (UIView *sub in view.subviews) {
    [self coverBands:sub visible:visible bands:grid count:count listBackground:listBackground];
  }
}

/// The share of the list's visible height that shows no content in this
/// frame. The visible area is read in horizontal bands of 4 points. A band
/// is covered when a drawn view crosses it anywhere across the width, so
/// the empty space beside a chat bubble counts as covered. An empty
/// stretch of bands taller than a row gap is missing content: a row not
/// drawn yet, or a sticker whose animation has not been built. Every
/// framework ends up as UIKit views, with the same Lottie view for a
/// sticker, so the rule works the same for all of them; it does not rely
/// on row views, which React Native's renderer flattens away.
- (double)blankShare {
  CGRect visible = [_view convertRect:_view.bounds toView:nil];
  NSInteger count = (NSInteger)ceil(visible.size.height / kBand);
  if (count <= 0) return 0;
  uint8_t *grid = calloc((size_t)count, 1);
  _walkViews = _walkDrawn = _walkHoles = 0;
  _walkGap = 0;
  [self coverBands:_view visible:visible bands:grid count:count listBackground:_view.backgroundColor.CGColor];
  NSInteger empty = 0, run = 0;
  for (NSInteger i = 0; i <= count; i++) {
    if (i < count && grid[i] == 0) {
      run++;
      continue;
    }
    if (run * kBand > kRowGap) {
      empty += run;
      if (run * kBand > _walkGap) _walkGap = run * kBand;
    }
    run = 0;
  }
  free(grid);
  return (double)empty / (double)count;
}

/// Appends the list's view tree, six levels deep with at most four views
/// per level, for BENCH_BLANK=2. Each view's drawing is shown as the count
/// sees it.
- (void)appendTree:(NSMutableString *)out frame:(NSInteger)frame share:(double)share {
  [out appendFormat:@"\nframe %ld, fling %ld, offset %.0f of %.0f, %.0f %% blank; list %@ bounds %@ visible %@\n",
       (long)frame, (long)_started, _view.contentOffset.y, _view.contentSize.height, share * 100, NSStringFromClass(_view.class),
       NSStringFromCGRect(_view.bounds), NSStringFromCGRect([_view convertRect:_view.bounds toView:nil])];
  [self appendTreeOf:_view depth:1 into:out];
}

- (void)appendTreeOf:(UIView *)view depth:(NSInteger)depth into:(NSMutableString *)out {
  if (depth > 6) return;
  CGColorRef listBackground = _view.backgroundColor.CGColor;
  NSInteger n = 0;
  for (UIView *sub in view.subviews) {
    if (n++ >= 4) { [out appendFormat:@"%*s... %lu subviews\n", (int)(2 * depth), "", (unsigned long)view.subviews.count]; break; }
    CGColorRef background = sub.backgroundColor.CGColor;
    [out appendFormat:@"%*s%@ %@ hidden %d alpha %.2f clips %d contents %d opaque %d, %lu subviews\n", (int)(2 * depth), "", NSStringFromClass(sub.class),
         NSStringFromCGRect([sub convertRect:sub.bounds toView:nil]), sub.hidden, sub.alpha, sub.clipsToBounds,
         sub.layer.contents != nil, background && CGColorGetAlpha(background) > 0.99 && !(listBackground && CGColorEqualToColor(background, listBackground)),
         (unsigned long)sub.subviews.count];
    [self appendTreeOf:sub depth:depth + 1 into:out];
  }
}

- (void)writeBlank {
  double mean = _blankFrames > 0 ? _blankSum / _blankFrames : 0;
  double perSecond = _blankSpan > 0 ? 1000 * _blankTime / _blankSpan : 0;
  NSString *out = [NSString stringWithFormat:@"blank space: mean %.2f %% of the list's visible height over %ld frames inside the flings, worst frame %.1f %%%@, %ld frames more than half blank\n"
                   "blank time %.1f ms per second of scrolling (the share weighted by each frame's time on screen)\n",
                   mean * 100, (long)_blankFrames, _blankWorst * 100,
                   _blankWorstWhere ? [NSString stringWithFormat:@" (%@)", _blankWorstWhere] : @"", (long)_blankHalfFrames, perSecond];
  if (_blankTrees.length > 0) out = [out stringByAppendingString:_blankTrees];
  NSURL *docs = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
  [out writeToURL:[docs URLByAppendingPathComponent:@"bench_blank.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
  os_log(_log, "autoscroll: %{public}@", out);
}

/// Finds the list: the largest scroll view on screen whose content is
/// taller than itself. While the screen has none (its content is still
/// loading), it tries again a second later. A screen with none after ten
/// tries has nothing to scroll: there are no flings, only the memory census
/// when BENCH_MEMORY asks for one.
- (void)findList {
  UIWindow *window = nil;
  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    if (![scene isKindOfClass:UIWindowScene.class]) continue;
    for (UIWindow *w in ((UIWindowScene *)scene).windows) {
      if (w.isKeyWindow || window == nil) window = w;
    }
  }
  UIScrollView *best = nil;
  CGFloat bestArea = 0;
  if (window) [self visit:window in:window best:&best area:&bestArea];
  if (!best) {
    if (++_searches < 10) {
      [self performSelector:@selector(findList) withObject:nil afterDelay:1];
    } else {
      os_log(_log, "autoscroll: no list to scroll");
      if ([NSProcessInfo.processInfo.environment[@"BENCH_MEMORY"] boolValue]) {
        [self performSelector:@selector(writeMemory) withObject:nil afterDelay:10];
      }
    }
    return;
  }
  _view = best;
  _flip = 1;
  for (UIView *v = best; v; v = v.superview) {
    if (v.transform.d < 0) _flip = -_flip;
  }
  os_log(_log, "autoscroll: %{public}@ %.0fx%.0f content %.0f pt%{public}s, %ld flings %{public}s",
         NSStringFromClass(best.class), best.bounds.size.width, best.bounds.size.height,
         best.contentSize.height, _flip < 0 ? ", flipped" : "", (long)_flings,
         _both ? "both ways" : _down ? "down" : "up");
  if (_watch) {
    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(watch:)];
    [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    return;
  }
  _run = os_signpost_id_generate(_log);
  os_signpost_interval_begin(_log, _run, "run", "%ld flings", (long)_flings);
  _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
  _fast = YES;
  _link.preferredFrameRateRange = CAFrameRateRangeMake(80, 120, 120);
  [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

/// Called every frame in watch mode: counts the frame while the list moves
/// under a finger, and writes the count once a second.
- (void)watch:(CADisplayLink *)link {
  BOOL moving = _view.isTracking || _view.isDragging || _view.isDecelerating;
  if (!moving) {
    if (_moving) [self writeBlank];
    _moving = NO;
    return;
  }
  _moving = YES;
  if (_view.contentOffset.y > HeaderRowHeight) [self countFrame:link];
  if (_blankFrames % 60 == 0) [self writeBlank];
}

/// Counts what the last frame showed: the list's views as they are laid out
/// for its current offset.
- (void)countFrame:(CADisplayLink *)link {
  double share = [self blankShare];
  double shown = MAX(0, link.targetTimestamp - link.timestamp);
  _blankFrames++;
  _blankSum += share;
  _blankTime += share * shown;
  _blankSpan += shown;
  if (share > 0.5) _blankHalfFrames++;
  if (share > 0.1 && _blankTrees && ++_blankTreeFrames <= 8) [self appendTree:_blankTrees frame:_blankFrames share:share];
  if (share > _blankWorst) {
    _blankWorst = share;
    _blankWorstWhere = [NSString stringWithFormat:@"at offset %.0f: %ld of %ld views on screen draw, %ld stickers with nothing drawn, the tallest empty stretch %.0f points",
                        _view.contentOffset.y, (long)_walkDrawn, (long)_walkViews, (long)_walkHoles, _walkGap];
  }
}

- (void)visit:(UIView *)view in:(UIWindow *)window best:(UIScrollView **)best area:(CGFloat *)bestArea {
  if (view.hidden || view.alpha == 0) return;
  if ([view isKindOfClass:UIScrollView.class]) {
    UIScrollView *s = (UIScrollView *)view;
    if (s.contentSize.height > s.bounds.size.height + 1) {
      CGRect shown = CGRectIntersection([s convertRect:s.bounds toView:window], window.bounds);
      CGFloat area = CGRectIsNull(shown) ? 0 : shown.size.width * shown.size.height;
      if (area > *bestArea) { *bestArea = area; *best = s; }
    }
  }
  for (UIView *sub in view.subviews) [self visit:sub in:window best:best area:bestArea];
}

- (void)tell:(SEL)selector {
  id<UIScrollViewDelegate> d = _view.delegate;
  if ([d respondsToSelector:selector]) {
    ((void (*)(id, SEL, id))objc_msgSend)(d, selector, _view);
  }
}

- (void)beginFlingAt:(CFTimeInterval)now {
  if (_decelerating) {
    // A finger that lands on a decelerating list stops it without a
    // did-end-decelerating call, as UIKit does.
    _decelerating = NO;
    [self closeFling];
  }
  BOOL down = _both ? _started >= _flings : _down;
  _sign = (down ? -1 : 1) * _flip;
  _start = now;
  _from = _view.contentOffset.y;
  _travelled = 0;
  _released = NO;
  _started++;
  _fling = os_signpost_id_generate(_log);
  _began = CACurrentMediaTime();
  os_signpost_interval_begin(_log, _fling, "fling", "%ld %{public}s", (long)_started, down ? "down" : "up");
  [self tell:@selector(scrollViewWillBeginDragging:)];
}

/// Ends the fling's signpost and keeps its times, on the same clock the
/// trace uses for its own (CACurrentMediaTime, the device's monotonic
/// clock).
- (void)closeFling {
  os_signpost_interval_end(_log, _fling, "fling");
  [_flingTimes appendFormat:@"fling %ld %.6f %.6f\n", (long)_started, _began, CACurrentMediaTime()];
}

/// Writes the flings' times to Documents/bench_flings.txt with a "sync"
/// line, and makes a "sync" signpost at the same instant carrying the same
/// clock reading. The trace places the signpost on its own time line, and
/// the difference between the two puts every fling on that line too. Only
/// this one mark has to reach the trace: the device's log daemon may leave
/// a process's signposts out of the first tens of seconds of a recording,
/// so the early flings can be missing from it, but the mark at the end of
/// the run always comes later than that.
- (void)writeFlings {
  uint64_t now = (uint64_t)(CACurrentMediaTime() * 1e6);
  os_signpost_event_emit(_log, os_signpost_id_generate(_log), "sync", "%llu", now);
  // How far the flings went, in points of content and, for a table view,
  // in rows, so the rows each app's flings covered can be compared.
  NSString *rows = @"";
  if ([_view isKindOfClass:UITableView.class]) {
    NSArray<NSIndexPath *> *visible = [(UITableView *)_view indexPathsForVisibleRows];
    if (visible.count > 0) rows = [NSString stringWithFormat:@"rows %ld..%ld of %ld\n", (long)visible.firstObject.row, (long)visible.lastObject.row, (long)[(UITableView *)_view numberOfRowsInSection:0]];
  }
  NSString *out = [NSString stringWithFormat:@"sync %llu\noffset %.0f of %.0f\n%@%@", now,
                   _view.contentOffset.y, _view.contentSize.height, rows, _flingTimes];
  NSURL *docs = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
  [out writeToURL:[docs URLByAppendingPathComponent:@"bench_flings.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)endFling {
  _decelerating = NO;
  [self closeFling];
  [self tell:@selector(scrollViewDidEndDecelerating:)];
  if (_started >= (_both ? 2 : 1) * _flings) [self finishRun];
}

/// Ends the run: writes the fling times and stops the display link, then
/// writes the blank count and the memory census when they are asked for.
- (void)finishRun {
  os_signpost_interval_end(_log, _run, "run");
  [self writeFlings];
  os_log(_log, "autoscroll: done, offset %.0f", _view.contentOffset.y);
  [_link invalidate];
  _link = nil;
  if (_blank) [self writeBlank];
  if ([NSProcessInfo.processInfo.environment[@"BENCH_MEMORY"] boolValue]) {
    // Ten seconds: the image buffers of the rows a list let go during
    // the flings stay in Core Animation's surface pool for about eight
    // seconds after the app stops asking for new ones, and count in the
    // footprint until then.
    [self performSelector:@selector(writeMemory) withObject:nil afterDelay:10];
  }
}

/// The name of a region's allocation kind, as the system tags it.
static NSString *tagName(unsigned tag) {
  switch (tag) {
    case 0: return @"untagged (mmap: the Dart heap, Hermes, ...)";
    case VM_MEMORY_MALLOC: case VM_MEMORY_MALLOC_SMALL: case VM_MEMORY_MALLOC_LARGE:
    case VM_MEMORY_MALLOC_HUGE: case VM_MEMORY_MALLOC_TINY: case VM_MEMORY_MALLOC_NANO:
    case VM_MEMORY_MALLOC_MEDIUM: case VM_MEMORY_MALLOC_LARGE_REUSABLE:
    case VM_MEMORY_MALLOC_LARGE_REUSED: case VM_MEMORY_REALLOC: return @"malloc";
    case VM_MEMORY_STACK: return @"thread stacks";
    case VM_MEMORY_COREGRAPHICS_BACKINGSTORES: return @"Core Graphics backing stores";
    case VM_MEMORY_COREGRAPHICS: case VM_MEMORY_COREGRAPHICS_DATA:
    case VM_MEMORY_COREGRAPHICS_SHARED: case VM_MEMORY_COREGRAPHICS_XALLOC: return @"Core Graphics";
    case VM_MEMORY_CGIMAGE: return @"CGImage";
    case VM_MEMORY_IMAGEIO: return @"ImageIO";
    case VM_MEMORY_LAYERKIT: return @"Core Animation";
    case VM_MEMORY_IOSURFACE: return @"IOSurface (image and layer buffers)";
    case VM_MEMORY_IOACCELERATOR: return @"GPU";
    case VM_MEMORY_COREUI: case VM_MEMORY_COREUI_CACHED_IMAGE_DATA: return @"CoreUI";
    case VM_MEMORY_FOUNDATION: return @"Foundation";
    case VM_MEMORY_LIBDISPATCH: return @"libdispatch";
    case VM_MEMORY_SWIFT_RUNTIME: case VM_MEMORY_SWIFT_METADATA: return @"Swift runtime";
    case VM_MEMORY_DYLD: case VM_MEMORY_DYLD_MALLOC: case VM_MEMORY_DYLIB: return @"dyld";
    case VM_MEMORY_OS_ALLOC_ONCE: return @"os_alloc_once";
    case VM_MEMORY_COREDATA: return @"Core Data";
    case VM_MEMORY_SQLITE: return @"SQLite";
    case VM_MEMORY_JAVASCRIPT_CORE: return @"JavaScriptCore";
    case VM_MEMORY_LIBNETWORK: return @"Network";
    case VM_MEMORY_AUDIO: return @"Audio";
    default: return [NSString stringWithFormat:@"tag %u", tag];
  }
}

// The malloc heap, counted from inside the process: every block in use in
// every zone, by the Objective-C (or Swift) class it is an instance of, by
// its size, and by how much of its region the blocks in use fill. The
// zones are locked while they are walked, so nothing in the walk may
// allocate: the tables are mapped with mmap beforehand and filled in place.
enum { kClassSlots = 1 << 17, kRegionCap = 1 << 14, kSizeBuckets = 12 };
static const size_t kSizeLimits[kSizeBuckets] = {16, 32, 48, 64, 128, 256, 512, 1024, 4096, 16384, 131072, SIZE_MAX};

typedef struct {
  uintptr_t isaMask;
  uintptr_t *keys;                 // class pointers, a hash table with open addressing
  uint64_t *counts, *bytes;        // each class's instances and their block bytes
  vm_range_t *regions;             // the zones' regions, in address order
  uint64_t *used;                  // bytes in use in each region
  unsigned regionCount;
  BOOL collectingRegions;
  uint64_t blocks, blockBytes;
  uint64_t bucketCount[kSizeBuckets], bucketBytes[kSizeBuckets];
} HeapCensus;

static unsigned classSlot(uintptr_t cls) { return (unsigned)((cls >> 4) & (kClassSlots - 1)); }

static int compareRanges(const void *a, const void *b) {
  vm_address_t x = ((const vm_range_t *)a)->address, y = ((const vm_range_t *)b)->address;
  return x < y ? -1 : x > y;
}

static void recordRanges(task_t __unused task, void *context, unsigned __unused type,
                         vm_range_t *ranges, unsigned count) {
  HeapCensus *c = context;
  for (unsigned i = 0; i < count; i++) {
    vm_range_t r = ranges[i];
    if (c->collectingRegions) {
      if (c->regionCount < kRegionCap) c->regions[c->regionCount++] = r;
      continue;
    }
    c->blocks++;
    c->blockBytes += r.size;
    for (unsigned b = 0; b < kSizeBuckets; b++) {
      if (r.size <= kSizeLimits[b]) { c->bucketCount[b]++; c->bucketBytes[b] += r.size; break; }
    }
    // The region the block lies in, by binary search.
    unsigned lo = 0, hi = c->regionCount;
    while (lo < hi) {
      unsigned mid = (lo + hi) / 2;
      if (c->regions[mid].address + c->regions[mid].size <= r.address) lo = mid + 1; else hi = mid;
    }
    if (lo < c->regionCount && c->regions[lo].address <= r.address) c->used[lo] += r.size;
    if (r.size < sizeof(uintptr_t)) continue;
    uintptr_t cls = *(uintptr_t *)r.address & c->isaMask;
    if (!cls) continue;
    for (unsigned s = classSlot(cls), n = 0; n < kClassSlots; s = (s + 1) & (kClassSlots - 1), n++) {
      if (c->keys[s] == cls) { c->counts[s]++; c->bytes[s] += r.size; break; }
      if (!c->keys[s]) break;
    }
  }
}

static void *mapZeroed(size_t bytes) {
  void *p = mmap(NULL, bytes, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
  return p == MAP_FAILED ? NULL : p;
}

static void appendHeapCensus(NSMutableString *out) {
  HeapCensus c = {0};
  uintptr_t *mask = dlsym(RTLD_DEFAULT, "objc_debug_isa_class_mask");
  c.isaMask = mask ? *mask : ~(uintptr_t)7;
  c.keys = mapZeroed(kClassSlots * sizeof(uintptr_t));
  c.counts = mapZeroed(kClassSlots * sizeof(uint64_t));
  c.bytes = mapZeroed(kClassSlots * sizeof(uint64_t));
  c.regions = mapZeroed(kRegionCap * sizeof(vm_range_t));
  c.used = mapZeroed(kRegionCap * sizeof(uint64_t));
  if (!c.keys || !c.counts || !c.bytes || !c.regions || !c.used) return;
  // Listing the classes makes the runtime set up every class the app has
  // not used yet, which allocates their runtime data; the heap counted
  // below is that much bigger than the app's own, and the output says by
  // how much.
  malloc_statistics_t before, after;
  malloc_zone_statistics(NULL, &before);
  unsigned classCount = 0;
  Class *classes = objc_copyClassList(&classCount);
  malloc_zone_statistics(NULL, &after);
  for (unsigned i = 0; i < classCount; i++) {
    uintptr_t key = (uintptr_t)(__bridge void *)classes[i];
    for (unsigned s = classSlot(key);; s = (s + 1) & (kClassSlots - 1)) {
      if (c.keys[s] == key) break;
      if (!c.keys[s]) { c.keys[s] = key; break; }
    }
  }
  free(classes);
  vm_address_t *zones = NULL;
  unsigned zoneCount = 0;
  malloc_get_all_zones(mach_task_self(), NULL, &zones, &zoneCount);
  malloc_zone_t *locked[64] = {0};
  unsigned lockedCount = 0;
  for (unsigned z = 0; z < zoneCount && lockedCount < 64; z++) {
    malloc_zone_t *zone = (malloc_zone_t *)zones[z];
    if (zone->introspect && zone->introspect->force_lock && zone->introspect->enumerator) {
      zone->introspect->force_lock(zone);
      locked[lockedCount++] = zone;
    }
  }
  c.collectingRegions = YES;
  for (unsigned z = 0; z < lockedCount; z++) {
    locked[z]->introspect->enumerator(mach_task_self(), &c, MALLOC_PTR_REGION_RANGE_TYPE,
                                      (vm_address_t)locked[z], NULL, recordRanges);
  }
  qsort(c.regions, c.regionCount, sizeof(vm_range_t), compareRanges);
  c.collectingRegions = NO;
  for (unsigned z = 0; z < lockedCount; z++) {
    locked[z]->introspect->enumerator(mach_task_self(), &c, MALLOC_PTR_IN_USE_RANGE_TYPE,
                                      (vm_address_t)locked[z], NULL, recordRanges);
  }
  for (unsigned z = lockedCount; z > 0; z--) locked[z - 1]->introspect->force_unlock(locked[z - 1]);

  [out appendFormat:@"\nmalloc heap: %.1f MiB in %llu blocks in use, %u regions "
                    @"(%.2f MiB of it the %u classes' runtime data, realised to name the objects)\n",
       c.blockBytes / 1048576.0, c.blocks, c.regionCount,
       ((int64_t)after.size_in_use - (int64_t)before.size_in_use) / 1048576.0, classCount];
  [out appendString:@"  blocks by size (up to bytes, count, MiB):\n"];
  for (unsigned b = 0; b < kSizeBuckets; b++) {
    if (!c.bucketCount[b]) continue;
    if (kSizeLimits[b] == SIZE_MAX) [out appendFormat:@"    %8s", "larger"];
    else [out appendFormat:@"    %8zu", kSizeLimits[b]];
    [out appendFormat:@"  %9llu  %7.2f\n", c.bucketCount[b], c.bucketBytes[b] / 1048576.0];
  }
  // Regions by how full they are: a region whose blocks in use fill a
  // quarter of it keeps three quarters of its dirty pages for nothing.
  uint64_t fullCount[4] = {0}, fullBytes[4] = {0}, fullUsed[4] = {0};
  for (unsigned r = 0; r < c.regionCount; r++) {
    unsigned q = (unsigned)MIN(3, 4 * c.used[r] / MAX(1, c.regions[r].size));
    fullCount[q]++;
    fullBytes[q] += c.regions[r].size;
    fullUsed[q] += c.used[r];
  }
  [out appendString:@"  regions by share in use (regions, MiB of region, MiB in use):\n"];
  static const char *const quarters[4] = {"under a quarter", "a quarter to a half", "a half to three quarters", "over three quarters"};
  for (unsigned q = 0; q < 4; q++) {
    [out appendFormat:@"    %-26s %5llu  %7.2f  %7.2f\n", quarters[q], fullCount[q],
         fullBytes[q] / 1048576.0, fullUsed[q] / 1048576.0];
  }
  // The classes with the most instance bytes.
  unsigned *order = mapZeroed(kClassSlots * sizeof(unsigned));
  unsigned found = 0;
  uint64_t objectBytes = 0, objectCount = 0;
  for (unsigned s = 0; s < kClassSlots; s++) {
    if (!c.counts[s]) continue;
    order[found++] = s;
    objectBytes += c.bytes[s];
    objectCount += c.counts[s];
  }
  for (unsigned i = 1; i < found; i++) {   // insertion sort by bytes, descending
    unsigned s = order[i], j = i;
    while (j > 0 && c.bytes[order[j - 1]] < c.bytes[s]) { order[j] = order[j - 1]; j--; }
    order[j] = s;
  }
  [out appendFormat:@"  objects: %.2f MiB in %llu instances of %u classes; the largest (count, MiB, class):\n",
       objectBytes / 1048576.0, objectCount, found];
  for (unsigned i = 0; i < MIN(found, 48u); i++) {
    unsigned s = order[i];
    [out appendFormat:@"    %8llu  %7.2f  %s\n", c.counts[s], c.bytes[s] / 1048576.0, class_getName((__bridge Class)(void *)c.keys[s])];
  }
  munmap(order, kClassSlots * sizeof(unsigned));
  munmap(c.keys, kClassSlots * sizeof(uintptr_t));
  munmap(c.counts, kClassSlots * sizeof(uint64_t));
  munmap(c.bytes, kClassSlots * sizeof(uint64_t));
  munmap(c.regions, kRegionCap * sizeof(vm_range_t));
  munmap(c.used, kRegionCap * sizeof(uint64_t));
}

/// Lists the window's layers whose bitmap, if they drew one, would take a
/// megabyte or more. For each: the layer's class, its view's class, its
/// size in points, the bytes a full backing store of it takes at the
/// screen's scale, and whether it holds contents or draws itself. A
/// screen-wide effect (a bar's backdrop, an edge effect) shows up here as a
/// layer the app never asked for.
- (void)appendBigLayers:(NSMutableString *)out {
  UIWindow *window = nil;
  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    for (UIWindow *w in ((UIWindowScene *)scene).windows) {
      if (w.isKeyWindow) window = w;
    }
  }
  if (!window) return;
  CGFloat scale = window.screen.scale;
  [out appendString:@"\nlayers of a megabyte or more (MiB, points, layer, view, contents):\n"];
  NSMutableArray<CALayer *> *stack = [NSMutableArray arrayWithObject:window.layer];
  while (stack.count) {
    CALayer *layer = stack.lastObject;
    [stack removeLastObject];
    [stack addObjectsFromArray:layer.sublayers ?: @[]];
    CGSize size = layer.bounds.size;
    double bytes = size.width * scale * size.height * scale * 4;
    if (bytes < 1048576) continue;
    UIView *view = [layer.delegate isKindOfClass:UIView.class] ? (UIView *)layer.delegate : nil;
    BOOL drawsItself = view && [view.class instanceMethodForSelector:@selector(drawRect:)]
                               != [UIView instanceMethodForSelector:@selector(drawRect:)];
    [out appendFormat:@"  %6.2f  %4.0fx%-4.0f  %@  %@  %@%@\n", bytes / 1048576.0, size.width, size.height,
         NSStringFromClass(layer.class), view ? NSStringFromClass(view.class) : @"-",
         layer.contents ? @"contents" : (drawsItself ? @"draws" : @"-"),
         layer.hidden ? @" hidden" : @""];
  }
}

/// Writes the memory census: the footprint, then the dirty memory by
/// allocation kind (each region's dirty and swapped-out pages added to the
/// total for its tag, with the sizes of that kind's regions), then the
/// malloc heap's census.
- (void)writeMemory {
  // The census allocates memory (the class list, its tables), so a trace
  // reads the app's memory from before this mark.
  os_signpost_event_emit(_log, os_signpost_id_generate(_log), "census");
  task_vm_info_data_t info;
  mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
  task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&info, &count);
  NSMutableDictionary<NSNumber *, NSNumber *> *dirty = [NSMutableDictionary dictionary];
  NSMutableDictionary<NSNumber *, NSCountedSet *> *sizes = [NSMutableDictionary dictionary];
  vm_address_t address = 0;
  natural_t depth = 0;
  for (;;) {
    vm_size_t size = 0;
    vm_region_submap_info_data_64_t region;
    mach_msg_type_number_t regionCount = VM_REGION_SUBMAP_INFO_COUNT_64;
    kern_return_t kr = vm_region_recurse_64(mach_task_self(), &address, &size, &depth,
                                            (vm_region_recurse_info_t)&region, &regionCount);
    if (kr != KERN_SUCCESS) break;
    if (region.is_submap) { depth++; continue; }
    uint64_t bytes = ((uint64_t)region.pages_dirtied + region.pages_swapped_out) * vm_kernel_page_size;
    if (bytes > 0) {
      NSNumber *tag = @(region.user_tag);
      dirty[tag] = @([dirty[tag] unsignedLongLongValue] + bytes);
      if (!sizes[tag]) sizes[tag] = [NSCountedSet set];
      [sizes[tag] addObject:@(bytes)];
    }
    address += size;
  }
  NSMutableString *out = [NSMutableString string];
  [out appendFormat:@"footprint %.1f MiB\n", info.phys_footprint / 1048576.0];
  [out appendFormat:@"resident %.1f MiB, compressed %.1f MiB\n",
       info.resident_size / 1048576.0, info.compressed / 1048576.0];
  malloc_statistics_t stats;
  malloc_zone_statistics(NULL, &stats);
  [out appendFormat:@"malloc in use %.1f MiB of %.1f MiB allocated (most in use at once %.1f MiB)\n",
       stats.size_in_use / 1048576.0, stats.size_allocated / 1048576.0, stats.max_size_in_use / 1048576.0];
  // Malloc pages that are free but still dirty count in the footprint
  // until the system takes them back under memory pressure. This gives
  // them back now and reads the footprint again, to show what they are
  // worth. The dirty memory by kind was read before this, so it still
  // includes them.
  size_t relieved = malloc_zone_pressure_relief(NULL, 0);
  task_vm_info_data_t after;
  mach_msg_type_number_t afterCount = TASK_VM_INFO_COUNT;
  task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&after, &afterCount);
  [out appendFormat:@"footprint with the free malloc pages given back %.1f MiB (%.1f MiB returned)\n",
       after.phys_footprint / 1048576.0, relieved / 1048576.0];
  NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory
                                                          inDomains:NSUserDomainMask].firstObject;
  NSString *heap = [NSString stringWithContentsOfURL:[documents URLByAppendingPathComponent:@"bench_heap.txt"]
                                            encoding:NSUTF8StringEncoding error:nil];
  if (heap.length > 0) [out appendString:heap];
  [out appendString:@"\n"];
  [out appendString:@"dirty memory by kind (MiB, regions), and the sizes its regions come in (KiB x count):\n"];
  NSArray *tags = [dirty.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
    return [dirty[b] compare:dirty[a]];
  }];
  for (NSNumber *tag in tags) {
    NSCountedSet *set = sizes[tag];
    [out appendFormat:@"%8.1f  %4lu  %@\n", [dirty[tag] unsignedLongLongValue] / 1048576.0,
         (unsigned long)set.count, tagName(tag.unsignedIntValue)];
    NSArray *common = [set.allObjects sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
      uint64_t x = a.unsignedLongLongValue * [set countForObject:a], y = b.unsignedLongLongValue * [set countForObject:b];
      return x > y ? NSOrderedAscending : x < y ? NSOrderedDescending : NSOrderedSame;
    }];
    if ([dirty[tag] unsignedLongLongValue] < 1048576) continue;
    [out appendString:@"                "];
    for (NSNumber *size in [common subarrayWithRange:NSMakeRange(0, MIN(common.count, 6u))]) {
      [out appendFormat:@"%llu x %lu  ", size.unsignedLongLongValue / 1024, (unsigned long)[set countForObject:size]];
    }
    [out appendString:@"\n"];
  }
  appendHeapCensus(out);
  [self appendBigLayers:out];
  NSURL *file = [documents URLByAppendingPathComponent:@"bench_memory.txt"];
  [out writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
  os_log(_log, "autoscroll: memory written, footprint %.1f MiB", info.phys_footprint / 1048576.0);
}

- (void)tick:(CADisplayLink *)link {
  CFTimeInterval now = link.targetTimestamp;
  // Count what the last frame showed: the list's views as they are laid
  // out for its current offset. Frames with the header box's row on screen
  // are left out, since that row shows the list background by design.
  if (_blank && _started > 0 && _view.contentOffset.y > HeaderRowHeight) [self countFrame:link];
  NSInteger total = (_both ? 2 : 1) * _flings;
  if (_started == 0 || (_started < total && now - _start >= kPeriod)) [self beginFlingAt:now];
  CFTimeInterval t = now - _start;
  CGFloat speed, travel;
  if (_uniform > 0) {
    // Like a finger that keeps dragging at one speed: the content moves the
    // same distance every frame, and the drag ends without a fling when the
    // time is up.
    speed = _releaseSpeed;
    travel = _releaseSpeed * MIN(t, _uniform);
  } else if (t <= kDrag) {
    speed = _releaseSpeed;
    travel = _releaseSpeed * t;
  } else {
    CGFloat decay = pow(UIScrollViewDecelerationRateNormal, (t - kDrag) * 1000);
    speed = _releaseSpeed * decay;
    travel = _releaseSpeed * kDrag + _releaseSpeed * (1 - decay) / (1000 * -log(UIScrollViewDecelerationRateNormal));
  }
  CGFloat top = -_view.adjustedContentInset.top;
  CGFloat bottom = MAX(top, _view.contentSize.height - _view.bounds.size.height + _view.adjustedContentInset.bottom);
  // Move the content by this frame's share of the travel, from wherever it
  // is now, as a finger does. A list may shift its own offset in between,
  // to keep the visible rows still when a row's measured height replaces
  // its estimate; moving from the current offset keeps that shift, while
  // setting the offset from the fling's start would lose it.
  CGFloat y = _view.contentOffset.y + _sign * (travel - _travelled);
  _travelled = travel;
  BOOL edge = y < top || y > bottom;
  y = MIN(MAX(y, top), bottom);
  if (_uniform > 0) {
    CGPoint offset = _view.contentOffset;
    offset.y = y;
    _view.contentOffset = offset;
    // An edge ends the scroll only once the content has moved more than
    // the list's height: a list re-measuring its rows can report a content
    // size smaller than the offset for a frame.
    if (t >= _uniform || (edge && _travelled > _view.bounds.size.height)) {
      id<UIScrollViewDelegate> d = _view.delegate;
      if ([d respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [d scrollViewDidEndDragging:_view willDecelerate:NO];
      }
      _decelerating = NO;
      [self closeFling];
      _started = _flings;
      [self finishRun];
    }
    return;
  }
  if (t > kDrag && !_released) {
    _released = YES;
    CGPoint velocity = CGPointMake(0, _sign * _releaseSpeed / 1000);
    CGFloat rest = _from + _sign * (_releaseSpeed * kDrag + _releaseSpeed / (1000 * -log(UIScrollViewDecelerationRateNormal)));
    CGPoint target = CGPointMake(_view.contentOffset.x, MIN(MAX(rest, top), bottom));
    id<UIScrollViewDelegate> d = _view.delegate;
    if ([d respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
      [d scrollViewWillEndDragging:_view withVelocity:velocity targetContentOffset:&target];
    }
    if ([d respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
      [d scrollViewDidEndDragging:_view willDecelerate:YES];
    }
    _decelerating = YES;
    [self tell:@selector(scrollViewWillBeginDecelerating:)];
  }
  CGPoint offset = _view.contentOffset;
  offset.y = y;
  _view.contentOffset = offset;
  BOOL fast = speed >= kSlowSpeed;
  if (fast != _fast) {
    _fast = fast;
    link.preferredFrameRateRange = fast ? CAFrameRateRangeMake(80, 120, 120) : CAFrameRateRangeMake(60, 60, 60);
  }
  if (_decelerating && (speed < kStopSpeed || edge)) [self endFling];
}

@end
