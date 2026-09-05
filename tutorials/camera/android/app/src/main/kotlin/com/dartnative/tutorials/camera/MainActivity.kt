package com.dartnative.tutorials.camera

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.dartnative.runtime.DartNativeActivity

class MainActivity : DartNativeActivity() {
    // The base class registers the root view, starts Dart, and wires
    // safe-area/IME insets. Override the lifecycle methods (calling super)
    // to customize.

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Request CAMERA + RECORD_AUDIO at runtime (same block as the camera
        // plugin's example app). The plugin's manifest DECLARES the
        // permissions, but Android 6+ also requires an explicit user grant —
        // without this request nothing ever prompts, the grant stays denied,
        // and opening the camera fails with "permission denied".
        val needed = mutableListOf<String>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
            != PackageManager.PERMISSION_GRANTED) needed += Manifest.permission.CAMERA
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) needed += Manifest.permission.RECORD_AUDIO
        if (needed.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, needed.toTypedArray(), 1042)
        }
    }
}
