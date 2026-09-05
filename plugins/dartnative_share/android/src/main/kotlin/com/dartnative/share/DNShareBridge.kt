// DNShareBridge.kt
// Kotlin JNI bridge for dart_native_share — Android side.
//
// Ported from share_plus (Flutter community).
// Flutter MethodChannel / Pigeon dispatch removed; replaced with @Keep JNI
// top-level functions called from C++ extern "C" symbols in dn_share_bridge.cpp.
//
// Upstream sources:
//   - SharePlusPlugin.kt       (Flutter plugin glue — discarded)
//   - MethodCallHandler.kt     ("share" arg dispatch — discarded)
//   - Share.kt                 (Intent.ACTION_SEND / SEND_MULTIPLE — ported)
//
// Supported share paths:
//   - shareText(text)                              — text/plain
//   - shareFiles(paths, mimeTypes?, text?)         — one OR many files;
//                                                    ACTION_SEND for 1,
//                                                    ACTION_SEND_MULTIPLE for N

package com.dartnative.share

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.Keep
import androidx.core.content.FileProvider
import com.dartnative.DNAppContext
import com.dartnative.DNNavigator
import java.io.File

private const val TAG = "DNShare"

/** Intent extra carrying the Dart request token through the chooser round-trip. */
internal const val EXTRA_SHARE_TOKEN = "com.dartnative.share.TOKEN"

/** Subdirectory under cacheDir that we copy outgoing files into. */
private const val SHARE_CACHE_SUBDIR = "dn_share"

/** Suffix appended to the host app's package id to form the FileProvider authority. */
private const val PROVIDER_AUTHORITY_SUFFIX = ".dartnative.share.provider"

private fun context(): Context? = DNNavigator.activity() ?: DNAppContext.get()

private fun providerAuthority(ctx: Context): String =
    ctx.packageName + PROVIDER_AUTHORITY_SUFFIX

// ─── Result dispatcher (generation-gated — hot-restart safe) ─────────────────
//
// Dart hands us ONE dispatcher address for the whole plugin (`setDispatcher`,
// called via the DNShareSetDispatcher FFI entry). The pointer is an
// isolate-bound trampoline that a hot restart deletes, so we capture the
// framework's isolate generation NEXT TO the pointer and compare it before
// EVERY delivery: the framework bumps the generation before the old isolate
// dies, so a share sheet still open across a restart delivers into a stale
// generation and drops — never into a freed trampoline ("Callback invoked
// after it has been deleted"). Recipe: dartnative docs,
// plugin_async_callbacks.md (option 3, Android).

@Volatile private var dispatcherPtr: Long = 0L
@Volatile private var dispatcherGen: Long = 0L

@Keep
fun setDispatcher(ptr: Long) {
    dispatcherPtr = ptr
    dispatcherGen = nativeIsolateGen()   // capture the generation WITH the ptr
}

/**
 * EVERY delivery to Dart goes through here — main thread, generation-gated.
 * status: 0 dismissed, 1 success, 2 unavailable.
 */
internal fun deliverShareResult(token: Long, status: Int, raw: String) {
    Handler(Looper.getMainLooper()).post {
        if (dispatcherGen != nativeIsolateGen()) return@post  // restarted → drop
        val ptr = dispatcherPtr
        if (ptr == 0L) return@post
        nativeDeliverShareResult(ptr, token, status, raw)
    }
}

/** Reads DN_IsolateGen() from libdartnative_android.so (see dn_share_bridge.cpp). */
private external fun nativeIsolateGen(): Long

/** Invokes the Dart dispatcher fn-pointer (see dn_share_bridge.cpp). */
private external fun nativeDeliverShareResult(
    ptr: Long, token: Long, status: Int, raw: String,
)

/**
 * Build the chooser IntentSender that reports the chosen target back to
 * [ShareResultReceiver]. FLAG_MUTABLE is required on Android 12+ — the
 * system fills in `Intent.EXTRA_CHOSEN_COMPONENT` on delivery.
 */
private fun resultSender(ctx: Context, token: Long): IntentSender {
    val intent = Intent(ctx, ShareResultReceiver::class.java)
        .putExtra(EXTRA_SHARE_TOKEN, token)
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        flags = flags or PendingIntent.FLAG_MUTABLE
    }
    return PendingIntent
        .getBroadcast(ctx, token.toInt(), intent, flags)
        .intentSender
}

/**
 * Present the system share chooser for [text].
 *
 * Mirrors `@_cdecl("DNShareText")` on iOS. Fire-and-forget; runs on the
 * main thread via Handler so it is safe to call from any Dart isolate /
 * platform thread.
 */
@Keep
fun shareText(text: String?) = shareTextImpl(text, token = null)

/**
 * Like [shareText], but reports the outcome to the Dart dispatcher under
 * [token]. Android's chooser reports *selections* only (via
 * [ShareResultReceiver]); dismissal is detected Dart-side when the app
 * resumes with the request still unanswered.
 */
@Keep
fun shareTextWithResult(token: Long, text: String?) {
    if (text.isNullOrEmpty()) {
        deliverShareResult(token, 2, "")
        return
    }
    shareTextImpl(text, token)
}

private fun shareTextImpl(text: String?, token: Long?) {
    if (text.isNullOrEmpty()) return

    Handler(Looper.getMainLooper()).post {
        try {
            val shareIntent = Intent().apply {
                action = Intent.ACTION_SEND
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
            }
            startChooser(chooserFor(shareIntent, token))
        } catch (e: Exception) {
            Log.w(TAG, "shareText failed: ${e.message}")
            if (token != null) deliverShareResult(token, 2, "")
        }
    }
}

/** Chooser intent, wired to [ShareResultReceiver] when a [token] is present. */
private fun chooserFor(target: Intent, token: Long?): Intent {
    val ctx = if (token != null) context() else null
    return if (token != null && ctx != null) {
        Intent.createChooser(target, null, resultSender(ctx, token))
    } else {
        Intent.createChooser(target, null)
    }
}

/**
 * Present the system share chooser for one or more files.
 *
 * - [paths] required, absolute filesystem paths.
 * - [mimeTypes] optional; if non-null, must have the same length as
 *   [paths]. When omitted, every file uses the wildcard MIME.
 * - [text] optional caption attached as `Intent.EXTRA_TEXT`. On WhatsApp
 *   this becomes the photo/video caption.
 *
 * Each file is copied into the app's cache dir
 * (`cacheDir/dn_share/<basename>`) and vended via `FileProvider` so the
 * receiving app can read it. The cache dir is cleared on every call.
 */
@Keep
fun shareFiles(paths: Array<String>?, mimeTypes: Array<String>?, text: String?) =
    shareFilesImpl(paths, mimeTypes, text, token = null)

/**
 * Like [shareFiles], but reports the outcome to the Dart dispatcher under
 * [token]. See [shareTextWithResult] for the result semantics.
 */
@Keep
fun shareFilesWithResult(
    token: Long,
    paths: Array<String>?,
    mimeTypes: Array<String>?,
    text: String?,
) = shareFilesImpl(paths, mimeTypes, text, token)

private fun shareFilesImpl(
    paths: Array<String>?,
    mimeTypes: Array<String>?,
    text: String?,
    token: Long?,
) {
    fun fail() { if (token != null) deliverShareResult(token, 2, "") }

    if (paths.isNullOrEmpty()) { fail(); return }
    if (mimeTypes != null && mimeTypes.size != paths.size) {
        Log.w(TAG, "shareFiles: mimeTypes.size != paths.size — ignoring mimeTypes")
    }
    val ctx = context()
    if (ctx == null) {
        Log.w(TAG, "shareFiles: no Activity / AppContext available")
        fail()
        return
    }

    Handler(Looper.getMainLooper()).post {
        try {
            // Copy every source into our private cache dir so we can hand
            // out stable FileProvider URIs.
            val cacheDir = File(ctx.cacheDir, SHARE_CACHE_SUBDIR)
            clearDir(cacheDir)
            cacheDir.mkdirs()

            val authority = providerAuthority(ctx)
            val uris = ArrayList<Uri>(paths.size)
            for (path in paths) {
                if (path.isEmpty()) continue
                val src = File(path)
                if (!src.exists()) {
                    Log.w(TAG, "shareFiles: source file does not exist: $path")
                    continue
                }
                val dest = File(cacheDir, src.name)
                src.copyTo(dest, overwrite = true)
                uris += FileProvider.getUriForFile(ctx, authority, dest)
            }
            if (uris.isEmpty()) {
                Log.w(TAG, "shareFiles: no valid files to share")
                if (token != null) deliverShareResult(token, 2, "")
                return@post
            }

            val resolvedMimes: List<String>? =
                if (mimeTypes != null && mimeTypes.size == paths.size) mimeTypes.toList()
                else null

            val shareIntent = Intent().apply {
                if (uris.size == 1) {
                    action = Intent.ACTION_SEND
                    type = resolvedMimes?.firstOrNull()?.ifEmpty { null } ?: "*/*"
                    putExtra(Intent.EXTRA_STREAM, uris.first())
                    // ACTION_SEND wants EXTRA_TEXT as a single CharSequence.
                    if (!text.isNullOrEmpty()) putExtra(Intent.EXTRA_TEXT, text)
                } else {
                    action = Intent.ACTION_SEND_MULTIPLE
                    type = reduceMimeTypes(resolvedMimes)
                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                    // ACTION_SEND_MULTIPLE wants EXTRA_TEXT as
                    // ArrayList<CharSequence> — one caption per item. Setting
                    // it as a plain String triggers
                    // Intent.migrateExtraStreamToClipData → ClassCastException
                    // when the chooser starts. We repeat the same caption for
                    // every URI (mirrors upstream share_plus behavior on
                    // multi-share with text).
                    if (!text.isNullOrEmpty()) {
                        val captions = ArrayList<CharSequence>(uris.size)
                        repeat(uris.size) { captions.add(text) }
                        putCharSequenceArrayListExtra(
                            Intent.EXTRA_TEXT, captions
                        )
                    }
                }
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            val chooser = chooserFor(shareIntent, token)

            // Pre-grant read permission to every app that can handle the
            // chooser intent — same approach as upstream share_plus.
            ctx.packageManager
                .queryIntentActivities(chooser, PackageManager.MATCH_DEFAULT_ONLY)
                .forEach { resolveInfo ->
                    val pkg = resolveInfo.activityInfo.packageName
                    for (uri in uris) {
                        ctx.grantUriPermission(
                            pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION
                        )
                    }
                }

            startChooser(chooser)
        } catch (e: Exception) {
            Log.w(TAG, "shareFiles failed: ${e.message}")
            if (token != null) deliverShareResult(token, 2, "")
        }
    }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Reduce a list of per-file MIME types to a single chooser MIME.
 * Ported from upstream `Share.kt#reduceMimeTypes`.
 *
 * Rules:
 *   - empty / null      -> wildcard
 *   - all equal         -> that exact MIME
 *   - same base ("a/x" + "a/y") -> "a/wildcard"
 *   - otherwise         -> full wildcard
 */
private fun reduceMimeTypes(mimes: List<String>?): String {
    if (mimes.isNullOrEmpty()) return "*/*"
    if (mimes.size == 1) return mimes.first().ifEmpty { "*/*" }
    var common = mimes.first()
    for (i in 1..mimes.lastIndex) {
        if (common == mimes[i]) continue
        common = if (baseOf(common) == baseOf(mimes[i])) {
            baseOf(mimes[i]) + "/*"
        } else {
            "*/*"
        }
        if (common == "*/*") break
    }
    return common
}

private fun baseOf(mime: String?): String =
    if (mime == null || !mime.contains("/")) "*" else mime.substringBefore('/')

private fun startChooser(chooser: Intent) {
    val activity = DNNavigator.activity()
    if (activity != null) {
        activity.startActivity(chooser)
    } else {
        val ctx = DNAppContext.get()
        if (ctx == null) {
            Log.w(TAG, "DNAppContext.get() returned null — cannot share")
            return
        }
        chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ctx.startActivity(chooser)
    }
}

private fun clearDir(dir: File) {
    if (!dir.exists()) return
    dir.listFiles()?.forEach { it.delete() }
}
