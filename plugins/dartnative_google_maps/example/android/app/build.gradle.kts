import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.dartnative.gradle-plugin")
}

// Google Maps Android key — read from android/secrets.properties (gitignored;
// key MAPS_API_KEY) and injected into the manifest's ${MAPS_API_KEY}
// placeholder. secrets.properties, NOT local.properties: the dn tool rewrites
// local.properties on every run and drops unknown keys (empty placeholder →
// auth failure → white map). No key is committed. See README → "API key setup".
val mapsApiKey: String = run {
    val props = Properties()
    val f = rootProject.file("secrets.properties")
    if (f.exists()) f.inputStream().use { props.load(it) }
    props.getProperty("MAPS_API_KEY") ?: ""
}

android {
    namespace = "com.dartnative.googleMapsExample"
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
        applicationId = "com.dartnative.googleMapsExample"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
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
    implementation(project(":dartnative_google_maps"))
}

flutter {
    source = "../.."
}
