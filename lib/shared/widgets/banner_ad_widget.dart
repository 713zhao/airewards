import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/ad_service.dart';

/// Unified banner ad widget that works across web (AdSense) and mobile (AdMob)
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final AdService _adService = AdService();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (kIsWeb) {
      // For web, AdSense is loaded via HTML script tags
      // We just show a placeholder container with the ad slot
      setState(() {
        _isAdLoaded = true;
      });
      return;
    }

    // For mobile, load AdMob banner
    try {
      final ad = await _adService.createBannerAd();
      if (mounted && ad != null) {
        setState(() {
          _bannerAd = ad;
          _isAdLoaded = _adService.isBannerAdLoaded;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading banner ad: $e');
    }
  }

  @override
  void dispose() {
    // Don't dispose the ad service singleton, just clear local reference
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      // Web: AdSense ad slot
      // The actual ad rendering is handled by AdSense script in index.html
      return Container(
        width: double.infinity,
        height: 90,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.ad_units,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'Ad Space',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile: AdMob banner
    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
