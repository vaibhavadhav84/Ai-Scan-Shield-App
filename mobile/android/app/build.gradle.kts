plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    val releaseStore = System.getenv("ANDROID_KEYSTORE_PATH")
    val releaseRequested = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
    if (releaseRequested && listOf("ANDROID_KEYSTORE_PATH", "ANDROID_KEYSTORE_PASSWORD",
            "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD").any { System.getenv(it).isNullOrBlank() }) {
        throw GradleException("Owner release signing variables required; see docs/DEPLOYMENT.md")
    }
    signingConfigs {
        create("ownerRelease") {
            if (releaseStore != null) {
                storeFile = file(releaseStore)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }
    namespace = "dev.scanshield.scan_shield"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "dev.scanshield.scan_shield"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("ownerRelease")
        }
    }
}

flutter {
    source = "../.."
}
