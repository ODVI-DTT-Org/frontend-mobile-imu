#!/bin/bash

# ===========================================
# PowerSync Credentials Setup Script
# IMU Mobile App - Production Deployment
# ===========================================

set -e  # Exit on error

echo "🔧 IMU PowerSync Credentials Setup"
echo "================================"
echo ""

# Check if user has the required files
echo "📋 Required Files Checklist:"
echo "  [1] PowerSync Private Key (PEM format)"
echo "  [2] PowerSync Public Key (PEM format)"
echo "  [3] PowerSync Instance ID"
echo ""

# Ask for PowerSync Instance ID
read -p "✅ Enter your PowerSync Instance ID: " POWERSYNC_INSTANCE_ID

# Ask for private key file path
echo ""
read -p "📁 Enter path to PowerSync Private Key (.pem file): " PRIVATE_KEY_PATH

if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo "❌ Error: Private key file not found: $PRIVATE_KEY_PATH"
    exit 1
fi

# Ask for public key file path
echo ""
read -p "📁 Enter path to PowerSync Public Key (.pem file): " PUBLIC_KEY_PATH

if [ ! -f "$PUBLIC_KEY_PATH" ]; then
    echo "❌ Error: Public key file not found: $PUBLIC_KEY_PATH"
    exit 1
fi

# Generate JWT secret
echo ""
echo "🔑 Generating JWT Secret..."
JWT_SECRET=$(openssl rand -base64 32)
echo "✅ JWT Secret Generated: ${JWT_SECRET:0:10}... (32 characters total)"

# Format private key for environment variable (escape newlines)
echo ""
echo "📝 Formatting Private Key for Environment Variable..."
PRIVATE_KEY_FORMATTED=$(cat "$PRIVATE_KEY_PATH" | tr '\n' '\\n' | sed 's/-----BEGIN PRIVATE KEY-----/-----BEGIN PRIVATE KEY-----\\n/g' | sed 's/-----END PRIVATE KEY-----/\\n-----END PRIVATE KEY-----/g')

PUBLIC_KEY_FORMATTED=$(cat "$PUBLIC_KEY_PATH" | tr '\n' '\\n' | sed 's/-----BEGIN PUBLIC KEY-----/-----BEGIN PUBLIC KEY-----\\n/g' | sed 's/-----END PUBLIC KEY-----/\\n-----END PUBLIC KEY-----/g')

# Create backend .env file
echo ""
echo "📄 Creating Backend Environment File..."
cat > backend/.env << EOF
# ===========================================
# IMU Backend Environment Configuration
# Generated: $(date)
# ===========================================

# PowerSync RSA Keys
POWERSYNC_PRIVATE_KEY="$PRIVATE_KEY_FORMATTED"
POWERSYNC_PUBLIC_KEY="$PUBLIC_KEY_FORMATTED"

# PowerSync Configuration
POWERSYNC_URL=https://$POWERSYNC_INSTANCE_ID.powersync.journeyapps.com
POWERSYNC_KEY_ID=imu-production-key-$(date +%Y%m%d)

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_EXPIRY_HOURS=24

# Database
DATABASE_URL=postgresql://user:pass@host:5432/imu

# Add your existing database configuration below
# ...

EOF

echo "✅ Created: backend/.env"

# Create mobile .env.qa file
echo ""
echo "📄 Creating Mobile QA Environment File..."
cat > .env.qa << EOF
# ===========================================
# IMU Mobile QA Environment Configuration
# Generated: $(date)
# ===========================================

# PowerSync Configuration
POWERSYNC_URL=https://$POWERSYNC_INSTANCE_ID.powersync.journeyapps.com

# Backend API Configuration
POSTGRES_API_URL=https://imu-api.cfbtools.app/api

# JWT Configuration (MUST match backend!)
JWT_SECRET=$JWT_SECRET
JWT_EXPIRY_HOURS=24

# App Configuration
APP_NAME=IMU QA
APP_ENV=qa
DEBUG_MODE=true
LOG_LEVEL=debug

# Mapbox Configuration
MAPBOX_ACCESS_TOKEN=your_mapbox_access_token_here

EOF

echo "✅ Created: .env.qa"

# Verify setup
echo ""
echo "✅ Setup Complete! Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PowerSync Instance ID: $POWERSYNC_INSTANCE_ID"
echo "PowerSync URL: https://$POWERSYNC_INSTANCE_ID.powersync.journeyapps.com"
echo "JWT Secret: ${JWT_SECRET:0:10}... (32 characters)"
echo ""
echo "📄 Files Created:"
echo "  • backend/.env (backend environment)"
echo "  • .env.qa (mobile QA environment)"
echo ""
echo "🚀 Next Steps:"
echo "  1. Restart backend service"
echo "  2. Test backend JWT generation"
echo "  3. Build QA test APK"
echo "  4. Test mobile app login and sync"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Ask user what to do next
echo ""
echo "What would you like to do next?"
echo "1. Restart backend service"
echo "2. Test backend JWT generation"
echo "3. Build QA test APK"
echo "4. View generated files"
echo ""
read -p "Enter choice (1-4): " CHOICE

case $CHOICE in
  1)
    echo ""
    echo "🔄 To restart backend service:"
    echo "  cd backend"
    echo "  pnpm dev  # or your start command"
    ;;
  2)
    echo ""
    echo "🧪 To test backend JWT generation:"
    echo "  curl -X POST https://imu-api.cfbtools.app/api/auth/login \\"
    echo "    -H \"Content-Type: application/json\" \\"
    echo "    -d '{\"email\":\"your-email@example.com\",\"password\":\"your-password\"}'"
    ;;
  3)
    echo ""
    echo "📱 To build QA test APK:"
    echo "  flutter build apk --debug --dart-define=ENV=qa"
    ;;
  4)
    echo ""
    echo "📄 Viewing generated files..."
    echo ""
    echo "=== backend/.env (first 20 lines) ==="
    head -20 backend/.env
    echo ""
    echo "=== .env.qa ==="
    cat .env.qa
    ;;
  *)
    echo "Invalid choice. Please run script again."
    exit 1
    ;;
esac

echo ""
echo "✅ Setup complete!"