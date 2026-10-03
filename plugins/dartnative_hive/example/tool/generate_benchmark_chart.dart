import 'dart:io';
import 'dart:math' as math;

/// Draws a horizontal bar chart of hive_ce in a Flutter app against
/// dartnative_hive in a DartNative app, on the same device, from a table of
/// the results document, so the picture can never drift from the numbers.
/// Two charts:
///
/// * `hive-ce`: hive_ce's own benchmark, writes only, one group per number
///   of writes, from the table headed `| Writes | hive_ce, Flutter (ms) |
///   dartnative_hive (ms) |`.
/// * `writes-and-reads`: a write and a read of a short string, each on 1
///   key and on 1000 keys, from the table headed `| Operation | hive_ce,
///   Flutter (ms) | dartnative_hive (ms) |`.
///
///     dart run tool/generate_benchmark_chart.dart <hive-ce|writes-and-reads> \
///       benchmarks/README.md benchmarks/<chart>.svg "iPhone 16 Pro"
///
/// With `--baseline=mmap-false` the first bar is dartnative_hive's own
/// `mmap: false` storage (hive_ce's file storage) in the same DartNative
/// app, for a device with no Flutter app beside it; its tables head that
/// column `mmap: false (ms)`.
///
/// Each group has two bars and says how many times faster, or slower,
/// dartnative_hive is. Each group is drawn to its own linear scale, the
/// longer bar at full width, so the bars' lengths show the ratio; a shared
/// axis would have to span reads of a few microseconds to 100,000 writes.
///
/// To turn the SVG into a PNG at twice its size:
///
///     "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
///       --headless --hide-scrollbars --force-device-scale-factor=2 \
///       --window-size=1240,<the SVG's height> \
///       --screenshot=benchmarks/<chart>.png benchmarks/<chart>.svg

const _background = '#0d1117';
const _panel = '#161b22';
const _panelStroke = '#30363d';
const _titleColour = '#f0f6fc';
const _subtitleColour = '#8b949e';
const _labelColour = '#c9d1d9';
const _legendColour = '#e6edf3';

/// "Nx faster", in dartnative_hive's colour.
const _fasterColour = '#a7f3d0';

/// One colour per bar, plus a lighter shade for its value label, in the
/// order of the table's columns.
const _baselineColours = ('#f59e0b', '#fde68a');
const _dartnativeHive = 'dartnative_hive';
const _dartnativeHiveColours = ('#10b981', '#a7f3d0');

/// What the first bar of each group measures: its table column, its legend
/// and the footnote that says where it was measured.
final class _Baseline {
  const _Baseline(this.column, this.legend, this.whereMeasured);

  final String column;
  final String legend;
  final String whereMeasured;
}

const _baselines = <String, _Baseline>{
  'flutter': _Baseline(
    'hive_ce, Flutter (ms)',
    'hive_ce (Flutter)',
    'hive_ce: version 2.20.1 from pub.dev, in a Flutter app. dartnative_hive: '
        'in a DartNative app. The same device.',
  ),
  'mmap-false': _Baseline(
    'mmap: false (ms)',
    'mmap: false (hive_ce file storage)',
    'Both in the same DartNative app: mmap: false, the file storage of '
        'hive_ce 2.20.1, against the default memory-mapped storage.',
  ),
};

final class _Group {
  const _Group(this.label, this.hiveCeMs, this.dartnativeHiveMs);

  final String label;
  final double hiveCeMs;
  final double dartnativeHiveMs;

  String get verdict => hiveCeMs >= dartnativeHiveMs
      ? '${_ratio(hiveCeMs / dartnativeHiveMs)} faster'
      : '${_ratio(dartnativeHiveMs / hiveCeMs)} slower';
}

/// Two decimals under 1.1, so a small difference never reads "1.0x".
String _ratio(double ratio) => '${ratio.toStringAsFixed(ratio < 1.1 ? 2 : 1)}x';

/// One chart: the table it reads, how a row becomes a group, and its words.
final class _Chart {
  const _Chart({
    required this.header,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.footnotes,
  });

  /// The table's header, with the baseline's column name.
  final String Function(String baselineColumn) header;

  /// The group a row's first cell names, or null when the row is not drawn.
  final String? Function(String name) group;
  final String Function(String device) title;
  final String subtitle;
  final List<String> footnotes;
}

final _charts = <String, _Chart>{
  'hive-ce': _Chart(
    header: (baseline) => '| Writes | $baseline | dartnative_hive (ms) |',
    group: (name) {
      final writes = int.tryParse(name);
      return writes == null ? null : '${_count(writes)} writes';
    },
    title: (device) => 'Hive Benchmark: $device',
    subtitle: 'Profile builds - average of 5 passes - lower is better',
    footnotes: const [],
  ),
  'writes-and-reads': _Chart(
    header: (baseline) => '| Operation | $baseline | dartnative_hive (ms) |',
    group: (name) => name,
    title: (device) => 'Hive Writes and Reads: $device',
    subtitle:
        'Profile builds - 1,000 operations per bar - median of 7 rounds - lower is '
        'better',
    footnotes: const [
      'Each bar is 1000 operations on a short string: awaited puts on 1 key or '
          'on 1000 keys, then a get of each.',
    ],
  ),
};

/// 100000 → "100,000".
String _count(int count) => count.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (match) => '${match[1]},',
);

/// Milliseconds, or seconds from one second up.
String _time(double milliseconds) => milliseconds >= 1000
    ? '${(milliseconds / 1000).toStringAsFixed(2)} s'
    : '${milliseconds.toStringAsFixed(milliseconds < 1 ? 3 : 2)} ms';

void main(List<String> arguments) {
  const baselineFlag = '--baseline=';
  final flags = arguments.where((a) => a.startsWith('--')).toList();
  final args = arguments.where((a) => !a.startsWith('--')).toList();
  final chart = args.isEmpty ? null : _charts[args[0]];
  final baselineName = flags.isEmpty
      ? 'flutter'
      : flags.length == 1 && flags.single.startsWith(baselineFlag)
      ? flags.single.substring(baselineFlag.length)
      : null;
  final baseline = _baselines[baselineName];
  if (chart == null || baseline == null || args.length < 4) {
    stderr.writeln(
      'usage: generate_benchmark_chart.dart '
      '<${_charts.keys.join('|')}> <results.md> <out.svg> <device name> '
      '[subtitle] [--baseline=${_baselines.keys.join('|')}]',
    );
    exitCode = 64;
    return;
  }

  final header = chart.header(baseline.column);
  final groups = _parse(File(args[1]).readAsStringSync(), chart, header);
  if (groups.isEmpty) {
    stderr.writeln(
      'No rows to draw in ${args[1]}. Expected a table headed '
      '"$header".',
    );
    exitCode = 65;
    return;
  }

  final svg = _draw(
    groups,
    title: chart.title(args[3]),
    subtitle: args.length > 4 ? args[4] : chart.subtitle,
    baselineLegend: baseline.legend,
    footnotes: [baseline.whereMeasured, ...chart.footnotes],
  );
  File(args[2]).writeAsStringSync(svg);
  stdout.writeln('Wrote ${args[2]} (${groups.length} groups).');
}

/// The drawn rows of the first table headed [header]; the document's other
/// tables are left alone. The first three columns are the row's name, the
/// baseline and dartnative_hive, in milliseconds.
List<_Group> _parse(String markdown, _Chart chart, String header) {
  final groups = <_Group>[];
  var inTable = false;
  for (final line in markdown.split('\n')) {
    final trimmed = line.trim();
    if (!inTable) {
      inTable = trimmed.startsWith(header);
      continue;
    }
    if (!trimmed.startsWith('|') || !trimmed.endsWith('|')) break;
    final cells = trimmed
        .substring(1, trimmed.length - 1)
        .split('|')
        .map((cell) => cell.trim())
        .toList();
    if (cells.length < 3) continue;
    final label = chart.group(cells[0]);
    final hiveCe = double.tryParse(cells[1]);
    final dartnativeHive = double.tryParse(cells[2]);
    if (label == null || hiveCe == null || dartnativeHive == null) continue;
    if (hiveCe <= 0 || dartnativeHive <= 0) continue;
    groups.add(_Group(label, hiveCe, dartnativeHive));
  }
  return groups;
}

String _draw(
  List<_Group> groups, {
  required String title,
  required String subtitle,
  required String baselineLegend,
  required List<String> footnotes,
}) {
  // Groups keep the order they appear in, so the chart reads like the table.
  const width = 1240;
  const left = 66.0;
  const right = 1182.0;
  const plotLeft = 300.0;
  // The longest bar still has to fit its value label before the verdict
  // column, which is right-aligned on the panel's inner edge.
  const valueLabelRoom = 190.0;
  const verdictRight = 1182.0;
  const barHeight = 12.0;
  const barGap = 4.0;
  const groupGap = 22.0;
  const top = 188.0;

  final height = top + groups.length * (2 * (barHeight + barGap) + groupGap);
  final plotBottom = height - 20;
  // Room for the footnote lines.
  final totalHeight = plotBottom + 66 + footnotes.length * 19;

  // Each group's own linear scale: its longer bar takes the full width.
  const fullWidth = right - plotLeft - valueLabelRoom;

  final buffer = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$width" '
      'height="${totalHeight.toStringAsFixed(0)}" '
      'viewBox="0 0 $width ${totalHeight.toStringAsFixed(0)}" role="img" '
      'aria-labelledby="title description">',
    )
    ..writeln('  <title id="title">${_escape(title)}</title>')
    ..writeln(
      '  <desc id="description">Elapsed-time comparison '
      'of hive_ce and dartnative_hive across '
      '${groups.length} cases. Lower is better.</desc>',
    )
    ..writeln(
      '  <rect width="$width" '
      'height="${totalHeight.toStringAsFixed(0)}" fill="$_background"/>',
    )
    ..writeln(
      '  <rect x="28" y="24" width="1184" '
      'height="${(totalHeight - 48).toStringAsFixed(0)}" rx="18" '
      'fill="$_panel" stroke="$_panelStroke"/>',
    );

  // Title, subtitle, legend.
  buffer
    ..writeln(
      '  <g font-family="-apple-system, BlinkMacSystemFont, '
      'Segoe UI, sans-serif">',
    )
    ..writeln(
      '    <text x="$left" y="77" fill="$_titleColour" font-size="27" '
      'font-weight="700">${_escape(title)}</text>',
    )
    ..writeln(
      '    <text x="${left + 1}" y="108" fill="$_subtitleColour" '
      'font-size="14">${_escape(subtitle)}</text>',
    );
  var legendX = left;
  for (final (key, (fill, _)) in [
    (baselineLegend, _baselineColours),
    (_dartnativeHive, _dartnativeHiveColours),
  ]) {
    buffer
      ..writeln(
        '    <rect x="${legendX.toStringAsFixed(1)}" y="138" '
        'width="15" height="15" rx="3" fill="$fill"/>',
      )
      ..writeln(
        '    <text x="${(legendX + 23).toStringAsFixed(1)}" y="151" '
        'fill="$_legendColour" font-size="13">${_escape(key)}</text>',
      );
    legendX += 48 + key.length * 7.0;
  }
  buffer.writeln('  </g>');

  // Bars.
  buffer.writeln(
    '  <g font-family="-apple-system, BlinkMacSystemFont, '
    'Segoe UI, sans-serif">',
  );
  var y = top;
  for (final group in groups) {
    const blockHeight = 2 * (barHeight + barGap);
    buffer.writeln(
      '    <text x="${plotLeft - 18}" '
      'y="${(y + blockHeight / 2 + 4).toStringAsFixed(1)}" '
      'fill="$_labelColour" font-size="14" font-weight="600" '
      'text-anchor="end">${_escape(group.label)}</text>',
    );
    for (final ((fill, textFill), ms) in [
      (_baselineColours, group.hiveCeMs),
      (_dartnativeHiveColours, group.dartnativeHiveMs),
    ]) {
      final longest = math.max(group.hiveCeMs, group.dartnativeHiveMs);
      final barWidth = math.max(3.0, fullWidth * ms / longest);
      buffer
        ..writeln(
          '    <rect x="$plotLeft" y="${y.toStringAsFixed(1)}" '
          'width="${barWidth.toStringAsFixed(1)}" height="$barHeight" '
          'rx="4" fill="$fill"/>',
        )
        ..writeln(
          '    <text '
          'x="${(plotLeft + barWidth + 8).toStringAsFixed(1)}" '
          'y="${(y + 10).toStringAsFixed(1)}" fill="$textFill" '
          'font-size="11" font-weight="600" text-anchor="start">'
          '${_time(ms)}</text>',
        );
      y += barHeight + barGap;
    }
    // One column for every group's verdict, centred on its two bars:
    // always a number, faster or slower.
    buffer.writeln(
      '    <text x="$verdictRight" '
      'y="${(y - blockHeight / 2 + 2).toStringAsFixed(1)}" '
      'fill="$_fasterColour" '
      'font-size="15" font-weight="700" '
      'text-anchor="end">${_escape(group.verdict)}</text>',
    );
    y += groupGap;
  }
  buffer.writeln('  </g>');

  // Footnotes: about 110 characters each, to fit the panel at 12px.
  for (var i = 0; i < footnotes.length; i++) {
    buffer.writeln(
      '  <text x="$left" '
      'y="${(plotBottom + 36 + i * 19).toStringAsFixed(1)}" '
      'fill="$_subtitleColour" font-family="-apple-system, '
      'BlinkMacSystemFont, Segoe UI, sans-serif" font-size="12">'
      '${_escape(footnotes[i])}</text>',
    );
  }

  buffer.writeln('</svg>');
  return buffer.toString();
}

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
