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
    // Step 1: Core initialization must succeed
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, _ ) {
      debugPrint('❌ Firebase.initializeApp failed: $e');
      // Core failure is fatal
      rethrow;
    }

    // Step 2: Best-effort initialize each service independently.
    // None of these should crash the whole app on web.
    try {
      await _initializeAuth();
    } catch (e) {
      debugPrint('⚠️  Firebase Auth init failed (continuing): $e');
    }

    try {
      await _initializeFirestore();
    } catch (e) {
      debugPrint('⚠️  Firestore init failed (continuing): $e');
    }

    try {
      await _initializeAnalytics();
    } catch (e) {
      debugPrint('⚠️  Analytics init failed (continuing): $e');
    }

    try {
      await _initializeMessaging();
    } catch (e) {
      debugPrint('⚠️  Messaging init failed (continuing): $e');
    }

    try {
      await _initializePerformance();
    } catch (e) {
      debugPrint('⚠️  Performance init failed (continuing): $e');
    }

    try {
      await _initializeCrashlytics();
    } catch (e) {
      debugPrint('⚠️  Crashlytics init failed (continuing): $e');
    }

    debugPrint('✅ Firebase services initialized (best-effort)');
  }

  /// Initialize Firebase Authentication
  static Future<void> _initializeAuth() async {
    _auth = FirebaseAuth.instance;
    
    // Configure Auth settings (some options may not be supported on Web)
    try {
      await _auth!.setSettings(
        appVerificationDisabledForTesting: kDebugMode,
        forceRecaptchaFlow: !kDebugMode,
      );
    } catch (e) {
      debugPrint('⚠️  Auth.setSettings not fully supported on this platform: $e');
    }

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
    // Messaging has additional constraints on web (service worker, https etc.)
    _messaging = FirebaseMessaging.instance;
    try {
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      debugPrint('✅ Firebase Messaging initialized: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('⚠️  Messaging permission request failed: $e');
    }

    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('⚠️  onBackgroundMessage setup failed: $e');
    }
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