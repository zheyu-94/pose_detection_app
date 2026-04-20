plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pose_detection_app"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.pose_detection_app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        // 將 Java 編譯目標統一設定為 17 或 21
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // 將 Kotlin 編譯目標也統一設定為 17
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}