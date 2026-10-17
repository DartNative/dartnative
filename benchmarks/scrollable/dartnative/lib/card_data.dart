/// The card feed's data, generated exactly as Legend List's example app
/// generates it (`screens/fixtures/shared/cardsRenderItem.tsx`), so both
/// apps show the same names, avatars, timestamps and text for every index.
library;
import 'dart:math' as math;

const int kCardCount = 1000;

const List<String> kNames = [
  'Alex Thompson',
  'Jordan Lee',
  'Sam Parker',
  'Taylor Kim',
  'Morgan Chen',
  'Riley Zhang',
  'Casey Williams',
  'Quinn Anderson',
  'Blake Martinez',
  'Avery Rodriguez',
  'Drew Campbell',
  'Jamie Foster',
  'Skylar Patel',
  'Charlie Wright',
  'Sage Mitchell',
  'River Johnson',
  'Phoenix Garcia',
  'Jordan Taylor',
  'Reese Cooper',
  'Morgan Bailey',
];

const List<String> kSentences = [
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
  'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
  'Duis aute irure dolor in reprehenderit in voluptate velit esse.',
  'Excepteur sint occaecat cupidatat non proident, sunt in culpa.',
  'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit.',
  'Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet.',
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
  'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
  'Duis aute irure dolor in reprehenderit in voluptate velit esse.',
  'Excepteur sint occaecat cupidatat non proident, sunt in culpa.',
  'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit.',
  'Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet.',
];

/// How many sentences an advanced card holds, the same in every app: card
/// n takes entry (n × 7) mod 13, so neighbouring cards alternate between
/// short and long and a list cannot guess a card's height from its
/// neighbours'.
const List<int> kAdvancedSentences = [1, 2, 3, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40];

/// Images in a card's rail in advanced mode, and the distinct images they
/// are drawn from (the same service as the avatars).
const int kRailLength = 10;
const int kRailImages = 70;

class CardData {
  CardData(this.index)
      : authorName = '${kNames[index % kNames.length]} $index',
        avatarUrl = 'https://i.pravatar.cc/150?img=${index % 20 + 1}',
        timestamp = '${index % 24 < 1 ? 1 : index % 24}h ago',
        body = List.generate(
          (index * 7919) % 12 + 1,
          (i) => kSentences[i % kSentences.length],
        ).join(' ');

  final int index;
  final String authorName;
  final String avatarUrl;
  final String timestamp;
  final String body;

  String get title => 'Item #$index';

  /// The card's text in advanced mode: one to forty sentences
  /// ([kAdvancedSentences]), so a short card sits beside a long one, from
  /// two lines of text to more than a screen.
  String get longBody => List.generate(
        kAdvancedSentences[(index * 7) % kAdvancedSentences.length],
        (i) => kSentences[i % kSentences.length],
      ).join(' ');

  /// Advanced mode: runs the example's PERF_TEST work for this card (the
  /// block under "EXPENSIVE COMPUTATIONS" in its `cardsRenderItem.tsx`) and
  /// returns the two results the example shows: whether `index + 1000` is
  /// prime, and a Fibonacci number computed the slow way. The card calls it
  /// in its build, as the example does in its render. The string and array
  /// work is done too and its results are discarded, as in the example.
  (bool, int) perfTest() {
    bool isPrime(int n) {
      if (n <= 1) return false;
      if (n <= 3) return true;
      if (n % 2 == 0 || n % 3 == 0) return false;
      for (var i = 5; i * i <= n; i += 6) {
        if (n % i == 0 || n % (i + 2) == 0) return false;
      }
      return true;
    }

    int fibonacci(int n) => n <= 1 ? n : fibonacci(n - 1) + fibonacci(n - 2);

    String expensiveStringOp(String str) {
      var result = str;
      for (var i = 0; i < 50; i++) {
        result = result.split('').reversed.join().toLowerCase().toUpperCase();
      }
      return result.substring(0, math.min(10, result.length));
    }

    final primeCheck = isPrime(index + 1000);
    final fibResult = fibonacci(math.min(index % 20 + 15, 25));
    final processedString = expensiveStringOp('$index' * 10);
    final random = math.Random();
    final largeArray = List.generate(1000, (_) => random.nextDouble() * index);
    final sortedFiltered = (largeArray.where((x) => x > index / 2).toList()
          ..sort((a, b) => b.compareTo(a)))
        .take(10)
        .toList();
    // The unshown results feed a value read below, so no compiler can drop
    // the work that made them; the branch never runs.
    final checksum = processedString.length +
        sortedFiltered.length +
        (sortedFiltered.isEmpty ? 0 : sortedFiltered.first.toInt());
    if (checksum == -1) print(processedString);
    return (primeCheck, fibResult);
  }

  /// Advanced mode: the card's rail of images, a different run of the
  /// service's images for every card.
  List<String> get railUrls => List.generate(
        kRailLength,
        (k) => 'https://i.pravatar.cc/150?img=${(index * 7 + k) % kRailImages + 1}',
      );
}
