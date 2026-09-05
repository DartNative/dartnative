package com.dartnative.playground

import com.dartnative.runtime.DartNativeApplication

class Application : DartNativeApplication() {
    // The base class owns the engine bootstrap (SoLoader, JNI bridge load,
    // DNAppContext, engine pre-warm). Override onEngineCreated() for custom
    // native setup.
}
