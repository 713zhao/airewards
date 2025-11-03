# Firebase Configuration Guide

## Overview
This document provides instructions for configuring Firebase services for the AI Rewards System across different environments (development, staging, production).

## Prerequisites
1. Firebase project created in Firebase Console
2. Authentication providers enabled:
   - ✅ Email/Password
   - ✅ Phone
   - ✅ Google Sign-In

## Configuration Steps

### 1. Firebase Project Setup

#### Development Environment
- Project ID: `ai-rewards-system-dev`
- Web App Name: `AI Rewards System (Dev)`

#### Staging Environment  
- Project ID: `ai-rewards-system-staging`
- Web App Name: `AI Rewards System (Staging)`

#### Production Environment
- Project ID: `ai-rewards-system`
- Web App Name: `AI Rewards System`

### 2. Android Configuration

1. Download `google-services.json` for each environment
2. Place files in:
   - Development: `android/app/src/debug/google-services.json`
   - Staging: `android/app/src/staging/google-services.json`
   - Production: `android/app/src/release/google-services.json`

### 3. iOS Configuration

1. Download `GoogleService-Info.plist` for each environment
2. Place files in:
   - Development: `ios/Runner/Firebase/Debug/GoogleService-Info.plist`
   - Staging: `ios/Runner/Firebase/Staging/GoogleService-Info.plist`
   - Production: `ios/Runner/Firebase/Release/GoogleService-Info.plist`

### 4. Web Configuration

Update `lib/core/config/firebase_config.dart` with actual values from Firebase Console:

1. Go to Firebase Console → Project Settings → General → Your Apps
2. Select Web App for each environment
3. Copy configuration values to respective environments in `firebase_config.dart`

### 5. Authentication Setup

#### Email/Password Authentication
- ✅ Enabled in Firebase Console
- Email verification enabled
- Password reset functionality configured

#### Phone Authentication  
- ✅ Enabled in Firebase Console
- SMS quota: Check limits in Firebase Console
- Test phone numbers can be configured for development

#### Google Sign-In
- ✅ Enabled in Firebase Console
- Web client ID configured
- Android/iOS client IDs will be automatically configured with google-services files

### 6. Firestore Database

1. Create Firestore database in each Firebase project
2. Start in **test mode** for development
3. Configure security rules for production:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Rewards are readable by authenticated users
    match /rewards/{rewardId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Categories are readable by all authenticated users
    match /categories/{categoryId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Admin only in production
    }
  }
}
```

### 7. Cloud Functions (Optional)

Configure Cloud Functions for:
- User profile initialization
- Reward point calculations  
- Push notification triggers
- Analytics event processing

### 8. Environment Variables

Create `.env` files for each environment:

#### `.env.development`
```env
ENVIRONMENT=development
FIREBASE_PROJECT_ID=ai-rewards-system-dev
ENABLE_CRASHLYTICS=false
ENABLE_ANALYTICS=false
```

#### `.env.staging`
```env
ENVIRONMENT=staging
FIREBASE_PROJECT_ID=ai-rewards-system-staging
ENABLE_CRASHLYTICS=true
ENABLE_ANALYTICS=true
```

#### `.env.production`
```env
ENVIRONMENT=production
FIREBASE_PROJECT_ID=ai-rewards-system
ENABLE_CRASHLYTICS=true
ENABLE_ANALYTICS=true
```

## Testing Configuration

### Development Testing
```bash
# Run with development configuration
flutter run --flavor development --dart-define=ENVIRONMENT=development
```

### Staging Testing  
```bash
# Run with staging configuration
flutter run --flavor staging --dart-define=ENVIRONMENT=staging
```

### Authentication Testing

Test all three authentication methods:
1. **Email/Password**: Create test accounts
2. **Phone**: Use Firebase test phone numbers
3. **Google**: Use test Google accounts

## Security Considerations

1. **API Keys**: Store production keys securely
2. **Test Data**: Use separate databases for each environment
3. **Access Rules**: Implement proper Firestore security rules
4. **App Check**: Enable for production to prevent abuse

## Next Steps

After completing Firebase configuration:
1. Update `firebase_config.dart` with actual project values
2. Add platform-specific configuration files
3. Test authentication flows
4. Configure Firestore collections and security rules
5. Set up Cloud Functions if needed

## Troubleshooting

Common issues:
- **Build errors**: Check google-services files are in correct locations
- **Auth failures**: Verify SHA-1 fingerprints for Android
- **Firestore access**: Check security rules and authentication
- **iOS issues**: Ensure GoogleService-Info.plist is added to Xcode project