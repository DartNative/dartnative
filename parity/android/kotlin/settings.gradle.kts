pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
plugins {
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}
dependencyResolutionManagement { repositories { google(); mavenCentral() } }
include(":app")
