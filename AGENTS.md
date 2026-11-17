# Apna Repository Instructions & Production Rules

All AI agents and developers working on Apna must strictly follow the rules documented in:
- [.agents/rules/production_stability.md](.agents/rules/production_stability.md)

### Key Non-Negotiables:
1. **Never re-introduce `android:taskAffinity=""`** in `android/app/src/main/AndroidManifest.xml`.
2. **Never set `isMinifyEnabled = true`** in `build.gradle.kts` without verifying every Flutter plugin reflection rule.
3. **Never trigger Biometric prompts directly inside `build()`** or on frame 0 without the 600-700ms window focus debounce.
4. **Never wrap `WidgetsFlutterBinding.ensureInitialized()` in `runZonedGuarded`**.
5. **Always build with `--target-platform android-arm,android-arm64`** for universal physical device compatibility under 50MB.
6. **Ensure Supabase `auth.users` triggers always have exception handlers** (`EXCEPTION WHEN OTHERS THEN RAISE WARNING ... RETURN NEW;`).
