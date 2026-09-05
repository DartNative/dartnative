import 'package:dartnative/dartnative.dart';
import 'package:dartnative_url_launcher/dartnative_url_launcher.dart';

import 'dartnative_plugin_registrant.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const UrlLauncherDemo());
}

class UrlLauncherDemo extends StatelessWidget {
  const UrlLauncherDemo({super.key});

  @override
  Widget build(BuildContext context) => const _DemoScreen();
}

// ── Data model ────────────────────────────────────────────────────────────────

const _kSections = [
  _Section('Web', [
    _Subgroup(null, [
      _Entry('DartNative Website', 'https://www.dartnative.com'),
      _Entry('GitHub – DartNative', 'https://github.com/DartNative'),
    ]),
  ]),
  _Section(
    'Native Apps',
    [
      _Subgroup('Streaming', [
        _Entry(
          'YouTube — Video',
          'https://youtu.be/RgKAFK5djSk?is=9kAp4CLGVlYZ86cZ',
        ),
        _Entry('YouTube — Homepage', 'https://www.youtube.com'),
        _Entry(
          'Spotify — Track',
          'https://open.spotify.com/track/2gmqnkY0jrfz3vnO4FVS4p?si=Iq4S0FcfTKq9gTDHYN1FLw',
        ),
        _Entry(
          'Apple Music — Taylor Swift',
          'https://music.apple.com/us/artist/taylor-swift/159260351',
        ),
      ]),
      _Subgroup('Social', [
        _Entry(
          'Instagram — @cristiano',
          'https://www.instagram.com/cristiano/',
        ),
        _Entry('TikTok — @khaby.lame', 'https://www.tiktok.com/@khaby.lame'),
        _Entry('X — @NASA', 'https://x.com/NASA'),
        _Entry('Facebook — NASA', 'https://www.facebook.com/NASA'),
        _Entry(
          'Snapchat — @kendalljenner',
          'https://www.snapchat.com/add/kendalljenner',
        ),
      ]),
      _Subgroup('Maps & Shopping', [
        _Entry(
          'Google Maps — Roman Forum',
          'https://www.google.com/maps?q=Roman+Forum+Rome',
        ),
        _Entry('Amazon — Product', 'https://a.co/d/02c0eU1h'),
      ]),
      _Subgroup('System', [
        _Entry('Send email', 'mailto:hello@dartnative.com'),
        _Entry('Call phone', 'tel:+15551234567'),
        _Entry('Send SMS', 'sms:+15551234567'),
      ]),
    ],
    description:
        'These URLs are tricky to handle correctly — YouTube video IDs, '
        'Amazon short links, Maps queries. DartNative normalises them and picks '
        'the right native app automatically.',
  ),
];

class _Section {
  const _Section(this.title, this.subgroups, {this.description});
  final String title;
  final List<_Subgroup> subgroups;
  final String? description;
}

class _Subgroup {
  const _Subgroup(this.label, this.entries);
  final String? label;
  final List<_Entry> entries;
}

class _Entry {
  const _Entry(this.label, this.url);
  final String label;
  final String url;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class _DemoScreen extends StatelessWidget {
  const _DemoScreen();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF1C1C1E),
          padding: const EdgeInsets.only(
            top: 60,
            bottom: 20,
            left: 24,
            right: 24,
          ),
          child: Row(
            children: [
              Text(
                'URL Launcher',
                style: TextStyle(
                  color: const Color(0xFFFFFFFF),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFF000000),
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              children: [
                for (final section in _kSections) ...[
                  _SectionHeader(
                    title: section.title,
                    description: section.description,
                  ),
                  for (final subgroup in section.subgroups) ...[
                    if (subgroup.label != null)
                      _SubgroupHeader(label: subgroup.label!),
                    for (final entry in subgroup.entries) _UrlTile(entry: entry),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Headers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.description});
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8E8E93),
              letterSpacing: 1.2,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: TextStyle(fontSize: 12, color: const Color(0xFF8E8E93)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubgroupHeader extends StatelessWidget {
  const _SubgroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8E8E93),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Container(height: 1, color: const Color(0xFF636366)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _UrlTile extends StatefulWidget {
  const _UrlTile({required this.entry});
  final _Entry entry;

  @override
  State<_UrlTile> createState() => _UrlTileState();
}

class _UrlTileState extends State<_UrlTile> {
  _LaunchStatus _status = _LaunchStatus.idle;
  String _detail = '';

  Future<void> _tap() async {
    setState(() {
      _status = _LaunchStatus.launching;
      _detail = '';
    });
    final (ok, note) = await UrlLauncherHelper.open(widget.entry.url);
    setState(() {
      _status = ok ? _LaunchStatus.success : _LaunchStatus.failure;
      _detail = note;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.entry.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.entry.url,
              style: TextStyle(fontSize: 12, color: const Color(0xFF5AADFF)),
            ),
            if (_status != _LaunchStatus.idle) ...[
              const SizedBox(height: 6),
              Text(
                _statusText(_status, _detail),
                style: TextStyle(fontSize: 12, color: _statusColor(_status)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusText(_LaunchStatus s, String detail) => switch (s) {
    _LaunchStatus.launching => 'Opening…',
    _LaunchStatus.success =>
      detail.isEmpty ? 'Opened ✓' : 'Opened via $detail ✓',
    _LaunchStatus.failure =>
      detail.isEmpty ? 'Failed to open' : 'Failed: $detail',
    _LaunchStatus.idle => '',
  };

  Color _statusColor(_LaunchStatus s) => switch (s) {
    _LaunchStatus.launching => const Color(0xFF8E8E93),
    _LaunchStatus.success => const Color(0xFF32D74B),
    _LaunchStatus.failure => const Color(0xFFFF453A),
    _LaunchStatus.idle => const Color(0xFF8E8E93),
  };
}

enum _LaunchStatus { idle, launching, success, failure }
