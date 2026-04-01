@echo off
REM ===========================================
REM IMU QA Build Script for Android (Windows)
REM ===========================================

setlocal enabledelayedexpansion

echo ========================================
echo   IMU QA Build Script for Android
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    exit /b 1
)

REM Get Flutter version
echo Flutter version:
flutter --version
echo.

REM Navigate to script directory
cd /d "%~dp0"

echo Building QA APK...
echo.

REM Build QA APK
flutter build apk --release --dart-define=ENV=qa --build-name=imu-qa --build-number=1.0.0

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] QA APK build successful!
    echo APK location: build\app\outputs\flutter-apk-QA-release.apk

    REM Offer to install on connected device
    echo.
    set /p response="Install on connected device? (y/N): "
    if /i "%response%"=="y" (
        echo Installing APK on device...
        adb install build\app\outputs\flutter-apk-QA-release.apk
        echo [SUCCESS] APK installed!
    )
) else (
    echo.
    echo [ERROR] Build failed
    exit /b 1
)

pause
