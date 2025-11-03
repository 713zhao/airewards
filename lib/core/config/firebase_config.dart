import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for different environments
class FirebaseConfig {
  static const String _projectId = 'airewards-3bed2';
  
  /// Development environment configuration
  static const FirebaseOptions development = FirebaseOptions(
    apiKey: kIsWeb ? 'AIzaSyC94wEqJRkmj-Q9O6XfARHc4Qe18Ks9r08' : 'AIzaSyC94wEqJRkmj-Q9O6XfARHc4Qe18Ks9r08',
    appId: kIsWeb ? '1:439400799171:web:af080c5be7e7c29ab27b76' : '1:439400799171:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '439400799171',
    projectId: _projectId,
    authDomain: 'airewards-3bed2.firebaseapp.com',
    storageBucket: 'airewards-3bed2.firebasestorage.app',
    measurementId: 'G-JDP6FPEB9L',
  );

  /// Staging environment configuration (same as dev for now)
  static const FirebaseOptions staging = FirebaseOptions(
    apiKey: kIsWeb ? 'AIzaSyC94wEqJRkmj-Q9O6XfARHc4Qe18Ks9r08' : 'AIzaSyC94wEqJRkmj-Q9O6XfARHc4Qe18Ks9r08',
    appId: kIsWeb ? '1:439400799171:web:af080c5be7e7c29ab27b76' : '1:439400799171:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '439400799171',
    projectId: _projectId,
    authDomain: 'airewards-3bed2.firebaseapp.com',
    storageBucket: 'airewards-3bed2.firebasestorage.app',
    measurementId: 'G-JDP6FPEB9L',
  );

  /// Production environment configuration
  static const FirebaseOptions production = FirebaseOptions(
    apiKey: kIsWeb ? 'AIzaSyC94wEqJRkmj-Q9O6XfARHc4Qe18Ks9r08' : 'AIzaSyC94wEqJRkmj-Q9O6XfARHc4Qe18Ks9r08',
    appId: kIsWeb ? '1:439400799171:web:af080c5be7e7c29ab27b76' : '1:439400799171:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '439400799171',
    projectId: _projectId,
    authDomain: 'airewards-3bed2.firebaseapp.com',
    storageBucket: 'airewards-3bed2.firebasestorage.app',
    measurementId: 'G-JDP6FPEB9L',
  );

  /// Get Firebase options based on environment
  static FirebaseOptions getFirebaseOptions(Environment environment) {
    switch (environment) {
      case Environment.development:
        return development;
      case Environment.staging:
        return staging;
      case Environment.production:
        return production;
    }
  }
}

/// Application environments
enum Environment {
  development,
  staging,
  production,
}

/// Environment configuration
class EnvironmentConfig {
  static Environment _environment = Environment.development;
  
  static Environment get environment => _environment;
  
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  /// Get environment from string (useful for build configurations)
  static Environment fromString(String env) {
    switch (env.toLowerCase()) {
      case 'development':
      case 'dev':
        return Environment.development;
      case 'staging':
      case 'stage':
        return Environment.staging;
      case 'production':
      case 'prod':
        return Environment.production;
      default:
        return Environment.development;
    }
  }
}