/// GlobalKey demo — showcases GlobalKey.currentContext usage.
///
/// This demo shows how to use GlobalKey to access a widget's BuildContext
/// without passing it through the widget tree. In dartnative, this is
/// particularly useful for:
/// - Accessing native UIKit view contexts
/// - Triggering native operations without context drilling
/// - Navigation and native screen management
///
/// NOTE: This is different from Flutter's GlobalKey — see the comparison
/// section below for framework differences.
import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class GlobalKeyDemo extends StatefulWidget {
  const GlobalKeyDemo({super.key});

  @override
  State<GlobalKeyDemo> createState() => _GlobalKeyDemoState();
}

class _GlobalKeyDemoState extends State<GlobalKeyDemo> {
  // Global keys for different widgets
  final _textWidgetKey = GlobalKey();
  final _containerKey = GlobalKey();

  String _statusText = 'Press buttons to test GlobalKey.currentContext';

  void _testTextWidgetContext() {
    dnLog(
        '[${DateTime.now().millisecondsSinceEpoch}] GlobalKeyDemo: _testTextWidgetContext - accessing _textWidgetKey.currentContext');
    final context = _textWidgetKey.currentContext;
    dnLog(
        '[${DateTime.now().millisecondsSinceEpoch}] GlobalKeyDemo: _textWidgetKey.currentContext = ${context != null ? "found ($context)" : "null"}');
    if (context != null) {
      setState(() {
        _statusText = '✓ Text widget found! Context is mounted and accessible.';
      });
    } else {
      setState(() {
        _statusText =
            '✗ Text widget context not found (widget may be unmounted).';
      });
    }
  }

  void _testContainerContext() {
    dnLog(
        '[${DateTime.now().millisecondsSinceEpoch}] GlobalKeyDemo: _testContainerContext - accessing _containerKey.currentContext');
    final context = _containerKey.currentContext;
    dnLog(
        '[${DateTime.now().millisecondsSinceEpoch}] GlobalKeyDemo: _containerKey.currentContext = ${context != null ? "found ($context)" : "null"}');
    if (context != null) {
      setState(() {
        _statusText =
            '✓ Container widget found! Can now perform actions on it.';
      });
    } else {
      setState(() {
        _statusText = '✗ Container context not found.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    dnLog(
        '[${DateTime.now().millisecondsSinceEpoch}] GlobalKeyDemo: build() called — building screen');
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'GlobalKey.currentContext Demo',
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
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 16,
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info Section ───────────────────────────────────────────
              Text(
                'What is GlobalKey.currentContext?',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'A GlobalKey allows you to access a mounted widget\'s BuildContext '
                  'without passing it through the widget tree. This enables powerful '
                  'patterns like:\n\n'
                  '• Accessing widget contexts from anywhere\n'
                  '• Triggering native UIKit operations\n'
                  '• Navigation and screen management\n'
                  '• Focus and input management\n\n'
                  'STATUS: currentContext is fully functional. currentState is TODO.',
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Test 1: Text Widget ────────────────────────────────────
              Text(
                'Test 1: Access Text Widget',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'I am a Text widget with a GlobalKey',
                      key: _textWidgetKey,
                      style: const TextStyle(
                        color: Color(0xFF3498DB),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Button(
                      onPressed: _testTextWidgetContext,
                      title: 'Get Text Widget Context',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Test 2: Container Widget ───────────────────────────────
              Text(
                'Test 2: Access Container Widget',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                key: _containerKey,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'I am a Container with a GlobalKey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Button(
                      onPressed: _testContainerContext,
                      title: 'Get Container Context',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Status Display ──────────────────────────────────────────
              Text(
                'Status',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3498DB),
                    width: 1,
                  ),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(
                    color: Color(0xFF3498DB),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // ── dartnative vs Flutter Comparison ────────────────────────
              Text(
                'dartnative vs Flutter GlobalKey',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DIFFERENCES FROM FLUTTER:\n\n'
                  '• Native Backing: dartnative GlobalKey accesses native UIKit views, '
                  'not RenderObjects. currentContext points to actual native elements.\n\n'
                  '• Simpler Element Model: No render/paint/layout layer — just a single '
                  'Element-per-widget model that maps directly to native views.\n\n'
                  '• Dependency Injection: The lookup callback is injected at runtime to '
                  'avoid circular imports (framework design detail).\n\n'
                  '• currentState Status: NOT YET IMPLEMENTED. Available: currentContext only.\n\n'
                  '• Use Cases: Primarily for accessing native view contexts and triggering '
                  'UIKit operations, not Skia re-paints.',
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                    height: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Use Case Example ────────────────────────────────────────
              Text(
                'Common Use Cases',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '1. StatefulWidget State Access\n'
                  '   Access a stateful widget\'s state from outside without context drilling.\n\n'
                  '2. Form Validation Errors\n'
                  '   Validate a form field and scroll to the error without passing context.\n\n'
                  '3. Navigation\n'
                  '   Navigate to a new screen or show a dialog from any callback.\n\n'
                  '4. Focus Management\n'
                  '   Request focus on a TextField from anywhere in your app.\n\n'
                  '5. Scroll Position\n'
                  '   Scroll to a specific item in a ListView without parent context.',
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                    height: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
