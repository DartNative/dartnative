// Ported from rive-flutter's example/lib/examples/inputs.dart
// (0.15.0-dev.3). Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   File.asset(…) + RiveWidgetController(file)  →  Rive(asset:)
//   controller.stateMachine.number('Level')     →  controller.number('Level')
//   ElevatedButton                              →  ElevatedPill
//   Positioned.fill(bottom: 32)                 →  Positioned(left: 0, top: 0,
//                                                  right: 0, bottom: 32): the
//                                                  same box; DartNative's .fill
//                                                  takes no edges
//   (inputs play on the classic runtime)        →  Rive(legacy: true)
//   Positioned.fill(child: RiveWidget)          →  Rive as the Stack's one
//                                                  unpositioned child: the same
//                                                  box in Flutter. DartNative
//                                                  sizes a Stack of positioned
//                                                  children only to nothing
//                                                  (Flutter: the biggest size
//                                                  allowed), and stretches a
//                                                  Rive child (framework gap,
//                                                  reported)
//
// Their `_riveFile == null` guard goes: the file loads on the platform side
// with the view. The state machine is named: skills.riv declares two, and
// only "Designer's Test" owns `Level` (see rive_official/inputs.dart).

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../elevated_pill.dart';

Widget buildInputs(BuildContext context) => const ExampleInputs();

/// We strongly recommend using Data Binding instead of Rive Inputs for better
/// runtime control. See: https://rive.app/docs/runtimes/data-binding
///
/// An example showing how to drive a StateMachine via one numeric input.
/// Triggers and boolean inputs can be driven in a similar way.
///
/// See: https://rive.app/docs/runtimes/inputs
class ExampleInputs extends StatefulWidget {
  const ExampleInputs({super.key});

  @override
  State<ExampleInputs> createState() => _ExampleInputsState();
}

class _ExampleInputsState extends State<ExampleInputs> {
  final RiveController _controller = RiveController();
  NumberInput? _levelInput;

  @override
  void initState() {
    super.initState();
    // You can access nested inputs by providing an optional path to the input
    _levelInput = _controller.number('Level');
    /* EXAMPLE BOOLEAN INPUT API */
    // var boolInput = _controller.boolean('some_bool');
    // boolInput?.value = true;
    /* EXAMPLE TRIGGER INPUT API */
    // var triggerInput = _controller.trigger('some_trigger');
    // triggerInput?.fire();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Rive(
            asset: 'assets/rive/skills.riv',
            stateMachineName: "Designer's Test",
            controller: _controller,
            legacy: true,
          ),
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedPill(
                  child: const Text('Beginner'),
                  onPressed: () => _levelInput?.value = 0,
                ),
                const SizedBox(width: 10),
                ElevatedPill(
                  child: const Text('Intermediate'),
                  onPressed: () => _levelInput?.value = 1,
                ),
                const SizedBox(width: 10),
                ElevatedPill(
                  child: const Text('Expert'),
                  onPressed: () => _levelInput?.value = 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
