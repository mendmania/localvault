import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use { stream -> load(stream) }
    }
}

fun releaseSigningValue(name: String): String? {
    return providers.gradleProperty(name).orNull
        ?: providers.environmentVariable(name).orNull
        ?: releaseSigningProperties.getProperty(name)
}

android {
    namespace = "com.mendmania.pocketmemory"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mendmania.pocketmemory"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystoreFile = releaseSigningValue("LOCALVAULT_KEYSTORE_FILE")
            if (!keystoreFile.isNullOrBlank()) {
                storeFile = rootProject.file(keystoreFile)
                storePassword = releaseSigningValue("LOCALVAULT_KEYSTORE_PASSWORD")
                keyAlias = releaseSigningValue("LOCALVAULT_KEY_ALIAS")
                keyPassword = releaseSigningValue("LOCALVAULT_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            if (releaseSigning.storeFile != null &&
                !releaseSigning.storePassword.isNullOrBlank() &&
                !releaseSigning.keyAlias.isNullOrBlank() &&
                !releaseSigning.keyPassword.isNullOrBlank()
            ) {
                signingConfig = releaseSigning
            }
        }
    }

    lint {
        checkDependencies = false
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

tasks.register("verifyReleaseSigning") {
    doLast {
        val releaseSigning = android.signingConfigs.getByName("release")
        if (releaseSigning.storeFile == null ||
            releaseSigning.storePassword.isNullOrBlank() ||
            releaseSigning.keyAlias.isNullOrBlank() ||
            releaseSigning.keyPassword.isNullOrBlank()
        ) {
            throw GradleException(
                "Release signing is not configured. Set LOCALVAULT_KEYSTORE_FILE, " +
                    "LOCALVAULT_KEYSTORE_PASSWORD, LOCALVAULT_KEY_ALIAS, and " +
                    "LOCALVAULT_KEY_PASSWORD in android/key.properties, Gradle properties, or the environment."
            )
        }
    }
}

tasks.register("verifyV1ReleaseReadiness") {
    dependsOn("verifyNoReleaseInternetPermission")
    dependsOn("verifyReleaseSigning")
}

tasks.matching {
    it.name == "assembleRelease" ||
        it.name == "bundleRelease" ||
        it.name == "packageRelease"
}.configureEach {
    dependsOn("verifyReleaseSigning")
}
