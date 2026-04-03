@echo off
REM ===========================================
REM PowerSync Credentials Setup Script (Windows)
REM IMU Mobile App - Production Deployment
REM ===========================================

setlocal enabledelayedexpansion

echo.
echo 🔧 IMU PowerSync Credentials Setup
echo ================================
echo.

REM Check if user has the required files
echo 📋 Required Files Checklist:
echo   [1] PowerSync Private Key (PEM format)
echo   [2] PowerSync Public Key (PEM format)
echo   [3] PowerSync Instance ID
echo.

REM Ask for PowerSync Instance ID
set /p POWERSYNC_INSTANCE_ID="✅ Enter your PowerSync Instance ID: "

REM Ask for private key file path
echo.
set /p PRIVATE_KEY_PATH="📁 Enter path to PowerSync Private Key (.pem file): "

if not exist "%PRIVATE_KEY_PATH%" (
    echo ❌ Error: Private key file not found: %PRIVATE_KEY_PATH%
    exit /b 1
)

REM Ask for public key file path
echo.
set /p PUBLIC_KEY_PATH="📁 Enter path to PowerSync Public Key (.pem file): "

if not exist "%PUBLIC_KEY_PATH%" (
    echo ❌ Error: Public key file not found: %PUBLIC_KEY_PATH%
    exit /b 1
)

REM Generate JWT secret
echo.
echo 🔑 Generating JWT Secret...
for /f "tokens=*" %%a in ('openssl rand -base64 32') do set JWT_SECRET=%%a
echo ✅ JWT Secret Generated: %JWT_SECRET:~0,10!... (32 characters total)

echo.
echo 📝 Creating Backend Environment File...

REM Read private key and format for environment variable
powershell -Command "(Get-Content '%PRIVATE_KEY_PATH%' -Raw) -replace '`n', '\n' -replace '-----BEGIN PRIVATE KEY-----', '-----BEGIN PRIVATE KEY-----`n' -replace '-----END PRIVATE KEY-----', '`n-----END PRIVATE KEY-----' -replace '\n', '\\n' | Out-File -Encoding ASCII temp_private.txt"

REM Read public key and format for environment variable
powershell -Command "(Get-Content '%PUBLIC_KEY_PATH%' -Raw) -replace '`n', '\n' -replace '-----BEGIN PUBLIC KEY-----', '-----BEGIN PUBLIC KEY-----`n' -replace '-----END PUBLIC KEY-----', '`n-----END PUBLIC KEY-----' -replace '\n', '\\n' | Out-File -Encoding ASCII temp_public.txt"

REM Read the formatted keys
set /p PRIVATE_KEY_FORMATTED=<temp_private.txt
set /p PUBLIC_KEY_FORMATTED=<temp_public.txt

REM Clean up temp files
del temp_private.txt
del temp_public.txt

(cat > backend\.env.new) Echo.
echo # ===========================================
echo # IMU Backend Environment Configuration
echo # Generated: %date% %time%
echo # ===========================================
echo.
echo # PowerSync RSA Keys
echo POWERSYNC_PRIVATE_KEY="%PRIVATE_KEY_FORMATTED%"
echo POWERSYNC_PUBLIC_KEY="%PUBLIC_KEY_FORMATTED%"
echo.
echo # PowerSync Configuration
echo POWERSYNC_URL=https://%POWERSYNC_INSTANCE_ID%.powersync.journeyapps.com
echo POWERSYNC_KEY_ID=imu-production-key-%date:~10,4%
echo.
echo # JWT Configuration
echo JWT_SECRET=%JWT_SECRET%
echo JWT_EXPIRY_HOURS=24
echo.
echo # Database
echo DATABASE_URL=postgresql://user:pass@host:5432/imu
echo.
echo # Add your existing database configuration below
echo # ...
echo.

REM Move to correct location
move /Y backend\.env.new backend\.env >nul 2>&1

echo ✅ Created: backend\.env

REM Create mobile .env.qa file
echo.
echo 📄 Creating Mobile QA Environment File...

(cat > .env.qa) Echo.
echo # ===========================================
echo # IMU Mobile QA Environment Configuration
echo # Generated: %date% %time%
echo # ===========================================
echo.
echo # PowerSync Configuration
echo POWERSYNC_URL=https://%POWERSYNC_INSTANCE_ID%.powersync.journeyapps.com
echo.
echo # Backend API Configuration
echo POSTGRES_API_URL=https://imu-api.cfbtools.app/api
echo.
echo # JWT Configuration ^(MUST match backend!^)
echo JWT_SECRET=%JWT_SECRET%
echo JWT_EXPIRY_HOURS=24
echo.
echo # App Configuration
echo APP_NAME=IMU QA
echo APP_ENV=qa
echo DEBUG_MODE=true
echo LOG_LEVEL=debug
echo.
echo # Mapbox Configuration
echo MAPBOX_ACCESS_TOKEN=your_mapbox_access_token_here
echo.

echo ✅ Created: .env.qa

echo.
echo ✅ Setup Complete! Summary:
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo PowerSync Instance ID: %POWERSYNC_INSTANCE_ID%
echo PowerSync URL: https://%POWERSYNC_INSTANCE_ID%.powersync.journeyapps.com
echo JWT Secret: %JWT_SECRET:~0,10!... ^(32 characters^)
echo.
echo 📄 Files Created:
echo   • backend\.env ^(backend environment^)
echo   • .env.qa ^(mobile QA environment^)
echo.
echo 🚀 Next Steps:
echo   1. Restart backend service
echo   2. Test backend JWT generation
echo   3. Build QA test APK
echo   4. Test mobile app login and sync
echo.

pause
