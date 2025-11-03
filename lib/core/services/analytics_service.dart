import 'package:injectable/injectable.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Service for handling analytics events and user properties
@singleton
class AnalyticsService {
  FirebaseAnalytics? _analytics;
  
  /// Initialize the analytics service
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics?.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      // Handle analytics initialization failure gracefully
      print('Analytics initialization failed: $e');
    }
  }
  
  /// Log custom event
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      print('Failed to log event: $name, error: $e');
    }
  }
  
  /// Log screen view
  Future<void> logScreenView(String screenName, String screenClass) async {
    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      print('Failed to log screen view: $screenName, error: $e');
    }
  }
  
  /// Set user property
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      print('Failed to set user property: $name, error: $e');
    }
  }
  
  /// Set user ID
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
    } catch (e) {
      print('Failed to set user ID: $userId, error: $e');
    }
  }
}