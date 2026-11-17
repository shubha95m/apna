# Flutter ProGuard Rules for Release Builds
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-ignorewarnings

# Preserve annotations and native method names
-keepattributes *Annotation*
-keepclassmembers class * {
    native <methods>;
}

# AndroidX and Biometrics
-dontwarn androidx.**
-keep class androidx.biometric.** { *; }
-keep class androidx.security.crypto.** { *; }
