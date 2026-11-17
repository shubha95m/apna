# Apna Production Stability & Architecture Rules

This document codifies the mandatory production stability rules established for Apna to prevent regressions on Android, Flutter, Biometrics, Supabase, and CI/CD pipelines.

---

## 1. Android Native & Manifest Architecture
- **No Empty Task Affinity**: Never set `android:taskAffinity=""` on the main launcher activity in `AndroidManifest.xml`. An empty task affinity causes the Android OS ActivityManager to isolate the task and dismiss it immediately upon launch, kicking the user back to the home screen.
- **Biometrics & FragmentActivity**: When using `local_auth`, `MainActivity` must always inherit from `FlutterFragmentActivity` (`io.flutter.embedding.android.FlutterFragmentActivity`), not plain `FlutterActivity`.
- **Drawable Theme Background**: In `styles.xml` (both `values/styles.xml` and `values-night/styles.xml`), `NormalTheme` must always use `?android:attr/windowBackground` (or a valid drawable reference), never `?android:colorBackground` (which throws a native `ResourceNotFoundException`).

---

## 2. Biometric Authentication & UI Lifecycle
- **Window Focus Debounce**: Never trigger `_localAuth.authenticate()` synchronously on cold start or immediately in `addPostFrameCallback`. The Android native Activity window must achieve focus first (`onWindowFocusChanged`). Always use a 600–700ms debounce timer before launching `BiometricPrompt`.
- **Pure Widget Builds**: Never invoke side-effects or asynchronous authentication checks directly inside `build()`. Always execute them in `initState()` via `WidgetsBinding.instance.addPostFrameCallback` or via Riverpod `ref.listen`.
- **Defensive Error Trapping**: Always wrap biometric calls in `try/catch` returning a graceful fallback boolean. Never let an unhandled `PlatformException` bubble up to kill the host process.

---

## 3. R8 / ProGuard Minification
- Flutter's Dart AOT compiler handles obfuscation and tree-shaking internally.
- In `android/app/build.gradle.kts`, keep `isMinifyEnabled = false` and `isShrinkResources = false` unless full native reflection rules are proven. AGP 9.0+ R8 shrinking strips native plugin classes (`com.it_nomads.fluttersecurestorage`, `com.tekartik.sqflite`, `androidx.appcompat`), causing silent startup crashes.
- Maintain `-dontobfuscate`, `-dontshrink`, and explicit plugin `-keep` rules in `proguard-rules.pro`.

---

## 4. Dart Engine Root Binding
- Always call `WidgetsFlutterBinding.ensureInitialized()` at the root of `void main() async`. Never wrap it inside `runZonedGuarded`, as doing so isolates binary messengers from the root isolate zone.
- Use `PlatformDispatcher.instance.onError = (error, stack) => true` and `FlutterError.onError` for global top-level uncaught exception handling.

---

## 5. Universal Dual-Architecture Mobile Releases
- For Android release builds targeting real physical devices, use `--target-platform android-arm,android-arm64`.
- This bundles both 64-bit (`arm64-v8a`) and 32-bit (`armeabi-v7a`) ARM libraries, guaranteeing compatibility with 100% of physical Android smartphones while excluding desktop x86_64 binaries, keeping the universal APK around ~43–45 MB (well under Supabase Storage's 50MB limit).

---

## 6. Supabase Auth Triggers & Migrations
- Triggers on `auth.users` (such as `handle_new_user`) must always run with `SECURITY DEFINER` and include defensive exception handling (`EXCEPTION WHEN OTHERS THEN RAISE WARNING ... RETURN NEW;`). An uncaught exception during user creation causes GoTrue to abort with `500: Database error saving new user`.
- All database operations in triggers must be idempotent (`ON CONFLICT DO NOTHING` or `DO UPDATE`).
- Registration forms must cleanly intercept duplicate email errors and guide the user to Sign In.

---

## 7. GitHub Actions CI/CD Versioning
- Never use a single hardcoded tag name (e.g., `v1.0.0-latest`) for releases.
- CI/CD must generate distinct semantic build tags (e.g., `v${BASE_VERSION}-b${{ github.run_number }}`) for immutable historical release archives, alongside a rolling `latest` pointer for direct downloads.
