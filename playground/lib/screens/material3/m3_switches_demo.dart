/// Material 3 switches — the real MaterialSwitch anatomy.
///
/// The generic Switch widget maps to com.google.android.material.materialswitch
/// .MaterialSwitch on Android, with no opt-in: a 52x32dp track that carries an
/// outline while off, and a thumb that grows 16dp → 24dp as it checks. The
/// `android:` group (AndroidSwitchStyle) adds the M3-only extras — the thumb
/// check mark and its size. On iOS the same widget stays UISwitch.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class M3SwitchesDemo extends StatefulWidget {
  const M3SwitchesDemo({super.key});

  @override
  State<M3SwitchesDemo> createState() => _M3SwitchesDemoState();
}

class _M3SwitchesDemoState extends State<M3SwitchesDemo> {
  bool _plain = true;
  bool _withIcon = true;
  bool _bigIcon = true;
  bool _tinted = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Switches',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 16,
          bottom: 16,
        ),
        children: [
          _SectionHeader('Stock'),
          const SizedBox(height: 4),
          _SectionSubtitle('Switch — no android: group needed'),
          const SizedBox(height: 12),
          _card(
            children: [
              _row(
                'Wi-Fi',
                Switch(
                  value: _plain,
                  onChanged: (v) => setState(() => _plain = v),
                ),
              ),
              const SizedBox(height: 8),
              _caption(
                'Material 3 colours from the theme — colorPrimary when on, '
                'outlined track when off. The thumb grows as it checks.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Check mark'),
          const SizedBox(height: 4),
          _SectionSubtitle('android: AndroidSwitchStyle(checkIcon: true)'),
          const SizedBox(height: 12),
          _card(
            children: [
              _row(
                'Bluetooth',
                Switch(
                  value: _withIcon,
                  onChanged: (v) => setState(() => _withIcon = v),
                  android: const AndroidSwitchStyle(checkIcon: true),
                ),
              ),
              const SizedBox(height: 8),
              _row(
                'Larger icon',
                Switch(
                  value: _bigIcon,
                  onChanged: (v) => setState(() => _bigIcon = v),
                  android: const AndroidSwitchStyle(
                    checkIcon: true,
                    thumbIconSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _caption('thumbIconSize 20 — Material default is 16'),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Tinted'),
          const SizedBox(height: 4),
          _SectionSubtitle('The four Flutter colour params still apply'),
          const SizedBox(height: 12),
          _card(
            children: [
              _row(
                'Focus mode',
                Switch(
                  value: _tinted,
                  onChanged: (v) => setState(() => _tinted = v),
                  activeTrackColor: const Color(0xFFFF9500),
                  android: const AndroidSwitchStyle(checkIcon: true),
                ),
              ),
              const SizedBox(height: 8),
              _caption(
                'Only the ON track is set — every other state keeps its '
                'Material 3 colour.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, Widget control) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(color: kTextPrimary, fontSize: 15),
        ),
      ),
      control,
    ],
  );

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: kRowBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(children: children),
  );

  Widget _caption(String text) =>
      Text(text, style: TextStyle(color: kTextSecondary, fontSize: 12));
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: kTextPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SectionSubtitle extends StatelessWidget {
  const _SectionSubtitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: kTextSecondary, fontSize: 12));
  }
}
