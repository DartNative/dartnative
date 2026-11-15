import 'package:dartnative/dartnative.dart' show Color;
import 'package:dartnative_live_activities/dartnative_live_activities.dart';

/// One step of a story: what its button says, what happens and the data it
/// sends. The first step starts the activity; a step with [end] ends it.
class StoryStep {
  const StoryStep({
    required this.title,
    required this.explain,
    required this.button,
    this.state = const {},
    this.alert,
    this.end = false,
  });

  final String title;
  final String explain;
  final String button;
  final Map<String, Object?> state;
  final LiveAlert? alert;
  final bool end;
}

/// A button on the activity's card, and what the app does when it is tapped.
class CardButton {
  const CardButton({
    required this.id,
    required this.label,
    required this.explain,
    required this.state,
  });

  final String id;
  final String label;
  final String explain;

  /// The last state shown when the app ends the activity for this button.
  final Map<String, Object?> state;
}

/// A design told as a short story the user plays step by step.
class Story {
  const Story({
    required this.id,
    required this.name,
    required this.summary,
    required this.accent,
    required this.design,
    required this.steps,
    this.cardButtons = const [],
  });

  /// Also the activity's `customId`, and the name of its pictures in
  /// `assets/stories/`.
  final String id;
  final String name;
  final String summary;

  /// The design's main colour, used for the story's steps in the app.
  final Color accent;
  final LivePreset Function() design;
  final List<StoryStep> steps;
  final List<CardButton> cardButtons;
}

String _clockIn(Duration d) {
  final t = DateTime.now().add(d);
  return '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
}

LiveImage get _rideHeader => LiveImage.asset(
  'assets/ride/header.png',
  width: 760,
  height: 308,
  fixedHeight: 40,
  shape: LiveShape.square,
);

LiveImage get _driverPhoto => LiveImage.asset(
  'assets/ride/avatar.png',
  width: 200,
  height: 205,
  size: 34,
  shape: LiveShape.square,
);

const _stock = [212, 213.5, 212.8, 214.9, 214.1, 216.3, 215.2, 217.8, 216.9];

/// The nine designs of the package's gallery. On Android each one asks for
/// the native Live Update style, which Android 16 and later promote.
final stories = <Story>[
  Story(
    id: 'ride_pickup',
    name: 'Ride pickup',
    summary: 'A driver on the way to pick you up.',
    accent: Color(0xFF1F5EFF),
    design: () => RidePickupPreset(
      androidStyle: LiveAndroidStyle.liveUpdate,
      headerImage: _rideHeader,
      driverPhoto: _driverPhoto,
      chip: const LiveChip.text('Ride'),
    ),
    steps: const [
      StoryStep(
        title: 'Request a ride',
        explain: 'The activity appears with the driver, the car and the '
            'time left.',
        button: 'Request ride',
        state: {
          'timeLeft': '6 min',
          'title': 'until pickup',
          'subtitle': 'Andrés is on the way',
          'progress': 0.1,
        },
      ),
      StoryStep(
        title: 'The driver gets closer',
        explain: 'The time left changes and the car moves along the bar.',
        button: 'Driver 2 min away',
        state: {
          'timeLeft': '2 min',
          'title': 'until pickup',
          'subtitle': 'Andrés arrives shortly',
          'progress': 0.66,
        },
      ),
      StoryStep(
        title: 'The driver arrives',
        explain: 'An alert plays a sound and brings the activity forward.',
        button: 'Driver is here',
        state: {
          'timeLeft': 'Now',
          'title': 'at the pickup point',
          'subtitle': 'Andrés is waiting outside',
          'progress': 1.0,
        },
        alert: LiveAlert(
          title: 'Your driver is here',
          body: 'Silver sedan, plate A1B-234',
        ),
      ),
      StoryStep(
        title: 'Get in the car',
        explain: 'The activity ends: it shows its last state for a few '
            'seconds, then leaves the screen.',
        button: 'Get in',
        state: {'subtitle': 'Enjoy your ride'},
        end: true,
      ),
    ],
  ),
  Story(
    id: 'trip_pin',
    name: 'Trip start with PIN',
    summary: 'The PIN to tell your driver, always in sight.',
    accent: Color(0xFF3D5AFE),
    design: () => RidePinPreset(
      androidStyle: LiveAndroidStyle.liveUpdate,
      driverPhoto: _driverPhoto,
    ),
    steps: const [
      StoryStep(
        title: 'Request a ride',
        explain: 'The PIN shows at once, and stays there even when the app '
            'is closed.',
        button: 'Request ride',
        state: {'minutes': '5 min', 'progress': 0.2},
      ),
      StoryStep(
        title: 'The driver gets closer',
        explain: 'The minutes left change and the car moves along the bar.',
        button: 'Driver 1 min away',
        state: {'minutes': '1 min', 'progress': 0.86},
      ),
      StoryStep(
        title: 'The driver arrives',
        explain: 'An alert plays a sound and brings the PIN forward.',
        button: 'Driver is here',
        state: {'minutes': '0 min', 'progress': 1.0},
        alert: LiveAlert(
          title: 'Marco is here',
          body: 'Tell your driver the PIN 0249',
        ),
      ),
      StoryStep(
        title: 'Start the trip',
        explain: 'The activity ends: it shows its last state for a few '
            'seconds, then leaves the screen.',
        button: 'Start trip',
        end: true,
      ),
    ],
  ),
  Story(
    id: 'delivery_order',
    name: 'Delivery order',
    summary: 'A food order in four stages, from the kitchen to your door.',
    accent: Color(0xFFF57C00),
    design: () =>
        const DeliveryOrderPreset(androidStyle: LiveAndroidStyle.liveUpdate),
    steps: [
      StoryStep(
        title: 'Place the order',
        explain: 'The activity appears with four stages: the first one is '
            'lit.',
        button: 'Place order',
        state: {
          'title': 'Order received',
          'time': _clockIn(const Duration(minutes: 35)),
          'progress': 0.0,
        },
      ),
      const StoryStep(
        title: 'The kitchen prepares it',
        explain: 'The second stage lights up.',
        button: 'Preparing',
        state: {'title': 'Preparing your order', 'progress': 1 / 3},
      ),
      const StoryStep(
        title: 'The courier picks it up',
        explain: 'The third stage lights up.',
        button: 'On the way',
        state: {'title': 'On the way to you', 'progress': 2 / 3},
      ),
      const StoryStep(
        title: 'The order arrives',
        explain: 'Every stage is lit, and an alert plays a sound.',
        button: 'Delivered',
        state: {'title': 'Delivered', 'progress': 1.0},
        alert: LiveAlert(title: 'Your order is here', body: 'Enjoy your meal'),
      ),
      const StoryStep(
        title: 'Close the order',
        explain: 'The activity ends: it shows its last state for a few '
            'seconds, then leaves the screen.',
        button: 'Close',
        end: true,
      ),
    ],
  ),
  Story(
    id: 'store_pickup',
    name: 'Store pickup',
    summary: 'A coffee order to collect at the counter.',
    accent: Color(0xFF00875A),
    design: () => const StorePickupPreset(
      androidStyle: LiveAndroidStyle.liveUpdate,
      chip: LiveChip.text('Order'),
    ),
    steps: const [
      StoryStep(
        title: 'Place the order',
        explain: 'The activity appears with three steps: received, '
            'preparing, ready.',
        button: 'Place order',
        state: {
          'title': 'Order received',
          'subtitle': 'The store has your order',
          'short': 'Received',
          'stage': 0,
          'progress': 0.1,
        },
      ),
      StoryStep(
        title: 'The barista prepares it',
        explain: 'The second step grows and turns white.',
        button: 'Preparing',
        state: {
          'title': 'Order being prepared',
          'subtitle': 'We are carefully preparing your order',
          'short': 'Preparing',
          'stage': 1,
          'progress': 0.5,
        },
      ),
      StoryStep(
        title: 'The order is ready',
        explain: 'The last step lights up, and an alert plays a sound.',
        button: 'Ready',
        state: {
          'title': 'Ready for pickup',
          'subtitle': 'Collect it at the counter',
          'short': 'Ready',
          'stage': 2,
          'progress': 1.0,
        },
        alert: LiveAlert(
          title: 'Your order is ready',
          body: 'Collect it at the counter',
        ),
      ),
      StoryStep(
        title: 'Collect it',
        explain: 'The activity ends: it shows its last state for a few '
            'seconds, then leaves the screen.',
        button: 'Collected',
        state: {
          'title': 'Enjoy your coffee',
          'subtitle': 'Thanks for your order',
          'short': 'Done',
        },
        end: true,
      ),
    ],
  ),
  Story(
    id: 'match_score',
    name: 'Match score',
    summary: 'A football match, goal by goal.',
    accent: Color(0xFF1B5E20),
    design: () => const MatchPreset(
      androidStyle: LiveAndroidStyle.liveUpdate,
      chip: LiveChip.text('Live'),
    ),
    steps: const [
      StoryStep(
        title: 'Kick-off',
        explain: 'The activity appears with both teams and the score.',
        button: 'Kick-off',
        state: {
          'homeGoals': '0',
          'awayGoals': '0',
          'minute': "1'",
          'progress': 0.0,
        },
      ),
      StoryStep(
        title: 'Lions score',
        explain: 'The score changes, and an alert plays a sound.',
        button: 'Goal for Lions',
        state: {
          'homeGoals': '1',
          'awayGoals': '0',
          'minute': "23'",
          'progress': 0.25,
        },
        alert: LiveAlert(title: 'Goal for Lions', body: 'Lions 1 – 0 Hawks'),
      ),
      StoryStep(
        title: 'Second half',
        explain: 'The score and the minute change, with no sound.',
        button: "Minute 67'",
        state: {
          'homeGoals': '2',
          'awayGoals': '1',
          'minute': "67'",
          'progress': 0.75,
        },
      ),
      StoryStep(
        title: 'Full time',
        explain: 'The activity ends: it shows the final score for a few '
            'seconds, then leaves the screen.',
        button: 'Full time',
        state: {'minute': 'FT', 'progress': 1.0},
        end: true,
      ),
    ],
  ),
  Story(
    id: 'stock_quote',
    name: 'Stock quote',
    summary: 'A share price and its chart, moving through the day.',
    accent: Color(0xFF1E9E4A),
    design: () => const StockPreset(
      androidStyle: LiveAndroidStyle.liveUpdate,
      chip: LiveChip.text('VOLT'),
    ),
    steps: [
      StoryStep(
        title: 'Follow a share',
        explain: 'The activity appears with the price, the change and the '
            'chart.',
        button: 'Follow VOLT',
        state: {
          'price': '216.90',
          'change': '+0.33%',
          'trend': '▲',
          'series': liveSeries(_stock),
        },
      ),
      StoryStep(
        title: 'The price goes up',
        explain: 'The price and the chart change, with no sound.',
        button: 'Price up',
        state: {
          'price': '221.10',
          'change': '+2.27%',
          'trend': '▲',
          'series': liveSeries([..._stock, 218.5, 221.1]),
        },
      ),
      StoryStep(
        title: 'The price drops',
        explain: 'The chart turns down, and an alert plays a sound.',
        button: 'Price down',
        state: {
          'price': '212.60',
          'change': '-1.66%',
          'trend': '▼',
          'series': liveSeries([..._stock, 218.5, 221.1, 216.0, 212.6]),
        },
        alert: const LiveAlert(title: 'VOLT is down', body: 'Now at 212.60'),
      ),
      const StoryStep(
        title: 'Stop following',
        explain: 'The activity ends: it shows its last state for a few '
            'seconds, then leaves the screen.',
        button: 'Stop',
        end: true,
      ),
    ],
  ),
  Story(
    id: 'flight',
    name: 'Flight with curved route',
    summary: 'A flight from Lima to Madrid, the plane moving along its route.',
    accent: Color(0xFF1E9E4A),
    design: () => const FlightPathPreset(
      androidStyle: LiveAndroidStyle.liveUpdate,
      chip: LiveChip.text('RA 234'),
    ),
    steps: const [
      StoryStep(
        title: 'Take off',
        explain: 'The activity appears with the route and the plane at the '
            'start.',
        button: 'Take off',
        state: {
          'status': 'Departed',
          'landsAt': 'Lands in 11 h 40 min',
          'progress': 0.05,
        },
      ),
      StoryStep(
        title: 'Over the ocean',
        explain: 'The plane moves along the route and the time left changes.',
        button: 'Halfway there',
        state: {
          'status': 'On time',
          'landsAt': 'Lands in 3 h 10 min',
          'progress': 0.72,
        },
      ),
      StoryStep(
        title: 'Landing',
        explain: 'The plane reaches the end, and an alert plays a sound.',
        button: 'Land',
        state: {
          'status': 'Landed',
          'landsAt': 'Welcome to Madrid',
          'progress': 1.0,
        },
        alert: LiveAlert(
          title: 'Landed in Madrid',
          body: 'Flight RA 234 is at the gate',
        ),
      ),
      StoryStep(
        title: 'Leave the plane',
        explain: 'The activity ends: it shows its last state for a few '
            'seconds, then leaves the screen.',
        button: 'Leave',
        end: true,
      ),
    ],
  ),
  Story(
    id: 'ev_charging',
    name: 'EV charging',
    summary: 'An electric car charging, with a glowing cable.',
    accent: Color(0xFF1E9E4A),
    design: () => const ChargePreset(
      androidStyle: LiveAndroidStyle.liveUpdate,
      chip: LiveChip.text('Charge'),
    ),
    steps: const [
      StoryStep(
        title: 'Plug in the car',
        explain: 'The activity appears with the charge level and the time '
            'left.',
        button: 'Plug in',
        state: {
          'level': '20 %',
          'status': 'Charging',
          'remaining': '1 h 5 min left',
          'power': '48 kW',
          'progress': 0.2,
        },
      ),
      StoryStep(
        title: 'The battery fills',
        explain: 'The level and the glowing bar grow.',
        button: 'Charge to 72 %',
        state: {
          'level': '72 %',
          'status': 'Charging',
          'remaining': '38 min left',
          'power': '48 kW',
          'progress': 0.72,
        },
      ),
      StoryStep(
        title: 'Fully charged',
        explain: 'The bar is full, and an alert plays a sound.',
        button: 'Full',
        state: {
          'level': '100 %',
          'status': 'Charged',
          'remaining': 'Ready to go',
          'power': '0 kW',
          'progress': 1.0,
        },
        alert: LiveAlert(
          title: 'Your car is charged',
          body: 'Unplug it whenever you are ready',
        ),
      ),
      StoryStep(
        title: 'Unplug',
        explain: 'The activity ends: it shows its last state for a few '
            'seconds, then leaves the screen.',
        button: 'Unplug',
        end: true,
      ),
    ],
  ),
  Story(
    id: 'waiting_room',
    name: 'Medical waiting room',
    summary: 'A virtual queue for the doctor, with a button on the card.',
    accent: Color(0xFF00796B),
    design: () => const WaitingRoomPreset(chip: LiveChip.text('Queue')),
    steps: const [
      StoryStep(
        title: 'Join the queue',
        explain: 'The activity appears with the people ahead of you and a '
            'Leave queue button.',
        button: 'Join queue',
        state: {
          'title': 'Virtual waiting room',
          'subtitle': 'Dr. Ríos · General medicine',
          'name': 'About 20 min',
          'highlight': '5 ahead',
          'progress': 0.2,
        },
      ),
      StoryStep(
        title: 'The queue moves',
        explain: 'The people ahead and the bar change, with no sound.',
        button: '2 ahead',
        state: {
          'name': 'Calling you soon',
          'highlight': '2 ahead',
          'progress': 0.8,
        },
      ),
      StoryStep(
        title: 'Your turn',
        explain: 'An alert plays a sound and brings the activity forward.',
        button: 'Call me',
        state: {
          'name': 'Go to room 3',
          'highlight': 'Now',
          'progress': 1.0,
        },
        alert: LiveAlert(
          title: "It's your turn",
          body: 'Dr. Ríos is waiting in room 3',
        ),
      ),
      StoryStep(
        title: 'See the doctor',
        explain: 'The activity ends: it shows its last state for a few '
            'seconds, then leaves the screen.',
        button: 'Done',
        state: {'name': 'Get well soon'},
        end: true,
      ),
    ],
    cardButtons: [
      CardButton(
        id: 'leave_queue',
        label: 'Leave queue',
        explain: 'Tap it on the card itself, not here. The app hears the '
            'tap and ends the activity.',
        state: {'name': 'You left the queue', 'highlight': 'Left'},
      ),
    ],
  ),
];
