plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.dartnative.benchmarks.cards"
    compileSdk = 36
    defaultConfig {
        applicationId = "com.dartnative.benchmarks.scrollable.kotlin"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        // The screen the app opens on: cards or chat,
        // chosen when it is built, as the DartNative app does.
        val benchScreen = project.findProperty("benchScreen")?.toString() ?: "cards"
        buildConfigField("String", "BENCH_SCREEN", "\"$benchScreen\"")
        // Each screen is its own app, so all of them can sit on one phone.
        // The app id ends with the screen ("...scrollable.kotlin.chat"), and
        // the app name gives the screen and the framework, as in the other
        // apps: "ChatList (Kotlin)".
        val screen = when (benchScreen) {
            "chat" -> "Chat"
            else -> "Cards"
        }
        applicationIdSuffix = "." + screen.lowercase()
        manifestPlaceholders["appName"] = "${screen}List (Kotlin)"
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    buildFeatures { buildConfig = true }
    // The Chat screen's messages and stickers, shared with the other apps.
    sourceSets["main"].assets.srcDir("../../../assets")
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.recyclerview:recyclerview:1.3.2")
    implementation("com.google.android.material:material:1.13.0")
    implementation("io.coil-kt:coil:2.6.0")
    // The version DartNative's Lottie plugin and lottie-react-native use.
    implementation("com.airbnb.android:lottie:6.7.1")
}
