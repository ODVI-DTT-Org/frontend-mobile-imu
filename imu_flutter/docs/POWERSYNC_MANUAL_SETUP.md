# PowerSync Credentials Setup - Manual Guide

> **You have:** PowerSync PEM keys (private + public) and Instance ID
> **Need to:** Configure them in backend and mobile app for production deployment

---

## Your PowerSync Details

- **PowerSync Instance ID:** `[Your Instance ID]`
- **PowerSync URL:** `https://[Your Instance ID].powersync.journeyapps.com`

---

## Step 1: Format Your PEM Keys for Environment Variables

Your PEM keys need to be formatted with escaped newlines (`\\n`) for environment variables.

### Option A: Use PowerShell (Windows)

```powershell
# Read private key and format with escaped newlines
$key = Get-Content "path\to\powersync-private.pem" -Raw
$formatted = $key -replace "`n", "\n" -replace "-----BEGIN PRIVATE KEY-----", "-----BEGIN PRIVATE KEY-----`n" -replace "-----END PRIVATE KEY-----", "`n-----END PRIVATE KEY-----" -replace "\n", "\\n"
$formatted | Out-File -Encoding ASCII "private-key-formatted.txt"

# Read public key and format with escaped newlines
$key = Get-Content "path\to\powersync-public.pem" -Raw
$formatted = $key -replace "`n", "\n" -replace "-----BEGIN PUBLIC KEY-----", "-----BEGIN PUBLIC KEY-----`n" -replace "-----END PUBLIC KEY-----", "`n-----END PUBLIC KEY-----" -replace "\n", "\\n"
$formatted | Out-File -Encoding ASCII "public-key-formatted.txt"
```

### Option B: Use Command Line

```bash
# On Linux/Mac
cat powersync-private.pem | tr '\n' '\\n' | sed 's/-----BEGIN PRIVATE KEY-----/-----BEGIN PRIVATE KEY-----\\n/g' | sed 's/-----END PRIVATE KEY-----/\\n-----END PRIVATE KEY-----/g' > private-key-formatted.txt

cat powersync-public.pem | tr '\n' '\\n' | sed 's/-----BEGIN PUBLIC KEY-----/-----BEGIN PUBLIC KEY-----\\n/g' | sed 's/-----END PUBLIC KEY-----/\\n-----END PUBLIC KEY-----/g' > public-key-formatted.txt
```

---

## Step 2: Generate JWT Secret

```bash
# Generate 32-character random secret
openssl rand -base64 32
```

**Example Output:**
```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4
```

---

## Step 3: Update Backend Environment

Add to `backend/.env`:

```bash
# PowerSync RSA Keys
POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MII... (paste formatted private key with \\n for newlines)
-----END PRIVATE KEY-----"

POWERSYNC_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIB... (paste formatted public key with \\n for newlines)
-----END PUBLIC KEY-----"

# PowerSync Configuration
POWERSYNC_URL=https://[YOUR-INSTANCE-ID].powersync.journeyapps.com
POWERSYNC_KEY_ID=imu-production-key-20260402

# JWT Configuration
JWT_SECRET=[YOUR-JWT-SECRET-32-CHARACTERS]
JWT_EXPIRY_HOURS=24

# Database (existing - keep your current)
DATABASE_URL=postgresql://user:pass@host:5432/imu

# Other existing configuration...
```

---

## Step 4: Update Mobile Environment

Add to `mobile/imu_flutter/.env.qa`:

```bash
# PowerSync Configuration
POWERSYNC_URL=https://[YOUR-INSTANCE-ID].powersync.journeyapps.com

# Backend API Configuration
POSTGRES_API_URL=https://imu-api.cfbtools.app/api

# JWT Configuration (MUST match backend!)
JWT_SECRET=[SAME-JWT-SECRET-FROM-STEP-3]
JWT_EXPIRY_HOURS=24

# App Configuration
APP_NAME=IMU QA
APP_ENV=qa
DEBUG_MODE=true
LOG_LEVEL=debug

# Mapbox Configuration (add your token)
MAPBOX_ACCESS_TOKEN=your-mapbox-access-token-here
```

---

## Step 5: Restart Backend

```bash
cd backend
# Stop current service (Ctrl+C)
pnpm dev
```

---

## Step 6: Test Backend JWT Generation

```bash
curl -X POST https://imu-api.cfbtools.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"your-email@example.com","password":"your-password"}'
```

**Expected Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": {
    "id": "...",
    "email": "your-email@example.com",
    "first_name": "...",
    "last_name": "...",
    "role": "..."
  }
}
```

---

## Step 7: Build QA Test APK

```bash
cd mobile/imu_flutter
flutter build apk --debug --dart-define=ENV=qa
```

**Output:** `build/app/outputs/flutter-apk/app-debug.apk`

---

## Step 8: Install and Test

1. **Install APK** on Android device
2. **Open app** and login
3. **Verify sync works** (clients should load)
4. **Check PowerSync status** in logs

---

## Quick Verification

After setup, verify:

```bash
# Test backend is running
curl https://imu-api.cfbtools.app/api/health

# Check PowerSync instance
# Go to: https://app.powersync.journeyapps.com
# Check your instance status

# Test mobile app login
# Use the installed APK and login with valid credentials
```

---

## Troubleshooting

### Issue: "POWERSYNC_PRIVATE_KEY not found"

**Solution:**
- Verify key is in `.env` file
- Check backend restarted after `.env` update
- Verify newlines are escaped (`\\n`)

### Issue: "Invalid PowerSync token"

**Solution:**
- Verify JWT_SECRET matches between backend and mobile
- Check private key format (4096 bits)
- Restart backend service

### Issue: "Sync not working on mobile"

**Solution:**
- Check PowerSync URL is correct
- Verify JWT token is valid (not expired)
- Check network connectivity
- Review mobile app logs for PowerSync errors

---

## Support

**Setup Script:** `scripts/setup-powersync-credentials.bat` (Windows)
**Setup Script:** `scripts/setup-powersync-credentials.sh` (Linux/Mac)
**Full Guide:** `docs/POWERSYNC_CREDENTIALS_SETUP.md`
**Quick Start:** `docs/POWERSYNC_QUICK_SETUP.md`

---

**Quick Setup Version:** 1.0
**Last Updated:** 2026-04-02
