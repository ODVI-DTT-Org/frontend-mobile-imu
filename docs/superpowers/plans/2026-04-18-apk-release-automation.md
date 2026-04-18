# APK Release Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a GitHub Actions workflow that builds a Flutter release APK on every push to `main` and uploads it to Google Drive, then emails `egonzaga@oakdriveventures.com` on success.

**Architecture:** A single GitHub Actions workflow file handles the full pipeline — Flutter build → APK rename → rclone upload to Google Drive via service account auth → Gmail SMTP email notification. All secrets are stored as GitHub repository secrets, never in code.

**Tech Stack:** GitHub Actions, Flutter (stable), Java 17, rclone, Google Drive API (service account), dawidd6/action-send-mail (Gmail SMTP)

**Spec:** `docs/superpowers/specs/2026-04-18-apk-release-automation-design.md`

---

## File Structure

```
frontend-mobile-imu/
└── .github/
    └── workflows/
        └── release-apk.yml    ← CREATE: full CI pipeline
```

That's the only file. All other setup is done in external systems (Google Cloud Console, Google Drive, GitHub Settings).

---

## Task 1: Complete One-Time External Setup

> This task is manual. No code. Must be done before pushing the workflow file or the first run will fail.

**Files:** None

- [ ] **Step 1: Create Google Cloud project and enable Drive API**

  1. Go to [https://console.cloud.google.com](https://console.cloud.google.com)
  2. Click the project dropdown (top left) → **New Project**
  3. Name it `IMU CI` → Create
  4. In the search bar, search **"Google Drive API"** → click it → click **Enable**

- [ ] **Step 2: Create a Service Account**

  1. Go to: APIs & Services → Credentials → **+ Create Credentials** → Service Account
  2. Name: `imu-github-actions` → click **Done** (skip optional steps)
  3. Click the new service account row → **Keys** tab → **Add Key** → **Create new key** → JSON → **Create**
  4. A JSON file downloads. Keep it open/handy — you'll paste it into GitHub secrets shortly.
  5. Copy the `client_email` field from the JSON (looks like `imu-github-actions@imu-ci.iam.gserviceaccount.com`)

- [ ] **Step 3: Set up Google Drive folder**

  1. Go to [https://drive.google.com](https://drive.google.com)
  2. Create a folder called **`IMU Releases`**
  3. Inside `IMU Releases`, create a subfolder called **`APK`**
  4. Right-click **`IMU Releases`** → Share → paste the service account `client_email` → change role to **Editor** → Send
  5. Open the **`APK`** subfolder → copy the folder ID from the URL:
     `https://drive.google.com/drive/folders/`**`<COPY_THIS_PART>`**

- [ ] **Step 4: Create Gmail App Password**

  1. Log in to the Gmail account that will send notifications (create one if needed)
  2. Go to: [https://myaccount.google.com/security](https://myaccount.google.com/security)
  3. Enable **2-Step Verification** if not already on
  4. Search for **"App Passwords"** → create one named `IMU GitHub Actions`
  5. Copy the 16-character password (shown once)

- [ ] **Step 5: Add GitHub Secrets**

  1. Go to the `frontend-mobile-imu` GitHub repo
  2. Settings → Secrets and variables → Actions → **New repository secret**
  3. Add these 4 secrets one by one:

  | Name | Value |
  |------|-------|
  | `GDRIVE_SERVICE_ACCOUNT_KEY` | Entire contents of the JSON key file (paste as-is) |
  | `GDRIVE_FOLDER_ID` | The folder ID from Step 3 (the string after `/folders/`) |
  | `MAIL_USERNAME` | The sender Gmail address |
  | `MAIL_PASSWORD` | The 16-character App Password from Step 4 |

---

## Task 2: Create the GitHub Actions Workflow

**Files:**
- Create: `.github/workflows/release-apk.yml`

- [ ] **Step 1: Create the workflows directory**

  ```bash
  mkdir -p .github/workflows
  ```

- [ ] **Step 2: Create the workflow file**

  Create `.github/workflows/release-apk.yml` with this exact content:

  ```yaml
  name: Release APK to Google Drive

  on:
    push:
      branches: [main]

  jobs:
    build-and-upload:
      runs-on: ubuntu-latest

      steps:
        - name: Checkout repository
          uses: actions/checkout@v4

        - name: Setup Java 17
          uses: actions/setup-java@v4
          with:
            distribution: temurin
            java-version: '17'

        - name: Setup Flutter
          uses: subosito/flutter-action@v2
          with:
            channel: stable
            cache: true

        - name: Cache pub dependencies
          uses: actions/cache@v4
          with:
            path: ~/.pub-cache
            key: ${{ runner.os }}-pub-${{ hashFiles('imu_flutter/pubspec.lock') }}
            restore-keys: |
              ${{ runner.os }}-pub-

        - name: Install dependencies
          working-directory: imu_flutter
          run: flutter pub get

        - name: Build release APK
          working-directory: imu_flutter
          run: flutter build apk --release

        - name: Rename and stage APK
          run: |
            DATE=$(date +%Y-%m-%d)
            APK_NAME="imu-${DATE}-b${{ github.run_number }}.apk"
            mv imu_flutter/build/app/outputs/flutter-apk/app-release.apk "${APK_NAME}"
            echo "APK_NAME=${APK_NAME}" >> $GITHUB_ENV
            echo "BUILD_DATE=${DATE}" >> $GITHUB_ENV

        - name: Install rclone
          run: curl https://rclone.org/install.sh | sudo bash

        - name: Configure rclone
          run: |
            echo '${{ secrets.GDRIVE_SERVICE_ACCOUNT_KEY }}' > /tmp/sa.json
            mkdir -p ~/.config/rclone
            cat > ~/.config/rclone/rclone.conf << 'RCLONE_EOF'
            [gdrive]
            type = drive
            scope = drive
            service_account_file = /tmp/sa.json
            RCLONE_EOF

        - name: Upload APK to Google Drive
          run: |
            rclone copy "${{ env.APK_NAME }}" "gdrive:/" \
              --drive-root-folder-id "${{ secrets.GDRIVE_FOLDER_ID }}" \
              --drive-upload-cutoff 100M \
              -v
            echo "Uploaded: ${{ env.APK_NAME }}"

        - name: Send email notification
          uses: dawidd6/action-send-mail@v3
          with:
            server_address: smtp.gmail.com
            server_port: 465
            username: ${{ secrets.MAIL_USERNAME }}
            password: ${{ secrets.MAIL_PASSWORD }}
            subject: "✅ IMU APK Build #${{ github.run_number }} — Ready on Google Drive"
            to: egonzaga@oakdriveventures.com
            from: ${{ secrets.MAIL_USERNAME }}
            body: |
              A new IMU APK has been built and uploaded to Google Drive.

              Build: #${{ github.run_number }}
              Date: ${{ env.BUILD_DATE }}
              File: ${{ env.APK_NAME }}
              Drive folder: https://drive.google.com/drive/folders/${{ secrets.GDRIVE_FOLDER_ID }}

              Triggered by: push to main
              Commit: ${{ github.sha }}
  ```

- [ ] **Step 3: Validate YAML syntax**

  Install `yamllint` and check for syntax errors:

  ```bash
  pip install yamllint
  yamllint .github/workflows/release-apk.yml
  ```

  Expected output: no errors (warnings about line length are fine).

- [ ] **Step 4: Commit the workflow**

  ```bash
  git add .github/workflows/release-apk.yml
  git commit -m "ci: add GitHub Actions workflow for APK release to Google Drive"
  ```

---

## Task 3: Trigger and Verify

**Files:** None (observing external systems)

- [ ] **Step 1: Push to main**

  ```bash
  git push origin main
  ```

- [ ] **Step 2: Watch the workflow run**

  1. Go to the `frontend-mobile-imu` GitHub repo
  2. Click the **Actions** tab
  3. You should see **"Release APK to Google Drive"** running
  4. Click into it and watch the steps execute in real time
  5. Full run takes ~5-8 minutes (Flutter compile is the slow step)

- [ ] **Step 3: Verify APK in Google Drive**

  1. Open `IMU Releases/APK/` in Google Drive
  2. Confirm the file `imu-YYYY-MM-DD-b1.apk` (where build number = 1) is present
  3. Download and confirm it opens (can be installed on an Android device)

- [ ] **Step 4: Verify email**

  1. Check `egonzaga@oakdriveventures.com` inbox
  2. Email subject should be: `✅ IMU APK Build #1 — Ready on Google Drive`
  3. Body should contain the Drive folder link

- [ ] **Step 5: If the workflow fails — common fixes**

  | Symptom | Fix |
  |---------|-----|
  | `flutter build apk` fails with SDK error | Check Java 17 is set up; run `flutter doctor` locally first |
  | `rclone: access denied` | Service account email not shared on the Drive folder (re-do Task 1 Step 3) |
  | `rclone: object not found` | `GDRIVE_FOLDER_ID` is wrong — must be the `APK` subfolder ID, not `IMU Releases` |
  | Email not received | Check spam folder; verify `MAIL_PASSWORD` is App Password, not regular Gmail password |
  | `GDRIVE_SERVICE_ACCOUNT_KEY` parse error | Ensure the JSON was pasted as-is with no trailing whitespace or truncation |

---

## Notes

- The `subosito/flutter-action@v2` action handles Flutter install; `cache: true` speeds up subsequent runs significantly.
- The service account JSON is written to `/tmp/sa.json` at runtime and referenced by rclone — it never touches the repo.
- `--drive-root-folder-id` tells rclone to treat `GDRIVE_FOLDER_ID` as the root, so the upload goes directly into the APK folder without creating subfolders.
- `dawidd6/action-send-mail@v3` uses Gmail SMTP over port 465 (SSL). App Password is required because Google blocks regular passwords for SMTP when 2FA is enabled.
