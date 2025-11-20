# Android AdMob Testing Guide

## Current Configuration
- **App ID**: `ca-app-pub-3737089294643612~2806673492`
- **Banner Unit ID**: `ca-app-pub-3737089294643612/1858330009`
- **Ad Placement**: Bottom of screen, above navigation bar

## Pre-Flight Checklist

### 1. Verify AndroidManifest.xml
```bash
# Check if App ID is present
Select-String -Path "android\app\src\main\AndroidManifest.xml" -Pattern "APPLICATION_ID"
```
Should show: `ca-app-pub-3737089294643612~2806673492`

### 2. Check Internet Permission
```bash
Select-String -Path "android\app\src\main\AndroidManifest.xml" -Pattern "INTERNET"
```
Should show: `<uses-permission android:name="android.permission.INTERNET" />`

### 3. Verify Package Installation
```bash
flutter pub get
```

## Testing Steps

### Step 1: Clean Build
```powershell
flutter clean
flutter pub get
```

### Step 2: Run with Logs
```powershell
# Run on connected Android device (NOT emulator for first test)
flutter run -v

# Or with specific device
flutter devices
flutter run -d <device-id> -v
```

### Step 3: Watch for Debug Logs

Look for these messages in console:

#### ✅ Success Indicators:
```
✅ AdMob initialized successfully
📱 BannerAdWidget initState - platform: Mobile
📱 Starting AdMob banner ad load...
✅ Banner ad loaded
✅ Banner ad successfully loaded and ready to display
📱 Rendering AdWidget with banner ad
```

#### ❌ Error Indicators:
```
❌ Error initializing ads: [error details]
❌ Banner ad failed to load: [error code]
❌ Error loading banner ad: [exception]
```

## Common Issues & Solutions

### Issue 1: "Ad failed to load: Error code 3 (No fill)"
**Cause**: New ad units may have no inventory yet
**Solution**: 
- Wait 24-48 hours after creating the ad unit
- Temporarily use test ad unit to verify integration works

**Test with Google test ad**:
Edit `lib/core/services/ad_service.dart`:
```dart
// Temporary - use test ID
static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';

String get _bannerAdUnitId {
  // Use test ID temporarily
  return _testBannerId;
}
```

### Issue 2: No Logs Appearing
**Cause**: AdService not initialized
**Check**: `lib/main.dart` should have:
```dart
await AdService().initialize();
```

### Issue 3: Ad Widget Not Visible
**Causes**:
- Container height too small
- Ad behind other widgets
- Loading state stuck

**Debug**:
```dart
// Add to banner_ad_widget.dart temporarily
debugPrint('📱 _isLoading: $_isLoading');
debugPrint('📱 _isAdLoaded: $_isAdLoaded');
debugPrint('📱 _bannerAd: $_bannerAd');
debugPrint('📱 _errorMessage: $_errorMessage');
```

### Issue 4: Error Code 0 (Internal Error)
**Possible Causes**:
- Invalid App ID format
- Package cache issue
- Google Play Services outdated

**Solutions**:
```powershell
# Clear cache
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get

# Reinstall app completely
flutter run --uninstall-first
```

### Issue 5: Error Code 1 (Invalid Request)
**Cause**: Ad unit ID mismatch or wrong format
**Check**:
- App ID in `AndroidManifest.xml` matches AdMob dashboard
- Banner unit ID in `ad_service.dart` matches AdMob dashboard
- No extra spaces or typos

### Issue 6: Error Code 2 (Network Error)
**Check**:
- Device has active internet connection
- Firewall not blocking Google ad servers
- Not using VPN that blocks ads

## Device Requirements

### ✅ Recommended:
- Physical Android device (phone/tablet)
- Android 5.0 (API 21) or higher
- Google Play Services installed and updated
- Active internet connection (WiFi or mobile data)

### ⚠️ Not Recommended:
- Android emulator (may have Play Services issues)
- Devices without Google Play Services
- Rooted devices (may be flagged)

## Verification Steps

### 1. Visual Check
- [ ] Banner ad container visible at bottom
- [ ] Ad content loads (not just empty space)
- [ ] Ad doesn't overlap navigation bar
- [ ] No layout shift when ad loads

### 2. Functional Check
- [ ] App doesn't crash on ad load
- [ ] Navigation still works with ad present
- [ ] Ad doesn't interfere with scrolling
- [ ] Ad updates on screen rotation (if applicable)

### 3. Log Check
```powershell
# Filter for ad-related logs
flutter run | Select-String -Pattern "Ad|banner|AdMob"
```

## Production Readiness

Before releasing to Play Store:

- [ ] Test ads load successfully on multiple devices
- [ ] Remove any test ad unit IDs
- [ ] Verify production ad unit IDs in code
- [ ] Test for at least 30 minutes to ensure stability
- [ ] Check memory usage doesn't spike
- [ ] Verify app works when ads fail to load
- [ ] Review AdMob policies one more time
- [ ] Set up app signing for release builds

## Quick Debug Commands

```powershell
# Check current ad service configuration
Select-String -Path "lib\core\services\ad_service.dart" -Pattern "ca-app-pub"

# Check manifest configuration  
Select-String -Path "android\app\src\main\AndroidManifest.xml" -Pattern "ca-app-pub"

# Full rebuild
flutter clean; flutter pub get; flutter run

# Check connected devices
flutter devices

# Install and run fresh
flutter run --uninstall-first
```

## Support Resources

- **AdMob Dashboard**: https://apps.admob.com/
- **Ad Unit Status**: Check in AdMob console if unit is active
- **Error Codes**: https://developers.google.com/android/reference/com/google/android/gms/ads/AdRequest#ERROR_CODE_INTERNAL_ERROR
- **Flutter Plugin**: https://pub.dev/packages/google_mobile_ads

## Current Implementation Summary

Your app currently:
- ✅ Initializes AdMob on app start
- ✅ Shows loading indicator while ad loads
- ✅ Displays error messages in debug mode
- ✅ Places ad at bottom above navigation
- ✅ Handles ad load failures gracefully
- ✅ Uses production ad unit IDs

If ads still don't show after 48 hours and all checks pass, temporarily switch to test IDs to verify the integration code is correct.
