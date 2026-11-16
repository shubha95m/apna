#!/usr/bin/env bash
set -e

echo "=== Apna Storage & APK Retention Pruner ==="

# 1. Prune stale / legacy APK variants from exports/
echo "--> Cleaning up stale APKs in exports/..."
find exports -name "*.apk" ! -name "apna-mobile.apk" -delete 2>/dev/null || true

# 2. Prune obsolete 32-bit and x86 builds from build/
echo "--> Cleaning up unused intermediate architecture APKs..."
rm -f build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
rm -f build/app/outputs/flutter-apk/app-x86_64-release.apk
rm -f build/app/outputs/flutter-apk/app-release.apk
rm -f build/app/outputs/apk/release/app-armeabi-v7a-release.apk
rm -f build/app/outputs/apk/release/app-x86_64-release.apk
rm -f build/web/apna-universal.apk

echo "--> Active retained APKs:"
find . -name "*.apk" -exec ls -lh {} +

echo "=== Cleanup complete! Storage optimized. ==="
