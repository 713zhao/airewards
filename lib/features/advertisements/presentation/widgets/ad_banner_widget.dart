import 'package:flutter/material.dart';

/// AdMob banner widget with proper lifecycle management and error handling
class AdBannerWidget extends StatefulWidget {
  final String adUnitId;
  final AdSize adSize;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool showOnError;
  final Widget? errorWidget;
  final void Function(String error)? onError;
  final VoidCallback? onLoaded;
  final VoidCallback? onClicked;

  const AdBannerWidget({
    super.key,
    required this.adUnitId,
    this.adSize = AdSize.banner,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.showOnError = true,
    this.errorWidget,
    this.onError,
    this.onLoaded,
    this.onClicked,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  
  @override
  bool get wantKeepAlive => true;
  
  bool _isLoaded = false;
  bool _hasError = false;
  String? _errorMessage;
  
  String? get errorMessage => _errorMessage;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pauseAd();
        break;
      case AppLifecycleState.resumed:
        _resumeAd();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _loadAd() async {
    try {
      setState(() {
        _hasError = false;
        _isLoaded = false;
      });

      // Simulate ad loading delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Simulate random success/failure for demo
      final success = DateTime.now().millisecondsSinceEpoch % 3 != 0;
      
      if (success) {
        _onAdLoaded();
      } else {
        _onAdError('Failed to load advertisement');
      }
    } catch (e) {
      _onAdError('Ad loading error: ${e.toString()}');
    }
  }

  void _onAdLoaded() {
    if (mounted) {
      setState(() {
        _isLoaded = true;
        _hasError = false;
        _isVisible = true;
      });
      widget.onLoaded?.call();
    }
  }

  void _onAdError(String error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoaded = false;
        _errorMessage = error;
        _isVisible = widget.showOnError;
      });
      widget.onError?.call(error);
    }
  }

  void _onAdClicked() {
    widget.onClicked?.call();
  }

  void _pauseAd() {
    // Pause ad when app goes to background
    setState(() {
      _isVisible = false;
    });
  }

  void _resumeAd() {
    // Resume ad when app comes to foreground
    if (_isLoaded && !_hasError) {
      setState(() {
        _isVisible = true;
      });
    }
  }

  void _dismissAd() {
    setState(() {
      _isVisible = false;
    });
  }

  void _retryAd() {
    _loadAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return Container(
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_hasError) {
      return _buildErrorWidget(theme);
    }
    
    if (!_isLoaded) {
      return _buildLoadingWidget(theme);
    }
    
    return _buildAdWidget(theme);
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return SizedBox(
      key: const ValueKey('loading'),
      height: widget.adSize.height.toDouble(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading ad...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }
    
    return SizedBox(
      key: const ValueKey('error'),
      height: widget.adSize.height.toDouble(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ad failed to load',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _retryAd,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 24),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              'Retry',
              style: theme.textTheme.bodySmall,
            ),
          ),
          IconButton(
            onPressed: _dismissAd,
            icon: const Icon(Icons.close, size: 16),
            constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAdWidget(ThemeData theme) {
    return GestureDetector(
      onTap: _onAdClicked,
      child: Container(
        key: const ValueKey('ad'),
        height: widget.adSize.height.toDouble(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Stack(
          children: [
            // Ad content placeholder
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.ads_click,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Advertisement',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            
            // Close button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: _dismissAd,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ad size enumeration
enum AdSize {
  banner(320, 50),
  largeBanner(320, 100),
  mediumRectangle(300, 250),
  fullBanner(468, 60),
  leaderboard(728, 90);

  const AdSize(this.width, this.height);

  final int width;
  final int height;
}