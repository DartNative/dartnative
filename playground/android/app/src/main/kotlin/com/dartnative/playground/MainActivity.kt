package com.dartnative.playground

import com.dartnative.runtime.DartNativeActivity

class MainActivity : DartNativeActivity() {
    // The base class registers the root view, starts Dart, wires
    // safe-area/IME insets, and dispatches activity events (intents,
    // permission results) to plugins via DNActivityEvents — the
    // notifications glue that used to live here is now automatic.
}
