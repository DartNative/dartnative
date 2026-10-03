// Ported from rive-flutter's example/lib/examples/inputs.dart (0.15.0-dev.1):
// Copyright (c) 2020 Rive, MIT; the full licence is reproduced in
// THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff is the load and
// how the input is reached:
//
//   File.asset(…, riveFactory:) + RiveWidgetController(file)  →  Rive(asset:)
//   controller.stateMachine.number('Level')                   →  controller.number('Level')
//   (inputs play on the classic runtime)                      →  Rive(legacy: true)
//
// The button row, the values and the layout are theirs. Note the state
// machine: skills.riv declares two, and only "Designer's Test" owns `Level`.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../rive_examples/perf_overlay.dart' show PerfAction, PerfOverlayHost;
import '../rive_examples/theme.dart';

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
  @override
  void initState() {
    super.initState();
    // A white screen: dark status-bar icons.
    SystemChrome.setSystemUIOverlayStyle(whiteScreenStatusBar);
  }

  final RiveController _controller = RiveController();

  /* EXAMPLE BOOLEAN INPUT API */
  // var boolInput = _controller.boolean('some_bool');
  // boolInput?.value = true;
  /* EXAMPLE TRIGGER INPUT API */
  // var triggerInput = _controller.trigger('some_trigger');
  // triggerInput?.fire();

  NumberInput? get _levelInput => _controller.number('Level');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        leading: const BackButton(iconColor: Color(0xFF000000)),
        title: const Text(
          'Inputs',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [PerfAction(color: Color(0xFF000000))],
      ),
      body: PerfOverlayHost(
        child: Stack(
          children: [
            Positioned.fill(
              child: Rive(
                asset: 'assets/rive/skills.riv',
                stateMachineName: "Designer's Test",
                controller: _controller,
                legacy: true,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Button('Beginner', () => _levelInput?.value = 0),
                  const SizedBox(width: 10),
                  _Button('Intermediate', () => _levelInput?.value = 1),
                  const SizedBox(width: 10),
                  _Button('Expert', () => _levelInput?.value = 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Their example uses Material's ElevatedButton; DartNative's own button is
/// the closest equivalent without pulling Material in.
class _Button extends StatelessWidget {
  const _Button(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14),
          ),
        ),
      );
}
