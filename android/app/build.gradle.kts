plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // ✅ Add Google Services plugin for Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.colourwalk"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.colourwalk"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BOM (keeps versions aligned)
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))

    // ✅ Firebase Auth (required for authentication)
    implementation("com.google.firebase:firebase-auth")

    // ✅ Google Play Services Auth (required for Google Sign-In)
    implementation("com.google.android.gms:play-services-auth:21.1.1")

    // Other Firebase services you may use (uncomment as needed)
    // implementation("com.google.firebase:firebase-firestore")
    // implementation("com.google.firebase:firebase-analytics")
}