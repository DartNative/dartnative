// Ported from rive-flutter's example/lib/examples/responsive_layouts.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Upstream:
//   FileLoader.fromAsset('assets/layout_test.riv', riveFactory: …)
//   RiveWidgetBuilder(… RiveWidget(controller:, fit: Fit.layout,
//                                  layoutScaleFactor: 1 / 2))
//
// Ours: the same file, `RiveFit.layout`, `layoutScaleFactor: 1 / 2`, filling
// the route as theirs does — rotate the phone to see the layout reflow. There
// is no loader and no builder: the platform runtime decodes the .riv, so
// there is no loading or failed state to switch on. The file is data-bound;
// its content appears once the default view-model instance is bound, which
// `Rive.autoBind` (on by default) does as upstream's controller does.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

Widget buildResponsiveLayouts(BuildContext context) => const Rive(
      asset: 'assets/rive/layout_test.riv',
      fit: RiveFit.layout,
      layoutScaleFactor: 1 / 2,
    );
