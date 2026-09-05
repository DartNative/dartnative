import 'package:dartnative/dartnative.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';

// ── Sticker URLs ──────────────────────────────────────────────────────────────

/// The 26 unique sticker-pack URLs (…/0.zip … 25.zip).
final stickerUrlsBase =
    List.generate(26, (i) => 'https://cdn.dartpub.dev/assets/lottie/$i.zip');

/// Grid data: the unique set repeated 3× (scroll / recycling test data).
final _stickerUrls = [for (var r = 0; r < 3; r++) ...stickerUrlsBase];

// ── Screen ────────────────────────────────────────────────────────────────────

class LottieGridDemo extends StatefulWidget {
  const LottieGridDemo({super.key});

  @override
  State<LottieGridDemo> createState() => _LottieGridDemoState();
}

class _LottieGridDemoState extends State<LottieGridDemo> {
  static final _shimmer = Shimmer.fromColors(
    baseColor: const Color(0xFF2C2C2E),
    highlightColor: const Color(0xFF3A3A3C),
    child: Container(color: const Color(0xFF2C2C2E)),
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // See-through iOS 26 bar: the clear glass AppBar lets the grid scroll
      // BEHIND it, and the system scroll-edge effect keeps the back capsule
      // + title legible.
      // The FastGrid's top content-padding rests row 0 below the bar; content
      // still scrolls up under the glass.
      extendBodyBehindAppBar: true,
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        leading: const BackButton(iconColor: Color(0xFF000000)),
        title: const Text(
          'Sticker Grid (URL)',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFFFFFFF),
        child: FastGrid(
          itemCount: _stickerUrls.length,
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          // NO padding → AUTOMATIC bar clearance (extendBodyBehindAppBar +
          // null padding → framework applies top = safeTop + bar height).
          // Content windowing: running Lottie animations hold keyframe buffers
          // + a live render layer per cell — exactly the content-agnostic
          // memory keepAliveCount releases (Image.cacheWidth can't help here).
          // 15 items × 3 cols ≈ 5 rows kept each side; off-window stickers are
          // disposed and rebuilt (re-parsed from the disk-cached .zip) as they
          // near the viewport. Value counts ITEMS, not rows.
          keepAliveCount: 15,
          itemBuilder: (_, i) => Lottie.network(
            _stickerUrls[i],
            loop: true,
            autoplay: true,
            fit: LottieFit.contain,
            placeholder: _shimmer,
          ),
        ),
      ),
    );
  }
}
