import 'package:dartnative/dartnative.dart';

import '../repositories/app_repository.dart';
import '../widgets/empty_state.dart';

/// A placeholder behind drawer items that have no screen yet.
///
/// Replace these with your real screens one by one. Keeping the stub means
/// the drawer navigation pattern stays demonstrable from day one.
class StubScreen extends StatelessWidget {
  const StubScreen({
    super.key,
    required this.title,
    this.icon = MaterialSymbolsRounded.construction,
  });

  final String title;

  /// Shown by the empty state, usually the drawer item's own icon so the
  /// screen feels like the place the user asked for.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = (AppRepository.themeState..watch(context)).palette;
    return Scaffold(
      backgroundColor: p.bg,
      brightness: p.brightness,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: p.text,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: p.bg,
      ),
      body: EmptyState(
        icon: icon,
        title: 'This screen is yours to build',
        message: 'It exists so the drawer has somewhere to navigate. '
            'Replace it with your real $title screen.',
      ),
    );
  }
}
