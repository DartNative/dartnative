import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_connectivity/connectivity.dart';

/// Shows both halves of `dartnative_connectivity`:
///
/// * **InternetConnection** — reachability: [InternetConnection.hasInternet]
///   (a check) and [InternetConnection.onInternetChanged] (a listener).
/// * **Connectivity** — transport type: [Connectivity.checkConnectivityType]
///   (a check) and [Connectivity.onConnectivityTypeChanged] (a listener).
///
/// Toggle Wi-Fi / Airplane Mode on the device to watch the listeners fire.
class ConnectivityDemo extends StatefulWidget {
  const ConnectivityDemo({super.key});

  @override
  State<ConnectivityDemo> createState() => _ConnectivityDemoState();
}

class _ConnectivityDemoState extends State<ConnectivityDemo> {
  // Reachability
  bool? _online;
  StreamSubscription<bool>? _internetSub;

  // Transport type
  ConnectivityType? _type;
  StreamSubscription<ConnectivityType>? _typeSub;

  final List<String> _log = [];

  @override
  void initState() {
    super.initState();

    // Listener: reactive internet status (only runs while subscribed).
    _internetSub = InternetConnection().onInternetChanged.listen((online) {
      setState(() {
        _online = online;
        _appendLog('onInternetChanged → ${online ? "online" : "offline"}');
      });
    });

    // Listener: reactive transport type.
    _typeSub = Connectivity().onConnectivityTypeChanged.listen((type) {
      setState(() {
        _type = type;
        _appendLog('onConnectivityTypeChanged → ${type.name}');
      });
    });
  }

  @override
  void dispose() {
    _internetSub?.cancel();
    _typeSub?.cancel();
    super.dispose();
  }

  void _appendLog(String message) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    _log.insert(0, '$ts  $message');
    if (_log.length > 12) _log.removeLast();
  }

  // Check: one-shot reachability probe.
  Future<void> _checkInternet() async {
    final online = await InternetConnection().hasInternet;
    setState(() {
      _online = online;
      _appendLog('hasInternet → $online');
    });
  }

  // Check: one-shot transport type.
  Future<void> _checkType() async {
    final type = await Connectivity().checkConnectivityType();
    setState(() {
      _type = type;
      _appendLog('checkConnectivityType → ${type.name}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.light,
      appBar: AppBar(
        title: const Text(
          'dartnative_connectivity',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _Section('Internet reachability — InternetConnection'),
          _Value('hasInternet', _online == null ? '…' : '$_online'),
          const SizedBox(height: 12),
          Button(
            title: 'Check internet (hasInternet)',
            variant: ButtonVariant.filled,
            // The native setup zeroes UIButton's content insets and lets Yoga
            // drive sizing, so give it padding or it collapses to text height.
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            onPressed: _checkInternet,
          ),
          const _Hint(
            'Live via onInternetChanged — it re-checks every 5 s, so it is not '
            'instant. The interval is a parameter: '
            'set InternetConnection().checkInterval. '
            'Toggle Airplane Mode and wait a few seconds to see it fire.',
          ),
          const SizedBox(height: 28),
          const _Section('Network type — Connectivity'),
          _Value('type', _type?.name ?? '…'),
          const SizedBox(height: 12),
          Button(
            title: 'Check type (checkConnectivityType)',
            variant: ButtonVariant.filled,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            onPressed: _checkType,
          ),
          const _Hint(
            'Live via onConnectivityTypeChanged — updates instantly '
            'when the transport changes. Toggle Wi-Fi to see it fire.',
          ),
          const SizedBox(height: 28),
          const _Section('Event log'),
          if (_log.isEmpty)
            const _Hint('No events yet.')
          else
            ..._log.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  e,
                  style: const TextStyle(
                    color: Color(0xFF1E9E4A),
                    fontSize: 13,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF636366),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Text(
    '$label: $value',
    style: const TextStyle(color: Color(0xFF111111), fontSize: 16),
  );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
    ),
  );
}
