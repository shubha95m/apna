plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.apna.apna"
    compileSdk = 37 // Latest Android API 37 compilation

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.apna.apna"
        minSdk = 24 // Supports Android 7.0 through Android 16 (last 10 Android versions!)
        targetSdk = 35 // Topmost stable Android 15 target API
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("apna-release.jks")
            storePassword = "ApnaProdVault2026@"
            keyAlias = "apna_key"
            keyPassword = "ApnaProdVault2026@"
            enableV1Signing = true
            enableV2Signing = true
            enableV3Signing = true
            enableV4Signing = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.fragment:fragment-ktx:1.8.6")
}

flutter {
    source = "../.."
}
