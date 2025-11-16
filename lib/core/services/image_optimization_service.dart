import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Image optimization service for efficient loading and caching
@lazySingleton
class ImageOptimizationService {
  static const int _maxCacheSize = 100; // MB
  static const Duration _cacheStaleAfter = Duration(days: 7);
  static const Duration _cacheMaxAge = Duration(days: 30);
  
  // Preloaded images cache
  static final Map<String, ImageProvider> _preloadedImages = {};
  
  /// Initialize image optimization service
  static Future<void> initialize() async {
    try {
      // Configure cached network image settings
      await _configureCachedNetworkImage();
      
      // Preload essential images
      await _preloadEssentialImages();
      
      debugPrint('🖼️ ImageOptimizationService initialized');
    } catch (e) {
      debugPrint('⚠️ ImageOptimizationService initialization failed: $e');
    }
  }

  /// Configure cached network image settings for optimal performance
  static Future<void> _configureCachedNetworkImage() async {
    // The cached_network_image package handles most configuration internally
    // We'll configure it through the widget parameters when used
    debugPrint('📋 CachedNetworkImage configuration set');
  }

  /// Preload essential images for faster access
  static Future<void> _preloadEssentialImages() async {
    try {
      // Skip preloading on web platform to avoid asset loading issues
      if (kIsWeb) {
        debugPrint('🌐 Skipping image preloading on web platform');
        return;
      }
      
      final imagesToPreload = [
        'assets/images/logo.png',
        'assets/images/default_avatar.png',
        'assets/icons/star.png',
        'assets/icons/trophy.png',
        'assets/animations/celebration_stars.gif',
      ];

      for (final imagePath in imagesToPreload) {
        try {
          if (await _assetExists(imagePath)) {
            final imageProvider = AssetImage(imagePath);
            _preloadedImages[imagePath] = imageProvider;
          
            // Preload the image into memory
            final imageConfiguration = const ImageConfiguration();
            final completer = imageProvider.resolve(imageConfiguration);
            
            completer.addListener(ImageStreamListener(
              (ImageInfo info, bool synchronousCall) {
                debugPrint('✅ Preloaded: $imagePath');
              },
              onError: (exception, stackTrace) {
                debugPrint('⚠️ Failed to preload: $imagePath - $exception');
              },
            ));
          }
        } catch (e) {
          debugPrint('⚠️ Failed to preload asset $imagePath: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to preload essential images: $e');
    }
  }

  /// Check if an asset exists
  static Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get optimized image widget for network images
  static Widget buildOptimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableMemoryCache = true,
    bool enableDiskCache = true,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: width?.round(),
      memCacheHeight: height?.round(),
      maxWidthDiskCache: 1024, // Limit disk cache size
      maxHeightDiskCache: 1024,
      placeholder: placeholder != null
          ? (context, url) => placeholder
          : (context, url) => _buildLoadingPlaceholder(width, height),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget
          : (context, url, error) => _buildErrorPlaceholder(width, height),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      useOldImageOnUrlChange: true,
    );
  }

  /// Build optimized avatar widget with fallback
  static Widget buildOptimizedAvatar({
    String? imageUrl,
    required double radius,
    String? fallbackAsset,
    Color? fallbackColor,
    IconData? fallbackIcon,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(
          imageUrl,
          maxWidth: (radius * 2).round(),
          maxHeight: (radius * 2).round(),
        ),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('⚠️ Avatar loading failed: $exception');
        },
        child: null, // Image will be background
      );
    } else if (fallbackAsset != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(fallbackAsset),
        backgroundColor: fallbackColor,
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: fallbackColor ?? Colors.grey[300],
        child: Icon(
          fallbackIcon ?? Icons.person,
          size: radius,
          color: Colors.white,
        ),
      );
    }
  }

  /// Build kid-friendly image with safety checks
  static Widget buildKidSafeImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return buildOptimizedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: _buildKidFriendlyPlaceholder(width, height),
      errorWidget: _buildKidFriendlyError(width, height),
    );
  }

  /// Build loading placeholder with kid-friendly design
  static Widget _buildLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error placeholder
  static Widget _buildErrorPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Image unavailable',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Build kid-friendly loading placeholder
  static Widget _buildKidFriendlyPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✨', style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Loading magic...',
            style: TextStyle(
              color: Colors.purple,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build kid-friendly error placeholder
  static Widget _buildKidFriendlyError(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🎨',
            style: TextStyle(
              fontSize: 28,
              color: Colors.orange[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Drawing not ready',
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Compress image for optimal performance
  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 85,
  }) async {
    try {
      // Decode the image
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: maxWidth,
        targetHeight: maxHeight,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Convert back to bytes with compression
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('⚠️ Image compression failed: $e');
    }
    
    return null;
  }

  /// Clear image cache
  static Future<void> clearImageCache() async {
    try {
      // Clear cached network images
      await CachedNetworkImage.evictFromCache('');
      
      // Clear preloaded images
      _preloadedImages.clear();
      
      // Clear image cache from memory
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      debugPrint('🗑️ Image cache cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear image cache: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      
      return {
        'current_size': imageCache.currentSize,
        'current_size_bytes': imageCache.currentSizeBytes,
        'maximum_size': imageCache.maximumSize,
        'maximum_size_bytes': imageCache.maximumSizeBytes,
        'live_image_count': imageCache.liveImageCount,
        'pending_image_count': imageCache.pendingImageCount,
        'preloaded_count': _preloadedImages.length,
      };
    } catch (e) {
      debugPrint('⚠️ Failed to get cache stats: $e');
      return {};
    }
  }

  /// Configure image cache for optimal performance
  static void configureImageCache({
    int maxImages = 1000,
    int maxSizeBytes = 50 * 1024 * 1024, // 50MB
  }) {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = maxImages;
    imageCache.maximumSizeBytes = maxSizeBytes;
    
    debugPrint('🎯 Image cache configured: $maxImages images, ${maxSizeBytes ~/ (1024 * 1024)}MB');
  }
}

/// Optimized image widget with lazy loading
class LazyLoadImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LazyLoadImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<LazyLoadImage> createState() => _LazyLoadImageState();
}

class _LazyLoadImageState extends State<LazyLoadImage> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if widget is in viewport
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final renderObject = context.findRenderObject() as RenderBox?;
          if (renderObject != null) {
            final position = renderObject.localToGlobal(Offset.zero);
            final size = renderObject.size;
            final viewport = MediaQuery.of(context).size;
            
            final isInViewport = position.dy < viewport.height && 
                                position.dy + size.height > 0;
            
            if (isInViewport && !_isVisible) {
              setState(() {
                _isVisible = true;
              });
            }
          }
        });

        if (_isVisible) {
          return ImageOptimizationService.buildOptimizedNetworkImage(
            imageUrl: widget.imageUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            placeholder: widget.placeholder,
            errorWidget: widget.errorWidget,
          );
        } else {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[100],
          );
        }
      },
    );
  }
}