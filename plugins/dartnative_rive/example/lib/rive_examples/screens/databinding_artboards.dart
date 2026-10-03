// Ported from rive-flutter's example/lib/examples/databinding_artboards.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   File.asset(path, riveFactory:)       →  RiveFile.asset(path)
//   RiveWidgetController(file)           →  RiveController() + Rive(asset:)
//   viewModelInstance.artboard('icon')!  →  viewModelInstance.artboard('icon')
//   DropdownButton(underline:)           →  dropped: DartNative's has none
//   Container(grey border) > Dropdown…   →  on Android the DropdownButton
//                                            alone: Material's own box in
//                                            place of the grey one, the hint
//                                            inside it while there is no
//                                            value, as Flutter's. iOS has no
//                                            such box and keeps the grey one
//
// RiveFile is rive-flutter's File under a name that does not hide dart:io's.
// It names the file; the platform side loads it when one of its artboards is
// first bound. The icon is set before the view mounts, as theirs is set
// before the widget exists, and is applied when the view does.
//
// See: https://rive.app/docs/runtimes/data-binding

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';

Widget buildDataBindingArtboards(BuildContext context) =>
    const ExampleDataBindingArtboards();

/// Example using Rive data binding artboards at runtime.
///
/// See: https://rive.app/docs/runtimes/data-binding
class ExampleDataBindingArtboards extends StatefulWidget {
  const ExampleDataBindingArtboards({super.key});

  @override
  State<ExampleDataBindingArtboards> createState() =>
      _ExampleDataBindingArtboardsState();
}

class _ExampleDataBindingArtboardsState
    extends State<ExampleDataBindingArtboards> {
  late final RiveFile travelPackFile;
  late final RiveFile webPackFile;
  late final RiveController controller;
  late final ViewModelInstance viewModelInstance;
  late ViewModelInstanceArtboard iconProperty;
  late BindableArtboard bindableArtboard;
  bool isInitialized = false;

  // Available artboard options
  final List<String> travelPackOptions = [
    'map',
    'car',
    'gas',
    'compass',
    'walk',
    'food',
    'GPS',
    'coffee',
  ];
  final List<String> webPackOptions = [
    'download',
    'refresh',
    'lock',
    'wifi',
    'email',
    'www',
  ];
  String selectedTravelPackArtboard = 'map';
  String selectedWebPackArtboard = 'download';

  @override
  void initState() {
    super.initState();
    initRive();
  }

  void initRive() async {
    travelPackFile = (await RiveFile.asset(
      'assets/rive/travel_icons_pack.riv',
    ))!;
    webPackFile = (await RiveFile.asset('assets/rive/web_icons_pack.riv'))!;
    controller = RiveController(); // uses default artboard: "Demo"
    viewModelInstance = controller.viewModelInstance;
    iconProperty = viewModelInstance.artboard('icon');
    bindableArtboard = travelPackFile.artboardToBind(
      selectedTravelPackArtboard,
    )!;
    iconProperty.value = bindableArtboard;
    setState(() => isInitialized = true);
  }

  void _onTravelIconSelected(String? newValue) {
    if (newValue != null && newValue != selectedTravelPackArtboard) {
      setState(() {
        selectedTravelPackArtboard = newValue;
        bindableArtboard = travelPackFile.artboardToBind(newValue)!;
        iconProperty.value = bindableArtboard;
      });
    }
  }

  void _onWebPackIconSelected(String? newValue) {
    if (newValue != null && newValue != selectedWebPackArtboard) {
      setState(() {
        selectedWebPackArtboard = newValue;
        bindableArtboard = webPackFile.artboardToBind(newValue)!;
        iconProperty.value = bindableArtboard;
      });
    }
  }

  @override
  void dispose() {
    travelPackFile.dispose();
    webPackFile.dispose();
    bindableArtboard.dispose();
    controller.dispose();
    iconProperty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          children: [
            _buildDropdown(
              'Travel Pack',
              travelPackOptions,
              selectedTravelPackArtboard,
              _onTravelIconSelected,
            ),
            _buildDropdown(
              'Web Pack',
              webPackOptions,
              selectedWebPackArtboard,
              _onWebPackIconSelected,
            ),
          ],
        ),
        Expanded(
          child: Rive(
            asset: 'assets/rive/travel_icons_pack.riv',
            controller: controller,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String title,
    List<String> options,
    String selected,
    Function(String?) onChanged,
  ) {
    final dropdown = DropdownButton<String>(
      value: selected,
      items: options.map((String artboard) {
        return DropdownMenuItem<String>(
          value: artboard,
          child: Text(artboard),
        );
      }).toList(),
      onChanged: (newValue) => onChanged(newValue),
      hint: const Text('Select Artboard'),
    );
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: _text),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Platform.isAndroid // see the top of this file
                ? dropdown
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: dropdown,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Upstream's Text on its Material theme: body text, 14 logical pixels.
const _text = TextStyle(
  color: Color(0xFFFFFFFF),
  fontSize: 14,
  fontFamily: monoFont,
);
