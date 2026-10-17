package com.dartnative.benchmarks.cards

/// The card feed's data, generated exactly as Legend List's example app
/// generates it (`screens/fixtures/shared/cardsRenderItem.tsx`), so every
/// app shows the same names, avatars, timestamps and text for every index.
object CardFixture {
    const val COUNT = 1000

    /// Images in a card's rail in advanced mode, and the distinct images
    /// they are drawn from (the same service as the avatars).
    const val RAIL_LENGTH = 10
    const val RAIL_IMAGES = 70

    private val names = listOf(
        "Alex Thompson", "Jordan Lee", "Sam Parker", "Taylor Kim", "Morgan Chen",
        "Riley Zhang", "Casey Williams", "Quinn Anderson", "Blake Martinez",
        "Avery Rodriguez", "Drew Campbell", "Jamie Foster", "Skylar Patel",
        "Charlie Wright", "Sage Mitchell", "River Johnson", "Phoenix Garcia",
        "Jordan Taylor", "Reese Cooper", "Morgan Bailey",
    )

    /// How many sentences an advanced card holds, the same in every app:
    /// card n takes entry (n × 7) mod 13, so neighbouring cards alternate
    /// between short and long and a list cannot guess a card's height from
    /// its neighbours'.
    val ADVANCED_SENTENCES = intArrayOf(1, 2, 3, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40)

    val sentences = listOf(
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
    )

    val cards: List<CardData> = List(COUNT) { index ->
        CardData(
            index = index,
            authorName = "${names[index % names.size]} $index",
            avatarUrl = "https://i.pravatar.cc/150?img=${index % 20 + 1}",
            timestamp = "${if (index % 24 < 1) 1 else index % 24}h ago",
            title = "Item #$index",
            body = List((index * 7919) % 12 + 1) { sentences[it % sentences.size] }.joinToString(" "),
        )
    }
}

data class CardData(
    val index: Int,
    val authorName: String,
    val avatarUrl: String,
    val timestamp: String,
    val title: String,
    val body: String,
) {
    /// The card's text in advanced mode: one to forty sentences
    /// (ADVANCED_SENTENCES), so a short card sits beside a long one, from
    /// two lines of text to more than a screen.
    val longBody: String by lazy {
        List(CardFixture.ADVANCED_SENTENCES[(index * 7) % CardFixture.ADVANCED_SENTENCES.size]) {
            CardFixture.sentences[it % CardFixture.sentences.size]
        }.joinToString(" ")
    }

    /// Advanced mode: runs the example's PERF_TEST work for this card (the
    /// block under "EXPENSIVE COMPUTATIONS" in its `cardsRenderItem.tsx`)
    /// and returns the two results the example shows. It runs when the card
    /// is bound to its row, as the example runs it in its render. The string
    /// and array work is done too; its results feed a branch that never
    /// runs, so the compiler keeps it.
    fun perfTest(): Pair<Boolean, Int> {
        fun isPrime(n: Int): Boolean {
            if (n <= 1) return false
            if (n <= 3) return true
            if (n % 2 == 0 || n % 3 == 0) return false
            var i = 5
            while (i * i <= n) {
                if (n % i == 0 || n % (i + 2) == 0) return false
                i += 6
            }
            return true
        }
        fun fibonacci(n: Int): Int = if (n <= 1) n else fibonacci(n - 1) + fibonacci(n - 2)
        fun expensiveStringOp(str: String): String {
            var result = str
            repeat(50) { result = result.reversed().lowercase().uppercase() }
            return result.take(10)
        }
        val primeCheck = isPrime(index + 1000)
        val fibResult = fibonacci(minOf(index % 20 + 15, 25))
        val processedString = expensiveStringOp(index.toString().repeat(10))
        val largeArray = List(1000) { kotlin.random.Random.nextDouble() * index }
        val sortedFiltered = largeArray.filter { it > index / 2.0 }.sortedDescending().take(10)
        val checksum = processedString.length + sortedFiltered.size +
            (sortedFiltered.firstOrNull()?.toInt() ?: 0)
        if (checksum == -1) println(processedString)
        return primeCheck to fibResult
    }

    /// Advanced mode: the card's rail of images, a different run of the
    /// service's images for every card.
    val railUrls get() = List(CardFixture.RAIL_LENGTH) { k ->
        "https://i.pravatar.cc/150?img=${(index * 7 + k) % CardFixture.RAIL_IMAGES + 1}"
    }
}
