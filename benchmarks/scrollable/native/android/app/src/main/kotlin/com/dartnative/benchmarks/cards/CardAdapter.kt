package com.dartnative.benchmarks.cards

import android.annotation.SuppressLint
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.animation.DecelerateInterpolator
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import coil.load
import kotlin.math.abs
import kotlin.math.min

/// The feed: the header box at position 0, then the 1,000 cards. A tap
/// expands a card's text; a swipe to the left reveals the 80 dp "Complete"
/// action behind it, which settles open past half the action's width and
/// closed otherwise, as the example's `Swipeable` does.
class CardAdapter(private val advanced: Boolean = false) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {
    private val expanded = HashSet<Int>()

    /// Advanced mode: the rails share one pool of image views across cards,
    /// as the example's nested lists share their recycled cells.
    private val railPool = RecyclerView.RecycledViewPool()

    override fun getItemCount() = CardFixture.COUNT + 1

    override fun getItemViewType(position: Int) = if (position == 0) HEADER else CARD

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        val inflater = LayoutInflater.from(parent.context)
        return if (viewType == HEADER) {
            object : RecyclerView.ViewHolder(inflater.inflate(R.layout.item_header, parent, false)) {}
        } else {
            CardHolder(inflater.inflate(R.layout.item_card, parent, false), advanced, railPool)
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        if (holder !is CardHolder) return
        val index = position - 1
        holder.show(CardFixture.cards[index], expanded.contains(index), advanced)
        holder.card.setOnClickListener {
            if (!expanded.add(index)) expanded.remove(index)
            notifyItemChanged(position)
        }
    }

    class CardHolder(view: View, advanced: Boolean, railPool: RecyclerView.RecycledViewPool) : RecyclerView.ViewHolder(view) {
        val card: View = view.findViewById(R.id.card)
        private val avatar: ImageView = view.findViewById(R.id.avatar)
        private val author: TextView = view.findViewById(R.id.author)
        private val timestamp: TextView = view.findViewById(R.id.timestamp)
        private val title: TextView = view.findViewById(R.id.title)
        private val body: TextView = view.findViewById(R.id.body)
        private val rail: RecyclerView = view.findViewById(R.id.rail)
        private val perf: TextView = view.findViewById(R.id.perf)
        private val railAdapter = RailAdapter()

        init {
            card.setOnTouchListener(SwipeToReveal(card, ACTION_WIDTH_DP * view.resources.displayMetrics.density))
            if (advanced) {
                rail.visibility = View.VISIBLE
                perf.visibility = View.VISIBLE
                rail.layoutManager = LinearLayoutManager(view.context, RecyclerView.HORIZONTAL, false)
                rail.setRecycledViewPool(railPool)
                rail.adapter = railAdapter
            }
        }

        fun show(data: CardData, isExpanded: Boolean, advanced: Boolean) {
            author.text = data.authorName
            timestamp.text = data.timestamp
            title.text = data.title
            val text = if (advanced) data.longBody else data.body
            body.text = if (isExpanded) text + text else text
            card.translationX = 0f
            avatar.load(data.avatarUrl)
            if (advanced) {
                val (prime, fib) = data.perfTest()
                perf.text = "🧮 Prime: ${if (prime) "✓" else "✗"} | Fib: $fib"
                railAdapter.urls = data.railUrls
                railAdapter.notifyDataSetChanged()
                rail.scrollToPosition(0)
            }
        }
    }

    /// The images of one card's rail, 8 dp apart.
    private class RailAdapter : RecyclerView.Adapter<RailAdapter.Holder>() {
        var urls: List<String> = emptyList()

        class Holder(val image: ImageView) : RecyclerView.ViewHolder(image)

        override fun getItemCount() = urls.size

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Holder {
            val image = LayoutInflater.from(parent.context).inflate(R.layout.item_rail_image, parent, false) as ImageView
            return Holder(image)
        }

        override fun onBindViewHolder(holder: Holder, position: Int) {
            val gap = (RAIL_GAP_DP * holder.image.resources.displayMetrics.density).toInt()
            (holder.image.layoutParams as ViewGroup.MarginLayoutParams).marginEnd =
                if (position == urls.size - 1) 0 else gap
            holder.image.load(urls[position])
        }
    }

    /// Drags the card sideways with the finger and settles it on release. A
    /// drag that starts sideways moves the card; anything else, a vertical
    /// drag or a tap, is left to the list and the click listener.
    private class SwipeToReveal(private val card: View, private val actionWidth: Float) : View.OnTouchListener {
        private var downX = 0f
        private var downY = 0f
        private var lastX = 0f
        private var dragging = false
        private val slop get() = android.view.ViewConfiguration.get(card.context).scaledTouchSlop

        @SuppressLint("ClickableViewAccessibility")
        override fun onTouch(v: View, e: MotionEvent): Boolean {
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = e.rawX; downY = e.rawY; lastX = e.rawX; dragging = false
                    card.animate().cancel()
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = e.rawX - downX
                    val dy = e.rawY - downY
                    if (!dragging && abs(dx) > slop && abs(dx) > abs(dy)) {
                        dragging = true
                        card.parent.requestDisallowInterceptTouchEvent(true)
                    }
                    if (dragging) {
                        card.translationX = min(0f, card.translationX + (e.rawX - lastX))
                    }
                    lastX = e.rawX
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (dragging) {
                        val target = if (card.translationX < -actionWidth / 2) -actionWidth else 0f
                        card.animate().translationX(target).setDuration(250)
                            .setInterpolator(DecelerateInterpolator()).start()
                        card.parent.requestDisallowInterceptTouchEvent(false)
                        return true
                    }
                }
            }
            // Not a sideways drag: the click listener and the list get the event.
            return false
        }
    }

    companion object {
        const val HEADER = 0
        const val CARD = 1
        const val ACTION_WIDTH_DP = 80f
        const val RAIL_GAP_DP = 8f
    }
}
