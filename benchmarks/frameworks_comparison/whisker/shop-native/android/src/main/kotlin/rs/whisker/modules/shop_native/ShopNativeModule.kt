package rs.whisker.modules.shop_native

import android.os.Handler
import android.os.Looper
import android.util.Log
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import rs.whisker.runtime.Module
import rs.whisker.runtime.ModuleDefinition
import rs.whisker.runtime.WhiskerModule
import rs.whisker.runtime.WhiskerValue

@WhiskerModule
class ShopNativeModule : Module() {
    private val executor = Executors.newFixedThreadPool(4)
    private val main = Handler(Looper.getMainLooper())

    override fun definition() = ModuleDefinition {
        Name("ShopNative")

        // post(url, body) -> response body (2xx) or error.
        AsyncFunction("post") { args, promise ->
            val url = args.getOrNull(0)?.asString() ?: ""
            val body = args.getOrNull(1)?.asString() ?: ""
            executor.execute {
                var result: String? = null
                var error: String? = null
                try {
                    val conn = URL(url).openConnection() as HttpURLConnection
                    conn.requestMethod = "POST"
                    conn.connectTimeout = 30000
                    conn.readTimeout = 30000
                    conn.doOutput = true
                    conn.setRequestProperty("Content-Type", "application/json")
                    conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
                    val code = conn.responseCode
                    if (code in 200..299) {
                        result = conn.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                    } else {
                        error = "HTTP $code"
                    }
                    conn.disconnect()
                } catch (e: Exception) {
                    error = e.message ?: e.toString()
                }
                val failure = error
                val responseBody = result ?: ""
                main.post {
                    if (failure != null) promise.reject(failure) else promise.resolve(WhiskerValue.Str(responseBody))
                }
            }
        }

        AsyncFunction("sleep") { args, promise ->
            val ms = args.getOrNull(0)?.asInt() ?: 0L
            main.postDelayed({ promise.resolve(WhiskerValue.Null) }, ms)
        }

        Function("alert") { args ->
            val message = args.getOrNull(0)?.asString() ?: ""
            main.post {
                val activity = appContext.currentActivity ?: return@post
                android.app.AlertDialog.Builder(activity)
                    .setMessage(message)
                    .setPositiveButton(android.R.string.ok, null)
                    .show()
            }
            WhiskerValue.Null
        }

        Function("tagTextField") { _ -> WhiskerValue.Bool(true) }

        Function("log") { args ->
            Log.i("Everbloom", args.getOrNull(0)?.asString() ?: "")
            WhiskerValue.Null
        }
    }
}
