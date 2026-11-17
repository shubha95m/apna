#!/usr/bin/env bash
set -e

echo "=== Apna Storage & APK Retention Pruner ==="

echo "--> Purging old / intermediate APK files to preserve local storage..."
rm -f build/app/outputs/flutter-apk/*.apk 2>/dev/null || true
rm -f build/app/outputs/apk/release/*.apk 2>/dev/null || true
rm -f build/web/*.apk 2>/dev/null || true
rm -f exports/*.apk 2>/dev/null || true

echo "--> Retained APK status: (clean)"
echo "=== Storage optimized! Ready for fresh single-target build. ==="
