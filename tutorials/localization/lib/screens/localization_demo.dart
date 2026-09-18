/// The whole tutorial in one screen: text that changes language, a picker,
/// and the three things ARB files do beyond plain strings — placeholders,
/// plurals, and formatted dates and numbers.
library;

import 'package:dartnative/dartnative.dart';

import '../generated/l10n.dart';
import '../main.dart' show languageProvider, prefs;
import '../state/language_provider.dart';

class LocalizationDemo extends StatefulWidget {
  const LocalizationDemo({super.key});

  @override
  State<LocalizationDemo> createState() => _LocalizationDemoState();
}

class _LocalizationDemoState extends State<LocalizationDemo> {
  int _messages = 0;

  @override
  Widget build(BuildContext context) {
    // Watching the signal is what makes the whole screen re-read S() when
    // the language changes. The provider loads the new messages before it
    // sets the signal, so this rebuild already sees them.
    final current = languageProvider.languageSignal.watch(context);

    return Scaffold(
      appBar: AppBar(title: Text(S().app_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Plain text and a placeholder ────────────────────────────
          Text(
            S().greeting('Ada'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(S().language_current(current.name)),

          const SizedBox(height: 28),
          _SectionTitle(S().language_section),
          for (final language in supportedAppLanguages)
            _LanguageRow(
              language: language,
              selected: language == current,
              onTap: () => languageProvider.changeLanguage(prefs, language),
            ),

          // ── One message, four forms, chosen by the number ───────────
          const SizedBox(height: 28),
          _SectionTitle(S().counter_section),
          Text(
            S().messages_count(_messages),
            style: const TextStyle(fontSize: 17),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Button(
                title: S().add_message,
                onPressed: () => setState(() => _messages++),
              ),
              const SizedBox(width: 12),
              Button(
                title: S().clear_messages,
                onPressed: () => setState(() => _messages = 0),
              ),
            ],
          ),

          // ── Dates and money, written the way each language writes them ──
          const SizedBox(height: 28),
          _SectionTitle(S().dates_section),
          Text(S().today_is(DateTime.now())),
          const SizedBox(height: 4),
          Text(S().price_is(12.5)),

          const SizedBox(height: 28),
          Text(
            S().restart_note,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E8E93),
          ),
        ),
      );
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.name, style: const TextStyle(fontSize: 17)),
              if (selected)
                const Icon(CupertinoIcons.checkmark, size: 18),
            ],
          ),
        ),
      );
}
