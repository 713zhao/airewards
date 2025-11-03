import 'package:flutter/foundation.dart';

/// AdMob manager for handling ad configuration and lifecycle
class AdManager {
  static AdManager? _instance;
  static AdManager get instance => _instance ??= AdManager._();
  
  AdManager._();

  bool _isInitialized = false;
  bool _isTestMode = kDebugMode;
  
  // Ad Unit IDs
  late String _bannerAdUnitId;
  late String _interstitialAdUnitId;
  late String _rewardedAdUnitId;

  /// Initialize AdMob with app ID
  Future<void> initialize({
    required String appId,
    required String bannerAdUnitId,
    required String interstitialAdUnitId,
    required String rewardedAdUnitId,
    bool testMode = false,
  }) async {
    if (_isInitialized) return;

    try {
      _isTestMode = testMode || kDebugMode;
      
      // Set ad unit IDs based on test mode
      _bannerAdUnitId = _isTestMode ? _getTestBannerAdUnitId() : bannerAdUnitId;
      _interstitialAdUnitId = _isTestMode ? _getTestInterstitialAdUnitId() : interstitialAdUnitId;
      _rewardedAdUnitId = _isTestMode ? _getTestRewardedAdUnitId() : rewardedAdUnitId;

      // Initialize AdMob SDK (simulated)
      await Future.delayed(const Duration(milliseconds: 500));
      
      _isInitialized = true;
      debugPrint('AdMob initialized successfully (Test Mode: $_isTestMode)');
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
      rethrow;
    }
  }

  /// Get banner ad unit ID
  String get bannerAdUnitId {
    _ensureInitialized();
    return _bannerAdUnitId;
  }

  /// Get interstitial ad unit ID
  String get interstitialAdUnitId {
    _ensureInitialized();
    return _interstitialAdUnitId;
  }

  /// Get rewarded ad unit ID
  String get rewardedAdUnitId {
    _ensureInitialized();
    return _rewardedAdUnitId;
  }

  /// Check if AdMob is initialized
  bool get isInitialized => _isInitialized;

  /// Check if running in test mode
  bool get isTestMode => _isTestMode;

  /// Set consent for personalized ads
  Future<void> setPersonalizedAds(bool enabled) async {
    _ensureInitialized();
    
    // Set consent (simulated)
    debugPrint('Personalized ads ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Request consent information update
  Future<ConsentStatus> requestConsentInfoUpdate() async {
    _ensureInitialized();
    
    // Simulate consent check
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Return consent status (simulated)
    return ConsentStatus.obtained;
  }

  /// Load and show consent form if required
  Future<bool> showConsentFormIfRequired() async {
    final consentStatus = await requestConsentInfoUpdate();
    
    if (consentStatus == ConsentStatus.required) {
      // Show consent form (simulated)
      await Future.delayed(const Duration(seconds: 1));
      return true; // User provided consent
    }
    
    return false; // No consent form shown
  }

  /// Preload interstitial ad
  Future<InterstitialAdWrapper?> loadInterstitialAd() async {
    _ensureInitialized();
    
    try {
      // Simulate ad loading
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Simulate loading success/failure
      final success = DateTime.now().millisecondsSinceEpoch % 4 != 0;
      
      if (success) {
        return InterstitialAdWrapper(_interstitialAdUnitId);
      } else {
        throw AdLoadException('Failed to load interstitial ad');
      }
    } catch (e) {
      debugPrint('Interstitial ad loading failed: $e');
      return null;
    }
  }

  /// Preload rewarded ad
  Future<RewardedAdWrapper?> loadRewardedAd() async {
    _ensureInitialized();
    
    try {
      // Simulate ad loading
      await Future.delayed(const Duration(milliseconds: 1200));
      
      // Simulate loading success/failure
      final success = DateTime.now().millisecondsSinceEpoch % 4 != 0;
      
      if (success) {
        return RewardedAdWrapper(_rewardedAdUnitId);
      } else {
        throw AdLoadException('Failed to load rewarded ad');
      }
    } catch (e) {
      debugPrint('Rewarded ad loading failed: $e');
      return null;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('AdManager not initialized. Call initialize() first.');
    }
  }

  // Test ad unit IDs (AdMob test IDs)
  String _getTestBannerAdUnitId() {
    return 'ca-app-pub-3940256099942544/6300978111'; // Test banner
  }

  String _getTestInterstitialAdUnitId() {
    return 'ca-app-pub-3940256099942544/1033173712'; // Test interstitial
  }

  String _getTestRewardedAdUnitId() {
    return 'ca-app-pub-3940256099942544/5224354917'; // Test rewarded
  }
}

/// Ad loading exception
class AdLoadException implements Exception {
  final String message;
  const AdLoadException(this.message);
  
  @override
  String toString() => 'AdLoadException: $message';
}

/// Consent status enumeration
enum ConsentStatus {
  unknown,
  required,
  notRequired,
  obtained,
}

/// Wrapper for interstitial ads
class InterstitialAdWrapper {
  final String adUnitId;
  bool _isLoaded = true;

  InterstitialAdWrapper(this.adUnitId);

  /// Show the interstitial ad
  Future<bool> show() async {
    if (!_isLoaded) {
      throw StateError('Ad not loaded');
    }

    try {
      // Simulate ad showing
      await Future.delayed(const Duration(milliseconds: 500));
      _isLoaded = false;
      
      debugPrint('Interstitial ad shown: $adUnitId');
      return true;
    } catch (e) {
      debugPrint('Failed to show interstitial ad: $e');
      return false;
    }
  }

  /// Dispose the ad
  void dispose() {
    _isLoaded = false;
    debugPrint('Interstitial ad disposed: $adUnitId');
  }

  bool get isLoaded => _isLoaded;
}

/// Wrapper for rewarded ads
class RewardedAdWrapper {
  final String adUnitId;
  bool _isLoaded = true;

  RewardedAdWrapper(this.adUnitId);

  /// Show the rewarded ad
  Future<AdReward?> show() async {
    if (!_isLoaded) {
      throw StateError('Ad not loaded');
    }

    try {
      // Simulate ad showing
      await Future.delayed(const Duration(seconds: 2));
      _isLoaded = false;
      
      // Simulate user watching the full ad
      final watched = DateTime.now().millisecondsSinceEpoch % 3 != 0;
      
      if (watched) {
        debugPrint('Rewarded ad completed: $adUnitId');
        return const AdReward(type: 'coins', amount: 50);
      } else {
        debugPrint('Rewarded ad dismissed: $adUnitId');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to show rewarded ad: $e');
      return null;
    }
  }

  /// Dispose the ad
  void dispose() {
    _isLoaded = false;
    debugPrint('Rewarded ad disposed: $adUnitId');
  }

  bool get isLoaded => _isLoaded;
}

/// Ad reward information
class AdReward {
  final String type;
  final int amount;

  const AdReward({
    required this.type,
    required this.amount,
  });

  @override
  String toString() => 'AdReward(type: $type, amount: $amount)';
}