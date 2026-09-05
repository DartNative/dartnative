plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.dartnative.gradle-plugin")
}

android {
    namespace = "com.dartnative.cameraExample"
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
        applicationId = "com.dartnative.cameraExample"
        // CameraX core requires API 21; we align the example with the
        // dartnative plugin baseline at 26 (matches dartnative_camera's
        // minSdk). Per PLUGIN_DEVELOPMENT.md §8 Rule A.
        minSdk = 26
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
}

flutter {
    source = "../.."
}
