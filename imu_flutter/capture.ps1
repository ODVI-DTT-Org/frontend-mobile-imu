# IMU Screenshot Capture Script
# Usage: .\capture.ps1 <filename>

$adb = "C:\Users\odvid\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$screenshotDir = ".\screenshots"

# Create screenshots directory if not exists
if (-not (Test-Path $screenshotDir)) {
    New-Item -ItemType Directory -Path $screenshotDir | Out-Null
}

# Get filename from argument or use timestamp
if ($args.Count -eq 0) {
    $filename = "screenshot-$(Get-Date -Format 'HHmmss').png"
} else {
    $filename = $args[0]
}

Write-Host "Capturing screenshot..." -ForegroundColor Yellow

# Capture screenshot on device
& $adb shell screencap -p /sdcard/screenshot.png

# Pull screenshot to computer
& $adb pull /sdcard/screenshot.png "$screenshotDir\$filename"

Write-Host "✓ Saved: $screenshotDir\$filename" -ForegroundColor Green
