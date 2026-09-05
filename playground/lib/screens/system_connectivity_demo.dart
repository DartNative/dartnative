/// System info + connectivity demo.
///
/// Showcases dartnative_system (PackageInfo, AppBadge) and
/// dartnative_connectivity — network transport (NWPathMonitor / NetworkCallback
/// via FFI) plus internet reachability (InternetConnection).
import 'dart:async';
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_system/dartnative_system.dart';
import 'package:dartnative_connectivity/connectivity.dart';
import 'home/demo_ui.dart';

class SystemConnectivityDemo extends StatefulWidget {
  const SystemConnectivityDemo({super.key});

  @override
  State<SystemConnectivityDemo> createState() => _SystemConnectivityDemoState();
}

class _SystemConnectivityDemoState extends State<SystemConnectivityDemo> {
  // ── Package Info ──────────────────────────────────────────────────────────
  PackageInfo? _packageInfo;

  // ── App Badge ─────────────────────────────────────────────────────────────
  int _badgeCount = 0;

  // ── Connectivity ──────────────────────────────────────────────────────────
  ConnectivityType? _connectivityType;
  bool? _hasInternet;
  StreamSubscription<ConnectivityType>? _connectivitySub;
  StreamSubscription<bool>? _internetSub;
  final List<String> _connectivityLog = [];

  @override
  void initState() {
    super.initState();
    dnLog(
        '[SystemConnectivityDemo] initState — platform=${Platform.operatingSystem}');
    _loadPackageInfo();
    _startConnectivityMonitor();
    _startInternetMonitor();
  }

  @override
  void dispose() {
    dnLog('[SystemConnectivityDemo] dispose');
    _connectivitySub?.cancel();
    _internetSub?.cancel();
    super.dispose();
  }

  void _loadPackageInfo() {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    dnLog(
        '[SystemConnectivityDemo] _loadPackageInfo — calling SystemFFIBindings...');
    try {
      final info = SystemFFIBindings.instance.getPackageInfo();
      dnLog(
          '[SystemConnectivityDemo] PackageInfo: ${info.appName} ${info.version}+${info.buildNumber}');
      setState(() {
        _packageInfo = info;
      });
    } catch (e, st) {
      dnLog('[SystemConnectivityDemo] ERROR loading PackageInfo: $e\n$st');
    }
  }

  // Transport monitor (Connectivity). Fires immediately on subscribe and on
  // every wifi ↔ cellular ↔ ethernet change — this is NOT reachability.
  void _startConnectivityMonitor() {
    dnLog('[connectivity] transport monitor — subscribing…');
    try {
      _connectivitySub =
          Connectivity().onConnectivityTypeChanged.listen((type) {
        setState(() {
          _connectivityType = type;
          _appendConnectivityLog('transport → ${type.name}');
        });
      });
      dnLog('[connectivity] transport monitor — subscribed OK');
    } catch (e, st) {
      dnLog('[connectivity] ERROR subscribing to transport: $e\n$st');
    }
  }

  // Reachability monitor (InternetConnection). Unlike the transport monitor this
  // POLLS — default every 5 s (InternetConnection().checkInterval) — so it is
  // not instant: a change can take up to that interval to surface. It also
  // re-checks on any transport change, and runs only while subscribed.
  void _startInternetMonitor() {
    dnLog('[connectivity] internet monitor — subscribing…');
    _internetSub = InternetConnection().onInternetChanged.listen((online) {
      setState(() {
        _hasInternet = online;
        _appendConnectivityLog('internet → ${online ? "up" : "down"}');
      });
    });
  }

  Future<void> _checkConnectivity() async {
    dnLog('[connectivity] check — checkConnectivityType + hasInternet…');
    final type = await Connectivity().checkConnectivityType();
    final online = await InternetConnection().hasInternet;
    dnLog('[connectivity] type=${type.name} hasInternet=$online');
    if (!mounted) return;
    setState(() {
      _connectivityType = type;
      _hasInternet = online;
      _appendConnectivityLog('check: ${type.name}, internet=$online');
    });
  }

  void _appendConnectivityLog(String message) {
    _connectivityLog.insert(
        0, '${DateTime.now().toIso8601String().substring(11, 19)}  $message');
    if (_connectivityLog.length > 10) _connectivityLog.removeLast();
  }

  void _setBadge(int count) {
    dnLog('[SystemConnectivityDemo] _setBadge($count)');
    try {
      SystemFFIBindings.instance.updateBadge(count);
      setState(() => _badgeCount = count);
    } catch (e, st) {
      dnLog('[SystemConnectivityDemo] ERROR _setBadge: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'System + Connectivity',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: Container(
        color: kHomeBg,
        child: ListView(
          padding: EdgeInsets.fromLTRB(24,
              isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 24, 24, 24),
          children: [
            // ─── Package Info ──────────────────────────────────────────────
            _SectionHeader('Package Info (FFI → Bundle / PackageManager)'),
            const SizedBox(height: 12),
            if (_packageInfo != null) ...[
              _InfoRow('App name', _packageInfo!.appName),
              _InfoRow('Package', _packageInfo!.packageName),
              _InfoRow('Version', _packageInfo!.version),
              _InfoRow('Build', _packageInfo!.buildNumber),
            ] else
              Text(
                'No package info available',
                style: TextStyle(color: kTextSecondary),
              ),
            const SizedBox(height: 32),

            // ─── App Badge ─────────────────────────────────────────────────
            _SectionHeader('App Badge (FFI → iOS UNUserNotificationCenter)'),
            const SizedBox(height: 12),
            Text(
              'Current badge: $_badgeCount',
              style: TextStyle(color: kTextPrimary, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton('Set 0', () => _setBadge(0)),
                const SizedBox(width: 12),
                _ActionButton('Set 5', () => _setBadge(5)),
                const SizedBox(width: 12),
                _ActionButton('Set 99', () => _setBadge(99)),
              ],
            ),
            const SizedBox(height: 32),

            // ─── Connectivity ──────────────────────────────────────────────
            _SectionHeader(
                'Connectivity — transport (FFI) + internet reachability'),
            const SizedBox(height: 12),
            Text(
              'Transport: ${_connectivityType?.name ?? "checking…"}'
              '${_hasInternet == null ? "" : "   ·   internet: $_hasInternet"}',
              style: TextStyle(color: kTextPrimary, fontSize: 15),
            ),
            const SizedBox(height: 8),
            _ConnectivityBadges(_connectivityType),
            const SizedBox(height: 12),
            _ActionButton('Check now', _checkConnectivity),
            const SizedBox(height: 24),
            Text(
              'Live: transport updates instantly (onConnectivityTypeChanged); '
              'internet is reactive via onInternetChanged but POLLS every 5 s, '
              'so it is not instant — the interval is configurable via '
              'InternetConnection().checkInterval. Tap "Check now" for an '
              'immediate one-shot, or toggle Wi-Fi / Airplane Mode.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ..._connectivityLog.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  e,
                  style: const TextStyle(
                    color: Color(0xFF30D158),
                    fontSize: 13,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ),
            if (_connectivityLog.isEmpty)
              Text(
                'No results yet — tap "Check now" above or toggle Wi-Fi / Airplane Mode',
                style: TextStyle(color: kTextTertiary, fontSize: 13),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: kTextTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: kTextSecondary, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(color: kTextPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kTileBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0A84FF),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ConnectivityBadges extends StatelessWidget {
  const _ConnectivityBadges(this.type);
  final ConnectivityType? type;

  static Color _colorFor(ConnectivityType t) => switch (t) {
        ConnectivityType.wifi => const Color(0xFF30D158),
        ConnectivityType.cellular => const Color(0xFF0A84FF),
        ConnectivityType.ethernet => const Color(0xFF64D2FF),
        ConnectivityType.unknown => kTextSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final t = type;
    if (t == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _colorFor(t).withAlpha(38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _colorFor(t), width: 1),
      ),
      child: Text(
        t.name,
        style: TextStyle(
          color: _colorFor(t),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
