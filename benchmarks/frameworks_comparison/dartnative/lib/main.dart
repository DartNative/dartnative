import 'dart:async';

import 'package:dartnative/dartnative.dart';

import 'app_state.dart';
import 'dartnative_plugin_registrant.dart';
import 'screens/cart.dart';
import 'screens/home.dart';
import 'screens/search.dart';
import 'theme.dart';
import 'widgets.dart';

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

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final List<GlobalKey<NavigatorState>> _keys =
      List<GlobalKey<NavigatorState>>.generate(3, (_) => GlobalKey<NavigatorState>());
  late final List<_TopRouteObserver> _observers =
      List<_TopRouteObserver>.generate(3, (_) => _TopRouteObserver(_onRoutesChanged));

  static const List<Widget> _roots = <Widget>[HomeScreen(), SearchScreen(), CartScreen()];

  void _onRoutesChanged() {
    // Observer callbacks can fire while the navigator is building; defer.
    scheduleMicrotask(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: currentTab,
      builder: (BuildContext context, int tab, Widget? _) {
        final bool hideTabBar = _observers[tab].topIsProduct;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) return;
            final NavigatorState? nav = _keys[tab].currentState;
            if (nav != null && nav.canPop()) {
              nav.pop();
            } else {
              SystemNavigator.pop();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: IndexedStack(
                  index: tab,
                  children: <Widget>[
                    for (int i = 0; i < 3; i++)
                      Navigator(
                        key: _keys[i],
                        observers: <NavigatorObserver>[_observers[i]],
                        onGenerateRoute: (RouteSettings s) => PageRoute<void>(
                          settings: s,
                          builder: (BuildContext context) => _roots[i],
                        ),
                      ),
                  ],
                ),
              ),
              if (!hideTabBar) TabBar(selected: tab),
            ],
          ),
        );
      },
    );
  }
}

class _TopRouteObserver extends NavigatorObserver {
  _TopRouteObserver(this.onChange);
  final VoidCallback onChange;
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  bool get topIsProduct => _stack.isNotEmpty && _stack.last.settings.name == productRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    onChange();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    onChange();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    onChange();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final int i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) {
      _stack[i] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    onChange();
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
