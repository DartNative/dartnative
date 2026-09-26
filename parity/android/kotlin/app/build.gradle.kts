plugins { id("com.android.application"); id("org.jetbrains.kotlin.android") }
android {
    namespace = "com.dartnative.parity.kotlin"
    compileSdk = 36
    defaultConfig { applicationId = "com.dartnative.parity.kotlin"; minSdk = 26; targetSdk = 36; versionCode = 1; versionName = "1" }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    kotlinOptions { jvmTarget = "17" }
}
dependencies {
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.core:core-ktx:1.12.0")
}
