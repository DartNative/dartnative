import 'dart:async';
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_live_activities/dartnative_live_activities.dart';

import 'stories.dart';

const _muted = Color(0xFF6E6E73);
const _faint = Color(0xFFD1D1D6);
const _card = Color(0xFFF2F2F7);
const _heading = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
const _dismiss = LiveDismiss.after(Duration(seconds: 5));

/// How long after the app leaves the screen an alert step is sent on iOS,
/// which shows nothing of an activity while its app is open.
const _alertDelay = Duration(seconds: 2);

/// What the story's activity looks like on this platform: the expanded
/// Dynamic Island on iOS, the Live Update at the top of the notifications
/// on Android.
class StoryPicture extends StatelessWidget {
  const StoryPicture(this.story, {super.key});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final ios = Platform.isIOS;
    // One height for every story: each picture is fitted inside it, on the
    // colour around it in the capture.
    return ClipRRect(
      borderRadius: BorderRadius.circular(ios ? 28 : 20),
      child: Container(
        height: 150,
        // Android: the notification card on the shade it was captured on.
        padding: ios ? null : const EdgeInsets.all(8),
        color: ios ? const Color(0xFF000000) : const Color(0xFFD9E2FF),
        child: Image.asset(
          'assets/stories/${ios ? 'ios' : 'android'}/${story.id}.png',
          width: double.infinity,
          height: ios ? 150 : 134,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Plays a [Story]: one numbered step per button, the next one lit, and
/// what happened listed underneath, newest first.
class StoryScreen extends StatefulWidget {
  const StoryScreen(this.story, {super.key});

  final Story story;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with WidgetsBindingObserver {
  late final LivePreset _design = widget.story.design();
  late final LiveLayout _layout = _design.build();
  LiveActivity? _activity;
  int _next = 0;
  bool _busy = false;

  /// The alert step waiting for the app to leave the screen (iOS).
  int? _armed;
  Timer? _armTimer;
  final _events = <(String, String)>[];
  StreamSubscription<LiveActivityStateChange>? _states;
  StreamSubscription<String>? _actions;
  StreamSubscription<LivePushToken>? _tokens;

  Story get _story => widget.story;

  // Every call, result and event goes to the console, tagged `[live]`.
  void _log(String message) => dnLog('[live] ${_story.id}: $message');

  void _note(String text) {
    if (!mounted) return;
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    setState(
      () => _events.insert(0, (
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}',
        text,
      )),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _states = LiveActivities.stateChanges.listen(_onState);
    _actions = LiveActivities.onAction(_onCardButton);
    _tokens = LiveActivities.pushTokens.listen(
      (t) => _log(
        'push token for ${t.activityId ?? 'push-to-start'}: '
        '${t.token.length ~/ 2} bytes',
      ),
    );
    _recover();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _armTimer?.cancel();
    _states?.cancel();
    _actions?.cancel();
    _tokens?.cancel();
    super.dispose();
  }

  // An armed alert step goes out a moment after the app leaves the screen,
  // once the island and the lock screen can show the activity again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final armed = _armed;
    if (armed == null) return;
    if (state == AppLifecycleState.paused) {
      _log('left the app with step ${armed + 1} armed');
      _armTimer?.cancel();
      _armTimer = Timer(_alertDelay, () => _play(armed, armedSend: true));
    }
  }

  // An activity outlives the app and this screen: pick up this story's one
  // if it is still running.
  Future<void> _recover() async {
    final running = await LiveActivities.activity(_story.id);
    _log('running at open: ${running?.id ?? 'none'}');
    if (running == null || !mounted || _activity != null) return;
    setState(() {
      _activity = running;
      _next = 1;
    });
    _note('Picked up the activity that was still running');
  }

  void _onState(LiveActivityStateChange change) {
    _log('state ${change.state.name}: ${change.id} (${change.customId})');
    if (change.id != _activity?.id) return;
    switch (change.state) {
      case LiveActivityState.active:
        _note('On screen');
      case LiveActivityState.stale:
        _note('Marked out of date');
      case LiveActivityState.ended:
        _note('Ended, showing its last state');
      case LiveActivityState.dismissed:
        _note('Left the screen');
        _disarm();
        setState(() {
          _activity = null;
          _next = 0;
        });
    }
  }

  Future<void> _onCardButton(String id) async {
    _log('card button "$id" tapped');
    final button = _story.cardButtons.where((b) => b.id == id).firstOrNull;
    _note('"${button?.label ?? id}" tapped on the card');
    final activity = _activity;
    if (button == null || activity == null) return;
    await _run('end for "${button.label}"', () async {
      await activity.end(state: button.state, dismiss: _dismiss);
      _note('Ended by the app, after the card button');
      _disarm();
      setState(() => _next = 0);
    });
  }

  void _disarm() {
    _armTimer?.cancel();
    _armTimer = null;
    if (_armed != null && mounted) setState(() => _armed = null);
  }

  Future<void> _play(int index, {bool armedSend = false}) async {
    final step = _story.steps[index];
    // iOS shows nothing of an activity while its app is open, an alert
    // included: the step waits until the app leaves the screen.
    if (Platform.isIOS && step.alert != null && !armedSend) {
      _log('step ${index + 1} armed');
      setState(() => _armed = index);
      _note('Waiting for you to leave the app');
      return;
    }
    if (armedSend) {
      _armTimer = null;
      if (_armed != index || !mounted) return;
      setState(() => _armed = null);
    }
    setState(() => _busy = true);
    await _run(step.button, () async {
      final activity = _activity;
      if (index == 0) {
        if (!await _start(step)) return;
      } else if (activity == null) {
        _note('No activity is running: start again from step 1');
        setState(() => _next = 0);
        return;
      } else if (step.end) {
        await activity.end(
          state: step.state.isEmpty ? null : step.state,
          dismiss: _dismiss,
        );
        _note('Sent the end: ${step.title}');
      } else {
        await activity.update(step.state, alert: step.alert);
        _note(
          step.alert == null
              ? 'Sent: ${step.title}'
              : 'Sent with an alert: ${step.title}',
        );
      }
      setState(() => _next = step.end ? 0 : index + 1);
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<bool> _start(StoryStep step) async {
    final enabled = await LiveActivities.areEnabled();
    final allowed = await LiveActivities.requestPermission();
    _log('enabled: $enabled, permission: $allowed');
    if (!allowed) {
      _note('Notifications are off for this app');
      _show('Notifications are off for this app. Turn them on in Settings.');
      return false;
    }
    // One activity at a time, so this one is the one on screen.
    await LiveActivities.endAll(dismiss: LiveDismiss.immediate);
    final state = {..._design.sampleState(), ...step.state};
    final report = LiveActivities.check(_layout, LiveState.normalize(state));
    for (final item in report.items) {
      _log('check ${item.code} $item');
    }
    final activity = await LiveActivities.start(
      layout: _layout,
      state: state,
      customId: _story.id,
    );
    _log('started ${activity.id} with ${state.keys.join(', ')}');
    setState(() => _activity = activity);
    _note('Started');
    return true;
  }

  Future<void> _run(String what, Future<void> Function() action) async {
    _log('$what: ${_activity?.id}');
    try {
      await action();
      _log('$what done');
    } on LiveActivitiesException catch (e) {
      _log('$what failed: $e');
      _note('Failed: ${e.message}');
      _show(e.message);
    }
  }

  void _show(String message) {
    showAlert(context: context, title: _story.name, message: message);
  }

  String get _whereToLook => Platform.isIOS
      ? 'Lock the phone to see it on the lock screen. Go to the home screen '
            'to see it in the Dynamic Island, and press and hold the island '
            'to open it. While this app is open the island leaves it out.'
      : 'Pull down the notification shade to see it. On Android 16 and '
            'later it sits at the top of the shade, with a chip in the '
            'status bar once you leave the app.';

  /// The number in its circle: filled in the story's colour once reached,
  /// a tick once done.
  Widget _marker(int index) {
    final done = index < _next;
    final current = index == _next;
    final filled = done || current;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? _story.accent : const Color(0xFFFFFFFF),
        border: filled ? null : Border.all(color: _faint, width: 2),
      ),
      child: done
          ? const Icon(Icons.check, size: 16, color: Color(0xFFFFFFFF))
          : Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: current ? const Color(0xFFFFFFFF) : _muted,
              ),
            ),
    );
  }

  Widget _action(int index) {
    final step = _story.steps[index];
    if (_armed == index) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _story.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Now go to the home screen or lock the phone: the alert comes '
              '${_alertDelay.inSeconds} seconds after you leave the app.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                _disarm();
                _note('Alert step cancelled');
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
    final lit = index == _next && !_busy && _armed == null;
    return lit
        ? FilledButton(onPressed: () => _play(index), child: Text(step.button))
        : OutlinedButton(onPressed: null, child: Text(step.button));
  }

  // The line to the next step runs down the left side, behind the content,
  // as tall as the step whatever its button shows.
  Widget _stepRow(int index) {
    final step = _story.steps[index];
    final last = index == _story.steps.length - 1;
    return Stack(
      children: [
        if (!last)
          Positioned(
            left: 13,
            top: 32,
            bottom: 4,
            child: Container(
              width: 2,
              color: index < _next ? _story.accent : _faint,
            ),
          ),
        Padding(
          padding: EdgeInsets.only(left: 42, top: 3, bottom: last ? 0 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: _heading),
              const SizedBox(height: 4),
              Text(step.explain, style: const TextStyle(color: _muted)),
              // A done step keeps only its tick.
              if (index >= _next) ...[
                const SizedBox(height: 10),
                _action(index),
              ],
            ],
          ),
        ),
        Positioned(left: 0, top: 0, child: _marker(index)),
      ],
    );
  }

  Widget _cardButtonNote(CardButton button) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('On the card: ${button.label}', style: _heading),
          const SizedBox(height: 4),
          Text(button.explain, style: const TextStyle(color: _muted)),
        ],
      ),
    );
  }

  Widget _event((String, String) event) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.$1,
            style: const TextStyle(
              fontSize: 14,
              color: _muted,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(event.$2, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.light,
      appBar: AppBar(title: Text(_story.name)),
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          StoryPicture(_story),
          const SizedBox(height: 16),
          Text(_story.summary, style: _heading),
          const SizedBox(height: 6),
          Text(_whereToLook, style: const TextStyle(color: _muted)),
          const SizedBox(height: 28),
          for (var i = 0; i < _story.steps.length; i++) _stepRow(i),
          for (final button in _story.cardButtons) _cardButtonNote(button),
          const SizedBox(height: 32),
          const Text('What happened', style: _heading),
          if (_events.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Nothing yet: start with step 1.',
                style: TextStyle(fontSize: 14, color: _muted),
              ),
            ),
          for (final event in _events) _event(event),
        ],
      ),
    );
  }
}
