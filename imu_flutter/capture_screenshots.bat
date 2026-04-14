@echo off
REM IMU Screenshot Capture Script
REM This script automates screenshot capture for Google Play Store

echo ============================================
echo IMU App Screenshot Capture Helper
echo ============================================
echo.
echo This script will help you capture screenshots for the Google Play Store.
echo.
echo PREREQUISITES:
echo 1. Android Emulator or Device connected
echo 2. App running in release mode
echo.
echo ============================================
echo.

REM Check if adb is available
where adb >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: adb not found in PATH
    echo Please install Android SDK or add it to your PATH
    echo.
    echo ADB is usually located at:
    echo %LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
    echo.
    pause
    exit /b 1
)

REM Check for connected devices
echo Checking for connected devices...
adb devices
echo.

REM Create screenshots directory
set SCREENSHOT_DIR=screenshots
if not exist "%SCREENSHOT_DIR%" mkdir "%SCREENSHOT_DIR%"
echo Screenshots will be saved to: %SCREENSHOT_DIR%
echo.

echo ============================================
echo SCREENSHOT CAPTURE INSTRUCTIONS
echo ============================================
echo.
echo Follow these steps to capture each screenshot:
echo.
echo 1. Navigate to the screen in the app
echo 2. Press ENTER to capture screenshot
echo 3. The script will save and name the screenshot automatically
echo.
echo ============================================
echo.

pause

REM Screenshot 1: Login Screen
echo.
echo [1/8] LOGIN SCREEN
echo Navigate to the login screen and press ENTER...
pause >nul
adb shell screencap -p /sdcard/01-login.png
adb pull /sdcard/01-login.png "%SCREENSHOT_DIR%\01-login-1080x1920.png"
echo ✓ Saved: 01-login-1080x1920.png

REM Screenshot 2: Home Dashboard
echo.
echo [2/8] HOME DASHBOARD
echo Navigate to the home dashboard and press ENTER...
pause >nul
adb shell screencap -p /sdcard/02-home.png
adb pull /sdcard/02-home.png "%SCREENSHOT_DIR%\02-home-dashboard-1080x1920.png"
echo ✓ Saved: 02-home-dashboard-1080x1920.png

REM Screenshot 3: Client List
echo.
echo [3/8] CLIENT LIST
echo Navigate to the client list and press ENTER...
pause >nul
adb shell screencap -p /sdcard/03-clients.png
adb pull /sdcard/03-clients.png "%SCREENSHOT_DIR%\03-client-list-1080x1920.png"
echo ✓ Saved: 03-client-list-1080x1920.png

REM Screenshot 4: Client Detail
echo.
echo [4/8] CLIENT DETAIL
echo Open a client detail page and press ENTER...
pause >nul
adb shell screencap -p /sdcard/04-client.png
adb pull /sdcard/04-client.png "%SCREENSHOT_DIR%\04-client-detail-1080x1920.png"
echo ✓ Saved: 04-client-detail-1080x1920.png

REM Screenshot 5: Touchpoint Form
echo.
echo [5/8] TOUCHPOINT FORM
echo Open the touchpoint creation form and press ENTER...
pause >nul
adb shell screencap -p /sdcard/05-touchpoint.png
adb pull /sdcard/05-touchpoint.png "%SCREENSHOT_DIR%\05-touchpoint-form-1080x1920.png"
echo ✓ Saved: 05-touchpoint-form-1080x1920.png

REM Screenshot 6: Itinerary View
echo.
echo [6/8] ITINERARY VIEW
echo Navigate to the itinerary view and press ENTER...
pause >nul
adb shell screencap -p /sdcard/06-itinerary.png
adb pull /sdcard/06-itinerary.png "%SCREENSHOT_DIR%\06-itinerary-view-1080x1920.png"
echo ✓ Saved: 06-itinerary-view-1080x1920.png

REM Screenshot 7: My Day
echo.
echo [7/8] MY DAY
echo Navigate to My Day and press ENTER...
pause >nul
adb shell screencap -p /sdcard/07-myday.png
adb pull /sdcard/07-myday.png "%SCREENSHOT_DIR%\07-my-day-1080x1920.png"
echo ✓ Saved: 07-my-day-1080x1920.png

REM Screenshot 8: Sync Status
echo.
echo [8/8] SYNC STATUS
echo Show sync status and press ENTER...
pause >nul
adb shell screencap -p /sdcard/08-sync.png
adb pull /sdcard/08-sync.png "%SCREENSHOT_DIR%\08-sync-status-1080x1920.png"
echo ✓ Saved: 08-sync-status-1080x1920.png

echo.
echo ============================================
echo SCREENSHOT CAPTURE COMPLETE!
echo ============================================
echo.
echo All screenshots saved to: %SCREENSHOT_DIR%\
echo.
echo Next steps:
echo 1. Review screenshots in the screenshots folder
echo 2. Resize if needed (target: 1080x1920)
echo 3. Upload to Google Play Console
echo.
echo For reference, see SCREENSHOT_GUIDE.md
echo.
pause
