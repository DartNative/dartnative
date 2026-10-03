// Ported from rive-flutter's example/lib/examples/events.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff is the load and
// the listener:
//
//   File.asset(…, riveFactory:) + RiveWidgetController(file)  →  Rive(asset:)
//   stateMachine.addEventListener(fn)         →  controller.events.listen(fn)
//   (events play on the classic runtime)     →  Rive(legacy: true)
//   event.numberProperty('rating')?.value     →  event.properties['rating']
//
// Everything else — the widget tree, the state, the dispose — is theirs. The
// Scaffold and AppBar are supplied by the catalogue shell, as upstream's
// _WrappedPage does for their screens.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

Widget buildEvents(BuildContext context) => const ExampleEvents();

/// We strongly recommend using Data Binding instead of Rive Events for better
/// runtime control if you need to do more advanced logic than simple events.
///
/// See: https://rive.app/docs/runtimes/data-binding
///
/// This example demonstrates how to retrieve custom properties set on a Rive
/// event, and update the UI accordingly.
///
/// See: https://rive.app/docs/runtimes/events
class ExampleEvents extends StatefulWidget {
  const ExampleEvents({super.key});

  @override
  State<ExampleEvents> createState() => _ExampleEventsState();
}

class _ExampleEventsState extends State<ExampleEvents> {
  // No `File` to hold: the platform runtime decodes the .riv, so the widget
  // takes the asset path directly and there is nothing to await.
  final RiveController _controller = RiveController();

  String ratingValue = 'Rating: 0';

  @override
  void initState() {
    super.initState();
    _controller.events.listen(_onRiveEvent);
  }

  void _onRiveEvent(RiveEvent event) {
    // Access custom properties defined on the event
    print(event); // ignore: avoid_print
    var rating = event.properties['rating'] ?? 0;
    setState(() {
      ratingValue = 'Rating: $rating';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kept clear of the home indicator; upstream's page runs under it.
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: Rive(
              asset: 'assets/rive/rating.riv',
              stateMachineName: 'State Machine 1',
              controller: _controller,
              legacy: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              ratingValue,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
