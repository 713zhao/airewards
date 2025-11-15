import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Unified ad service that handles both AdMob (mobile) and AdSense (web)
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  BannerAd? _bannerAd;
  bool _isInitialized = false;
  bool _isBannerAdLoaded = false;

  // Test Ad Unit IDs (replace with your production IDs)
  // Android Test Banner: ca-app-pub-3940256099942544/6300978111
  // iOS Test Banner: ca-app-pub-3940256099942544/2934735716
  static const String _testAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testIOSBannerId =
      'ca-app-pub-3940256099942544/2934735716';

  /// Initialize the Mobile Ads SDK (AdMob for mobile platforms)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        // For web, we'll use AdSense which is handled separately in HTML
        debugPrint('🎯 Running on Web - AdSense should be configured in index.html');
        _isInitialized = true;
        return;
      }

      // Initialize AdMob for mobile platforms
      await MobileAds.instance.initialize();
      debugPrint('✅ AdMob initialized successfully');
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error initializing ads: $e');
    }
  }

  /// Get the appropriate banner ad unit ID based on platform
  String get _bannerAdUnitId {
    if (kIsWeb) {
      // Web doesn't use AdMob unit IDs
      return '';
    }

    // TODO: Replace with your actual production ad unit IDs
    // Get your ad unit IDs from: https://apps.admob.com/
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _testAndroidBannerId; // Replace with your Android banner ID
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _testIOSBannerId; // Replace with your iOS banner ID
    }
    return '';
  }

  /// Create and load a banner ad (AdMob for mobile)
  Future<BannerAd?> createBannerAd() async {
    if (kIsWeb) {
      // Web uses AdSense, not AdMob
      return null;
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      _bannerAd?.dispose();
      _isBannerAdLoaded = false;

      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('✅ Banner ad loaded');
            _isBannerAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ Banner ad failed to load: $error');
            ad.dispose();
            _isBannerAdLoaded = false;
          },
          onAdOpened: (ad) {
            debugPrint('📱 Banner ad opened');
          },
          onAdClosed: (ad) {
            debugPrint('🔙 Banner ad closed');
          },
        ),
      );

      await _bannerAd!.load();
      return _bannerAd;
    } catch (e) {
      debugPrint('❌ Error creating banner ad: $e');
      return null;
    }
  }

  /// Check if banner ad is loaded and ready
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  /// Get the current banner ad
  BannerAd? get bannerAd => _bannerAd;

  /// Dispose of the banner ad
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  /// Dispose of all ads
  void dispose() {
    disposeBannerAd();
  }
}
