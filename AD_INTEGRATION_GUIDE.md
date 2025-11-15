# Ad Integration Setup Guide

This guide explains how to set up Google AdSense (for web) and Google AdMob (for Android/iOS) in your AI Rewards System app.

## 📱 What's Implemented

The app now includes:
- **AdMob** integration for Android and iOS (mobile banner ads)
- **AdSense** integration for web (web banner ads)
- Unified `AdService` that automatically detects platform
- `BannerAdWidget` that displays ads at the top of the main screen
- Test ad units pre-configured for development

## 🎯 Current Setup (Test Mode)

### Test Ad Unit IDs Currently Used:
- **Android Banner**: `ca-app-pub-3940256099942544/6300978111`
- **iOS Banner**: `ca-app-pub-3940256099942544/2934735716`
- **Android App ID**: `ca-app-pub-3940256099942544~3347511713`
- **iOS App ID**: `ca-app-pub-3940256099942544~1458002511`

These are Google's official test IDs and will show test ads only.

## 🚀 Production Setup Instructions

### Step 1: Create AdMob Account (for Mobile)

1. Go to [AdMob](https://admob.google.com/)
2. Sign in with your Google account
3. Click "Apps" → "Add App"
4. Select your platform (Android/iOS)
5. Enter app details
6. Get your **App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`)

### Step 2: Create Ad Units in AdMob

1. In AdMob, go to "Apps" → Select your app
2. Click "Ad units" → "Add ad unit"
3. Select "Banner" ad format
4. Configure ad unit settings
5. Get your **Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`)
6. Repeat for both Android and iOS apps

### Step 3: Create AdSense Account (for Web)

1. Go to [AdSense](https://adsense.google.com/)
2. Sign in with your Google account
3. Complete account setup and verification
4. Get your **Publisher ID** (format: `ca-pub-XXXXXXXXXXXXXXXX`)

### Step 4: Update Configuration Files

#### For Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<!-- Replace the test App ID with your production App ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

#### For iOS (`ios/Runner/Info.plist`):
```xml
<!-- Replace the test App ID with your production App ID -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

#### For Flutter Code (`lib/core/services/ad_service.dart`):
```dart
// Replace test ad unit IDs around line 18-22:
static const String _testAndroidBannerId = 'YOUR_ANDROID_BANNER_ID';
static const String _testIOSBannerId = 'YOUR_IOS_BANNER_ID';

// Or better, rename variables and update the getter:
String get _bannerAdUnitId {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Your Android banner ID
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Your iOS banner ID
  }
  return '';
}
```

#### For Web (`web/index.html`):
```html
<!-- Uncomment and update with your AdSense Publisher ID (around line 34): -->
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-XXXXXXXXXXXXXXXX"
     crossorigin="anonymous"></script>
```

## 📍 Ad Placement

Banner ads are currently displayed:
- **Location**: Top of the main app screen (below app bar)
- **Size**: Standard banner (320x50 for mobile, responsive for web)
- **Behavior**: Loads automatically when app starts

### To Add More Ad Placements:

Import the widget:
```dart
import '../../shared/widgets/banner_ad_widget.dart';
```

Add to any screen:
```dart
Column(
  children: [
    const BannerAdWidget(),
    // Your other widgets
  ],
)
```

## 🧪 Testing

### Test Ads (Current Setup):
- Test ads will show with "Test Ad" label
- Safe to click without policy violations
- No revenue generated from test ads

### Real Ads (After Production Setup):
- Real ads appear after updating to production IDs
- **IMPORTANT**: Never click your own ads (policy violation)
- Use test devices for development

### Enable Test Device:

In `lib/core/services/ad_service.dart`, modify the `AdRequest`:
```dart
request: AdRequest(
  testDevices: ['YOUR_TEST_DEVICE_ID'], // Get this from logcat/console
),
```

## 💰 Revenue Tracking

### AdMob (Mobile):
- View earnings at [AdMob Dashboard](https://admob.google.com/)
- Reports available for impressions, clicks, eCPM, revenue
- Payment setup in AdMob settings

### AdSense (Web):
- View earnings at [AdSense Dashboard](https://adsense.google.com/)
- Reports available for impressions, clicks, CTR, revenue
- Payment setup in AdSense settings

## 🔧 Troubleshooting

### Mobile: Ads Not Showing

1. **Check AdMob initialization logs**:
   - Look for "✅ AdMob initialized successfully" in console
   - Look for "✅ Banner ad loaded" when ads load

2. **Verify App IDs are correct**:
   - Android: Check `AndroidManifest.xml`
   - iOS: Check `Info.plist`

3. **Check internet connectivity**:
   - Ads require active internet connection

4. **Wait for ad inventory**:
   - New ad units may take hours to serve ads
   - Test IDs work immediately

### Web: Ads Not Showing

1. **Verify AdSense approval**:
   - Account must be approved by Google
   - Can take days to weeks

2. **Check script tag**:
   - Ensure AdSense script is in `web/index.html`
   - Verify Publisher ID is correct

3. **Domain verification**:
   - Add your domain in AdSense settings
   - May need to verify ownership

### Common Issues

**"Ad failed to load" errors**:
- Normal during development
- May indicate no ad inventory available
- Test IDs should always work

**Policy violations**:
- Never click your own ads
- Don't encourage clicks
- Follow [AdMob policies](https://support.google.com/admob/answer/6128543)

## 📝 Best Practices

1. **Start with Test IDs**: Always test with test IDs first
2. **Gradual Rollout**: Test thoroughly before publishing
3. **Monitor Performance**: Check ad performance regularly
4. **User Experience**: Don't overload with ads
5. **Compliance**: Follow all Google policies
6. **Privacy**: Update privacy policy to mention ads

## 🔐 Privacy Requirements

Update your privacy policy to include:
- Use of Google AdMob/AdSense
- Collection of advertising IDs
- Third-party ad vendors
- User consent (GDPR/CCPA if applicable)

## 📚 Resources

- [AdMob Documentation](https://developers.google.com/admob)
- [AdSense Documentation](https://support.google.com/adsense)
- [Flutter google_mobile_ads Plugin](https://pub.dev/packages/google_mobile_ads)
- [AdMob Policy Center](https://support.google.com/admob/answer/6128543)

## ⚡ Quick Start Checklist

- [x] AdMob/AdSense integration code added
- [x] Test ad units configured
- [x] Banner ad widget created
- [x] Ad service initialized in main.dart
- [x] Banner ad added to main screen
- [ ] Create AdMob account
- [ ] Create ad units
- [ ] Update production ad unit IDs
- [ ] Create AdSense account (for web)
- [ ] Add AdSense script to web/index.html
- [ ] Test on real devices
- [ ] Update privacy policy
- [ ] Submit for review (if required by platform)

---

**Current Status**: ✅ Development setup complete with test ads
**Next Step**: Create production AdMob/AdSense accounts and update IDs
