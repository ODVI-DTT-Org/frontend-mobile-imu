# Google Play Store Deployment Setup Guide

This guide walks you through setting up automated Play Store deployments via GitHub Actions.

## Overview

The workflow supports:
- **Automatic deployment** to Internal Testing on every push to `main`
- **Manual deployment** to any track (Internal, Alpha, Beta, Production) with staged rollout
- **Email notifications** for success/failure
- **AAB (Android App Bundle)** format (required by Google Play)

## Required Secrets

### 1. Google Play Service Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (com.odvi.imu)
3. Navigate to **Setup → API access**
4. Click **Link a new service account**
5. This opens Google Cloud Console - create a new service account:
   - **Name**: `github-actions-playstore`
   - **Role**: Service Account User
6. After creating, click the service account → **Keys** tab → **Add Key** → **Create new key**
   - Key type: **JSON**
   - Download the JSON file
7. **Important**: Copy the entire content of the JSON file

8. Back in Play Console, under **API access**, grant permissions:
   - **Release Manager** - Required for uploading releases
   - (Optional) **Admin** - Full access

9. Add to GitHub Secrets:
   ```
   Name: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
   Value: <paste entire JSON content>
   ```

### 2. App Signing Keystore

Generate a production keystore (one-time):

```bash
keytool -genkey -v -keystore imu-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias imu-key
```

**Important**: Keep this file secure! Never commit it to git.

Add to GitHub Secrets:

```bash
# Encode keystore to base64
base64 -i imu-release.jks | pbcopy  # macOS
base64 -w 0 imu-release.jks           # Linux
```

```
Name: KEYSTORE_FILE
Value: <paste base64-encoded keystore>
```

Add keystore credentials:

```
Name: KEYSTORE_PASSWORD
Value: <your keystore password>

Name: KEY_ALIAS
Value: imu-key

Name: KEY_PASSWORD
Value: <your key password>
```

### 3. Email Notifications (Optional)

Already configured for `release-apk.yml`. Reuse the same secrets:

```
Name: MAIL_USERNAME
Value: your-email@gmail.com

Name: MAIL_PASSWORD
Value: your-app-password
```

**Note**: Use an App Password, not your regular password. Enable 2FA first.

---

## Local Development Setup

For local development, create `android/app/key.properties`:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=imu-key
storeFile=../../keystore.jks
```

Place your keystore file at `android/keystore.jks` (don't commit this).

Add to `.gitignore`:
```
android/app/key.properties
*.jks
keystore.jks
```

---

## Usage

### Automatic Deployment (Internal Testing)

Every push to `main` branch automatically deploys to **Internal Testing**:

```bash
git push origin main
```

The workflow will:
1. Build the AAB
2. Upload to Play Store (Internal Testing)
3. Send email notification
4. Comment on linked PR (if any)

### Manual Deployment (Any Track)

1. Go to **Actions** tab in GitHub
2. Select **Deploy to Google Play Store** workflow
3. Click **Run workflow**
4. Choose options:
   - **Track**: `internal`, `alpha`, `beta`, or `production`
   - **Rollout**: For beta/production, specify percentage (e.g., `0.1` = 10%, `1.0` = 100%)

### Recommended Deployment Strategy

```
main branch push → Internal Testing (automatic)
                     ↓
                 Manual promotion → Alpha → Beta → Production
```

| Track | Purpose | Automation |
|-------|---------|------------|
| **Internal** | Your team (up to 100 testers) | Auto on push to main |
| **Alpha** | Trusted testers | Manual dispatch |
| **Beta** | Public beta | Manual with staged rollout |
| **Production** | All users | Manual with staged rollout |

---

## Testing Locally

Before deploying, test the AAB build locally:

```bash
cd imu_flutter
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Test the AAB:
```bash
# Install via ADB on connected device
bundletool build-apks --bundle=app-release.aab --output=app.apks
bundletool install-apks --apks=app.apks
```

---

## Troubleshooting

### Build Fails with "Signing failed"

- Verify all keystore secrets are set correctly
- Ensure KEYSTORE_FILE is base64-encoded
- Check that passwords match your keystore

### Play Store Upload Fails

- Verify `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` is complete JSON
- Check service account has **Release Manager** permissions in Play Console
- Ensure package name matches: `com.odvi.imu`

### "App not found" Error

- Ensure the app exists in Google Play Console
- Package name must match exactly
- Service account must be linked to the correct app

### AAB Size Too Large

- AAB has a 150MB limit
- Check for unnecessary assets in `assets/` folder
- Consider enabling App Bundle size reporting

---

## Release Notes Format

The workflow automatically generates release notes:

```
🚀 Automated Build #42

📅 Date: 2026-04-21 10:30:00 UTC
🌿 Branch: main
👤 Author: username

📝 Changes:
Fix: resolve GitHub Actions APK build failure

🔗 Commit: abc123...
📦 View on GitHub: https://github.com/...
```

You can customize the template in `.github/workflows/deploy-playstore.yml`.

---

## Security Best Practices

1. **Never commit keystore files** to git
2. **Use GitHub Secrets** for all sensitive data
3. **Rotate secrets** periodically (especially keystore passwords)
4. **Limit service account permissions** to only what's needed
5. **Monitor deployment activity** in Play Console
6. **Keep backups** of your keystore in a secure location

---

## Related Files

- Workflow: `.github/workflows/deploy-playstore.yml`
- Build config: `android/app/build.gradle`
- Gradle props: `android/gradle.properties`

---

## Need Help?

- GitHub Actions: https://github.com/ODVI-DTT-Org/frontend-mobile-imu/actions
- Play Console: https://play.google.com/console
- Google Play API Docs: https://developers.google.com/android-publisher
