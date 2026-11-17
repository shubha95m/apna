# Flutter ProGuard Rules for Release Builds
-dontobfuscate
-dontshrink
-dontoptimize
-ignorewarnings

# Keep all Flutter classes and plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep FlutterSecureStorage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# Keep Sqflite
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Keep FilePicker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# Preserve annotations and native method names
-keepattributes *Annotation*
-keepclassmembers class * {
    native <methods>;
}

# AndroidX and Biometrics
-dontwarn androidx.**
-keep class androidx.** { *; }
-keep class androidx.biometric.** { *; }
-keep class androidx.appcompat.** { *; }
-keep class androidx.security.crypto.** { *; }
