# PowerSync Credentials Setup Guide

> **For:** IMU Mobile App Production Deployment
> **Date:** 2026-04-02
> **PowerSync Instance:** 69cb46b4f69619e9d4830ea1

---

## Overview

The IMU mobile app uses PowerSync for offline-first data synchronization. This guide will help you set up all required credentials and API keys.

---

## Required Credentials

### 1. PowerSync Cloud Credentials ✅

**What:** PowerSync Cloud account and instance access

**Purpose:** Authenticates mobile app with PowerSync service

**How to Get:**

1. **Sign up for PowerSync Cloud:**
   - Go to: https://www.powersync.com/
   - Click "Sign Up" or "Start Free Trial"
   - Create account with email/password

2. **Create PowerSync Instance:**
   - Log in to PowerSync Dashboard: https://app.powersync.journeyapps.com
   - Click "Create New Instance"
   - **Instance Name:** IMU Production
   - **Database:** PostgreSQL (connected to your backend)
   - **Region:** Select closest to your users

3. **Get Instance Details:**
   - **Instance ID:** `69cb46b4f69619e9d4830ea1`
   - **PowerSync URL:** `https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com`
   - **Project ID:** Found in dashboard

---

### 2. PowerSync RSA Key Pair ✅ (CRITICAL)

**What:** RSA private/public key pair for signing PowerSync JWT tokens

**Purpose:** Backend uses private key to sign JWT tokens; PowerSync uses public key to verify

**Generate Keys:**

```bash
# Generate RSA private key (4096 bits)
openssl genrsa -out powersync-private.pem 4096

# Extract public key
openssl rsa -in powersync-private.pem -pubout -out powersync-public.pem

# Verify keys
openssl rsa -in powersync-private.pem -check
openssl rsa -in powersync-public.pem -pubin -check
```

**Key Format (PEM):**

```bash
# Private key format (for environment variable)
-----BEGIN PRIVATE KEY-----
MII... (very long string)...
-----END PRIVATE KEY-----

# Public key format (for environment variable)
-----BEGIN PUBLIC KEY-----
MIIB... (long string)...
-----END PUBLIC KEY-----
```

**Add to Backend Environment Variables:**

```bash
# DigitalOcean App Platform / Server
POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MII...
-----END PRIVATE KEY-----"

POWERSYNC_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIB...
-----END PUBLIC KEY-----"
```

**⚠️ CRITICAL:** Handle private keys securely! Never commit to git.

---

### 3. Backend API JWT Secret ✅

**What:** Secret key for signing backend API JWT tokens

**Purpose:** Authenticates mobile app with backend API

**Generate Secret:**

```bash
# Generate 32+ character random string
openssl rand -base64 32
```

**Example Output:**
```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
```

**Add to Backend Environment Variables:**

```bash
JWT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
```

---

### 4. PowerSync Service URL ✅

**What:** URL of your PowerSync Cloud instance

**Purpose:** Mobile app connects to this URL for sync

**Your PowerSync URL:**
```
https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com
```

**Add to Mobile Environment Variables:**

```bash
# .env.qa
POWERSYNC_URL=https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com
```

---

### 5. Backend API URL ✅

**What:** URL of your backend API

**Purpose:** Mobile app connects to this URL for API calls

**Your Backend API URL:**
```
https://imu-api.cfbtools.app/api
```

**Add to Mobile Environment Variables:**

```bash
# .env.qa
POSTGRES_API_URL=https://imu-api.cfbtools.app/api
```

---

## Environment Configuration

### Backend Environment Variables

Create/update `.env` file in backend directory:

```bash
# PowerSync RSA Keys (REQUIRED)
POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MII... (4096-bit key)
-----END PRIVATE KEY-----"

POWERSYNC_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIB... (public key)
-----END PUBLIC KEY-----"

# PowerSync Configuration
POWERSYNC_URL=https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com
POWERSYNC_KEY_ID=imu-production-key-20260402

# JWT Configuration
JWT_SECRET=your-jwt-secret-min-32-characters
JWT_EXPIRY_HOURS=24

# Database (existing)
DATABASE_URL=postgresql://user:pass@host:5432/imu

# Other (existing)
# ...
```

### Mobile Environment Variables

Create/update `.env.qa` in mobile directory:

```bash
# PowerSync Configuration
POWERSYNC_URL=https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com

# Backend API Configuration
POSTGRES_API_URL=https://imu-api.cfbtools.app/api

# JWT Configuration (must match backend)
JWT_SECRET=your-jwt-secret-min-32-characters
JWT_EXPIRY_HOURS=24

# App Configuration
APP_NAME=IMU QA
DEBUG_MODE=true
LOG_LEVEL=debug
```

---

## Verification Steps

### 1. Verify Backend Keys

**Test Private Key:**
```bash
# Test private key is valid
openssl rsa -in powersync-private.pem -check -noout

# View key details
openssl rsa -in powersync-private.pem -text -noout
```

**Expected Output:**
```
RSA key ok
n=4096 bits
e=65537 (0x10001)
```

### 2. Verify Backend JWT Generation

**Test JWT Signing:**
```bash
# Test PowerSync JWT generation
curl -X POST https://imu-api.cfbtools.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass"}'
```

**Expected Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": {...}
}
```

### 3. Verify Mobile App Configuration

**Test API Connection:**
```bash
# Test backend health endpoint
curl https://imu-api.cfbtools.app/api/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-04-02T..."
}
```

### 4. Verify PowerSync Connection

**Test PowerSync Authentication:**
```bash
# Get PowerSync status
cd mobile/imu_flutter/powersync
powersync login
powersync link cloud --project-id=<your-project-id> --instance-id=69cb46b4f69619e9d4830ea1
powersync fetch status
```

**Expected Output:**
```
✅ Connected to PowerSync
Status: Connected
Instance: 69cb46b4f69619e9d4830ea1
```

---

## Current Configuration Status

### ✅ Already Configured

1. **PowerSync Instance:** `69cb46b4f69619e9d4830ea1`
2. **PowerSync URL:** `https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com`
3. **Backend API:** `https://imu-api.cfbtools.app/api`
4. **Sync Rules:** Role-based filtering configured

### ⚠️ Needs Configuration

1. **PowerSync RSA Keys:** Generate and add to backend
2. **JWT Secret:** Generate and add to both backend and mobile
3. **Environment Variables:** Update both backend and mobile

---

## Setup Checklist

### Backend Setup

- [ ] Generate RSA key pair (private/public)
- [ ] Add POWERSYNC_PRIVATE_KEY to backend environment
- [ ] Add POWERSYNC_PUBLIC_KEY to backend environment
- [ ] Verify JWT_SECRET is set (32+ characters)
- [ ] Restart backend service
- [ ] Test `/auth/login` endpoint
- [ ] Verify JWT tokens are generated correctly

### Mobile App Setup

- [ ] Update .env.qa with production URLs
- [ ] Add JWT_SECRET matching backend
- [ ] Add POWERSYNC_URL
- [ ] Build APK with QA environment
- [ ] Test login functionality
- [ ] Verify PowerSync sync works

---

## Security Best Practices

### 🔐 Private Key Security

**DO:**
- Store in secure environment variables
- Use different keys for dev/staging/production
- Rotate keys periodically
- Restrict file access (chmod 600)

**DON'T:**
- Commit keys to git
- Share keys via email/chat
- Store in plain text files
- Use the same key everywhere

### 🔐 JWT Secret Security

**DO:**
- Use 32+ character random string
- Rotate secrets periodically
- Use different secrets per environment
- Store in secure environment variables

**DON'T:**
- Use default/weak secrets
- Share secrets via email/chat
- Commit secrets to git
- Use production secrets in development

---

## Testing Your Setup

### 1. Test Backend JWT Generation

```bash
# Login and get tokens
curl -X POST https://imu-api.cfbtools.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"your-email@example.com","password":"your-password"}'
```

**Expected:** JSON with access_token and refresh_token

### 2. Test PowerSync Authentication

```bash
# Decode JWT to verify PowerSync claims
# Use jwt.io or similar tool
# Should contain: user_id, exp, iat
```

### 3. Test Mobile App Login

1. Install debug APK on device
2. Open app and login
3. Check if sync works (clients should load)

---

## Troubleshooting

### Issue: "POWERSYNC_PRIVATE_KEY not found"

**Cause:** Environment variable not set

**Solution:**
```bash
# Add to backend .env file
POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
...your key here...
-----END PRIVATE KEY-----"
```

### Issue: "Invalid PowerSync token"

**Cause:** JWT signing failed or key mismatch

**Solution:**
1. Verify private key is valid
2. Check key format (with \n escaped)
3. Restart backend service
4. Generate new tokens

### Issue: "PowerSync connection refused"

**Cause:** Wrong PowerSync URL or credentials

**Solution:**
1. Verify PowerSync URL is correct
2. Check instance is active
3. Verify JWT token is valid
4. Test PowerSync authentication

---

## Next Steps

After setting up credentials:

1. ✅ **Verify backend JWT generation works**
2. ✅ **Test mobile app login**
3. ✅ **Verify PowerSync sync works**
4. ✅ **Build QA test APK**
5. ✅ **Deploy to staging for QA testing**

---

## Support

**PowerSync Documentation:** https://docs.powersync.com
**PowerSync Dashboard:** https://app.powersync.journeyapps.com
**Backend API Docs:** `backend/docs/api-contracts.md`
**Mobile App Docs:** `mobile/imu_flutter/docs/DEPLOYMENT_GUIDE.md`

---

**Last Updated:** 2026-04-02
**Document Version:** 1.0
