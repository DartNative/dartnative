import 'package:dartnative/dartnative.dart';

/// One tab's stack of screens.
///
/// DartNative's `Navigator` is one native stack for the whole app
/// (UINavigationController / the Activity back stack), not a widget, so a tab
/// cannot hold a `Navigator` of its own. Each tab keeps its screens here
/// instead and shows the top one in an [IndexedStack], so the screens below
/// keep their state and scroll position, as routes under the top route do.
class TabStack extends ChangeNotifier {
  TabStack(Widget root) {
    _entries.add(_Entry(_Page(key: const ValueKey<int>(0), child: root), false));
  }

  final List<_Entry> _entries = <_Entry>[];
  int _serial = 0;

  List<Widget> get pages => <Widget>[for (final _Entry e in _entries) e.page];

  bool get topIsProduct => _entries.last.isProduct;

  bool get canPop => _entries.length > 1;

  void push(Widget screen, {bool isProduct = false}) {
    _serial++;
    _entries.add(_Entry(_Page(key: ValueKey<int>(_serial), child: screen), isProduct));
    notifyListeners();
  }

  void pop() {
    if (!canPop) return;
    _entries.removeLast();
    notifyListeners();
  }
}

class _Entry {
  _Entry(this.page, this.isProduct);
  final Widget page;
  final bool isProduct;
}

/// An opaque page in a tab's stack.
class _Page extends StatelessWidget {
  const _Page({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Gives the screens of a tab access to the tab's [TabStack].
class TabScope extends InheritedWidget {
  const TabScope({super.key, required this.stack, required super.child});

  final TabStack stack;

  static TabStack of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabScope>()!.stack;

  @override
  bool updateShouldNotify(TabScope oldWidget) => oldWidget.stack != stack;
}

/// Shows the top screen of [stack]; the screens below stay mounted, hidden.
class TabView extends StatefulWidget {
  const TabView({super.key, required this.stack});
  final TabStack stack;

  @override
  State<TabView> createState() => _TabViewState();
}

class _TabViewState extends State<TabView> {
  @override
  void initState() {
    super.initState();
    widget.stack.addListener(_changed);
  }

  @override
  void dispose() {
    widget.stack.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = widget.stack.pages;
    return IndexedStack(index: pages.length - 1, children: pages);
  }
}
