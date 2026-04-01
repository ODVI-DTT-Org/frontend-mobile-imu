@echo off
REM PowerSync Sync Rules Deployment Script (Windows)
REM This script deploys the sync-config.yaml to PowerSync Cloud

echo ==========================================
echo PowerSync Sync Rules Deployment
echo ==========================================
echo.

REM Check if logged in
echo Step 1: Checking authentication status...
powersync fetch instances >nul 2>&1
if errorlevel 1 (
  echo Not authenticated. Please login first:
  echo   powersync login
  echo.
  pause
  exit /b 1
)

echo [OK] Authenticated
echo.

REM Validate configuration
echo Step 2: Validating sync configuration...
powersync validate
if errorlevel 1 (
  echo [ERROR] Validation failed. Please fix the errors before deploying.
  pause
  exit /b 1
)

echo [OK] Configuration is valid
echo.

REM Deploy sync rules
echo Step 3: Deploying sync rules...
echo Instance: https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com
echo.

powersync deploy sync-config
if errorlevel 1 (
  echo.
  echo [ERROR] Deployment failed. Please check the errors above.
  pause
  exit /b 1
)

echo.
echo [OK] Sync rules deployed successfully!
echo.
echo Step 4: Verifying deployment...
powersync fetch status
echo.
echo ==========================================
echo Deployment completed successfully!
echo ==========================================
pause
