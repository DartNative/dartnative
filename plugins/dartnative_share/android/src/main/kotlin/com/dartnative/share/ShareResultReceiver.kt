package com.dartnative.share

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Receives the chooser's "target chosen" broadcast for `*WithResult` shares.
 *
 * The system fires the [android.app.PendingIntent] built in
 * `resultSender(...)` when the user picks a share target, filling in
 * [Intent.EXTRA_CHOSEN_COMPONENT]. Dismissing the sheet fires nothing —
 * dismissal is detected Dart-side (app-resume grace window).
 *
 * Runs on the main thread; delivery is generation-gated in
 * [deliverShareResult], so a selection landing after a hot restart is
 * dropped instead of invoking a freed callback.
 */
class ShareResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val token = intent.getLongExtra(EXTRA_SHARE_TOKEN, -1L)
        if (token < 0) return
        val component: ComponentName? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(
                    Intent.EXTRA_CHOSEN_COMPONENT, ComponentName::class.java,
                )
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_CHOSEN_COMPONENT)
            }
        deliverShareResult(token, 1, component?.flattenToString() ?: "")
    }
}
