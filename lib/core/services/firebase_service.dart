import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../config/firebase_config.dart' as config;
import '../../firebase_options.dart';

/// Firebase service initialization and configuration
@lazySingleton
class FirebaseService {
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseAnalytics? _analytics;
  static FirebaseMessaging? _messaging;
  static FirebasePerformance? _performance;
  static FirebaseCrashlytics? _crashlytics;

  /// Initialize Firebase services
  static Future<void> initialize(config.Environment environment) async {
    try {
      // Initialize Firebase Core with platform-specific options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize individual services
      await _initializeAuth();
      await _initializeFirestore();
      await _initializeAnalytics();
      await _initializeMessaging();
      await _initializePerformance();
      await _initializeCrashlytics();

      debugPrint('✅ Firebase services initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing Firebase: $e');
      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      }
      rethrow;
    }
  }

  /// Initialize Firebase Authentication
  static Future<void> _initializeAuth() async {
    _auth = FirebaseAuth.instance;
    
    // Configure Auth settings
    await _auth!.setSettings(
      appVerificationDisabledForTesting: kDebugMode,
      forceRecaptchaFlow: !kDebugMode,
    );

    debugPrint('✅ Firebase Auth initialized');
  }

  /// Initialize Cloud Firestore
  static Future<void> _initializeFirestore() async {
    _firestore = FirebaseFirestore.instance;
    
    // Configure Firestore settings
    _firestore!.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Enable offline persistence
    await _firestore!.enableNetwork();

    debugPrint('✅ Cloud Firestore initialized');
  }

  /// Initialize Firebase Analytics
  static Future<void> _initializeAnalytics() async {
    _analytics = FirebaseAnalytics.instance;
    
    // Set analytics collection enabled
    await _analytics!.setAnalyticsCollectionEnabled(!kDebugMode);

    debugPrint('✅ Firebase Analytics initialized');
  }

  /// Initialize Firebase Cloud Messaging
  static Future<void> _initializeMessaging() async {
    _messaging = FirebaseMessaging.instance;

    // Request permission for notifications
    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('✅ Firebase Messaging initialized: ${settings.authorizationStatus}');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Initialize Firebase Performance
  static Future<void> _initializePerformance() async {
    _performance = FirebasePerformance.instance;
    
    // Set performance collection enabled
    await _performance!.setPerformanceCollectionEnabled(!kDebugMode);

    debugPrint('✅ Firebase Performance initialized');
  }

  /// Initialize Firebase Crashlytics
  static Future<void> _initializeCrashlytics() async {
    // Firebase Crashlytics has limited support on web platform
    // Only initialize for mobile platforms
    if (kIsWeb) {
      debugPrint('⚠️  Firebase Crashlytics skipped (Web platform)');
      return;
    }

    try {
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Set crashlytics collection enabled
      await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      if (!kDebugMode) {
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
        
        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      debugPrint('✅ Firebase Crashlytics initialized');
    } catch (e) {
      debugPrint('⚠️  Firebase Crashlytics initialization failed: $e');
      // Don't rethrow as Crashlytics is not critical for app functionality
    }
  }

  /// Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    debugPrint('📱 Handling background message: ${message.messageId}');
  }

  /// Getters for Firebase services
  static FirebaseAuth get auth => _auth!;
  static FirebaseFirestore get firestore => _firestore!;
  static FirebaseAnalytics get analytics => _analytics!;
  static FirebaseMessaging get messaging => _messaging!;
  static FirebasePerformance get performance => _performance!;
  static FirebaseCrashlytics? get crashlytics => _crashlytics;

  /// Check if all services are initialized
  static bool get isInitialized {
    return _auth != null &&
           _firestore != null &&
           _analytics != null &&
           _messaging != null &&
           _performance != null &&
           (kIsWeb || _crashlytics != null); // Crashlytics is optional on web
  }
}