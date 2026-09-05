import 'package:dartnative/dartnative.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';

// Toggle: true = FastGrid (UICollectionView, virtualised), false = GridView (all cells in hierarchy)
// Toggle to compare FastGrid against a plain GridView.
const _useFastGrid = true;

/// The 26 unique bundled assets (assets/lotties/0.json … 25.json).
final _uniqueAssetPaths =
    List.generate(26, (i) => 'assets/lotties/$i.json');

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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Light status-bar background (iOS) → dark status-bar content.
        statusBarBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        // Android: dark icons on the light bar.
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFFFFFFFF),
      // See-through iOS 26 bar (same as lottie_grid_demo.dart): the grid scrolls
      // behind the clear glass AppBar. extendBodyBehindAppBar runs the body under
      // the bar; each scroll view's top content-padding clears row 0 at rest.
      extendBodyBehindAppBar: true,
      brightness: Brightness.light,
      appBar: AppBar(
        leading: const BackButton(iconColor: Color(0xFF000000)),
        title: Text(
          'Lottie Grid (Assets) [${_useFastGrid ? "FastGrid" : "GridView"}]',
          style: const TextStyle(
            color: Color(0xFF000000),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _useFastGrid
          ? FastGrid(
              itemCount: _gridPaths.length,
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              // Explicit clearance: a non-null padding opts out of the
              // framework's automatic bar clearance.
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 56,
                left: 4,
                right: 4,
                bottom: 4,
              ),
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
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 56,
                left: 4,
                right: 4,
                bottom: 4,
              ),
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
    );
  }
}
