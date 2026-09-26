package com.dartnative.parity.kotlin

import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.badge.BadgeDrawable
import com.google.android.material.badge.BadgeUtils
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.button.MaterialButton
import com.google.android.material.color.DynamicColors
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.materialswitch.MaterialSwitch

/** The platform's own widgets with nothing set on them, on Material 3
 *  with the device palette applied the recommended way: the screen a
 *  Kotlin developer gets by default, to hold next to the DartNative one. */
@androidx.annotation.OptIn(com.google.android.material.badge.ExperimentalBadgeUtils::class)
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        DynamicColors.applyToActivityIfAvailable(this)
        super.onCreate(savedInstanceState)
        setContentView(R.layout.main)
        // The bar's button switches light and dark in place, so both themes
        // are compared in one install; the activity is recreated, as the
        // system does on a theme change.
        // A tap on the page outside a field puts the keyboard away.
        val page = findViewById<android.view.ViewGroup>(R.id.page)
        page.isClickable = true
        page.isFocusableInTouchMode = true
        page.setOnClickListener {
            currentFocus?.let { f ->
                (getSystemService(INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager)
                    .hideSoftInputFromWindow(f.windowToken, 0)
                f.clearFocus()
            }
        }
        val toolbar = findViewById<com.google.android.material.appbar.MaterialToolbar>(R.id.toolbar)
        toolbar.inflateMenu(R.menu.toolbar)
        toolbar.setOnMenuItemClickListener {
            val dark = (resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) ==
                android.content.res.Configuration.UI_MODE_NIGHT_YES
            androidx.appcompat.app.AppCompatDelegate.setDefaultNightMode(
                if (dark) androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_NO
                else androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_YES)
            true
        }
        findViewById<MaterialButton>(R.id.btn_sheet).setOnClickListener { showSheet() }
        findViewById<MaterialButton>(R.id.btn_dialog).setOnClickListener { showDialog() }
        findViewById<MaterialButton>(R.id.btn_medium).setOnClickListener { showMediumSheet() }
        findViewById<MaterialButton>(R.id.btn_alert).setOnClickListener { showAlert() }
        // The badge on a view of the screen, as Material draws it.
        val anchor = findViewById<android.widget.ImageView>(R.id.badge_anchor)
        anchor.post {
            val badge = BadgeDrawable.create(this).apply { number = 3 }
            BadgeUtils.attachBadgeDrawable(badge, anchor)
        }
        val nav = findViewById<com.google.android.material.bottomnavigation.BottomNavigationView>(R.id.bottom_nav)
        nav.getOrCreateBadge(R.id.nav_search).number = 3
        // The system navigation strip takes the tab bar's colour, as the
        // DartNative screen does, so the bottom of the screen reads as one
        // surface. The one colour this screen sets on purpose.
        (nav.background as? com.google.android.material.shape.MaterialShapeDrawable)
            ?.fillColor?.defaultColor?.let { window.navigationBarColor = it }
    }

    /** Row params with the panels' spacing above: 8 between the texts, 16
     *  before the button, the same in the three apps. */
    private fun gap(dp: Int) = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply { topMargin = (dp * resources.displayMetrics.density).toInt() }

    private fun showAlert() {
        MaterialAlertDialogBuilder(this)
            .setTitle("Native alert")
            .setMessage("A native alert with a message and a button.")
            .setPositiveButton("OK", null)
            .show()
    }

    /** The navigation strip under a sheet takes the sheet's colour, so the
     *  panel reads as one surface to the bottom edge. Set here by hand: a
     *  customisation of this screen, not a Material default. */
    private fun matchNavBarToSheet(d: BottomSheetDialog) {
        d.setOnShowListener {
            val sheet = d.findViewById<android.view.View>(com.google.android.material.R.id.design_bottom_sheet)
            (sheet?.background as? com.google.android.material.shape.MaterialShapeDrawable)
                ?.fillColor?.defaultColor?.let { d.window?.navigationBarColor = it }
        }
    }

    private fun showSheet() {
        val d = BottomSheetDialog(this)
        matchNavBarToSheet(d)
        val pad = (20 * resources.displayMetrics.density).toInt()
        val c = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(pad, pad, pad, pad) }
        c.addView(TextView(this).apply {
            text = "Native sheet"
            setTextAppearance(com.google.android.material.R.style.TextAppearance_Material3_TitleLarge)
        })
        c.addView(TextView(this).apply { text = "Dismiss this sheet by dragging the grabber down." }, gap(8))
        c.addView(TextView(this).apply {
            text = "Body text with TextAppearance BodyLarge"
            setTextAppearance(com.google.android.material.R.style.TextAppearance_Material3_BodyLarge)
        }, gap(8))
        c.addView(MaterialButton(this).apply { text = "Close"; setOnClickListener { d.dismiss() } }, gap(16))
        d.setContentView(c)
        d.show()
    }

    /** The same sheet resting at half the screen, as a medium detent does. */
    private fun showMediumSheet() {
        val d = BottomSheetDialog(this)
        matchNavBarToSheet(d)
        val pad = (20 * resources.displayMetrics.density).toInt()
        val c = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(pad, pad, pad, pad) }
        c.addView(TextView(this).apply {
            text = "Native sheet"
            setTextAppearance(com.google.android.material.R.style.TextAppearance_Material3_TitleLarge)
        })
        c.addView(TextView(this).apply { text = "Dismiss this sheet by dragging the grabber down." }, gap(8))
        c.addView(TextView(this).apply {
            text = "Body text with TextAppearance BodyLarge"
            setTextAppearance(com.google.android.material.R.style.TextAppearance_Material3_BodyLarge)
        }, gap(8))
        c.addView(MaterialButton(this).apply { text = "Close"; setOnClickListener { d.dismiss() } }, gap(16))
        d.setContentView(c, android.view.ViewGroup.LayoutParams(
            android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT))
        d.behavior.isFitToContents = false
        d.behavior.halfExpandedRatio = 0.5f
        d.behavior.skipCollapsed = true
        d.behavior.state = BottomSheetBehavior.STATE_HALF_EXPANDED
        d.show()
        // Resting half expanded, the sheet still reaches the bottom edge: its
        // own view fills the window (content that asks to match the parent
        // gets the sheet's wrap_content height otherwise, and the sheet then
        // ends where the content does, floating mid-screen).
        d.findViewById<android.view.View>(com.google.android.material.R.id.design_bottom_sheet)?.apply {
            layoutParams.height = android.view.ViewGroup.LayoutParams.MATCH_PARENT
            requestLayout()
        }
    }

    private fun showDialog() {
        val pad = (20 * resources.displayMetrics.density).toInt()
        val c = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(pad, pad, pad, pad) }
        c.addView(TextView(this).apply {
            text = "Native dialog"
            setTextAppearance(com.google.android.material.R.style.TextAppearance_Material3_TitleLarge)
        })
        c.addView(TextView(this).apply { text = "Dismiss this dialog by hand, or close it below." }, gap(8))
        val d = MaterialAlertDialogBuilder(this).setView(c).create()
        c.addView(MaterialButton(this).apply { text = "Close"; setOnClickListener { d.dismiss() } }, gap(16))
        d.show()
    }
}
