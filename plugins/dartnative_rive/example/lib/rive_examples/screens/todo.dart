// Ported from rive-flutter's example/lib/examples/todo.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Upstream lists five screens — Flutter Lists, Hero Transitions, State
// Management, Localization, Internationalization — that all open on this one
// placeholder. Theirs, verbatim: a centred "Todo - coming soon".

import 'package:dartnative/dartnative.dart';

import '../theme.dart';

Widget buildTodo(BuildContext context) => const Center(
      child: Text(
        'Todo - coming soon',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 15,
          fontFamily: monoFont,
        ),
      ),
    );
