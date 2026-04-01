#!/bin/bash
# Build script for Production environment
# Usage: ./build_prod.sh

echo "Building IMU Flutter app for Production environment..."

# Build APK for Production
flutter build apk \
  --release \
  --dart-define=ENV=prod \
  --obfuscate \
  --split-debug-info=./debug-info/prod \
  --build-name=1.0.0 \
  --build-number=$(date +%Y%m%d%H%M)

echo "Production APK built successfully: build/app/outputs/flutter-apk/app-release.apk"
echo "Debug info stored in: ./debug-info/prod/"
