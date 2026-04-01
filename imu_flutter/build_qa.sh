#!/bin/bash
# Build script for QA environment
# Usage: ./build_qa.sh

echo "Building IMU Flutter app for QA environment..."

# Build APK for QA
flutter build apk \
  --release \
  --dart-define=ENV=qa \
  --obfuscate \
  --split-debug-info=./debug-info/qa \
  --build-name=1.0.0-qa \
  --build-number=$(date +%Y%m%d%H%M)

echo "QA APK built successfully: build/app/outputs/flutter-apk/app-release.apk"
echo "Debug info stored in: ./debug-info/qa/"
