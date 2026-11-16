#!/usr/bin/env bash
set -e

echo "=== Deploying Apna to Supabase Cloud ==="

# 1. Build Split-ABI APKs for Mobile
echo "--> Building optimized Android APK..."
flutter build apk --split-per-abi --release

# 2. Build Web SPA with Supabase Storage base-href
echo "--> Building Web App for Supabase Cloud Storage..."
flutter build web --release --base-href "/storage/v1/object/public/web/" --output build/web-supabase

# 3. Upload APK to Supabase 'releases' bucket
echo "--> Uploading APK to Supabase Cloud Storage (releases/apna.apk)..."
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk exports/apna-mobile.apk
python3 scripts/upload_apk_to_supabase.py

# 4. Prune stale / legacy APKs to prevent storage bloat
./scripts/cleanup_apks.sh

# 4. Upload Web App to Supabase 'web' bucket
echo "--> Uploading Web Assets to Supabase Cloud Storage (web/)..."
python3 scripts/upload_web_to_supabase.py

echo "=== Deployment Successful! ==="
echo "Live Web App: https://jkmdshurqjjcwshnfihi.supabase.co/storage/v1/object/public/web/index.html"
echo "Mobile APK:   https://jkmdshurqjjcwshnfihi.supabase.co/storage/v1/object/public/releases/apna.apk"
