/// Legend List's "Cards" and chat screens, built with DartNative for the
/// scrolling benchmark in `benchmarks/scrollable`.
///
/// The app opens straight on one screen, as each React Native app does, and
/// each screen is its own app, such as "ChatList (DN)". README.md explains
/// how the iOS app id is set:
///
///   dn run --release                                   # Cards
///   dn run --release --dart-define=BENCH_SCREEN=chat   # Chat
///   dn run --release --dart-define=BENCH_SCREEN=empty  # Empty
///
/// Empty is a screen with nothing to scroll: a bar and a line of text. Its
/// memory is what the app costs before any list, the baseline under every
/// other screen's number.
library;
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import 'bench_env.dart';
import 'bench_memory.dart';
import 'card_data.dart';
import 'chat_screen.dart';
import 'dartnative_plugin_registrant.dart';
import 'item_card.dart';

const String _screen = String.fromEnvironment('BENCH_SCREEN', defaultValue: 'cards');

/// How far beyond the viewport the list keeps rows built; the rows it lets
/// go are reused for the rows that scroll in (`recycleItems`), as Legend
/// List's example recycles its items. By default the window is 250 points
/// on each side (`cacheExtent`), Legend List's draw distance and Flutter's
/// default, so every app holds the same amount of content whatever a row
/// holds. `BENCH_KEEP_ALIVE=n` counts the window in rows instead, and 0
/// holds every row the user has scrolled past, the list's default, with
/// nothing to reuse.
///
///   dn run --release --dart-define=BENCH_KEEP_ALIVE=4
const int _keepAlive = int.fromEnvironment('BENCH_KEEP_ALIVE', defaultValue: -1);
double? get _cacheExtent => _keepAlive < 0 ? 250 : null;
int? get _keepAliveCount => _keepAlive > 0 ? _keepAlive : null;
bool get _recycle => _keepAlive != 0;

/// `BENCH_LOG=1` runs the app with the framework's verbose log, written
/// to `Documents/bench_log.txt` in the app's container. Leave it off for a
/// measured run, because the log costs frames.
const bool _log = String.fromEnvironment('BENCH_LOG') == '1';

void main() {
  void start() {
    DartNativePluginRegistrant.registerAll();
    startHeapReport();
    runApp(App(
      home: switch (_screen) {
        'chat' => ChatScreen(thread: loadChatThread(), keepAliveCount: _keepAliveCount, cacheExtent: _cacheExtent, recycleItems: _recycle),
        'empty' => const EmptyScreen(),
        _ => const CardsScreen(),
      },
    ));
  }

  if (_log) {
    DartNativeLogger.run(start, verbose: true, saveToFile: true,
        filePath: '${benchEnv('HOME')}/Documents/bench_log.txt');
  } else {
    start();
  }
}

/// Nothing to scroll: the bar and one line of text, the same in every app.
class EmptyScreen extends StatelessWidget {
  const EmptyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kScreenBackground,
        appBar: AppBar(
          backgroundColor: headerBackground(context),
          toolbarHeight: Platform.isAndroid ? 56 : null,
          title: const Text('Empty (DN)'),
        ),
        body: const Center(child: Text('Nothing to scroll')),
      );
}

final List<CardData> _cards = List.generate(kCardCount, CardData.new);

/// The cards the bar's Scroll button goes to, in turn, the same in every
/// app. Each press scrolls, animated, until that card's top is at the top
/// of the list ([FastListController.scrollToItem]). The list opens at its
/// first card and every scroll goes down it, away from there. Two are
/// short: the first, to card 1, lands among cards every list has measured,
/// so it shows where a card's title sits when the card is at the top, and
/// the one to card 402 moves two cards. The others go far, hundreds of
/// cards, past cards no list has measured.
const kScrollTargets = [1, 400, 402, 700, 950];

/// One card per row: the example's `LegendList` with 1,000 cards and a
/// header box, in the benchmark's advanced mode: one to forty sentences per
/// card and a rail of ten images inside each ([ItemCard] keeps the
/// example's plain card for `advanced: false`). The bar's Scroll button
/// animates to the next card of [kScrollTargets], as the example's own
/// scroll-to fixtures do.
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _list = FastListController();
  int _nextTarget = 0;

  void _scroll() {
    // The list's first row is the header box, so card n is row n + 1.
    final card = kScrollTargets[_nextTarget % kScrollTargets.length];
    _nextTarget++;
    _list.scrollToItem(card + 1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kScreenBackground,
        appBar: AppBar(
          backgroundColor: headerBackground(context),
          // React Native's stack header is 56 dp on Android; on iOS both
          // apps use the system navigation bar.
          toolbarHeight: Platform.isAndroid ? 56 : null,
          title: const Text('Cards (DN)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              tooltip: 'Scroll',
              onPressed: _scroll,
            ),
          ],
        ),
        body: FastList(
          controller: _list,
          itemCount: _cards.length + 1,
          keepAliveCount: _keepAliveCount,
          cacheExtent: _cacheExtent,
          recycleItems: _recycle,
          itemBuilder: (context, i) => i == 0
              ? const ListHeaderBox()
              : ItemCard(
                  data: _cards[i - 1],
                  width: MediaQuery.of(context).size.width - 24,
                  advanced: true,
                ),
        ),
      );
}
