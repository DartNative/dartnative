/// The parity screen: every widget with its default look and nothing set on
/// it, in the same order as the platform's own screen beside it (the Kotlin
/// app under android/kotlin, the SwiftUI app under ios/swiftui), so the two
/// can be held side by side.
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const ParityScreen());
}

class ParityScreen extends StatefulWidget {
  const ParityScreen({super.key});

  @override
  State<ParityScreen> createState() => _ParityScreenState();
}

class _ParityScreenState extends State<ParityScreen> {
  bool _switch = true;
  bool _check = true;
  int _radio = 0;
  double _slider = 0.4;
  int _segment = 0;
  String? _pick;
  int _tab = 0;
  final TextEditingController _text = TextEditingController();
  final FocusNode _hintFocus = FocusNode();
  final FocusNode _plainFocus = FocusNode();

  /// A tap on the page outside a field puts the keyboard away.
  void _putKeyboardAway() {
    _hintFocus.unfocus();
    _plainFocus.unfocus();
  }

  /// The bar's button switches light and dark in place, so both themes are
  /// compared in one install; null follows the system.
  Brightness? _brightness;

  bool _isDark(BuildContext context) =>
      (_brightness ?? MediaQuery.of(context).platformBrightness) ==
      Brightness.dark;

  /// The same content as the twins' panels, at the same spacing: 8
  /// between the texts, 16 before the button, 20 around.
  /// Material's primary text role on Android, the colour the Kotlin screen's
  /// named text styles (TitleLarge, BodyLarge) carry; a `Text` with only a
  /// size wears the plain TextView colour there, as a TextView with only a
  /// size does. Null on iOS, where the system text colour applies.
  Color? _materialText(BuildContext context) => DynamicColor.colorScheme(
        brightness: _isDark(context) ? Brightness.dark : Brightness.light,
      )?.onSurface;

  /// Switches the app between light and dark, as the Kotlin screen's button
  /// switches its app's night mode.
  void _switchBrightness(BuildContext context) {
    final next = _isDark(context) ? Brightness.light : Brightness.dark;
    // Android rebuilds the screen in the new night mode, as the Kotlin
    // screen's button does, so nothing changes before the rebuild; iOS
    // re-themes the screen in place.
    if (Platform.isIOS) setState(() => _brightness = next);
    setAppBrightness(next);
  }

  Widget _panel(String what) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Native $what',
            style: TextStyle(fontSize: 22, color: _materialText(context))),
        const SizedBox(height: 8),
        if (what == 'sheet')
          const Text('Dismiss this sheet by dragging the grabber down.')
        else
          const Text('Dismiss this dialog by hand, or close it below.'),
        if (what == 'sheet') ...[
          const SizedBox(height: 8),
          Text(
            'Body text with TextAppearance BodyLarge',
            style: TextStyle(fontSize: 16, color: _materialText(context)),
          ),
        ],
        const SizedBox(height: 16),
        Button(title: 'Close', onPressed: () => Navigator.pop(context)),
      ],
    ),
  );

  /// Stacked buttons 8 apart, the same on both platforms, as every
  /// spacing of this screen is; the widgets themselves keep their
  /// defaults (a Material button adds its own 4dp of air above and below).
  List<Widget> _spaced(List<Widget> buttons) => [
    for (var i = 0; i < buttons.length; i++) ...[
      if (i > 0) const SizedBox(height: 8),
      buttons[i],
    ],
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    brightness: _brightness,
    appBar: AppBar(
      title: const Text('System parity (DN)'),
      actions: [
        IconButton(
          icon: Icon(
            _isDark(context)
                ? MaterialSymbolsRounded.light_mode
                : MaterialSymbolsRounded.dark_mode,
          ),
          onPressed: () => _switchBrightness(context),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // One column that hugs its children at the start, as the
        // native screen's vertical layout does.
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _putKeyboardAway,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Plain Text, no style'),
              Text('Title, 22',
                  style: TextStyle(fontSize: 22, color: _materialText(context))),
              Text('Body, 16',
                  style: TextStyle(fontSize: 16, color: _materialText(context))),
              const SizedBox(height: 12),
              ..._spaced([
                Button(
                  title: 'Filled',
                  variant: ButtonVariant.filled,
                  onPressed: () {},
                ),
                Button(
                  title: 'Tinted',
                  variant: ButtonVariant.tinted,
                  onPressed: () {},
                ),
                Button(
                  title: 'Gray',
                  variant: ButtonVariant.gray,
                  onPressed: () {},
                ),
                Button(
                  title: 'Bordered',
                  variant: ButtonVariant.bordered,
                  onPressed: () {},
                ),
                Button(
                  title: 'Plain',
                  variant: ButtonVariant.plain,
                  onPressed: () {},
                ),
                Button(title: 'No variant', onPressed: () {}),
              ]),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: _switch,
                    onChanged: (v) => setState(() => _switch = v),
                  ),
                  const SizedBox(width: 12),
                  const Text('Switch'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _check,
                    onChanged: (v) => setState(() => _check = v ?? false),
                  ),
                  const SizedBox(width: 12),
                  const Text('Checkbox'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Radio<int>(
                    value: 0,
                    groupValue: _radio,
                    onChanged: (v) => setState(() => _radio = v ?? 0),
                  ),
                  const SizedBox(width: 12),
                  const Text('Radio'),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _slider,
                onChanged: (v) => setState(() => _slider = v),
              ),
              const SizedBox(height: 12),
              // The wavy indicators are Material's own; iOS has no wave, so the
              // screen shows them on Android only.
              Row(
                children: [
                  const CircularProgressIndicator(),
                  if (Platform.isAndroid) ...const [
                    SizedBox(width: 16),
                    CircularProgressIndicator(
                      android: AndroidProgressIndicatorStyle(wavy: true),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              const LinearProgressIndicator(value: 0.6),
              if (Platform.isAndroid) ...const [
                SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.6,
                  android: AndroidProgressIndicatorStyle(wavy: true),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                focusNode: _hintFocus,
                decoration: const InputDecoration(
                  labelText: 'Hint',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                focusNode: _plainFocus,
                decoration: const InputDecoration(hintText: 'Plain EditText'),
              ),
              const SizedBox(height: 12),
              SegmentedControl(
                segments: const ['One', 'Two', 'Three'],
                selectedIndex: _segment,
                onValueChanged: (i) => setState(() => _segment = i),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: _pick,
                hint: const Text('Pick'),
                items: [
                  for (final s in const ['One', 'Two', 'Three'])
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (v) => setState(() => _pick = v),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: double.infinity,
                child: Card(padding: EdgeInsets.all(16), child: Text('Card')),
              ),
              const SizedBox(height: 12),
              const ListTile(
                title: Text('List item'),
                subtitle: Text('Supporting text'),
              ),
              const Divider(),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Badge(
                    count: 3,
                    child: Icon(MaterialSymbolsRounded.favorite, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text('Badge'),
                ],
              ),
              const SizedBox(height: 20),
              ..._spaced([
                Button(
                  title: 'Bottom sheet',
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => _panel('sheet'),
                  ),
                ),
                Button(
                  title: 'Modal sheet (medium)',
                  onPressed: () => showModalSheet<void>(
                    context: context,
                    detent: SheetDetent.medium,
                    builder: (_) => _panel('sheet'),
                  ),
                ),
                Button(
                  title: 'Dialog',
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _panel('dialog'),
                  ),
                ),
                Button(
                  title: 'Alert',
                  onPressed: () => showAlert(
                    context: context,
                    title: 'Native alert',
                    message: 'A native alert with a message and a button.',
                    actions: const ['OK'],
                  ),
                ),
              ]),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {},
      child: const Icon(MaterialSymbolsRounded.add),
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) => setState(() => _tab = i),
      items: const [
        BottomNavigationBarItem(
          label: 'Home',
          icon: Icon(MaterialSymbolsRounded.home),
        ),
        BottomNavigationBarItem(
          label: 'Search',
          icon: Icon(MaterialSymbolsRounded.search),
        ),
        BottomNavigationBarItem(
          label: 'Profile',
          icon: Icon(MaterialSymbolsRounded.person),
        ),
      ],
    ),
  );
}
