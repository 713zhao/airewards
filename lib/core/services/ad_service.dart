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

  // Production Ad Unit IDs
  // Banner ad unit for both Android and iOS
  static const String _productionBannerId =
      'ca-app-pub-3737089294643612/1858330009';

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

    // Production banner ad unit ID (same for Android and iOS)
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return _productionBannerId;
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
            debugPrint('✅ Banner ad LOADED - Ad is ready to display');
            _isBannerAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ Banner ad FAILED to load: ${error.message} (Code: ${error.code})');
            debugPrint('   Domain: ${error.domain}, Response: ${error.responseInfo}');
            ad.dispose();
            _isBannerAdLoaded = false;
          },
          onAdOpened: (ad) {
            debugPrint('📱 Banner ad opened (user clicked)');
          },
          onAdClosed: (ad) {
            debugPrint('🔙 Banner ad closed');
          },
          onAdImpression: (ad) {
            debugPrint('👁️ Banner ad impression recorded');
          },
        ),
      );

      debugPrint('🔄 Requesting banner ad from AdMob...');
      await _bannerAd!.load();
      debugPrint('📤 Ad load request sent, waiting for callback...');
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
