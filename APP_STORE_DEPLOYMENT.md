# SLAPP - App Store Deployment Guide

## Overview
SLAPP uses **Codemagic** for building iOS and Android apps without a Mac.

## App Identifiers
- **Android Package ID**: `fun.slapp.slapp`
- **iOS Bundle ID**: `fun.slapp.slapp`

---

## 🤖 Android (Google Play Store)

### Step 1: Create App in Google Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app with package name: `fun.slapp.slapp`
3. Fill in app details, content rating, etc.

### Step 2: Create Service Account for Codemagic
1. In Play Console, go to **Setup > API access**
2. Click **Create new service account**
3. Follow the link to Google Cloud Console
4. Create a service account with **Editor** role
5. Create a JSON key and download it
6. Back in Play Console, grant this service account access to your app

### Step 3: Build APK for Testing (Local)
```bash
cd /workspaces/SLAPP
flutter build apk --release
```
APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🍎 iOS (App Store)

### Step 1: Create App in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps > +** to create new app
3. Use Bundle ID: `fun.slapp.slapp`
4. Fill in app name: **SLAPP**

### Step 2: Create App ID in Developer Portal
1. Go to [Apple Developer Portal](https://developer.apple.com)
2. **Certificates, IDs & Profiles > Identifiers**
3. Click **+** and create App ID
4. Bundle ID: `fun.slapp.slapp`
5. Enable capabilities: **Push Notifications** (optional)

### Step 3: Create Provisioning Profile
1. In Developer Portal: **Profiles > +**
2. Select **App Store** distribution
3. Select your App ID (`fun.slapp.slapp`)
4. Download the profile

---

## 🚀 Codemagic Setup (Recommended - No Mac Required!)

### Step 1: Connect Repository
1. Go to [codemagic.io](https://codemagic.io)
2. Sign up with GitHub
3. Add your SLAPP repository

### Step 2: Configure iOS Code Signing
1. In Codemagic, go to your app settings
2. **Code signing > iOS**
3. Upload your:
   - Distribution certificate (.p12)
   - Provisioning profile (.mobileprovision)
   - Or use **Automatic code signing** with App Store Connect API key

### Step 3: Configure Android Signing
1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore slapp-release.keystore -alias slapp -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Upload keystore to Codemagic
3. Add environment variables:
   - `CM_KEYSTORE_PASSWORD`
   - `CM_KEY_ALIAS`
   - `CM_KEY_PASSWORD`

### Step 4: Add Publishing Credentials

**For Google Play:**
1. Create environment group `google_play_credentials`
2. Add variable `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` with JSON content

**For App Store:**
1. Create environment group `app_store_credentials`  
2. Use App Store Connect API key or Apple ID credentials

### Step 5: Trigger Build
Push to main branch or manually trigger in Codemagic dashboard.

---

## 📱 App Store Requirements Checklist

### Both Stores Need:
- [ ] App icon (1024x1024 PNG, no transparency for iOS)
- [ ] App screenshots (various sizes)
- [ ] App description
- [ ] Privacy policy URL
- [ ] Support URL/email

### iOS Specific:
- [ ] Keywords (100 characters max)
- [ ] Promotional text
- [ ] App Review contact info

### Android Specific:
- [ ] Feature graphic (1024x500)
- [ ] Short description (80 chars)
- [ ] Full description (4000 chars)
- [ ] Content rating questionnaire

---

## 🔐 Keystore Commands (Android)

### Generate New Keystore
```bash
keytool -genkey -v -keystore android/app/slapp-release.keystore \
  -alias slapp \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD
```

### View Keystore Info
```bash
keytool -list -v -keystore android/app/slapp-release.keystore
```

---

## 🔧 Build Commands

### Android APK (Debug)
```bash
flutter build apk --debug
```

### Android APK (Release)
```bash
flutter build apk --release
```

### Android App Bundle (For Play Store)
```bash
flutter build appbundle --release
```

### iOS (Requires Mac or Codemagic)
```bash
flutter build ipa --release
```

---

## 📝 Version Management

Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # format: major.minor.patch+buildNumber
```

- **Build name** (1.0.0): Shown to users
- **Build number** (+1): Must increment for each store upload

---

## 🔗 Useful Links

- [Codemagic Flutter Docs](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/)
- [Flutter Deployment](https://docs.flutter.dev/deployment)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Google Play Console](https://play.google.com/console)
