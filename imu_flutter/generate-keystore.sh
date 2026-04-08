#!/bin/bash

# IMU Flutter App - Keystore Generation Script
# This script generates a production keystore for signing the release APK/AAB

echo "Generating production keystore for IMU Flutter app..."
echo ""

# Configuration
KEYSTORE_FILE="release.keystore"
KEY_ALIAS="release"
VALIDITY=10000  # 10,000 days (~27 years)
KEY_SIZE=2048

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "Error: keytool not found. Please install Java JDK."
    echo "Keytool is included in Java JDK and should be in your PATH."
    exit 1
fi

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "Warning: Keystore file '$KEYSTORE_FILE' already exists."
    read -p "Do you want to overwrite it? (yes/no): " response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Keystore generation cancelled."
        exit 0
    fi
    rm -f "$KEYSTORE_FILE"
fi

# Generate keystore
echo "Generating keystore..."
keytool -genkey \
    -v \
    -keystore "$KEYSTORE_FILE" \
    -keyalg RSA \
    -keysize "$KEY_SIZE" \
    -validity "$VALIDITY" \
    -alias "$KEY_ALIAS" \
    -dname "CN=IMU, OU=ODVI, O=ODVI, L=Cebu, ST=Cebu, PH" \
    -storepass "" \
    -keypass ""

echo ""
echo "✅ Keystore generated successfully: $KEYSTORE_FILE"
echo ""
echo "IMPORTANT SECURITY NOTES:"
echo "1. Keep the keystore file safe and secure - it's your app's identity"
echo "2. Never commit the keystore file to git"
echo "3. Store the keystore passwords securely (use password manager)"
echo "4. Backup the keystore file in multiple secure locations"
echo ""
echo "ENVIRONMENT VARIABLES NEEDED:"
echo "  KEYSTORE_PASSWORD=<your store password>"
echo "  KEY_PASSWORD=<your key password>"
echo "  KEY_ALIAS=$KEY_ALIAS"
echo ""
echo "SET ENVIRONMENT VARIABLES:"
echo "  # Windows (Command Prompt)"
echo "  set KEYSTORE_PASSWORD=your_store_password"
echo "  set KEY_PASSWORD=your_key_password"
echo "  set KEY_ALIAS=$KEY_ALIAS"
echo ""
echo "  # Windows (PowerShell)"
echo "  \$env:KEYSTORE_PASSWORD='your_store_password'"
echo "  \$env:KEY_PASSWORD='your_key_password'"
echo "  \$env:KEY_ALIAS='$KEY_ALIAS'"
echo ""
echo "  # Linux/Mac"
echo "  export KEYSTORE_PASSWORD=your_store_password"
echo "  export KEY_PASSWORD=your_key_password"
echo "  export KEY_ALIAS=$KEY_ALIAS"
echo ""
echo "BUILD COMMANDS:"
echo "  flutter build apk --release"
echo "  flutter build appbundle --release"
