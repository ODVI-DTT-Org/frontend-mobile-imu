@echo off
REM Build script for QA environment (Windows)
REM Usage: build_qa.bat

echo Building IMU Flutter app for QA environment...

REM Build APK for QA
flutter build apk ^
  --release ^
  --dart-define=ENV=qa ^
  --obfuscate ^
  --split-debug-info=./debug-info/qa ^
  --build-name=1.0.0-qa ^
  --build-number=%date:~10,4%%date:~4,2%%date:~7,2%%time:~0,2%%time:~3,2%

echo QA APK built successfully: build/app/outputs/flutter-apk/app-release.apk
echo Debug info stored in: ./debug-info/qa/
pause
