// Ported from rive-flutter's example/lib/examples/databinding.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   File.asset + RiveWidgetController(file)   →  Rive(asset:, controller:)
//   controller.viewModelInstance!             →  controller.viewModelInstance
//   viewModelInstance.number('…')!            →  viewModelInstance.number('…')
//   Fit.layout, layoutScaleFactor: 1 / 2      →  RiveFit.contain
//
// The fit is rive-ios's own Rewards example's (its RiveViewModel default).
// Fit.layout re-lays the artboard out at the screen's shape, narrower than
// the file was drawn on a phone, and the pressed button's "You win 15
// Coins" wraps its last word onto a line the button clips — upstream's
// Flutter example shows the same. The button's uneven rim and the dots at
// its corners are in the file itself, as upstream renders them too.
//
// Our lookups never return null: a path that resolves to nothing is logged
// natively, and the property simply never receives a value. Values arrive
// by push, so `energyBarLivesProperty.value` reads 0 until the runtime has
// answered the bind — rive_native reads the runtime synchronously. Their
// screen sets every value it later reads, so nothing here depends on it.
//
// Not carried over: `file.globalViewModelNames` (rewards.riv declares none,
// and the plugin has no file-level query yet) and `dispose()` on the
// properties (ours hold no native resource).
//
// See: https://rive.app/docs/runtimes/data-binding
// Rive Editor file: https://rive.app/marketplace/25475-47540-data-binding-demo/

import 'dart:math';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';

Widget buildDataBinding(BuildContext context) => const ExampleDataBinding();

class ExampleDataBinding extends StatefulWidget {
  const ExampleDataBinding({super.key});

  @override
  State<ExampleDataBinding> createState() => _ExampleDataBindingState();
}

class _ExampleDataBindingState extends State<ExampleDataBinding> {
  final controller = RiveController();
  late ViewModelInstance viewModelInstance;
  late ViewModelInstance coinItemVM;
  late ViewModelInstance gemItemVM;
  late ViewModelInstanceNumber coinProperty;
  late ViewModelInstanceNumber gemProperty;
  late ViewModelInstanceNumber energyBarProperty;
  late ViewModelInstanceNumber energyBarLivesProperty;
  late ViewModelInstanceColor energyBarColorProperty;
  late ViewModelInstanceString buttonTitleProperty;
  late ViewModelInstanceTrigger buttonPressedProperty;

  late Stream<double> _energyBarStream;

  @override
  void initState() {
    super.initState();
    _setupDataBinding();
  }

  void _setupDataBinding() {
    // Rive(autoBind:) binds the file's default instance, as their controller
    // does at construction.
    viewModelInstance = controller.viewModelInstance;

    // Set a random token to reward
    _selectRandomToken();

    // Print the view model instance properties
    debugPrint(viewModelInstance.properties.toString());

    // Get the rewards view model
    coinItemVM = viewModelInstance.viewModel('Coin');
    gemItemVM = viewModelInstance.viewModel('Gem');

    // Get the Item_Value number properties for the coin and gem
    coinProperty = coinItemVM.number('Item_Value');
    gemProperty = gemItemVM.number('Item_Value');

    // Listen to the changes on the Item_Value for the gen and coin
    coinProperty.addListener(_onCoinValueChange);
    gemProperty.addListener(_onGemValueChange);

    // Set the initial values for the coin and gem
    coinProperty.value = 1000;
    gemProperty.value = 4000;

    // Get the Energy_Bar/Energy_Bar number property
    energyBarProperty = viewModelInstance.number('Energy_Bar/Energy_Bar');
    // Create a stream for the energy bar
    _energyBarStream = energyBarProperty.valueStream;

    // Get the Energy_Bar/Energy_Bar lives number property
    energyBarLivesProperty = viewModelInstance.number('Energy_Bar/Lives');

    // Get the Energy_Bar/Energy_Bar color property
    energyBarColorProperty = viewModelInstance.color('Energy_Bar/Bar_Color');

    // Get the Button/Button_Title string property
    buttonTitleProperty = viewModelInstance.string('Button/State_1');

    // Get the Button/Button_Trigger trigger property
    buttonPressedProperty = viewModelInstance.trigger('Button/Pressed');
    // Listen to the changes on the Button/Pressed trigger
    buttonPressedProperty.addListener(_onButtonPressed);
  }

  // Randomly select to reward either coins or gems
  void _selectRandomToken() {
    final random = Random.secure().nextBool() ? 'Coin' : 'Gem';
    viewModelInstance
        .viewModel('Item_Selection')
        .enumerator('Item_Selection')
        .value = random;
  }

  // Listener for the changes on the Item_Value for the coin
  void _onCoinValueChange(double value) {
    debugPrint('New coin value: $value');
  }

  // Listener for the changes on the Item_Value for the gem
  void _onGemValueChange(double value) {
    debugPrint('New gem value: $value');
  }

  void _onButtonPressed(void _) {
    debugPrint('Button pressed');
  }

  @override
  void dispose() {
    // Listeners must be removed
    coinProperty.removeListener(_onCoinValueChange);
    gemProperty.removeListener(_onGemValueChange);
    buttonPressedProperty.removeListener(_onButtonPressed);
    controller.dispose();
    super.dispose();
  }

  void _showConfigSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _ConfigSheet(state: this),
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Rive(
            asset: 'assets/rive/rewards.riv',
            fit: RiveFit.contain, // see the top of this file
            controller: controller,
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.tune, color: Color(0xFFFFFFFF)),
              onPressed: () => _showConfigSheet(context),
            ),
          ),
        ],
      );
}

/// Their configuration sheet, as its own widget: a bottom sheet re-renders
/// from its own state, as their `StatefulBuilder` does.
class _ConfigSheet extends StatefulWidget {
  const _ConfigSheet({required this.state});

  final _ExampleDataBindingState state;

  @override
  State<_ConfigSheet> createState() => _ConfigSheetState();
}

class _ConfigSheetState extends State<_ConfigSheet> {
  double _sliderValue = 0.5;
  Color _selectedColor = const Color(0xFF4CAF50);

  static const _swatches = [
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF00BCD4), // Cyan
    Color(0xFFE91E63), // Pink
  ];

  TextStyle get _body => const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 14,
        fontFamily: monoFont,
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Container(
      padding: const EdgeInsets.all(24),
      color: appBarColor,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: _body.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            // This is just an example of using a value stream
            StreamBuilder<double>(
              stream: s._energyBarStream,
              builder: (context, snapshot) => Text(
                'Energy: ${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                style: _body,
              ),
            ),
            Slider(
              value: _sliderValue,
              onChanged: (value) {
                setState(() => _sliderValue = value);
                s.energyBarProperty.value = value * 100;
              },
            ),
            const SizedBox(height: 24),
            Text('Bar Color', style: _body),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in _swatches)
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = color);
                      s.energyBarColorProperty.value = color;
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor.value == color.value
                              ? const Color(0xFFFFFFFF)
                              : const Color(0x00000000),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Lives: ${s.energyBarLivesProperty.value}', style: _body),
            const SizedBox(height: 16),
            Slider(
              value: s.energyBarLivesProperty.value.clamp(0, 10),
              onChanged: (value) {
                s.energyBarLivesProperty.value = value;
                setState(() {});
              },
              min: 0,
              max: 10,
              divisions: 10,
            ),
            const SizedBox(height: 16),
            Text('Button Title: ${s.buttonTitleProperty.value}', style: _body),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                s.buttonTitleProperty.value = value;
                setState(() {});
              },
              decoration: const InputDecoration(labelText: 'Button Title'),
            ),
          ],
        ),
      ),
    );
  }
}
