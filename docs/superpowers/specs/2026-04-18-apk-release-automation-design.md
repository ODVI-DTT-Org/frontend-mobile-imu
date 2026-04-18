# APK Release Automation — Design Spec

**Date:** 2026-04-18
**Project:** IMU Flutter Mobile App (`frontend-mobile-imu`)
**Status:** Approved

---

## Overview

Automate the Flutter APK release process so that every push to `main` builds a release APK and uploads it to Google Drive, then sends a success email notification.

**Future scope (not in this spec):** AAB → Google Play Store (Play Console not yet configured).

---

## Pipeline Flow

```
Push to main
  → GitHub Actions triggered
  → Java 17 + Flutter (stable) setup
  → flutter pub get
  → flutter build apk --release
  → rclone uploads APK to Google Drive
  → Email notification sent to egonzaga@oakdriveventures.com
```

**Trigger:** Push to `main` branch
**Runner:** `ubuntu-latest`
**Estimated build time:** 5–8 minutes
**Workflow file:** `.github/workflows/release-apk.yml`

---

## Google Drive Structure

```
IMU Releases/          ← shared with service account (Editor)
└── APK/
    ├── imu-2026-04-18-b42.apk
    ├── imu-2026-04-19-b43.apk
    └── ...
```

**Naming convention:** `imu-YYYY-MM-DD-b{run_number}.apk`
- Uses GitHub's built-in `${{ github.run_number }}` for build number
- APK source path: `build/outputs/flutter-apk/app-release.apk`

All previous APKs are retained (no auto-deletion).

---

## Authentication

### Google Drive — Service Account
- Create a Google Cloud project and enable the **Google Drive API**
- Create a **Service Account** and download the JSON key
- Share the `IMU Releases` Google Drive folder with the service account email (Editor access)
- rclone config is generated at runtime from the secret (no config file committed to repo)

### Email — Gmail SMTP
- A sender Gmail account with an **App Password** (not the regular account password)
- Uses `dawidd6/action-send-mail` GitHub Action

---

## GitHub Secrets (4 total)

| Secret | Value |
|--------|-------|
| `GDRIVE_SERVICE_ACCOUNT_KEY` | Full JSON content of the service account key file |
| `GDRIVE_FOLDER_ID` | Google Drive folder ID for `IMU Releases/APK/` (from URL) |
| `MAIL_USERNAME` | Sender Gmail address |
| `MAIL_PASSWORD` | Gmail App Password |

---

## Email Notification

**Recipient:** `egonzaga@oakdriveventures.com`
**Trigger:** Only on successful upload (not on build failure)
**Subject:** `✅ IMU APK Build #<run_number> — Ready on Google Drive`
**Body:**
```
A new IMU APK has been built and uploaded to Google Drive.

Build: #<run_number>
Date: <YYYY-MM-DD>
File: imu-<date>-b<run_number>.apk
Drive folder: https://drive.google.com/drive/folders/<GDRIVE_FOLDER_ID>

Triggered by: push to main
```

---

## Workflow Steps (detail)

```yaml
name: Release APK to Google Drive

on:
  push:
    branches: [main]

jobs:
  build-and-upload:
    runs-on: ubuntu-latest
    steps:
      - Checkout repo
      - Setup Java 17 (temurin distribution)
      - Setup Flutter (stable channel)
      - Cache ~/.pub-cache (speeds up subsequent builds)
      - Run: flutter pub get
      - Run: flutter build apk --release
      - Rename APK to imu-{date}-b{run_number}.apk
      - Install rclone
      - Write rclone.conf using GDRIVE_SERVICE_ACCOUNT_KEY secret
      - Upload APK via rclone to GDRIVE_FOLDER_ID
      - Send email via dawidd6/action-send-mail
```

---

## One-Time Setup Guide

### Step 1: Google Cloud Console
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (e.g., "IMU CI")
3. Enable the **Google Drive API**: APIs & Services → Library → search "Google Drive API" → Enable
4. Go to: APIs & Services → Credentials → Create Credentials → Service Account
5. Name it (e.g., "imu-github-actions"), click Done
6. Click the service account → Keys tab → Add Key → JSON → download the file
7. Note the service account email (e.g., `imu-github-actions@imu-ci.iam.gserviceaccount.com`)

### Step 2: Google Drive
1. In Google Drive, create a folder called `IMU Releases`
2. Inside it, create a subfolder called `APK`
3. Right-click `IMU Releases` → Share → paste the service account email → set to Editor → Send
4. Open the `APK` subfolder → copy the folder ID from the URL:
   `https://drive.google.com/drive/folders/`**`<THIS_IS_THE_FOLDER_ID>`**

### Step 3: Gmail App Password
1. Use or create a Gmail account for sending notifications
2. Enable 2-Step Verification on the account (required for App Passwords)
3. Go to: Google Account → Security → App Passwords → create one named "IMU GitHub Actions"
4. Copy the 16-character password

### Step 4: GitHub Secrets
1. Go to the `frontend-mobile-imu` GitHub repo
2. Settings → Secrets and variables → Actions → New repository secret
3. Add all 4 secrets:
   - `GDRIVE_SERVICE_ACCOUNT_KEY` — paste entire JSON file content
   - `GDRIVE_FOLDER_ID` — the folder ID from Step 2
   - `MAIL_USERNAME` — sender Gmail address
   - `MAIL_PASSWORD` — the App Password from Step 3

---

## Out of Scope

- AAB → Google Play Store (Play Console setup pending)
- Build failure notifications
- Automatic deletion of old APKs
- Versioning from `pubspec.yaml` (using run number instead for simplicity)
