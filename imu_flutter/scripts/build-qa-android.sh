#!/bin/bash
# ===========================================
# IMU QA Build Script for Android
# ===========================================
# This script builds the Flutter app for QA environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  IMU QA Build Script for Android${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo -e "${RED}Error: Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Get Flutter version
echo -e "${YELLOW}Flutter version:${NC}"
flutter --version

# Navigate to project root
cd "$(dirname "$0")"

echo -e "${YELLOW}Building QA APK...${NC}"

# Build QA APK
flutter build apk \
  --release \
  --dart-define=ENV=qa \
  --build-name=imu-qa \
  --build-number=1.0.0

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ QA APK build successful!${NC}"
    echo -e "${GREEN}APK location: build/app/outputs/flutter-apk-QA-release.apk${NC}"

    # Get file size
    APK_SIZE=$(du -h build/app/outputs/flutter-apk-QA-release.apk | cut -f1)
    echo -e "${GREEN}APK size: $APK_SIZE${NC}"

    # Offer to install on connected device
    echo -e "\n${YELLOW}Install on connected device? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo -e "${YELLOW}Installing APK on device...${NC}"
        adb install build/app/outputs/flutter-apk-QA-release.apk
        echo -e "${GREEN}✅ APK installed!${NC}"
    fi
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
