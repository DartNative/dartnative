package com.dartnative.revenuecatExample

import com.dartnative.runtime.DartNativeApplication

class Application : DartNativeApplication() {
    // The base class owns the engine bootstrap (JNI bridge load, engine
    // pre-warm). Override onEngineCreated() for custom native setup.
}
