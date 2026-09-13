import 'package:dartnative/dartnative.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';
import '../home/demo_ui.dart';

// Toggle: true = FastGrid (UICollectionView, virtualised), false = GridView (all cells in hierarchy)
// Set false to rule out FastGrid cell-recycling as the source of scroll jank.
const _useFastGrid = true;

/// The Hot Cherry pack's 32 bundled stickers (assets/stickers/hot_cherry/).
final _uniqueAssetPaths = [
  for (final n in const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '27', '28', '29', '30', '31', '32', '33']) 'assets/stickers/hot_cherry/$n.json',
];

/// Grid data: the unique set repeated 3× — enough rows to exercise scrolling
/// and cell recycling without hand-duplicating the declaration.
final _gridPaths = [for (var r = 0; r < 3; r++) ..._uniqueAssetPaths];

// ── Screen ────────────────────────────────────────────────────────────────────

class LottieAssetsGridDemo extends StatefulWidget {
  const LottieAssetsGridDemo({super.key});

  @override
  State<LottieAssetsGridDemo> createState() => _LottieAssetsGridDemoState();
}

class _LottieAssetsGridDemoState extends State<LottieAssetsGridDemo> {
  @override
  void initState() {
    super.initState();
    // Transparent statusBarColor — required for the iOS 26 glass AppBar (an
    // opaque overlay paints over the bar frost and clips capsule press-scale);
    // icon brightness follows the theme.
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Lottie Grid (Assets) [${_useFastGrid ? "FastGrid" : "GridView"}]',
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
        child: _useFastGrid
            ? FastGrid(
                itemCount: _gridPaths.length,
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                padding: const EdgeInsets.all(4),
                // Content windowing: each running Lottie holds keyframe
                // buffers + a live render layer — keepAliveCount releases
                // off-window cells (content-agnostic) and rebuilds them as
                // they near the viewport. Value counts ITEMS, not rows
                // (15 ≈ 5 rows each side at 3 columns).
                keepAliveCount: 15,
                itemBuilder: (_, i) => Lottie(
                  asset: _gridPaths[i],
                  loop: true,
                  autoplay: true,
                  fit: LottieFit.contain,
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(4),
                children: [
                  GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      for (final path in _gridPaths)
                        Lottie(
                          asset: path,
                          loop: true,
                          autoplay: true,
                          fit: LottieFit.contain,
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
