# PowerSync Credentials Quick Setup Script

> **Quick Setup:** Run these commands to generate and test PowerSync credentials

---

## Step 1: Generate RSA Key Pair

```bash
# Navigate to a secure directory
cd ~/imu-credentials

# Generate RSA private key (4096 bits)
openssl genrsa -out powersync-private.pem 4096

# Extract public key
openssl rsa -in powersync-private.pem -pubout -out powersync-public.pem

# Verify keys
openssl rsa -in powersync-private.pem -check
openssl rsa -in powersync-public.pem -pubin -check
```

---

## Step 2: Generate JWT Secret

```bash
# Generate 32+ character random string
openssl rand -base64 32
```

**Example Output:**
```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4
```

---

## Step 3: Format Keys for Environment Variables

```bash
# Read private key and format for environment variable
cat powersync-private.pem | tr '\n' '\\n' | pbcopy  # macOS
cat powersync-private.pem | tr '\n' '\\n' | xclip   # Linux

# Read public key and format for environment variable
cat powersync-public.pem | tr '\n' '\\n' | pbcopy    # macOS
cat powersync-public.pem | tr '\n' '\\n' | xclip     # Linux
```

---

## Step 4: Add to Backend Environment

Create or update `.env` in backend directory:

```bash
# PowerSync RSA Keys
POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MII... (paste private key here with \\n for newlines)
-----END PRIVATE KEY-----"

POWERSYNC_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIB... (paste public key here with \\n for newlines)
-----END PUBLIC KEY-----"

# PowerSync Configuration
POWERSYNC_URL=https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com
POWERSYNC_KEY_ID=imu-production-key-20260402

# JWT Configuration
JWT_SECRET=<paste generated JWT secret here>
JWT_EXPIRY_HOURS=24

# Database
DATABASE_URL=postgresql://user:pass@host:5432/imu
```

---

## Step 5: Add to Mobile Environment

Create or update `.env.qa` in mobile directory:

```bash
# PowerSync Configuration
POWERSYNC_URL=https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com

# Backend API
POSTGRES_API_URL=https://imu-api.cfbtools.app/api

# JWT Configuration (must match backend!)
JWT_SECRET=<same JWT secret as backend>
JWT_EXPIRY_HOURS=24

# App Configuration
APP_NAME=IMU QA
DEBUG_MODE=true
LOG_LEVEL=debug
```

---

## Step 6: Test Backend JWT Generation

```bash
# Test login endpoint
curl -X POST https://imu-api.cfbtools.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass"}'
```

**Expected:** JSON response with access_token

---

## Step 7: Verify PowerSync Configuration

```bash
# Navigate to PowerSync directory
cd mobile/imu_flutter/powersync

# Install PowerSync CLI (if not installed)
npm install -g @powersync/cli

# Login to PowerSync
powersync login

# Link to your instance
powersync link cloud --project-id=<your-project-id> --instance-id=69cb46b4f69619e9d4830ea1

# Check status
powersync fetch status
```

---

## Quick Verification Checklist

- [ ] RSA keys generated (4096 bits)
- [ ] JWT secret generated (32+ characters)
- [ ] Backend .env updated with POWERSYNC_PRIVATE_KEY
- [ ] Backend .env updated with POWERSYNC_PUBLIC_KEY
- [ ] Backend .env updated with JWT_SECRET
- [ ] Mobile .env.qa updated with same JWT_SECRET
- [ ] Mobile .env.qa updated with POWERSYNC_URL
- [ ] Mobile .env.qa updated with POSTGRES_API_URL
- [ ] Backend restarted with new environment variables
- [ ] Test `/auth/login` endpoint works
- [ ] Test PowerSync connection works

---

## Your Configuration Values

**PowerSync Instance ID:** `69cb46b4f69619e9d4830ea1`
**PowerSync URL:** `https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com`
**Backend API:** `https://imu-api.cfbtools.app/api`

---

## Need Help?

- **Full Guide:** `docs/POWERSYNC_CREDENTIALS_SETUP.md`
- **PowerSync Docs:** https://docs.powersync.com
- **Support:** Contact development team

---

**Quick Setup Version:** 1.0
**Last Updated:** 2026-04-02
