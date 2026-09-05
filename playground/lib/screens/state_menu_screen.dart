/// State Management — sub-menu screen.
///
/// Lists the two state demos (Basics, Store + Provided) so the main
/// playground only needs one "State Management" entry.
import 'package:dartnative/dartnative.dart';

import 'state_basics_demo.dart';
import 'state_store_demo.dart';
import 'home/demo_ui.dart';

class StateMenuScreen extends StatelessWidget {
  const StateMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'State Management',
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
        child: ListView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 24,
            bottom: 24,
          ),
          children: [
            _StateCard(
              title: 'Basics',
              body: 'Signal<T>, Computed<T>, effect(), and Listenable.watch(). '
                  'Counter + toggle + ChangeNotifier bridge — all in '
                  'StatelessWidgets, no setState.',
              onTap: (ctx) => Navigator.push(
                ctx,
                PageRoute(
                  builder: (_) => const StateBasicsDemo(),
                  settings: '/state-basics',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StateCard(
              title: 'Store + Provided',
              body:
                  'Store pattern: plain Dart class with signal fields + actions. '
                  'Two task lists each with their own TaskStore instance, '
                  'injected via Provided<T>.',
              onTap: (ctx) => Navigator.push(
                ctx,
                PageRoute(
                  builder: (_) => const StateStoreDemo(),
                  settings: '/state-store',
                ),
              ),
            ),
            const SizedBox(height: 36),
            const _WhySection(),
          ],
        ),
      ),
    );
  }
}

class _WhySection extends StatelessWidget {
  const _WhySection();

  static const _bullets = [
    'Access state from services, repositories, and callbacks.',
    'Watch a value and rebuild a widget when it changes.',
    'Update state from anywhere.',
    'Hand a per-subtree value down without prop-drilling.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simple, yet powerful',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The things you actually need in real apps:',
          style: TextStyle(color: kTextSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        for (final bullet in _bullets) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ',
                  style: TextStyle(color: kTextSecondary, fontSize: 14)),
              Expanded(
                child: Text(bullet,
                    style: TextStyle(color: kTextSecondary, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        const SizedBox(height: 12),
        Text(
          'Everything else — scopes, refs, families, providers, consumer base '
          'classes — exists to solve problems that come from a specific '
          'library\'s design choices, not from the apps themselves. Dropping '
          'those concepts leaves: one type to learn (Signal<T>), one extension '
          '(.watch(context)), one bridge (Listenable.watch), one helper '
          '(Provided<T>).',
          style: TextStyle(color: kTextTertiary, fontSize: 13),
        ),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final void Function(BuildContext ctx) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        decoration: BoxDecoration(
          color: kTileBg,
          borderRadius: BorderRadius.circular(34),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
