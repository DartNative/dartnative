package com.dartnative.benchmarks.cards

import android.os.Bundle
import android.view.View
import android.view.ViewTreeObserver
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.LinearSmoothScroller
import androidx.recyclerview.widget.RecyclerView

/// Legend List's "Cards" screen and its chat, written in Kotlin on a
/// RecyclerView for the scrolling benchmark. The app opens straight on
/// one screen, chosen when it is built, as the DartNative app does:
///
///   ./gradlew assembleRelease                      # Cards
///   ./gradlew assembleRelease -PbenchScreen=chat   # Chat
class MainActivity : AppCompatActivity() {
    private var nextTarget = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Edge to edge on every Android version, as the React Native and
        // DartNative apps are: the toolbar's colour runs under the status
        // bar and the list under the navigation bar.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        setContentView(R.layout.activity_main)
        val chatScreen = BuildConfig.BENCH_SCREEN == "chat"
        val toolbar = findViewById<Toolbar>(R.id.toolbar)
        toolbar.title = if (chatScreen) "Chat (Kotlin)" else "Cards (Kotlin)"
        // The toolbar's content sits below the status bar.
        val toolbarHeight = toolbar.layoutParams.height
        ViewCompat.setOnApplyWindowInsetsListener(toolbar) { v, insets ->
            val top = insets.getInsets(WindowInsetsCompat.Type.statusBars()).top
            v.updatePadding(top = top)
            v.layoutParams = v.layoutParams.apply { height = toolbarHeight + top }
            insets
        }
        val list = findViewById<RecyclerView>(R.id.list)
        if (chatScreen) {
            // The example's chat: its background, drawn under the
            // navigation bar too, 16 dp of padding around the thread, and
            // the thread kept above the navigation bar.
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
            findViewById<View>(R.id.root).setBackgroundColor(Chat.BACKGROUND)
            list.setBackgroundColor(Chat.BACKGROUND)
            val pad = (16 * resources.displayMetrics.density).toInt()
            list.setPadding(pad, pad, pad, pad)
            list.clipToPadding = false
            ViewCompat.setOnApplyWindowInsetsListener(list.parent as View) { v, insets ->
                v.updatePadding(bottom = insets.getInsets(WindowInsetsCompat.Type.navigationBars()).bottom)
                insets
            }
            val thread = Chat.load(this)
            list.adapter = ChatAdapter(thread.asReversed())
            // Newest first, laid out from the bottom up: the list opens at
            // the newest message.
            list.layoutManager = LinearLayoutManager(this, RecyclerView.VERTICAL, true)
            // The bar's Scroll button animates to the next message of
            // CHAT_SCROLL_TARGETS. messageRows holds each message's position
            // in the newest-first list, by the message's number.
            val messageRows = thread.indices
                .filter { thread[it].sticker == null && thread[it].photo == null }
                .map { thread.size - 1 - it }
            toolbar.inflateMenu(R.menu.cards)
            // The Chat screen's scrolls go up the history: an up arrow, as
            // in the other apps.
            val scroll = toolbar.menu.findItem(R.id.scroll)
            scroll.setIcon(R.drawable.ic_arrow_upward)
            scroll.icon?.setTint(getColor(R.color.header_text))
            toolbar.setOnMenuItemClickListener { clicked ->
                if (clicked.itemId != R.id.scroll) return@setOnMenuItemClickListener false
                val position = messageRows[CHAT_SCROLL_TARGETS[nextTarget % CHAT_SCROLL_TARGETS.size]]
                nextTarget++
                scrollToTop(list, position)
                true
            }
            return
        }
        // The Cards screen is in the benchmark's advanced mode (CardAdapter
        // keeps the example's plain card for advanced = false). Its bar's
        // Scroll button animates to the next card of SCROLL_TARGETS.
        list.adapter = CardAdapter(advanced = true)
        toolbar.inflateMenu(R.menu.cards)
        val scroll = toolbar.menu.findItem(R.id.scroll)
        toolbar.setOnMenuItemClickListener { clicked ->
            if (clicked.itemId != R.id.scroll) return@setOnMenuItemClickListener false
            // The list's first row is the header box, so card n is
            // position n + 1.
            val card = SCROLL_TARGETS[nextTarget % SCROLL_TARGETS.size]
            nextTarget++
            scrollToTop(list, card + 1)
            true
        }
        scroll.icon?.setTint(getColor(R.color.header_text))
        list.layoutManager = LinearLayoutManager(this)
    }

    private companion object {
        /// Where the Scroll button goes, in turn, the same in every app:
        /// card numbers, each brought to the top of the list with an
        /// animated scroll. The list opens at its first card and every
        /// scroll goes down it, away from there. Two are short: the first,
        /// to card 1, lands among cards every list has measured, so it
        /// shows where a card's title sits when the card is at the top, and
        /// the one to card 402 moves two cards. The others go far, hundreds
        /// of cards, past cards no list has measured.
        val SCROLL_TARGETS = intArrayOf(1, 400, 402, 700, 950)

        /// The Chat screen's Scroll targets, the same in every app: message
        /// numbers (0 is the oldest, 999 the newest), each brought to the
        /// top of the list with an animated scroll. The first, to a message
        /// a few rows from the newest one where the thread opens, lands
        /// among rows every list has measured, so it shows where a
        /// message's top sits when it is at the top. Every scroll goes up
        /// the history, away from where the thread opens: the one to
        /// message 598 moves two messages, the others hundreds, past
        /// messages no list has measured, the oldest last.
        val CHAT_SCROLL_TARGETS = intArrayOf(996, 600, 598, 300, 0)
    }

    /// Animates [position] to the top of [list] with the platform's own
    /// LinearSmoothScroller, which snaps the row's start to the list's start
    /// (the top of the screen, even for a list laid out from the bottom).
    /// For a row more than a screen away, the list first jumps to a screen
    /// short of it, as Android's own apps do, because at the scroller's
    /// speed hundreds of rows would take tens of seconds. The jump takes
    /// effect at the next layout, so the animation starts once that layout
    /// is done and the scroller measures its distance from where the jump
    /// left the list.
    private fun scrollToTop(list: RecyclerView, position: Int) {
        val lm = list.layoutManager as LinearLayoutManager
        val first = lm.findFirstVisibleItemPosition()
        val last = lm.findLastVisibleItemPosition()
        val lead = maxOf(2, last - first + 1)
        val scroller = object : LinearSmoothScroller(this) {
            override fun getVerticalSnapPreference() = SNAP_TO_START
        }
        scroller.targetPosition = position
        val near = when {
            position > last + lead -> position - lead
            position < first - lead -> position + lead
            else -> null
        }
        if (near == null) {
            lm.startSmoothScroll(scroller)
            return
        }
        lm.scrollToPositionWithOffset(near, 0)
        list.viewTreeObserver.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                list.viewTreeObserver.removeOnGlobalLayoutListener(this)
                lm.startSmoothScroll(scroller)
            }
        })
    }
}
