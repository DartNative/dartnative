import Foundation

/// The card feed's data, generated exactly as Legend List's example app
/// generates it (`screens/fixtures/shared/cardsRenderItem.tsx`), so every
/// app shows the same names, avatars, timestamps and text for every index.
enum CardFixture {
  static let count = 1000

  static let names = [
    "Alex Thompson", "Jordan Lee", "Sam Parker", "Taylor Kim", "Morgan Chen",
    "Riley Zhang", "Casey Williams", "Quinn Anderson", "Blake Martinez",
    "Avery Rodriguez", "Drew Campbell", "Jamie Foster", "Skylar Patel",
    "Charlie Wright", "Sage Mitchell", "River Johnson", "Phoenix Garcia",
    "Jordan Taylor", "Reese Cooper", "Morgan Bailey",
  ]

  /// How many sentences an advanced card holds, the same in every app:
  /// card n takes entry (n × 7) mod 13, so neighbouring cards alternate
  /// between short and long and a list cannot guess a card's height from
  /// its neighbours'.
  static let advancedSentences = [1, 2, 3, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40]

  static let sentences = [
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
    "Duis aute irure dolor in reprehenderit in voluptate velit esse.",
    "Excepteur sint occaecat cupidatat non proident, sunt in culpa.",
    "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit.",
    "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet.",
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
    "Duis aute irure dolor in reprehenderit in voluptate velit esse.",
    "Excepteur sint occaecat cupidatat non proident, sunt in culpa.",
    "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit.",
    "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet.",
  ]

  static let cards: [CardData] = (0..<count).map(CardData.init)

  /// Images in a card's rail in advanced mode, and the distinct images
  /// they are drawn from (the same service as the avatars).
  static let railLength = 10
  static let railImages = 70
}

struct CardData {
  let index: Int
  let authorName: String
  let avatarURL: URL
  let timestamp: String
  let title: String
  let body: String

  init(index: Int) {
    self.index = index
    authorName = "\(CardFixture.names[index % CardFixture.names.count]) \(index)"
    avatarURL = URL(string: "https://i.pravatar.cc/150?img=\(index % 20 + 1)")!
    timestamp = "\(index % 24 < 1 ? 1 : index % 24)h ago"
    title = "Item #\(index)"
    let n = (index * 7919) % 12 + 1
    body = (0..<n).map { CardFixture.sentences[$0 % CardFixture.sentences.count] }
      .joined(separator: " ")
  }

  /// The card's text in advanced mode: one to forty sentences
  /// (`CardFixture.advancedSentences`), so a short card sits beside a long
  /// one, from two lines of text to more than a screen.
  var longBody: String {
    let n = CardFixture.advancedSentences[(index * 7) % CardFixture.advancedSentences.count]
    return (0..<n).map { CardFixture.sentences[$0 % CardFixture.sentences.count] }
      .joined(separator: " ")
  }

  /// Advanced mode: runs the example's PERF_TEST work for this card (the
  /// block under "EXPENSIVE COMPUTATIONS" in its `cardsRenderItem.tsx`) and
  /// returns the two results the example shows. It runs when the card is
  /// prepared for display, as the example runs it in its render. The string
  /// and array work is done too; its results feed a branch that never runs,
  /// so the compiler keeps it.
  func perfTest() -> (prime: Bool, fib: Int) {
    func isPrime(_ n: Int) -> Bool {
      if n <= 1 { return false }
      if n <= 3 { return true }
      if n % 2 == 0 || n % 3 == 0 { return false }
      var i = 5
      while i * i <= n {
        if n % i == 0 || n % (i + 2) == 0 { return false }
        i += 6
      }
      return true
    }
    func fibonacci(_ n: Int) -> Int { n <= 1 ? n : fibonacci(n - 1) + fibonacci(n - 2) }
    func expensiveStringOp(_ str: String) -> String {
      var result = str
      for _ in 0..<50 { result = String(result.reversed()).lowercased().uppercased() }
      return String(result.prefix(10))
    }
    let primeCheck = isPrime(index + 1000)
    let fibResult = fibonacci(min(index % 20 + 15, 25))
    let processedString = expensiveStringOp(String(repeating: String(index), count: 10))
    let largeArray = (0..<1000).map { _ in Double.random(in: 0..<1) * Double(index) }
    let sortedFiltered = Array(largeArray.filter { $0 > Double(index) / 2 }.sorted(by: >).prefix(10))
    let checksum = processedString.count + sortedFiltered.count + Int(sortedFiltered.first ?? 0)
    if checksum == -1 { print(processedString) }
    return (primeCheck, fibResult)
  }

  /// Advanced mode: the card's rail of images, a different run of the
  /// service's images for every card.
  var railURLs: [URL] {
    (0..<CardFixture.railLength).map { k in
      URL(string: "https://i.pravatar.cc/150?img=\((index * 7 + k) % CardFixture.railImages + 1)")!
    }
  }
}
