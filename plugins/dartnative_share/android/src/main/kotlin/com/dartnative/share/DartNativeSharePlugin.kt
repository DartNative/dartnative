package com.dartnative.share

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Flutter plugin entry point for dart_native_share.
 *
 * Registered automatically via pubspec.yaml `pluginClass`.
 * Its sole job: trigger JNI_OnLoad by calling System.loadLibrary on engine
 * attach, which caches the JavaVM and Kotlin method ID needed by the JNI
 * bridge in dn_share_bridge.cpp.
 */
class DartNativeSharePlugin : FlutterPlugin {

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        try {
            System.loadLibrary("dartnative_share")
        } catch (e: UnsatisfiedLinkError) {
            android.util.Log.e(
                "DNShare",
                "Failed to load libdart_native_share.so: ${e.message}"
            )
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op.
    }
}
