import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension on ThemeData for app-specific theme utilities
/// 
/// Provides convenient access to app-specific colors, spacing,
/// and theme-dependent utilities that extend beyond standard
/// Material Design components.
extension AppThemeExtension on ThemeData {
  
  /// Get success color based on current theme brightness
  Color get successColor => brightness == Brightness.light 
      ? AppColors.success 
      : AppColors.successDark;
  
  /// Get warning color based on current theme brightness
  Color get warningColor => brightness == Brightness.light 
      ? AppColors.warning 
      : AppColors.warningDark;
  
  /// Get info color based on current theme brightness
  Color get infoColor => brightness == Brightness.light 
      ? AppColors.info 
      : AppColors.infoDark;
  
  /// Get reward category color by index
  Color getRewardCategoryColor(int index) {
    return AppColors.getRewardCategoryColor(index, brightness == Brightness.dark);
  }
  
  /// Check if current theme is dark
  bool get isDark => brightness == Brightness.dark;
  
  /// Check if current theme is light
  bool get isLight => brightness == Brightness.light;
  
  /// Get adaptive color that contrasts well with current background
  Color get adaptiveColor => isDark 
      ? colorScheme.onSurface 
      : colorScheme.onSurface;
  
  /// Get surface color with slight elevation tint
  Color get elevatedSurfaceColor => isDark 
      ? Color.alphaBlend(
          colorScheme.primary.withOpacity(0.05),
          colorScheme.surface,
        )
      : colorScheme.surface;
}

/// Extension on BuildContext for theme access
/// 
/// Provides convenient theme access methods that reduce boilerplate
/// and make theme-dependent code more readable.
extension ThemeContextExtension on BuildContext {
  
  /// Get current theme
  ThemeData get theme => Theme.of(this);
  
  /// Get current color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Get current text theme
  TextTheme get textTheme => theme.textTheme;
  
  /// Check if current theme is dark
  bool get isDarkTheme => theme.isDark;
  
  /// Check if current theme is light
  bool get isLightTheme => theme.isLight;
  
  /// Get success color for current theme
  Color get successColor => theme.successColor;
  
  /// Get warning color for current theme
  Color get warningColor => theme.warningColor;
  
  /// Get info color for current theme
  Color get infoColor => theme.infoColor;
  
  /// Get reward category color by index
  Color getRewardCategoryColor(int index) => theme.getRewardCategoryColor(index);
  
  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Get screen size
  Size get screenSize => mediaQuery.size;
  
  /// Get screen width
  double get screenWidth => screenSize.width;
  
  /// Get screen height
  double get screenHeight => screenSize.height;
  
  /// Check if screen is considered small (< 600px wide)
  bool get isSmallScreen => screenWidth < 600;
  
  /// Check if screen is considered medium (600-1000px wide)
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1000;
  
  /// Check if screen is considered large (>= 1000px wide)
  bool get isLargeScreen => screenWidth >= 1000;
  
  /// Get responsive padding based on screen size
  EdgeInsets get responsivePadding {
    if (isSmallScreen) {
      return const EdgeInsets.all(12.0);
    } else if (isMediumScreen) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }
  
  /// Get responsive horizontal padding
  EdgeInsets get responsiveHorizontalPadding {
    if (isSmallScreen) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else if (isMediumScreen) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0);
    }
  }
}

/// Custom theme properties for app-specific styling
/// 
/// Defines additional theme properties that are specific to the
/// AI Rewards System app and don't exist in standard Material themes.
class AppThemeProperties {
  
  /// Reward card styling properties
  static const double rewardCardElevation = 2.0;
  static const BorderRadius rewardCardBorderRadius = BorderRadius.all(
    Radius.circular(12.0),
  );
  static const EdgeInsets rewardCardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets rewardCardMargin = EdgeInsets.all(8.0);
  
  /// Category chip styling properties  
  static const double categoryChipHeight = 32.0;
  static const BorderRadius categoryChipBorderRadius = BorderRadius.all(
    Radius.circular(16.0),
  );
  static const EdgeInsets categoryChipPadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 6.0,
  );
  
  /// Button styling properties
  static const double buttonHeight = 48.0;
  static const BorderRadius buttonBorderRadius = BorderRadius.all(
    Radius.circular(12.0),
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 12.0,
  );
  
  /// Input field styling properties
  static const BorderRadius inputBorderRadius = BorderRadius.all(
    Radius.circular(12.0),
  );
  static const EdgeInsets inputContentPadding = EdgeInsets.all(16.0);
  
  /// Dialog styling properties
  static const BorderRadius dialogBorderRadius = BorderRadius.all(
    Radius.circular(20.0),
  );
  static const EdgeInsets dialogPadding = EdgeInsets.all(24.0);
  static const double dialogElevation = 8.0;
  
  /// Bottom sheet styling properties
  static const BorderRadius bottomSheetBorderRadius = BorderRadius.vertical(
    top: Radius.circular(20.0),
  );
  static const double bottomSheetElevation = 8.0;
  
  /// Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  /// Spacing constants
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  /// Typography enhancements
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
}

/// Responsive breakpoints for different screen sizes
/// 
/// Defines breakpoints for responsive design that determine
/// layout changes based on screen width.
class ResponsiveBreakpoints {
  static const double mobile = 480.0;
  static const double tablet = 768.0;
  static const double desktop = 1024.0;
  static const double largeDesktop = 1440.0;
  
  /// Check if screen width qualifies as mobile
  static bool isMobile(double width) => width < mobile;
  
  /// Check if screen width qualifies as tablet
  static bool isTablet(double width) => width >= mobile && width < desktop;
  
  /// Check if screen width qualifies as desktop
  static bool isDesktop(double width) => width >= desktop;
  
  /// Check if screen width qualifies as large desktop
  static bool isLargeDesktop(double width) => width >= largeDesktop;
  
  /// Get responsive columns count based on screen width
  static int getColumnsCount(double width) {
    if (isMobile(width)) return 1;
    if (isTablet(width)) return 2;
    if (isDesktop(width)) return 3;
    return 4;
  }
  
  /// Get responsive grid cross axis count
  static int getGridCrossAxisCount(double width) {
    if (isMobile(width)) return 2;
    if (isTablet(width)) return 3;
    if (isDesktop(width)) return 4;
    return 6;
  }
}