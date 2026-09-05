plugins {
    id("com.android.application")
    id("kotlin-android")
    // The DartNative Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("com.dartnative.gradle-plugin")
}

android {
    namespace = "com.dartnative.tutorials.photo_grid"
    compileSdk = dartnative.compileSdkVersion
    ndkVersion = dartnative.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dartnative.tutorials.photo_grid"
        // You can update the following values to match your application needs.
        minSdk = dartnative.minSdkVersion
        targetSdk = dartnative.targetSdkVersion
        versionCode = dartnative.versionCode
        versionName = dartnative.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `dn run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dartnative {
    source = "../.."
}

dependencies {
    // dartnative MainActivity extends DartNativeActivity (AppCompat-based);
    // com.dartnative.* classes come transitively from the dartnative_android
    // dependency via the plugin auto-inclusion.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.core:core-ktx:1.12.0")
}
