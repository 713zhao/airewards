# Fix Google Play Services SecurityException

## Issue
`SecurityException: Unknown calling package name 'com.google.android.gms'`

This occurs because:
1. Your app's signing certificate isn't registered with Google
2. Missing google-services.json configuration
3. Package visibility issues in Android 11+

## Quick Fixes Applied

✅ Added package query for Google Play Services
✅ Added tools namespace for permission handling
✅ Removed AD_ID permission (not needed for basic ads)

## Required Steps

### Step 1: Get Your SHA-1 Certificate Fingerprint

Run this command in your project root:

```powershell
# For debug certificate (testing)
cd android
./gradlew signingReport
```

Look for the **SHA-1** under `Variant: debug` section. Copy it.

Example output:
```
Variant: debug
Config: debug
Store: C:\Users\YourName\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX...
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:11:22:33:44
SHA-256: ...
```

### Step 2: Register SHA-1 with Firebase/AdMob

1. Go to **Firebase Console**: https://console.firebase.google.com/
2. Select your project (or create one)
3. Go to **Project Settings** (gear icon)
4. Scroll to **Your apps** → Select Android app (or add Android app)
5. Add your SHA-1 certificate fingerprint
6. Click **Save**

### Step 3: Download google-services.json

1. In Firebase Console, after adding SHA-1
2. Click **Download google-services.json**
3. Place it here: `android/app/google-services.json`

### Step 4: Alternative - Use Test Ads Without google-services.json

If you don't want to set up Firebase, temporarily use **test ad units**:

Edit `lib/core/services/ad_service.dart`:
```dart
// Use Google's test ad unit (no authentication needed)
static const String _productionBannerId = 'ca-app-pub-3940256099942544/6300978111';
```

This will bypass the authentication issue and show test ads immediately.

## Verify Fixes

After applying changes:

```powershell
# Clean and rebuild
flutter clean
cd android
./gradlew clean
cd ..

# Rebuild and run
flutter run --uninstall-first
```

## Check Logs

You should NO LONGER see:
```
E/GoogleApiManager: SecurityException: Unknown calling package name
```

You SHOULD see:
```
✅ AdMob initialized successfully
✅ Banner ad loaded
```

## If Still Not Working

### Option A: Complete Firebase Setup
1. Add `google-services.json` to `android/app/`
2. Register both debug and release SHA-1 certificates
3. Enable Google Sign-In in Firebase (if using auth)

### Option B: Simplify Testing
Use test ad units until you're ready for production:
```dart
// Test banner (works without authentication)
'ca-app-pub-3940256099942544/6300978111'
```

### Option C: Update Google Play Services
On your test device:
1. Open Google Play Store
2. Search "Google Play Services"
3. Update to latest version
4. Restart device
5. Try again

## Production Checklist

Before releasing with real ads:
- [ ] `google-services.json` added and configured
- [ ] Production SHA-1 registered in Firebase
- [ ] Release SHA-1 registered (from release keystore)
- [ ] Switch back to production ad unit IDs
- [ ] Test on multiple devices
- [ ] Verify no SecurityException in logs

## Quick Commands

```powershell
# Get debug SHA-1
cd android; ./gradlew signingReport; cd ..

# Clean build
flutter clean; flutter pub get

# Fresh install
flutter run --uninstall-first -v

# Check for errors
flutter run -v 2>&1 | Select-String -Pattern "SecurityException|AdMob|Banner"
```

## Summary

The SecurityException happens because Google Play Services can't verify your app's identity. You have 3 options:

1. **Full Setup** (recommended for production): Add google-services.json + register SHA-1
2. **Quick Test** (for development): Use test ad unit IDs
3. **Minimal Fix** (temporary): Manifest changes already applied + update Play Services on device

Choose option 2 (test ads) if you want to see ads working immediately while you set up Firebase properly.
