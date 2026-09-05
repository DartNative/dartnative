/// Full-screen language picker for the SuperTonic demo.
///
/// Pushed by the demo's "Language" row. Shows every language SuperTonic-3
/// supports ([TTSLanguage.all] — 31 of them) as a single scrollable list with
/// the current one check-marked. Tapping a row pops with that language's `code`;
/// tapping the auto-implied back button pops with `null` → the demo keeps its
/// current selection.
library;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_supertonic_tts/dartnative_supertonic_tts.dart';
import '../home/demo_ui.dart';

class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key, required this.selectedCode});

  /// The currently selected language code — its row is check-marked.
  final String selectedCode;

  @override
  Widget build(BuildContext context) {
    final langs = TTSLanguage.all;
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        // Centered screen title. The back button is auto-implied because this
        // route can pop, and is icon-only by default (showBackTitle is false),
        // so it won't drag the previous screen's name in beside the chevron.
        title: Text(
          'Select Language',
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
              top: isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 8,
              bottom: 8),
          children: [
            for (var i = 0; i < langs.length; i++)
              _LanguageRow(
                language: langs[i],
                selected: langs[i].code == selectedCode,
                isLast: i == langs.length - 1,
                onTap: () => Navigator.pop(context, langs[i].code),
              ),
          ],
        ),
      ),
    );
  }
}

/// One row in the picker: the native name, with the English name underneath when
/// it differs, plus a check-mark slot that's only visible for the selected
/// language (reserved always, so row heights stay stable).
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.isLast,
    required this.onTap,
  });

  final TTSLanguage language;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showEnglish = language.nativeName != language.name;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Opaque fill so taps anywhere on the row register (not just on glyphs).
        color: kHomeBg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.nativeName,
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 17,
                          ),
                        ),
                        if (showEnglish) ...[
                          const SizedBox(height: 2),
                          Text(
                            language.name,
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: selected ? 1.0 : 0.0,
                    child: const Text(
                      '✓',
                      style: TextStyle(
                        color: Color(0xFF0A84FF),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                margin: const EdgeInsets.only(left: 20),
                height: 0.5,
                color: kChipBg,
              ),
          ],
        ),
      ),
    );
  }
}
