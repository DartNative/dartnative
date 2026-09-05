import 'package:dartnative/dartnative.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';
import '../home/demo_ui.dart';

// ── Sticker URLs ──────────────────────────────────────────────────────────────

/// The 26 unique sticker-pack URLs (…/0.zip … 25.zip).
final stickerUrlsBase = List.generate(26,
    (i) => 'https://cdn.presence.is/stickers/cl69ghdwt000100bx966hxbp6/$i.zip');

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
    baseColor: kTileBg,
    highlightColor: kChipBg,
    child: Container(color: kTileBg),
  );

  @override
  void initState() {
    super.initState();
    // Transparent bars (an opaque statusBarColor overlay paints over the
    // iOS 26 glass bar frost); icon brightness follows the theme.
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Sticker Grid (URL)',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: Container(
        color: kHomeBg,
        child: FastGrid(
          itemCount: _stickerUrls.length,
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          padding: const EdgeInsets.all(4),
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
