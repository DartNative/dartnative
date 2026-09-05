pluginManagement {
    val dnSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val dnSdkPath = properties.getProperty("dn.sdk")
            require(dnSdkPath != null) { "dn.sdk not set in local.properties (run `dn build` once, or set it to your DartNative SDK path)" }
            dnSdkPath
        }

    includeBuild("$dnSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.dartnative.plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    // Crashlytics: injects the build-id resource its ContentProvider needs at
    // startup (without it firebase-crashlytics crashes the app on launch).
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
}

include(":app")
