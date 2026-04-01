@echo off
REM Build script for Production environment (Windows)
REM Usage: build_prod.bat

echo Building IMU Flutter app for Production environment...

REM Build APK for Production
flutter build apk ^
  --release ^
  --dart-define=ENV=prod ^
  --obfuscate ^
  --split-debug-info=./debug-info/prod ^
  --build-name=1.0.0 ^
  --build-number=%date:~10,4%%date:~4,2%%date:~7,2%%time:~0,2%%time:~3,2%

echo Production APK built successfully: build/app/outputs/flutter-apk/app-release.apk
echo Debug info stored in: ./debug-info/prod/
pause
