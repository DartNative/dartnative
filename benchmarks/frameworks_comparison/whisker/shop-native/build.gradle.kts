// Gradle subproject for the `shop-native` Whisker module on Android.
// Wired into the consumer app's settings.gradle.kts by whisker-build.
// build.gradle.kts sits at the package root, alongside Package.swift
// + Cargo.toml; the Kotlin source set points at the `android/` subdir.

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("com.google.devtools.ksp") version "2.0.21-1.0.27"
}

android {
    namespace = "rs.whisker.modules.shop_native"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main") {
            kotlin.srcDirs("android/src/main/kotlin")
        }
    }
}

ksp {
    arg("whisker.moduleName", "ShopNative")
    arg("whisker.crateName", "shop-native")
}

dependencies {
    // Published Whisker runtime + KSP processor — the same Maven
    // coordinates every first-party module uses. ksp(rs.whisker:ksp)
    // stays separate because it's a build-time processor, not on the
    // runtime classpath. The KSP processor discovers explicit
    // `@WhiskerModule` declarations. The `0.1.0`
    // tag is the Android (Maven) release, versioned independently from
    // the cargo crate.
    implementation("rs.whisker:whisker-module-android:0.1.21")
    ksp("rs.whisker:ksp:0.1.21")
}
