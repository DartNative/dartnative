package com.dartnative.benchmarks.cards

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.LayerDrawable
import android.os.Build
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.widget.TextViewCompat
import androidx.recyclerview.widget.RecyclerView
import com.airbnb.lottie.LottieAnimationView
import com.airbnb.lottie.LottieDrawable
import coil.load
import coil.transform.RoundedCornersTransformation
import org.json.JSONArray

/// The Chat screen: Legend List's chat example (ChatExample.tsx), with its
/// messages, bubbles and attachment cards, plus two kinds of message added.
/// After every fourth message comes a photo with a bubble's rounded corners
/// and no padding, at one of five aspect ratios, loaded with Coil; after
/// every third, a sticker, a looping Lottie animation (lottie-android, the
/// library React Native's lottie-react-native uses) shown without a bubble.
/// Both sit on the sender's side. The messages are the ones the example's
/// own generator makes (`tool/extract_chat.sh` writes them to
/// `assets/chat.json`); the stickers are six from each of four packs of the
/// DartNative playground's sticker keyboard. The list is laid out from the
/// bottom, newest first, so it opens at the newest message.
class ChatAttachment(val accent: Int, val heightDp: Float, val label: String, val subtitle: String)

class ChatItem(
    val self: Boolean,
    val senderName: String = "",
    val text: String = "",
    val timestamp: String = "",
    val attachment: ChatAttachment? = null,
    val sticker: String? = null,
    val photo: String? = null,
    val photoHeightDp: Float = 0f,
)

object Chat {
    /// A sticker follows every this many messages, as on the React Native
    /// screen (STICKER_EVERY).
    const val STICKER_EVERY = 3

    /// A sticker's side, as a messaging app shows one.
    const val STICKER_SIDE_DP = 160f

    /// A photo follows every this many messages (PHOTO_EVERY), 240 dp wide;
    /// its height follows its shape.
    const val PHOTO_EVERY = 4
    const val PHOTO_WIDTH_DP = 240f

    /// The photos' shapes, in turn: the pixel size asked of the image
    /// service (720 wide, three pixels a point) and the height shown: 4:3,
    /// 3:4, 1:1, 16:9 and 9:16.
    val PHOTO_SHAPES = listOf(
        Triple(720, 540, 180f),
        Triple(720, 960, 320f),
        Triple(720, 720, 240f),
        Triple(720, 405, 135f),
        Triple(720, 1280, 427f),
    )

    /// The photos: 24 images from picsum.photos, picked by id, the same in
    /// every app.
    const val FIRST_PHOTO_ID = 10
    const val PHOTO_COUNT = 24

    /// The light fill a chat shows while a photo loads.
    const val PHOTO_FILL = 0xFFE5E7EB.toInt()

    // The example's chat palette (screens/examples/shared.tsx).
    const val BACKGROUND = 0xFFF6F3EE.toInt()
    const val SELF_BUBBLE = 0xFFDBEAFE.toInt()
    const val OTHER_BUBBLE = 0xFFFFFFFF.toInt()
    const val TEXT = 0xFF111827.toInt()
    const val TIMESTAMP = 0xFF64748B.toInt()
    const val SCRIM = 0x240F172A

    /// The sticker files: six from each of four packs, the same in every app.
    val STICKERS = listOf("duck", "mia_bunny", "hot_cherry", "baby_yoda")
        .flatMap { pack -> (0 until 6).map { "stickers/${pack}_$it.json" } }

    /// The thread, oldest first: the example's messages, with a photo after
    /// the second of every four and a sticker after the third of every
    /// three, each from the sender of the message before it. The sticker is
    /// picked by a small generator with a fixed seed, the same in every
    /// app, so a sticker file never repeats at a fixed distance: a list
    /// reuses its views in turn, and a file that came back to the view
    /// still holding it would be shown without being built again.
    fun load(context: Context): List<ChatItem> {
        val messages = JSONArray(context.assets.open("chat.json").bufferedReader().readText())
        val thread = ArrayList<ChatItem>()
        var stickerSeed = 2026L
        for (i in 0 until messages.length()) {
            val m = messages.getJSONObject(i)
            val self = m.getString("sender") == "self"
            val a = m.optJSONObject("attachment")
            thread += ChatItem(
                self = self,
                senderName = m.getString("senderName"),
                text = m.getString("text"),
                timestamp = m.getString("timestampLabel"),
                attachment = a?.let {
                    ChatAttachment(
                        Color.parseColor(it.getString("accent")),
                        it.getDouble("height").toFloat(),
                        it.getString("label"),
                        it.getString("subtitle"),
                    )
                },
            )
            if (i % PHOTO_EVERY == 1) {
                val n = i / PHOTO_EVERY
                val (w, h, height) = PHOTO_SHAPES[n % PHOTO_SHAPES.size]
                thread += ChatItem(
                    self = self,
                    photo = "https://picsum.photos/id/${FIRST_PHOTO_ID + n % PHOTO_COUNT}/$w/$h",
                    photoHeightDp = height,
                )
            }
            if (i % STICKER_EVERY == STICKER_EVERY - 1) {
                stickerSeed = stickerSeed * 48271 % 2147483647
                thread += ChatItem(self = self, sticker = STICKERS[(stickerSeed % STICKERS.size).toInt()])
            }
        }
        return thread
    }
}

private fun Context.dp(value: Float) =
    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()

private fun rounded(color: Int, radius: Int) = GradientDrawable().apply {
    setColor(color)
    cornerRadius = radius.toFloat()
}

/// The typeface React Native uses for a fontWeight of "800": a true 800
/// weight on Android 9 (API 28) and later, which support font weights, and
/// bold on earlier versions.
private fun extraBold(): Typeface =
    if (Build.VERSION.SDK_INT >= 28) Typeface.create(Typeface.DEFAULT, 800, false) else Typeface.DEFAULT_BOLD

/// A column at most 84 % as wide as what it is given: the example's
/// bubble, `maxWidth: "84%"`, sized to its content up to that. A bubble
/// with an attachment card takes all of it, the card filling it.
private class BubbleLayout(context: Context) : LinearLayout(context) {
    var full = false
        set(value) {
            if (field != value) requestLayout()
            field = value
        }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val cap = (MeasureSpec.getSize(widthMeasureSpec) * 0.84f).toInt()
        val mode = if (full) MeasureSpec.EXACTLY else MeasureSpec.AT_MOST
        super.onMeasure(MeasureSpec.makeMeasureSpec(cap, mode), heightMeasureSpec)
    }
}

class ChatAdapter(private val newestFirst: List<ChatItem>) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {
    override fun getItemCount() = newestFirst.size

    override fun getItemViewType(position: Int) = when {
        newestFirst[position].sticker != null -> STICKER
        newestFirst[position].photo != null -> PHOTO
        else -> MESSAGE
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        val ctx = parent.context
        val row = FrameLayout(ctx).apply {
            layoutParams = RecyclerView.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            setPadding(0, 0, 0, ctx.dp(12f))
        }
        if (viewType == PHOTO) {
            val photo = ImageView(ctx).apply {
                scaleType = ImageView.ScaleType.CENTER_CROP
                background = rounded(Chat.PHOTO_FILL, ctx.dp(18f))
                layoutParams = FrameLayout.LayoutParams(ctx.dp(Chat.PHOTO_WIDTH_DP), 0)
            }
            row.addView(photo)
            return PhotoHolder(row, photo)
        }
        if (viewType == STICKER) {
            val side = ctx.dp(Chat.STICKER_SIDE_DP)
            val sticker = LottieAnimationView(ctx).apply {
                repeatCount = LottieDrawable.INFINITE
                layoutParams = FrameLayout.LayoutParams(side, side)
            }
            row.addView(sticker)
            return StickerHolder(row, sticker)
        }
        val bubble = BubbleLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            val pad = ctx.dp(14f)
            setPadding(pad, pad, pad, pad)
            layoutParams = FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        }
        val sender = TextView(ctx).apply {
            setTextColor(Chat.TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
                .apply { bottomMargin = ctx.dp(4f) }
        }
        // The attachment card: the accent colour under a light scrim, the
        // label and subtitle at its bottom.
        val label = TextView(ctx).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = extraBold()
            letterSpacing = 0.5f / 12f
            isAllCaps = true
        }
        val subtitle = TextView(ctx).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            typeface = extraBold()
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
                .apply { topMargin = ctx.dp(6f) }
        }
        val attachment = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.BOTTOM
            val pad = ctx.dp(12f)
            setPadding(pad, pad, pad, pad)
            addView(label)
            addView(subtitle)
        }
        val body = TextView(ctx).apply {
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            setTextColor(Chat.TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            TextViewCompat.setLineHeight(
                this,
                TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, 20f, ctx.resources.displayMetrics).toInt(),
            )
        }
        val time = TextView(ctx).apply {
            setTextColor(Chat.TIMESTAMP)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
                .apply { topMargin = ctx.dp(8f) }
        }
        bubble.addView(sender)
        bubble.addView(attachment)
        bubble.addView(body)
        bubble.addView(time)
        row.addView(bubble)
        return MessageHolder(row, bubble, sender, attachment, label, subtitle, body, time)
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        val item = newestFirst[position]
        val gravity = if (item.self) Gravity.END else Gravity.START
        if (holder is PhotoHolder) {
            val ctx = holder.itemView.context
            (holder.photo.layoutParams as FrameLayout.LayoutParams).apply {
                this.gravity = gravity
                height = ctx.dp(item.photoHeightDp)
            }
            // The bubble's corners on the picture itself.
            holder.photo.load(item.photo) {
                transformations(RoundedCornersTransformation(ctx.dp(18f).toFloat()))
            }
            return
        }
        if (holder is StickerHolder) {
            (holder.sticker.layoutParams as FrameLayout.LayoutParams).gravity = gravity
            holder.sticker.setAnimation(item.sticker!!)
            holder.sticker.playAnimation()
            return
        }
        holder as MessageHolder
        val ctx = holder.itemView.context
        (holder.bubble.layoutParams as FrameLayout.LayoutParams).gravity = gravity
        holder.bubble.background = rounded(if (item.self) Chat.SELF_BUBBLE else Chat.OTHER_BUBBLE, ctx.dp(18f))
        holder.sender.text = item.senderName
        val a = item.attachment
        (holder.bubble as BubbleLayout).full = a != null
        if (a == null) {
            holder.attachment.visibility = View.GONE
        } else {
            holder.attachment.visibility = View.VISIBLE
            // The accent under the example's scrim, both behind the text.
            val radius = ctx.dp(16f)
            holder.attachment.background = LayerDrawable(arrayOf(rounded(a.accent, radius), rounded(Chat.SCRIM, radius)))
            holder.attachment.layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ctx.dp(a.heightDp))
                .apply { bottomMargin = ctx.dp(10f) }
            holder.label.text = a.label
            holder.subtitle.text = a.subtitle
        }
        holder.body.text = item.text
        holder.time.text = item.timestamp
    }

    class StickerHolder(view: View, val sticker: LottieAnimationView) : RecyclerView.ViewHolder(view)

    class PhotoHolder(view: View, val photo: ImageView) : RecyclerView.ViewHolder(view)

    class MessageHolder(
        view: View,
        val bubble: LinearLayout,
        val sender: TextView,
        val attachment: LinearLayout,
        val label: TextView,
        val subtitle: TextView,
        val body: TextView,
        val time: TextView,
    ) : RecyclerView.ViewHolder(view)

    private companion object {
        const val MESSAGE = 0
        const val STICKER = 1
        const val PHOTO = 2
    }
}
