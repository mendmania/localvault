plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.localvault.localvault"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.localvault.localvault"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

tasks.register("verifyNoReleaseInternetPermission") {
    dependsOn("processReleaseMainManifest")
    doLast {
        val manifest = layout.buildDirectory
            .file("intermediates/merged_manifests/release/processReleaseMainManifest/AndroidManifest.xml")
            .get()
            .asFile
        if (manifest.exists() && manifest.readText().contains("android.permission.INTERNET")) {
            throw GradleException("Release manifest must not contain INTERNET permission")
        }
    }
}

tasks.named("check") {
    dependsOn("verifyNoReleaseInternetPermission")
}
