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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('📱 BannerAdWidget initState - platform: ${kIsWeb ? "Web" : "Mobile"}');
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (kIsWeb) {
      // For web, AdSense is loaded via HTML script tags
      // We just show a placeholder container with the ad slot
      if (mounted) {
        setState(() {
          _isAdLoaded = true;
          _isLoading = false;
        });
      }
      return;
    }

    // For mobile, load AdMob banner
    try {
      debugPrint('📱 Starting AdMob banner ad load...');
      final ad = await _adService.createBannerAd();
      
      if (!mounted) return;
      
      if (ad != null) {
        debugPrint('📱 Ad object created, setting up widget...');
        // Set the banner ad immediately - the BannerAdListener will handle the ready state
        if (mounted) {
          setState(() {
            _bannerAd = ad;
            _isLoading = false;
          });
        }
        
        // Wait for the ad to load and check status
        await Future.delayed(const Duration(milliseconds: 1000));
        
        if (mounted) {
          final isLoaded = _adService.isBannerAdLoaded;
          setState(() {
            _isAdLoaded = isLoaded;
            if (_isAdLoaded) {
              debugPrint('✅ Banner ad successfully loaded and ready to display');
            } else {
              debugPrint('⚠️ Ad widget created but waiting for load callback');
              // Still show the widget, the listener will update when ready
              _isAdLoaded = true; // Show it anyway, AdWidget handles internal state
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Ad creation returned null';
            debugPrint('❌ $_errorMessage');
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading banner ad: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
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
    // Show loading state
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 50,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Show error state (only in debug mode)
    if (_errorMessage != null && kDebugMode) {
      return Container(
        width: double.infinity,
        height: 50,
        color: Colors.red.withOpacity(0.1),
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            'Ad Error: $_errorMessage',
            style: const TextStyle(fontSize: 10, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // If no ad loaded and not in debug mode, hide
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

    debugPrint('📱 Rendering AdWidget with banner ad');
    return Container(
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      color: Colors.transparent,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
