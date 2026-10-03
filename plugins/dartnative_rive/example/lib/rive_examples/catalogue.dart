// The catalogue of screens, mirroring rive-flutter's own example app.
//
// Upstream groups its ~41 screens into seven sections (see their
// `example/lib/main.dart`). We keep the same sections, the same order and the
// same screen names, so the two apps can be walked side by side.
//
// Every entry states its `status`. That is the honest part of this port: a
// screen upstream has that we cannot yet show is listed anyway, with the
// plugin feature it waits on, rather than quietly dropped. Counting the
// entries tells you how far the port has come.

import 'package:dartnative/dartnative.dart';

/// How far a screen has been ported.
enum PortStatus {
  /// Ported and working against our API.
  done,

  /// Upstream's screen exercises a plugin feature we have not built yet.
  /// [Entry.blockedOn] names it.
  blocked,

  /// Upstream ships this as an unimplemented `Todo`, so there is nothing to
  /// port. We list it to keep the two menus aligned.
  upstreamTodo,
}

/// One screen in the catalogue.
class Entry {
  const Entry(
    this.name,
    this.description, {
    this.builder,
    this.status = PortStatus.done,
    this.blockedOn,
    this.upstreamFile,
    this.selfManaged = false,
  });

  /// Upstream's own name for the screen, verbatim.
  final String name;

  /// Upstream's own one-line description, verbatim where it still applies.
  final String description;

  /// Null unless [status] is [PortStatus.done].
  final WidgetBuilder? builder;

  final PortStatus status;

  /// For [PortStatus.blocked]: the plugin
  /// feature or platform capability the screen needs.
  final String? blockedOn;

  /// The file in `rive-flutter/example/lib/examples/` this came from.
  final String? upstreamFile;

  /// When true the screen supplies its own Scaffold and AppBar, and the
  /// catalogue shows it directly instead of wrapping it. Upstream's `_Page`
  /// has the same flag for the same reason.
  final bool selfManaged;
}

/// A named group of screens, matching one of upstream's sections.
class Section {
  const Section(this.title, this.entries);

  final String title;
  final List<Entry> entries;
}
