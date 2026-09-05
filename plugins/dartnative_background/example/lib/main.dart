import 'dart:io';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_background/dartnative_background.dart';
import 'package:dartnative_notifications/dartnative_notifications.dart';
import 'package:dartnative_path_provider/dartnative_path_provider.dart';

import 'dartnative_plugin_registrant.dart';

// ── Task identifiers ──────────────────────────────────────────────────────────
const simpleTask = 'com.dartnative.background.simpleTask';
const delayedTask = 'com.dartnative.background.delayedTask';
const rescheduledTask = 'com.dartnative.background.rescheduledTask';
const failedTask = 'com.dartnative.background.failedTask';
const periodicTask = 'com.dartnative.background.periodicTask';
const processingTask = 'com.dartnative.background.processingTask';

const _allTasks = [
  simpleTask,
  delayedTask,
  rescheduledTask,
  failedTask,
  periodicTask,
  processingTask,
];

void main() {
  // Deeper debugging: background tasks run in a headless isolate detached from
  // the `dn run` terminal, so their logs are easy to miss. To capture them, wrap
  // BOTH this body and `callbackDispatcher` in DartNativeLogger.run, e.g.:
  //   DartNativeLogger.run(
  //     () { DartNativePluginRegistrant.registerAll(); runApp(...); },
  //     verbose: true, saveToFile: true,
  //     filePath: '${getApplicationDocumentsDirectory()}/dnbg.log',
  //   );
  // It tees every dnLog/print (incl. bridge-forwarded native logs) to a file you
  // can pull off the device. Left off here to keep the example minimal.
  DartNativePluginRegistrant.registerAll();
  runApp(const BackgroundExampleApp());
}

/// Runs in the **headless background isolate** the OS spins up for a task.
/// Top-level + `@pragma('vm:entry-point')` so the engine can find it.
@pragma('vm:entry-point')
void callbackDispatcher() {
  // registerAll() does NOT run in this isolate, so load any plugins we use here.
  try {
    NotificationsFFIBindings.loadSymbols();
  } catch (_) {
    // Notifications are best-effort feedback — never fail the task over them.
  }

  TaskManager().executeTask((task, inputData) async {
    final shortName = task.split('.').last;
    dnLog('[dn-bg] "$task" started — inputData=$inputData');

    // dartnative_path_provider works in the headless isolate (FFI).
    final docs = getApplicationDocumentsDirectory();
    final marker = File('$docs/dnbg_$shortName.txt');

    bool success;
    String note;
    switch (task) {
      case simpleTask:
      case delayedTask:
      case periodicTask:
        marker.writeAsStringSync('ran at ${DateTime.now()}');
        success = true;
        note = 'ran';
      case processingTask:
        await Future<void>.delayed(const Duration(seconds: 10));
        marker.writeAsStringSync('processing ran at ${DateTime.now()}');
        success = true;
        note = 'ran (after 10s)';
      case rescheduledTask:
        if (marker.existsSync()) {
          success = true;
          note = 'retry → success';
        } else {
          marker.writeAsStringSync('first run ${DateTime.now()}');
          success = false;
          note = 'first run → reschedule';
        }
      case failedTask:
        success = false;
        note = 'failed (on purpose)';
      default:
        success = true;
        note = 'ran';
    }

    dnLog('[dn-bg] "$task" $note');

    // Visible, cross-platform proof the task ran — even with the app backgrounded.
    try {
      DartNativeNotifications.show(
        id: 'dnbg-$shortName',
        title: 'Background task: $shortName',
        body: '$note — ${DateTime.now().toString().substring(11, 19)}',
      );
    } catch (_) {}

    return success;
  });
}

class BackgroundExampleApp extends StatelessWidget {
  const BackgroundExampleApp({super.key});

  @override
  Widget build(BuildContext context) => const _HomeScreen();
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  bool _initialized = false;
  bool? _notifGranted;
  String _status = 'Not initialized — tap "Initialize" first.';
  String _results = 'No results yet — register a task, then Refresh.';

  @override
  void initState() {
    super.initState();
    // Ask for the notification permission once, at launch — after the first frame so
    // the foreground activity is attached, and before the user taps anything (so a
    // grant never interrupts the Initialize flow). The dispatcher posts a local
    // notification when a task runs (Android 13+ requires this; iOS always).
    //
    // We use the notifications plugin's own request here. An app that centralizes
    // every permission with dartnative_permissions could instead call
    // `Permission.notification.request()` — it requests the exact same permission.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final granted = await DartNativeNotifications.requestPermission();
        if (mounted) setState(() => _notifGranted = granted);
      } catch (_) {
        // Notifications are best-effort feedback — never block the demo on them.
      }
    });
  }

  void _log(String msg) => setState(() => _status = msg);

  Future<void> _initialize() async {
    try {
      await TaskManager().initialize(callbackDispatcher, isInDebugMode: true);
      setState(() {
        _initialized = true;
        _status = 'Initialized ✓ — register a task below.';
      });
    } catch (e) {
      _log('initialize failed: $e');
    }
  }

  Future<void> _guard(String label, Future<void> Function() action) async {
    if (!_initialized) {
      _log('Initialize first.');
      return;
    }
    try {
      await action();
      // periodic/processing are system-scheduled — they don't run on tap, so
      // tell the user that's expected (vs immediate tasks, which notify now).
      final deferred = label == 'periodic' || label == 'processing';
      _log(
        deferred
            ? 'Scheduled ✓ — the system runs this later in the background, not right now.'
            : 'Done ✓ — look for the notification.',
      );
    } catch (e) {
      _log('$label failed: $e');
    }
  }

  /// Cancels a single scheduled task by its unique name, leaving the others in
  /// place. For a periodic task this also stops it from re-arming itself on iOS.
  Future<void> _cancelByName(String label, String uniqueName) async {
    if (!_initialized) {
      _log('Initialize first.');
      return;
    }
    try {
      await TaskManager().cancelByUniqueName(uniqueName);
      _log('Cancelled "$label" ✓ — it won\'t run again. Tap Refresh to confirm.');
    } catch (e) {
      _log('cancel $label failed: $e');
    }
  }

  /// `cancelAll()` returns void, so the proof is behavioural: a task you scheduled
  /// no longer runs. The caption under the button explains how to see it.
  Future<void> _cancelAll() async {
    if (!_initialized) {
      _log('Initialize first.');
      return;
    }
    try {
      await TaskManager().cancelAll();
      _log(
        'Cancelled all pending tasks ✓ — none will run. Tap Refresh to confirm.',
      );
    } catch (e) {
      _log('cancelAll failed: $e');
    }
  }

  /// Reads the marker files the headless dispatcher writes.
  void _refreshResults() {
    final docs = getApplicationDocumentsDirectory();
    final buf = StringBuffer();
    for (final task in _allTasks) {
      final short = task.split('.').last;
      final f = File('$docs/dnbg_$short.txt');
      buf.writeln(
        '• $short: ${f.existsSync() ? f.readAsStringSync() : '— not run yet'}',
      );
    }
    setState(() => _results = buf.toString().trimRight());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'Background',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section('Status'),
          const SizedBox(height: 6),
          Text(
            _status,
            style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Notifications: ${_notifGranted == null
                ? 'asking…'
                : _notifGranted!
                ? 'granted ✓'
                : 'denied (markers still work)'}',
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
          ),
          const SizedBox(height: 20),

          _Section('Setup'),
          const SizedBox(height: 8),
          _Button('Initialize', _initialize),
          const SizedBox(height: 20),

          _Section('One-off tasks'),
          const SizedBox(height: 8),
          _Button(
            'Register simple',
            () => _guard(
              'simple',
              () => TaskManager().registerOneOffTask(simpleTask, simpleTask),
            ),
          ),
          const SizedBox(height: 8),
          _Button(
            'Register delayed (10s)',
            () => _guard(
              'delayed',
              () => TaskManager().registerOneOffTask(
                delayedTask,
                delayedTask,
                initialDelay: const Duration(seconds: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Button(
            'Register reschedule',
            () => _guard(
              'reschedule',
              () => TaskManager().registerOneOffTask(
                rescheduledTask,
                rescheduledTask,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Button(
            'Register failed',
            () => _guard(
              'failed',
              () => TaskManager().registerOneOffTask(failedTask, failedTask),
            ),
          ),
          const SizedBox(height: 20),

          _Section('Periodic / processing'),
          const SizedBox(height: 8),
          _Button(
            'Register periodic',
            () => _guard(
              'periodic',
              () => TaskManager().registerPeriodicTask(
                periodicTask,
                periodicTask,
                frequency: const Duration(minutes: 15),
                initialDelay: Duration.zero,
                // Constraints apply on Android (WorkManager); iOS
                // BGAppRefreshTask ignores them — firing is OS-scheduled.
                constraints: Constraints(networkType: NetworkType.connected),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Button(
            'Register processing',
            () => _guard(
              'processing',
              () => TaskManager().registerProcessingTask(
                processingTask,
                processingTask,
                initialDelay: Duration.zero,
                // iOS BGProcessingTask honors these. Production apps often
                // set requiresCharging: true to run overnight while charging
                // (the reliable iOS window); kept false here so it can run
                // sooner while testing. networkType demonstrates the
                // constraint path.
                constraints: Constraints(
                  networkType: NetworkType.connected,
                  requiresCharging: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
              children: [
                TextSpan(
                  text:
                      "Periodic runs are system-scheduled — they won't fire "
                      'right away.\n\n',
                ),
                TextSpan(
                  text: 'Android',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      ': WorkManager, 15 min minimum; the OS may defer further '
                      'under Doze / battery saver.\n\n',
                ),
                TextSpan(
                  text: 'iOS',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      ': OS-scheduled based on your app-usage pattern. '
                      'Minimum ~15 min between invocations (iOS floor, '
                      'regardless of the frequency set in AppDelegate); '
                      'each run is capped to ~30s of CPU time. '
                      'Needs Info.plist IDs + AppDelegate registration — '
                      'force one from lldb to test (see the README).',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _Section('Results'),
          const SizedBox(height: 8),
          _Button('Refresh results', _refreshResults),
          const SizedBox(height: 8),
          Text(
            _results,
            style: const TextStyle(
              color: Color(0xFFE5E5EA),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 20),

          _Section('Control'),
          const SizedBox(height: 8),
          _Button(
            'Cancel periodic',
            () => _cancelByName('periodic', periodicTask),
          ),
          const SizedBox(height: 8),
          _Button(
            'Cancel processing',
            () => _cancelByName('processing', processingTask),
          ),
          const SizedBox(height: 8),
          _Button('Cancel all', _cancelAll),
          const SizedBox(height: 6),
          const Text(
            'Schedule a task → Cancel → it never runs.\n'
            'Try it: register "delayed (10s)", tap Cancel all within 10s, then '
            'Refresh — delayedTask stays "— not run yet".\n\n'
            'Periodic re-arms itself each run on iOS, so a plain '
            'cancelAllTaskRequests() leaves it firing. "Cancel periodic" '
            '(and Cancel all) now clear that re-arm, so the task stops even if '
            'you force a run from lldb.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Button extends StatelessWidget {
  const _Button(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3A3A3C)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0A84FF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
