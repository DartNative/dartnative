import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.dartnative.gradle-plugin")
}

// Conditionally apply google-services plugin only if google-services.json
// exists. This keeps `flutter pub get` / first build working before the dev
// drops in their own Firebase config (see MIGRATION.md).
val hasGoogleServices = file("google-services.json").exists()
if (hasGoogleServices) {
    apply(plugin = "com.google.gms.google-services")
    // Crashlytics SDK is on the classpath via dartnative_firebase, and
    // FirebaseInitProvider eagerly initializes it. The Crashlytics Gradle
    // plugin is mandatory whenever crashlytics is initialized — it injects
    // the build ID otherwise FirebaseInitProvider crashes the app at launch.
    apply(plugin = "com.google.firebase.crashlytics")
}

android {
    namespace = "com.dartnative.firebase.example"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.dartnative.firebase.example"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    // Required for Yoga's libyoga.so used by dartnative flex layout.
    implementation("com.facebook.soloader:soloader:0.10.5")
}

flutter {
    source = "../.."
}
