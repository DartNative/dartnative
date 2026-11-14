import 'package:dartnative/dartnative.dart';

import 'app_state.dart';
import 'dartnative_plugin_registrant.dart';
import 'nav.dart';
import 'screens/cart.dart';
import 'screens/home.dart';
import 'screens/search.dart';
import 'theme.dart';

/// Launch timing lines for diagnosis, compiled in only with
/// `--dart-define=SHOPBENCH_DIAG=true` (the benchmark build has none).
const bool kShopbenchDiag = bool.fromEnvironment('SHOPBENCH_DIAG');

void diag(String what) {
  if (kShopbenchDiag) print('SHOPBENCH_DIAG $what');
}

void main() {
  diag('main');
  DartNativePluginRegistrant.registerAll();
  runApp(const EverbloomApp());
  diag('runApp returned');
  WidgetsBinding.instance.addPostFrameCallback((_) => diag('first frame'));
}

class EverbloomApp extends StatelessWidget {
  const EverbloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App(
      title: 'Everbloom',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData.light(),
      home: const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.background,
          brightness: Brightness.light,
          body: Shell(),
        ),
      ),
    );
  }
}

/// The three tabs, each with its own stack of screens, and the bottom bar.
final List<TabStack> tabStacks = <TabStack>[
  TabStack(const HomeScreen()),
  TabStack(const SearchScreen()),
  TabStack(const CartScreen()),
];

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final List<Widget> _tabs = <Widget>[
    for (final TabStack s in tabStacks) TabScope(stack: s, child: TabView(stack: s)),
  ];

  @override
  void initState() {
    super.initState();
    currentTab.addListener(_changed);
    for (final TabStack s in tabStacks) {
      s.addListener(_changed);
    }
  }

  @override
  void dispose() {
    currentTab.removeListener(_changed);
    for (final TabStack s in tabStacks) {
      s.removeListener(_changed);
    }
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final int tab = currentTab.value;
    final bool hideTabBar = tabStacks[tab].topIsProduct;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        final TabStack stack = tabStacks[currentTab.value];
        if (stack.canPop) {
          stack.pop();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: IndexedStack(index: tab, children: _tabs)),
          if (!hideTabBar) TabBar(selected: tab),
        ],
      ),
    );
  }
}

class TabBar extends StatelessWidget {
  const TabBar({super.key, required this.selected});
  final int selected;

  @override
  Widget build(BuildContext context) {
    final double itemWidth = MediaQuery.sizeOf(context).width / 3;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 49,
          child: Row(
            children: <Widget>[
              _TabItem(index: 0, selected: selected, id: 'tab-home', label: 'Home', icon: AppIcon.home, width: itemWidth),
              _TabItem(index: 1, selected: selected, id: 'tab-search', label: 'Search', icon: AppIcon.search, width: itemWidth),
              _TabItem(index: 2, selected: selected, id: 'tab-cart', label: 'Cart', icon: AppIcon.cart, width: itemWidth, badge: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.index,
    required this.selected,
    required this.id,
    required this.label,
    required this.icon,
    required this.width,
    this.badge = false,
  });

  final int index;
  final int selected;
  final String id;
  final String label;
  final AppIcon icon;
  final double width;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final bool active = index == selected;
    final Color color = active ? AppColors.text : AppColors.textMuted;
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: Semantics(
              container: true,
              identifier: id,
              button: true,
              selected: active,
              label: label,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => currentTab.value = index,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    VectorIcon(icon, color: color),
                    const SizedBox(height: 2),
                    Text(label,
                        style: ts(11,
                            weight: active ? FontWeight.w600 : FontWeight.w500, color: color)),
                  ],
                ),
              ),
            ),
          ),
          // The badge sits beside the tab's element, so XCUITest sees it as an
          // element of its own; touches on it reach the tab below.
          if (badge)
            Positioned(
              top: 4,
              left: width / 2 + 6,
              child: const IgnorePointer(child: _CartBadge()),
            ),
        ],
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  const _CartBadge();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cartStore,
      builder: (BuildContext context, Widget? _) {
        final int count = cartStore.totalQuantity;
        if (count <= 0) return const SizedBox.shrink();
        return Semantics(
          container: true,
          identifier: 'cart-badge',
          label: '$count',
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sale,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$count',
                style: ts(11, weight: FontWeight.w700, color: AppColors.background, lineHeight: 13)),
          ),
        );
      },
    );
  }
}
