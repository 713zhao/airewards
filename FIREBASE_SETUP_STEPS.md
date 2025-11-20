# Google Services Setup Guide for AI Rewards

## Your Debug Certificate Information

**SHA-1 Fingerprint:**
```
3F:5F:44:C3:C9:7B:2C:13:83:49:05:55:80:9A:F5:65:A3:2F:E5:65
```

**SHA-256 Fingerprint:**
```
EF:5D:84:32:A3:1B:4E:8A:54:94:83:CE:B7:D7:61:50:1C:8C:5A:63:5A:A3:4C:75:B2:1C:B5:EC:67:8F:33:5B
```

## Step-by-Step Firebase Setup

### Step 1: Go to Firebase Console

1. Open: https://console.firebase.google.com/
2. Click **"Add project"** or select existing project if you have one
3. Project name: `AI Rewards` (or any name you prefer)
4. Continue through the setup

### Step 2: Add Android App

1. In Firebase Console, click the **Android icon** (or "Add app")
2. Fill in the form:
   - **Android package name:** `com.airewards` (MUST match your app)
   - **App nickname:** `AI Rewards` (optional)
   - **Debug signing certificate SHA-1:** Paste this:
     ```
     3F:5F:44:C3:C9:7B:2C:13:83:49:05:55:80:9A:F5:65:A3:2F:E5:65
     ```
3. Click **"Register app"**

### Step 3: Download google-services.json

1. Firebase will show a download button for **google-services.json**
2. Click **"Download google-services.json"**
3. Save it to your Downloads folder

### Step 4: Place File in Your Project

**Critical:** The file MUST go in the correct location:

```
C:\ZJB\AIRewards\android\app\google-services.json
```

To copy it:
1. Open File Explorer
2. Go to your Downloads folder
3. Find `google-services.json`
4. Copy it
5. Navigate to: `C:\ZJB\AIRewards\android\app\`
6. Paste the file there

**Verify the location:**
```powershell
Test-Path "C:\ZJB\AIRewards\android\app\google-services.json"
```
This should return `True`

### Step 5: Verify the File Content

Open the file and check it has your package name:

```powershell
Select-String -Path "android\app\google-services.json" -Pattern "com.airewards"
```

Should show: `"package_name": "com.airewards"`

### Step 6: Enable Google Services in Firebase

In Firebase Console:
1. Go to **Build** → **Authentication** (in left sidebar)
2. Click **"Get Started"**
3. This ensures the services are activated

### Step 7: Rebuild Your App

```powershell
# Clean everything
flutter clean

# Get dependencies
flutter pub get

# Rebuild and install fresh
flutter run --uninstall-first
```

## Troubleshooting

### "File not found" during build
- Check file is exactly at: `android/app/google-services.json`
- Not in `android/` (wrong)
- Not in `android/app/src/` (wrong)

### "Package name mismatch"
- Open `google-services.json`
- Find `"package_name"` field
- MUST be: `"com.airewards"`
- If not, re-download from Firebase with correct package name

### Still getting SecurityException
1. Verify SHA-1 is registered in Firebase
2. Wait 5-10 minutes after adding SHA-1 (Firebase needs to propagate)
3. Uninstall app completely and reinstall
4. Restart your Android device

## What This Fixes

✅ SecurityException: Unknown calling package name
✅ Google Play Services authentication
✅ AdMob ad loading
✅ Firebase services integration

## After Setup

Your logs should show:
```
✅ AdMob initialized successfully
✅ Banner ad loaded
```

Instead of:
```
❌ SecurityException: Unknown calling package name
```

## Alternative: Skip Firebase for Now

If you just want to test that ads work, you can temporarily use test ad units that don't require authentication.

Let me know if you want that instead!

---

## Quick Copy Commands

```powershell
# After downloading google-services.json to Downloads:
Copy-Item "$env:USERPROFILE\Downloads\google-services.json" -Destination "C:\ZJB\AIRewards\android\app\google-services.json"

# Verify it's there:
Test-Path "C:\ZJB\AIRewards\android\app\google-services.json"

# Check content:
Get-Content "C:\ZJB\AIRewards\android\app\google-services.json" | Select-String "com.airewards"
```
