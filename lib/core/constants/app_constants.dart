/// Core application constants
class AppConstants {
  
  // App Information
  static const String appName = 'AI Rewards System';
  static const String appVersion = '1.0.0';
  
  // Environment Keys
  static const String environmentKey = 'ENVIRONMENT';
  static const String firebaseProjectIdKey = 'FIREBASE_PROJECT_ID';
  
  // Default Values
  static const String defaultEnvironment = 'development';
  
  // Cache Keys
  static const String userCacheKey = 'user_data';
  static const String settingsCacheKey = 'app_settings';
  static const String rewardsCacheKey = 'rewards_data';
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  static const Duration minimumSplashDuration = Duration(seconds: 2);
  
  // API Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double defaultRadius = 12.0;
  static const double smallRadius = 6.0;
  static const double largeRadius = 20.0;
}