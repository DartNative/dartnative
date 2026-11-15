import 'dart:async';
import 'dart:math';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_home_widget/dartnative_home_widget.dart';

import 'dartnative_plugin_registrant.dart';
import 'designs.dart';

void main() {
  // Platform bindings and the plugins' FFI symbols. Keep this as the first
  // line of main(): see lib/dartnative_plugin_registrant.dart.
  DartNativePluginRegistrant.registerAll();
  // The counter's button works with the app open, in the background or
  // closed.
  unawaited(HomeWidgets.handleActions(onWidgetAction));
  runApp(const HomeScreen());
}

/// The counter, as the screen shows it, while the app runs.
final counterChanges = StreamController<int>.broadcast();

/// Runs for each button pressed on a widget. With the app closed on
/// Android it runs on its own, without the app's screen.
@pragma('vm:entry-point')
Future<void> onWidgetAction(HomeWidgetAction action) async {
  if (action.widget != 'counter' || action.button != 'add') return;
  final count = await addToCounter();
  counterChanges.add(count);
}

/// Raises the counter widget's number by one, from the number it shows.
Future<int> addToCounter() async {
  final shown = (await HomeWidgets.values('counter'))['count'];
  final count = (shown is num ? shown.toInt() : 0) + 1;
  await HomeWidgets.update('counter', values: {'count': count});
  return count;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _places = ['Lisbon', 'Kyoto', 'Oslo', 'New York City', 'Cairo'];
  static const _skies = ['Sunny', 'Cloudy', 'Light rain', 'Windy', 'Clear'];

  final _random = Random();
  final _subscriptions = <StreamSubscription<Object?>>[];
  var _status = 'Add the widgets from the home screen, then draw them here.';
  var _canPin = false;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(HomeWidgets.taps.listen((t) => _say('Opened from ${t.widget}: ${t.link}')))
      ..add(counterChanges.stream.listen((n) => _say('Counter at $n (from the widget).')));
    HomeWidgets.launchTap().then((t) {
      if (t != null) _say('Launched from ${t.widget}: ${t.link}');
    });
    HomeWidgets.canPin().then((can) {
      if (mounted) setState(() => _canPin = can);
    });
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  void _say(String text) {
    if (mounted) setState(() => _status = text);
  }

  /// Runs [work] and shows what it returns, or why it failed.
  Future<void> _run(Future<String> Function() work) async {
    try {
      _say(await work());
    } on HomeWidgetException catch (e) {
      _say(e.message);
    }
  }

  Map<String, Object?> _weather() {
    final rain = _random.nextInt(101);
    return {
      'place': _places[_random.nextInt(_places.length)],
      'temperature': '${8 + _random.nextInt(25)}°',
      'sky': _skies[_random.nextInt(_skies.length)],
      'rain': rain / 100,
      'rainText': '$rain%',
    };
  }

  Future<void> _drawAll() => _run(() async {
    await _sendWeather();
    final count = (await HomeWidgets.values('counter'))['count'];
    await HomeWidgets.update('counter', design: counterDesign, values: {'count': count ?? 0});
    return 'Both widgets drawn.';
  });

  Future<void> _newWeather() => _run(() async {
    await _sendWeather();
    return 'New weather sent.';
  });

  /// The widget's color follows the sky, so the design goes with the values.
  Future<void> _sendWeather() {
    final weather = _weather();
    return HomeWidgets.update(
      'weather',
      design: weatherDesign(weather['sky']! as String),
      values: weather,
    );
  }

  /// The next three minutes, one a minute: the widget changes on its own,
  /// with the app closed. Only what changes is in each entry.
  Future<void> _nextMinutes() => _run(() async {
    final now = DateTime.now();
    await HomeWidgets.update(
      'weather',
      timeline: [
        for (var i = 1; i <= 3; i++)
          HomeWidgetEntry(now.add(Duration(minutes: i)), {
            'temperature': '${8 + _random.nextInt(25)}°',
            'sky': 'In $i min',
          }),
      ],
    );
    return 'The weather widget changes each minute for three minutes.';
  });

  Future<void> _addOne() => _run(() async {
    return 'Counter at ${await addToCounter()} (from the app).';
  });

  Future<void> _pin(String widget) => _run(() async {
    return await HomeWidgets.pin(widget)
        ? 'The home screen asks whether to add it.'
        : 'This home screen cannot add widgets for apps.';
  });

  Future<void> _showPlaced() => _run(() async {
    final placed = await HomeWidgets.placed();
    return placed.isEmpty
        ? 'No widget on the home screen or the lock screen yet.'
        : 'Placed: ${placed.map((p) => '${p.widget} (${p.size.name})').join(', ')}';
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home widgets')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_status),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _drawAll, child: const Text('Draw both widgets')),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _newWeather, child: const Text('New weather')),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _nextMinutes, child: const Text('Weather for the next minutes')),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _addOne, child: const Text('Add one to the counter')),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _showPlaced, child: const Text('Which widgets are placed?')),
              if (_canPin) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _pin('counter'),
                  child: const Text('Add the counter to the home screen'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
