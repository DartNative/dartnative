/// Core system components demo.
///
/// Showcases native UIKit / Android controls mapped through dartnative:
/// UISwitch, UISlider, UIButton, UIAlertController, UITabBar, UIDatePicker.
import 'dart:async';
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart'
    hide showMediaPicker, MediaPickerType, MediaFile;
import 'package:dartnative_media_picker/dartnative_media_picker.dart';
import 'home/demo_ui.dart';

class SystemComponentsDemo extends StatefulWidget {
  const SystemComponentsDemo({super.key});

  @override
  State<SystemComponentsDemo> createState() => _SystemComponentsDemoState();
}

class _SystemComponentsDemoState extends State<SystemComponentsDemo> {
  // ── Switch state ──────────────────────────────────────────────────────────
  bool _switch1 = true;
  bool _switch2 = false;

  // ── Slider state ──────────────────────────────────────────────────────────
  double _slider1 = 0.5;
  double _slider2 = 50;

  // ── Button state ──────────────────────────────────────────────────────────
  int _buttonTapCount = 0;

  // ── Alert state ───────────────────────────────────────────────────────────
  String _alertResult = 'No alert shown yet';

  // ── Action sheet state ────────────────────────────────────────────────────
  String _actionSheetResult = 'No action sheet shown yet';

  // ── Cupertino native sheet state ──────────────────────────────────────────
  String _sheetResult = 'No sheet shown yet';

  // ── Bottom overlay state ──────────────────────────────────────────────────
  String _overlayResult = 'No overlay shown yet';

  // ── Tab bar state ─────────────────────────────────────────────────────────
  int _selectedTab = 0;

  /// Device Material You dark scheme — see the Bottom Navigation Bar below.
  /// Null on iOS / pre-Android-12, which fall back to the framework default.
  static final ColorScheme? _dynamicScheme =
      DynamicColor.colorScheme(brightness: Brightness.dark);

  // ── Date picker state ─────────────────────────────────────────────────────
  String _pickedDate = 'No date picked yet';

  // ── Media picker state ────────────────────────────────────────────────────
  String _pickedMedia = 'No media picked yet';

  // ── Segmented Control state ───────────────────────────────────────────────
  int _segmentIndex = 0;

  // ── Checkbox state ────────────────────────────────────────────────────────
  bool? _checkbox1 = false;
  bool? _checkbox2 = true;
  bool? _checkboxTristate; // starts null (indeterminate)

  // ── Radio state ───────────────────────────────────────────────────────────
  String _radioSelected = 'b';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      // Trait declaration: native controls (segmented thumb, sheets,
      // keyboards) are trait-adaptive — follow the app theme, not the device.
      brightness: playgroundPalette.brightness,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'System Components',
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
            left: 16,
            right: 16,
            top: isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 16,
            bottom: 16,
          ),
          children: [
            // ── 1. Switch ───────────────────────────────────────────────────
            _SectionHeader('Switch'),
            const SizedBox(height: 4),
            _SectionSubtitle('UISwitch · android.widget.Switch'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Default',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Switch(
                        value: _switch1,
                        onChanged: (v) => setState(() => _switch1 = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Custom colors',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Switch(
                        value: _switch2,
                        onChanged: (v) => setState(() => _switch2 = v),
                        activeThumbColor: const Color(0xFFFFFFFF),
                        activeTrackColor: const Color(0xFFFF9500),
                        inactiveThumbColor: const Color(0xFFFFFFFF),
                        inactiveTrackColor: kChevron,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Disabled (on)',
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Switch(value: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 2. Slider ───────────────────────────────────────────────────
            _SectionHeader('Slider'),
            const SizedBox(height: 4),
            _SectionSubtitle('UISlider · android.widget.SeekBar'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Default',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        _slider1.toStringAsFixed(2),
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Slider(
                    value: _slider1,
                    onChanged: (v) => setState(() => _slider1 = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Custom range (0–100)',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        _slider2.toStringAsFixed(0),
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Slider(
                    value: _slider2,
                    min: 0,
                    max: 100,
                    onChanged: (v) => setState(() => _slider2 = v),
                    activeColor: const Color(0xFFFF9500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 3. Button ───────────────────────────────────────────────────
            _SectionHeader('Button'),
            const SizedBox(height: 4),
            _SectionSubtitle(
                'UIButton · MaterialButton'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Button(
                    title: 'Filled (taps: $_buttonTapCount)',
                    variant: ButtonVariant.filled,
                    onPressed: () => setState(() => _buttonTapCount++),
                  ),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Tinted',
                    variant: ButtonVariant.tinted,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Gray',
                    variant: ButtonVariant.gray,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Bordered',
                    variant: ButtonVariant.bordered,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Plain',
                    variant: ButtonVariant.plain,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Custom Color',
                    variant: ButtonVariant.filled,
                    color: const Color(0xFFFF9500),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Fully Rounded (Stadium)',
                    variant: ButtonVariant.filled,
                    shape: const StadiumBorder(),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Squircle',
                    variant: ButtonVariant.filled,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  // ── Sign-in buttons ──────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sign-in style',
                      style: TextStyle(
                        color: kTextTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // fixed height: 44
                  if (Platform.isIOS)
                    Button(
                      title: 'Sign in with Apple',
                      imageAsset: 'assets/apple-logo.png',
                      foregroundColor: Colors.white,
                      color: const Color(0xFF000000),
                      shape: const StadiumBorder(),
                      height: 44,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      imageSize: 23,
                      onPressed: () {},
                    )
                  else
                    Button(
                      title: 'Sign in with Google',
                      imageAsset: 'assets/google-logo.png',
                      foregroundColor: Colors.white,
                      color: const Color(0xFF0169FF),
                      shape: const StadiumBorder(),
                      height: 44,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      imageSize: 23,
                      onPressed: () {},
                    ),
                  const SizedBox(height: 8),
                  // padding-based height: vertical: 13 → content + 26pt
                  if (Platform.isIOS)
                    Button(
                      title: 'Sign in with Google',
                      imageAsset: 'assets/google-logo.png',
                      foregroundColor: Colors.white,
                      color: const Color(0xFF0169FF),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 20,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      imageSize: 23,
                      onPressed: () {},
                    )
                  else
                    Button(
                      title: 'Sign in with Apple',
                      imageAsset: 'assets/apple-logo.png',
                      foregroundColor: Colors.white,
                      color: const Color(0xFF000000),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 20,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      imageSize: 23,
                      onPressed: () {},
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 4. Alert Dialog ─────────────────────────────────────────────
            _SectionHeader('Alert Dialog'),
            const SizedBox(height: 4),
            _SectionSubtitle('UIAlertController · AlertDialog'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Button(
                    title: 'Show Alert',
                    variant: ButtonVariant.filled,
                    onPressed: () async {
                      final index = await showAlert(
                        context: context,
                        title: 'Hello',
                        message: 'This is a native alert dialog.',
                        actions: ['Cancel', 'OK', 'Delete'],
                      );
                      setState(() {
                        _alertResult = 'Tapped action index: $index';
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _alertResult,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 4b. Action Sheet ────────────────────────────────────────────
            _SectionHeader('Action Sheet'),
            const SizedBox(height: 4),
            _SectionSubtitle('UIAlertController(.actionSheet)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Button(
                    title: 'Show Action Sheet',
                    variant: ButtonVariant.filled,
                    onPressed: () async {
                      final index = await showActionSheet(
                        context: context,
                        title: 'Choose an option',
                        message: 'This is a native action sheet.',
                        actions: ['Save', 'Share', 'Delete'],
                        cancelLabel: 'Cancel',
                        destructiveIndices: const [2],
                      );
                      setState(() {
                        _actionSheetResult = index == -1
                            ? 'Cancelled'
                            : 'Tapped action index: $index';
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _actionSheetResult,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 4c. Native Modal Sheet ───────────────────────────────────────────
            // iOS-only: UISheetPresentationController has no Android equivalent.
            if (Platform.isIOS) ...[
              _SectionHeader('Native Modal Sheet'),
              const SizedBox(height: 4),
              _SectionSubtitle(
                  'UISheetPresentationController · grab handle · swipe-to-dismiss'),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Button(
                      title: 'Show Modal Sheet (drag handle)',
                      variant: ButtonVariant.filled,
                      onPressed: () async {
                        final result = await showModalSheet<String>(
                          context: context,
                          // fitContent: the sheet hugs its content height.
                          detent: SheetDetent.fitContent,
                          backgroundColor: kBarBg,
                          builder: (_) => const _DemoSheetContent(),
                        );
                        setState(() {
                          _sheetResult = result ?? 'Dismissed';
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // The messenger-style editor panel: medium detent, no
                    // grab handle, close/done as standalone system glass
                    // buttons in the content.
                    Button(
                      title: 'Show Modal Sheet (header buttons)',
                      variant: ButtonVariant.filled,
                      onPressed: () async {
                        // Declared header — the framework renders it.
                        final result = await showModalSheet<String>(
                          context: context,
                          detent: SheetDetent.medium,
                          backgroundColor: playgroundPalette.brightness ==
                                  Brightness.dark
                              ? kBarBg
                              : const Color(0xFFF2F2F7),
                          showDragHandle: false,
                          header: SheetHeader(
                            title: 'Editor',
                            close: BarButtonItem(
                              icon: 'xmark',
                              onPressed: () =>
                                  Navigator.pop(context, 'Closed'),
                            ),
                            action: BarButtonItem(
                              icon: 'checkmark',
                              prominent: true,
                              titleStyle:
                                  const TextStyle(color: Color(0xFF007AFF)),
                              onPressed: () => Navigator.pop(context, 'Done'),
                            ),
                          ),
                          builder: (_) => const _HeaderSheetContent(),
                        );
                        setState(() {
                          _sheetResult = result ?? 'Dismissed';
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sheetResult,
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── 4d. Bottom Overlay ────────────────────────────────────────────
            _SectionHeader('Bottom Overlay'),
            const SizedBox(height: 4),
            _SectionSubtitle(
                'VC containment · content-fit · tap-outside-to-dismiss'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Button(
                    title: 'Show Bottom Overlay',
                    variant: ButtonVariant.filled,
                    onPressed: () async {
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        // The sheet demo's surface: the field's grey fill
                        // (kTileBg) has to read against the card.
                        backgroundColor: kBarBg,
                        builder: (_) => const _DemoOverlayContent(),
                      );
                      setState(() {
                        _overlayResult = result ?? 'Dismissed (tap outside)';
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _overlayResult,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Button(
                    title: 'Show Keyboard Overlay',
                    variant: ButtonVariant.filled,
                    onPressed: () {
                      // Measured out here, in the screen's own context: the
                      // panel is mounted in the keyboard's window, and its
                      // tree is not the one holding the keyboard inset.
                      final media = MediaQuery.of(context);
                      final keyboard = media.viewInsets.bottom;
                      showKeyboardOverlay<void>(
                        context: context,
                        builder: (_) => _KeyboardOverlayCard(
                          left: 16,
                          top: media.size.height -
                              keyboard -
                              _kKeyboardOverlayCard -
                              16,
                          width: media.size.width - 32,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An overlay that shows above the keyboard. See ChatGPT '
                    'Picker in Showcase for it in use.',
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 5. Segmented Control ─────────────────────────────────────────
            _SectionHeader('Segmented Control'),
            const SizedBox(height: 4),
            _PlatformSubtitle(
              iosName: 'UISegmentedControl',
              androidName: 'LinearLayout + MaterialButton',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Full palette set: pass label styles alongside a custom
                  // indicatorColor so both themes render intentionally.
                  SegmentedControl(
                    backgroundColor: kSegBg,
                    indicatorColor: kSegTint,
                    labelFontStyle: TextStyle(color: kTextSecondary),
                    selectedLabelFontStyle: TextStyle(color: kTextPrimary),
                    segments: const ['Grid', 'Masonry', 'Infinite Grid'],
                    selectedIndex: _segmentIndex,
                    onValueChanged: (i) => setState(() => _segmentIndex = i),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selected segment: $_segmentIndex',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 6. Bottom Navigation Bar ────────────────────────────────────
            _SectionHeader('Bottom Navigation Bar'),
            const SizedBox(height: 4),
            _PlatformSubtitle(
              iosName: 'UITabBar',
              androidName: 'BottomNavigationView',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  BottomNavigationBar(
                    currentIndex: _selectedTab,
                    onTap: (index) => setState(() => _selectedTab = index),
                    labelFontStyle: TextStyle(
                      fontSize: 13,
                      color: kTextSecondary,
                    ),
                    selectedLabelFontStyle: TextStyle(
                      color: kTextPrimary,
                    ),
                    iconColor: kTextSecondary,
                    // Dark theme: M3's default indicator (`secondaryContainer`)
                    // is a dark tone that vanishes against this dark row, so
                    // take the light end of the same wallpaper palette. Light
                    // theme: keep the framework default — the pale tint reads
                    // well — with a dark glyph rather than the old hardcoded
                    // white, which was invisible on it.
                    indicatorColor: playgroundPalette.brightness == Brightness.dark
                        ? _dynamicScheme?.primary
                        : null,
                    selectedIconColor:
                        playgroundPalette.brightness == Brightness.dark
                            ? (_dynamicScheme?.onPrimary ?? kTextPrimary)
                            : kTextPrimary,
                    items: [
                      BottomNavigationBarItem(
                        label: 'Home',
                        icon: const Icon(CupertinoIcons.house_fill),
                      ),
                      BottomNavigationBarItem(
                        label: 'Search',
                        icon: const Icon(CupertinoIcons.search),
                      ),
                      BottomNavigationBarItem(
                        label: 'Profile',
                        icon: const Icon(CupertinoIcons.person_fill),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selected tab: $_selectedTab',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 7. Media Picker ──────────────────────────────────────────────
            _SectionHeader('Media Picker'),
            const SizedBox(height: 4),
            _SectionSubtitle('PHPickerViewController · ACTION_PICK_IMAGES'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Button(
                    title: 'Pick Image',
                    variant: ButtonVariant.tinted,
                    onPressed: () async {
                      final files = await showMediaPicker(
                        type: MediaPickerType.images,
                      );
                      setState(() {
                        _pickedMedia = files.isEmpty
                            ? 'Cancelled'
                            : files
                                .map((f) => '${f.type}: ${f.name}')
                                .join('\n');
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Pick Video',
                    variant: ButtonVariant.tinted,
                    onPressed: () async {
                      final files = await showMediaPicker(
                        type: MediaPickerType.videos,
                      );
                      setState(() {
                        _pickedMedia = files.isEmpty
                            ? 'Cancelled'
                            : files
                                .map((f) => '${f.type}: ${f.name}')
                                .join('\n');
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Pick Multiple (up to 3)',
                    variant: ButtonVariant.tinted,
                    onPressed: () async {
                      final files = await showMediaPicker(
                        type: MediaPickerType.imagesAndVideos,
                        maxSelection: 3,
                      );
                      setState(() {
                        _pickedMedia = files.isEmpty
                            ? 'Cancelled'
                            : '${files.length} file(s):\n${files.map((f) => '${f.type}: ${f.name}').join('\n')}';
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pickedMedia,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 8. Date Picker ──────────────────────────────────────────────
            _SectionHeader('Date Picker'),
            const SizedBox(height: 4),
            _PlatformSubtitle(
              iosName: 'UIDatePicker',
              androidName: 'DatePickerDialog',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Button(
                    title: 'Pick Date',
                    variant: ButtonVariant.tinted,
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        mode: NativeDatePickerMode.date,
                      );
                      // Null = dismissed without picking (Flutter contract).
                      if (date == null) return;
                      setState(() {
                        _pickedDate =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Pick Date & Time',
                    variant: ButtonVariant.tinted,
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        mode: NativeDatePickerMode.dateAndTime,
                      );
                      if (date == null) return;
                      setState(() {
                        _pickedDate =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pickedDate,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ── 9. Checkbox ─────────────────────────────────────────────────
            _SectionHeader('Checkbox'),
            const SizedBox(height: 4),
            _PlatformSubtitle(
              iosName: 'UIButton + SF Symbol · tristate supported',
              androidName: 'MaterialCheckBox · tristate supported',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _checkbox1,
                        onChanged: (v) => setState(() => _checkbox1 = v),
                        activeColor: const Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Unchecked → checked',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _checkbox2,
                        onChanged: (v) => setState(() => _checkbox2 = v),
                        activeColor: const Color(0xFF34C759),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pre-checked (green tint)',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _checkboxTristate,
                        tristate: true,
                        onChanged: (v) => setState(() => _checkboxTristate = v),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tristate (${_checkboxTristate == null ? "indeterminate" : _checkboxTristate! ? "checked" : "unchecked"})',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 10. Radio ────────────────────────────────────────────────────
            _SectionHeader('Radio'),
            const SizedBox(height: 4),
            _PlatformSubtitle(
              iosName: 'UIButton + SF Symbol · circle.inset.filled',
              androidName: 'RadioButton',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (final (idx, (value, label)) in [
                    ('a', 'Option A'),
                    ('b', 'Option B — selected by default'),
                    ('c', 'Option C'),
                  ].indexed) ...[
                    if (idx > 0) const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<String>(
                          value: value,
                          groupValue: _radioSelected,
                          onChanged: (v) => setState(
                            () => _radioSelected = v ?? _radioSelected,
                          ),
                          activeColor: const Color(0xFF007AFF),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 11. FloatingActionButton ─────────────────────────────────────
            _SectionHeader('FloatingActionButton'),
            const SizedBox(height: 4),
            _SectionSubtitle('Circular UIButton · SF Symbol · shadow'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      FloatingActionButton(
                        child: const Icon(MaterialSymbolsRounded.add),
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: const Color(0xFFFFFFFF),
                        onPressed: () => setState(() => _buttonTapCount++),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Regular',
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      FloatingActionButton(
                        child: const Icon(CupertinoIcons.pencil),
                        backgroundColor: const Color(0xFF34C759),
                        foregroundColor: const Color(0xFFFFFFFF),
                        mini: true,
                        onPressed: () => setState(() => _buttonTapCount++),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mini',
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      FloatingActionButton(
                        child: const Icon(CupertinoIcons.trash),
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: const Color(0xFFFFFFFF),
                        onPressed: () {},
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Custom sig.',
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 12. Card / ListTile / Badge ───────────────────────────────────
            _SectionHeader('Card / ListTile / Badge'),
            const SizedBox(height: 4),
            _SectionSubtitle(
              'Pure Dart composites built on Container + Row + Stack',
            ),
            const SizedBox(height: 12),
            Card(
              color: kRowBg,
              elevation: 4,
              borderRadius: 12.0,
              child: Column(
                children: [
                  ListTile(
                    leading: Badge(
                      label: '3',
                      badgeColor: const Color(0xFFFF3B30),
                      labelColor: const Color(0xFFFFFFFF),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kChevron,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.person,
                          size: 22,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                    title: Text(
                      'Bob',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Unread messages: 3',
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: kTextSecondary,
                    ),
                  ),
                  ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/avatar.jpg',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      'Lisa',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Online',
                      style: TextStyle(color: Color(0xFF34C759), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 13. Wrap / Flow Layout ────────────────────────────────────────
            _SectionHeader('Wrap'),
            const SizedBox(height: 4),
            _SectionSubtitle(
              'Flow layout — items wrap to the next line automatically',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in [
                    'SwiftUI',
                    'Compose',
                    'Yoga',
                    'UIKit',
                    'FlexLayout',
                    'Dart',
                    'Flutter',
                    'dartnative',
                    'Signals',
                    'Provided',
                    'MVVM',
                    'Clean Arch',
                  ])
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kTileBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── 14. Icon ─────────────────────────────────────────────────────
            _SectionHeader('Icon'),
            const SizedBox(height: 4),
            _SectionSubtitle(
              'CupertinoIcons · MaterialSymbolsRounded · both fonts registered',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CupertinoIcons',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(CupertinoIcons.house, color: kTextPrimary, size: 24),
                      Icon(CupertinoIcons.heart,
                          color: Color(0xFFFF3B30), size: 24),
                      Icon(CupertinoIcons.heart_fill,
                          color: Color(0xFFFF3B30), size: 24),
                      Icon(CupertinoIcons.bell, color: kTextPrimary, size: 24),
                      Icon(CupertinoIcons.checkmark,
                          color: Color(0xFF34C759), size: 24),
                      Icon(CupertinoIcons.xmark,
                          color: kTextSecondary, size: 24),
                      Icon(CupertinoIcons.person,
                          color: kTextPrimary, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MaterialSymbolsRounded',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(MaterialSymbolsRounded.home,
                          color: kTextPrimary, size: 24),
                      Icon(MaterialSymbolsRounded.favorite,
                          color: Color(0xFFFF3B30), size: 24),
                      Icon(MaterialSymbolsRounded.star,
                          color: Color(0xFFFFCC00), size: 24),
                      Icon(MaterialSymbolsRounded.check,
                          color: Color(0xFF34C759), size: 24),
                      Icon(MaterialSymbolsRounded.close,
                          color: kTextSecondary, size: 24),
                      Icon(MaterialSymbolsRounded.person,
                          color: kTextPrimary, size: 24),
                      Icon(MaterialSymbolsRounded.settings,
                          color: kTextPrimary, size: 24),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: kChipBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Note: plain Icons.* (MaterialIcons font) is not registered — use CupertinoIcons or MaterialSymbolsRounded instead.',
                      style: TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Progress Indicator ────────────────────────────────────────
            _SectionHeader('Progress Indicator'),
            const SizedBox(height: 4),
            _SectionSubtitle(
              'CircularProgressIndicator(value:) · CAShapeLayer · Material',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ProgressRingDemo(),
                  SizedBox(height: 12),
                  Text(
                    'Tap ▶ to fill the ring over 10s · tap ✕ to cancel',
                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                  SizedBox(height: 22),
                  Text(
                    'Indeterminate (value: null)',
                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
                  ),
                ],
              ),
            ),

            // ── The android: group's tuning (Android only). The indicators
            // above are already Material's; this shows what the group adds
            // on top — the wave, the track gap, the stop dot.
            if (Platform.isAndroid) ...[
              const SizedBox(height: 16),
              _SectionSubtitle(
                'Tuned — android: AndroidProgressIndicatorStyle(wavy:)',
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const _M3ProgressShowcase(),
              ),
            ],

            // ── Stray-dot repro: STATIC rings at fixed values (white arc,
            // white@90% track, strokeWidth 1.5, size 32, centred arrow).
            // Watch value 0.0 and 1.0 — a dot there with no animation or
            // state involved isolates a pure rendering issue.
            const SizedBox(height: 16),
            _SectionSubtitle(
              'Dot repro — static rings (value labelled below each)',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const _DotReproRow(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────────

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
    return Text(
      text,
      style: TextStyle(color: kTextSecondary, fontSize: 12),
    );
  }
}

/// Static `CircularProgressIndicator`s at fixed values — a download-button
/// style ring (white arc, white@90% track, strokeWidth 1.5, size 32, centred
/// arrow). Reproduces the "stray dot" with no animation or state involved, so
/// a dot at a specific value points to a rendering issue.
/// The `android:` group's tuning for the progress indicators (Android only):
/// wavy style on both widgets, indeterminate and determinate. The stock
/// M3 extras (track gap, stop dot) come with the Material classes.
class _M3ProgressShowcase extends StatelessWidget {
  const _M3ProgressShowcase();

  static const _wavy = AndroidProgressIndicatorStyle(wavy: true);
  static const _blue = Color(0xFF0A84FF);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: _blue, android: _wavy),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: 0.7,
                color: _blue,
                android: _wavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Wavy spinner · wavy ring at 70%',
          style: TextStyle(color: kTextSecondary, fontSize: 12),
        ),
        const SizedBox(height: 20),
        const SizedBox(
          width: double.infinity,
          height: 16,
          child: LinearProgressIndicator(
            value: 0.6,
            color: _blue,
            android: _wavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Wavy bar at 60% — with the M3 track gap and stop dot',
          style: TextStyle(color: kTextSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          width: double.infinity,
          height: 16,
          child: LinearProgressIndicator(color: _blue, android: _wavy),
        ),
        const SizedBox(height: 8),
        Text(
          'Wavy indeterminate bar',
          style: TextStyle(color: kTextSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _DotReproRow extends StatelessWidget {
  const _DotReproRow();

  @override
  Widget build(BuildContext context) {
    // Contrasting track vs arc so the value is actually visible: dim-grey track
    // = the empty ring, blue arc = the filled progress. A dot at value 0.0
    // (round-cap zero-length stroke) would show as a blue dot at 12 o'clock.
    final track = kChevron; // dim grey = empty ring
    const arc = Color(0xFF0A84FF); // blue = progress fill
    const vals = <double>[0.0, 0.0001, 0.25, 0.5, 1.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final v in vals)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: v,
                  color: arc,
                  backgroundColor: track,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text('$v', style: TextStyle(color: kTextSecondary, fontSize: 11)),
            ],
          ),
      ],
    );
  }
}

/// Interactive determinate-ring demo: tap ▶ to fill the ring over 10s; while
/// running, the center shows ✕ to cancel; on completion it shows ✓.
/// Exercises the new `CircularProgressIndicator(value:)`.
class _ProgressRingDemo extends StatefulWidget {
  const _ProgressRingDemo();

  @override
  State<_ProgressRingDemo> createState() => _ProgressRingDemoState();
}

class _ProgressRingDemoState extends State<_ProgressRingDemo> {
  static const _durationMs = 10000;
  static const _tickMs = 50;
  Timer? _timer;
  double _progress = 0;
  bool _running = false;

  void _start() {
    _timer?.cancel();
    setState(() {
      _running = true;
      _progress = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (_) {
      if (!mounted) return;
      setState(() {
        _progress += _tickMs / _durationMs;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _timer?.cancel();
          _timer = null;
          _running = false;
        }
      });
    });
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _running = false;
      _progress = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 42.0;
    final done = !_running && _progress >= 1.0;
    return GestureDetector(
      onTap: _running ? _cancel : _start,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: _progress, // determinate (idle shows an empty ring)
                color: const Color(0xFF0A84FF),
                backgroundColor: kChipBg,
                strokeWidth: 4,
              ),
            ),
            Icon(
              _running
                  ? CupertinoIcons.xmark
                  : (done
                      ? CupertinoIcons.checkmark
                      : CupertinoIcons.play_fill),
              color: kTextPrimary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Platform-aware component name subtitle.
/// Shows [iosName] on iOS and [androidName] on Android.
class _PlatformSubtitle extends StatelessWidget {
  const _PlatformSubtitle({required this.iosName, required this.androidName});
  final String iosName;
  final String androidName;

  @override
  Widget build(BuildContext context) {
    return _SectionSubtitle(
      Platform.isAndroid ? androidName : iosName,
    );
  }
}

/// Input surface for the overlay's text field: Liquid Glass on iOS 26
/// (grey-tinted in light theme so it reads on the white card), grey fill
/// pre-26.
class _OverlayFieldSurface extends StatelessWidget {
  const _OverlayFieldSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isIOS26) {
      return GlassEffectContainer(
        borderRadius: BorderRadius.circular(10),
        brightness: playgroundPalette.brightness,
        tint: playgroundPalette.brightness == Brightness.dark
            ? null
            : const Color(0x338E8E93),
        child: SizedBox(height: 96, child: child),
      );
    }
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: playgroundPalette.brightness == Brightness.dark
            ? kChipBg
            : kTileBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

// ── Native Modal Sheet demo content ─────────────────────────────────────────

/// Generic content for the Native Modal Sheet demo.
/// Shows a title, description, text field, and done button.
/// Demonstrates: UISheetPresentationController + grab handle + swipe-to-dismiss.
/// Header-panel sheet content: a title row with a round close button on the
/// left and a round info button on the right (no grab handle on the sheet),
/// a row of choice pills, and a full-width apply button — the messenger-style
/// editor panel.
/// Body of the header-buttons sheet — the header itself is DECLARED via
/// [SheetHeader] and rendered by the framework.
class _HeaderSheetContent extends StatelessWidget {
  const _HeaderSheetContent();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 18),
            _SheetOptionsBody(),
          ],
        ),
      ),
    );
  }
}

/// Shared body for all header-sheet variants: option pills, caption, Apply.
class _SheetOptionsBody extends StatefulWidget {
  const _SheetOptionsBody();
  @override
  State<_SheetOptionsBody> createState() => _SheetOptionsBodyState();
}

class _SheetOptionsBodyState extends State<_SheetOptionsBody> {
  static const _styles = ['Option A', 'Option B', 'Option C'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < _styles.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selected == i
                          ? const Color(0xFF007AFF)
                          : kChipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _styles[i],
                      style: TextStyle(
                        color:
                            _selected == i ? Colors.white : kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'A medium-detent native sheet with no grab handle: the header '
          'row carries the controls instead. Swipe down still dismisses '
          'it — that physics is the system\'s own.',
          style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.4),
        ),
        // Fixed gap, not Spacer: the sheet's Dart root is content-sized
        // (it does not adopt the detent height), so flex space collapses.
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () =>
              Navigator.pop(context, 'Applied: ${_styles[_selected]}'),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'Apply',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DemoSheetContent extends StatefulWidget {
  const _DemoSheetContent();
  @override
  State<_DemoSheetContent> createState() => _DemoSheetContentState();
}

class _DemoSheetContentState extends State<_DemoSheetContent> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildField() {
    // Three-line multiline field (UITextView) — fits the medium sheet
    // better than a single-line strip.
    return TextField(
      controller: _ctrl,
      style: TextStyle(color: kTextPrimary, fontSize: 16),
      keyboardType: TextInputType.multiline,
      minLines: 3,
      maxLines: 3,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'Type something…',
        hintStyle: TextStyle(color: kTextSecondary),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              'Native Modal Sheet',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'This is a fully native UISheetPresentationController sheet hosting dartnative widgets. '
              'Grab handle, spring physics, and swipe-to-dismiss are all provided by UIKit.',
              style:
                  TextStyle(color: kTextSecondary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            // Input capsule. iOS 26: Liquid Glass — light theme adds a grey
            // tint so the glass reads on the white sheet. Pre-26: grey fill.
            isIOS26
                ? GlassEffectContainer(
                    borderRadius: BorderRadius.circular(10),
                    brightness: playgroundPalette.brightness,
                    tint: playgroundPalette.brightness == Brightness.dark
                        ? null
                        : const Color(0x338E8E93),
                    child: SizedBox(height: 96, child: _buildField()),
                  )
                : Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: playgroundPalette.brightness == Brightness.dark
                          ? kChipBg
                          : kTileBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _buildField(),
                  ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(
                  context, _ctrl.text.isEmpty ? 'Done' : _ctrl.text),
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Done',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Overlay demo content ────────────────────────────────────────────────────

/// Generic content for the Bottom Overlay demo.
/// Shows a title, description, text field, and confirm button.
/// Demonstrates: VC-containment overlay + dim + tap-outside-to-dismiss.
/// Height of the card below, which is given a rect rather than left to
/// size itself. See [_KeyboardOverlayCard].
const double _kKeyboardOverlayCard = 168;

/// A card drawn above the keyboard by [showKeyboardOverlay].
///
/// The panel is a full-screen transparent surface in the window that hosts
/// the keyboard, so everything about the card is ordinary layout. It is
/// given an explicit rect: the panel's tree is not the one that holds the
/// keyboard inset, so anchoring to the bottom from in here would put the
/// card off the screen.
///
/// Touches outside this tree pass through, so the keyboard stays usable
/// while the card is up.
class _KeyboardOverlayCard extends StatelessWidget {
  const _KeyboardOverlayCard({
    required this.left,
    required this.top,
    required this.width,
  });

  final double left;
  final double top;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: width,
          height: _kKeyboardOverlayCard,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kTileBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Keyboard Overlay',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'With a keyboard up, this draws over it. Tap outside to '
                  'dismiss.',
                  style: TextStyle(color: kTextSecondary, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Button(
                  title: 'Close',
                  variant: ButtonVariant.tinted,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoOverlayContent extends StatefulWidget {
  const _DemoOverlayContent();
  @override
  State<_DemoOverlayContent> createState() => _DemoOverlayContentState();
}

class _DemoOverlayContentState extends State<_DemoOverlayContent> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              'Bottom Overlay',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'This overlay uses VC containment — not modal presentation. '
              'The screen behind is visible. Tap outside the card to dismiss.',
              style:
                  TextStyle(color: kTextSecondary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            // Liquid Glass input surface on iOS 26 (grey-tinted in light so
            // the glass reads on the white card), grey fill pre-26.
            // Three lines, the sheet demo's field: Return inserts a
            // newline and the box holds the rows.
            _OverlayFieldSurface(
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: kTextPrimary, fontSize: 16),
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: 3,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter a value…',
                  hintStyle: TextStyle(color: kTextSecondary),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(
                  context, _ctrl.text.isEmpty ? 'Confirmed' : _ctrl.text),
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Confirm',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
