import 'package:flutter/material.dart';

/// App color constants following Material Design 3 color system
/// 
/// This class defines the complete color palette for both light and dark themes,
/// following Material Design 3 guidelines for color roles and accessibility.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================

  /// Primary color - main brand color for prominent UI elements
  static const Color lightPrimary = Color(0xFF1976D2); // Blue 700
  
  /// Color displayed most frequently across your app's screens and components
  static const Color lightOnPrimary = Color(0xFFFFFFFF); // White
  
  /// Tonal variant of primary, used for less prominent elements
  static const Color lightPrimaryContainer = Color(0xFFBBDEFB); // Blue 100
  
  /// Color for text and icons on primary container
  static const Color lightOnPrimaryContainer = Color(0xFF0D47A1); // Blue 900
  
  /// Secondary color - provides more ways to accent and distinguish your product
  static const Color lightSecondary = Color(0xFF43A047); // Green 600
  
  /// Color for text and icons on secondary color
  static const Color lightOnSecondary = Color(0xFFFFFFFF); // White
  
  /// Tonal variant of secondary color
  static const Color lightSecondaryContainer = Color(0xFFC8E6C9); // Green 100
  
  /// Color for text and icons on secondary container
  static const Color lightOnSecondaryContainer = Color(0xFF1B5E20); // Green 900
  
  /// Tertiary color - used to balance primary and secondary colors
  static const Color lightTertiary = Color(0xFFFF7043); // Deep Orange 400
  
  /// Color for text and icons on tertiary color
  static const Color lightOnTertiary = Color(0xFFFFFFFF); // White
  
  /// Tonal variant of tertiary color
  static const Color lightTertiaryContainer = Color(0xFFFFE0B2); // Orange 100
  
  /// Color for text and icons on tertiary container
  static const Color lightOnTertiaryContainer = Color(0xFFE65100); // Orange 900
  
  /// Error color for destructive actions and error states
  static const Color lightError = Color(0xFFD32F2F); // Red 700
  
  /// Color for text and icons on error color
  static const Color lightOnError = Color(0xFFFFFFFF); // White
  
  /// Tonal variant of error color
  static const Color lightErrorContainer = Color(0xFFFFCDD2); // Red 100
  
  /// Color for text and icons on error container
  static const Color lightOnErrorContainer = Color(0xFFB71C1C); // Red 900
  
  /// Background color of the app
  static const Color lightBackground = Color(0xFFFAFAFA); // Grey 50
  
  /// Color for text and icons on background
  static const Color lightOnBackground = Color(0xFF212121); // Grey 900
  
  /// Surface color for cards, sheets, and menus
  static const Color lightSurface = Color(0xFFFFFFFF); // White
  
  /// Color for text and icons on surface
  static const Color lightOnSurface = Color(0xFF212121); // Grey 900
  
  /// Variant of surface color with subtle contrast
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5); // Grey 100
  
  /// Color for text and icons on surface variant
  static const Color lightOnSurfaceVariant = Color(0xFF757575); // Grey 600
  
  /// Color for borders and dividers
  static const Color lightOutline = Color(0xFFBDBDBD); // Grey 400
  
  /// Variant of outline color for subtle borders
  static const Color lightOutlineVariant = Color(0xFFE0E0E0); // Grey 300
  
  /// Shadow color for elevation
  static const Color lightShadow = Color(0xFF000000); // Black
  
  /// Scrim color for modals and overlays
  static const Color lightScrim = Color(0xFF000000); // Black
  
  /// Inverse surface color for high contrast elements
  static const Color lightInverseSurface = Color(0xFF303030); // Grey 850
  
  /// Color for text and icons on inverse surface
  static const Color lightOnInverseSurface = Color(0xFFF5F5F5); // Grey 100
  
  /// Inverse primary color
  static const Color lightInversePrimary = Color(0xFF90CAF9); // Blue 200

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================

  /// Primary color for dark theme
  static const Color darkPrimary = Color(0xFF90CAF9); // Blue 200
  
  /// Color for text and icons on primary in dark theme
  static const Color darkOnPrimary = Color(0xFF0D47A1); // Blue 900
  
  /// Primary container for dark theme
  static const Color darkPrimaryContainer = Color(0xFF1565C0); // Blue 800
  
  /// Color for text and icons on primary container in dark theme
  static const Color darkOnPrimaryContainer = Color(0xFFE3F2FD); // Blue 50
  
  /// Secondary color for dark theme
  static const Color darkSecondary = Color(0xFF81C784); // Green 300
  
  /// Color for text and icons on secondary in dark theme
  static const Color darkOnSecondary = Color(0xFF1B5E20); // Green 900
  
  /// Secondary container for dark theme
  static const Color darkSecondaryContainer = Color(0xFF388E3C); // Green 700
  
  /// Color for text and icons on secondary container in dark theme
  static const Color darkOnSecondaryContainer = Color(0xFFE8F5E8); // Green 50
  
  /// Tertiary color for dark theme
  static const Color darkTertiary = Color(0xFFFFAB91); // Deep Orange 200
  
  /// Color for text and icons on tertiary in dark theme
  static const Color darkOnTertiary = Color(0xFFE65100); // Orange 900
  
  /// Tertiary container for dark theme
  static const Color darkTertiaryContainer = Color(0xFFFF5722); // Deep Orange 500
  
  /// Color for text and icons on tertiary container in dark theme
  static const Color darkOnTertiaryContainer = Color(0xFFFFF3E0); // Orange 50
  
  /// Error color for dark theme
  static const Color darkError = Color(0xFFEF5350); // Red 400
  
  /// Color for text and icons on error in dark theme
  static const Color darkOnError = Color(0xFFB71C1C); // Red 900
  
  /// Error container for dark theme
  static const Color darkErrorContainer = Color(0xFFC62828); // Red 800
  
  /// Color for text and icons on error container in dark theme
  static const Color darkOnErrorContainer = Color(0xFFFFEBEE); // Red 50
  
  /// Background color for dark theme
  static const Color darkBackground = Color(0xFF121212); // Material Dark Background
  
  /// Color for text and icons on background in dark theme
  static const Color darkOnBackground = Color(0xFFE0E0E0); // Grey 300
  
  /// Surface color for dark theme
  static const Color darkSurface = Color(0xFF1E1E1E); // Dark Surface
  
  /// Color for text and icons on surface in dark theme
  static const Color darkOnSurface = Color(0xFFE0E0E0); // Grey 300
  
  /// Surface variant for dark theme
  static const Color darkSurfaceVariant = Color(0xFF424242); // Grey 800
  
  /// Color for text and icons on surface variant in dark theme
  static const Color darkOnSurfaceVariant = Color(0xFFBDBDBD); // Grey 400
  
  /// Outline color for dark theme
  static const Color darkOutline = Color(0xFF757575); // Grey 600
  
  /// Outline variant for dark theme
  static const Color darkOutlineVariant = Color(0xFF616161); // Grey 700
  
  /// Shadow color for dark theme
  static const Color darkShadow = Color(0xFF000000); // Black
  
  /// Scrim color for dark theme
  static const Color darkScrim = Color(0xFF000000); // Black
  
  /// Inverse surface for dark theme
  static const Color darkInverseSurface = Color(0xFFE0E0E0); // Grey 300
  
  /// Color for text and icons on inverse surface in dark theme
  static const Color darkOnInverseSurface = Color(0xFF303030); // Grey 850
  
  /// Inverse primary for dark theme
  static const Color darkInversePrimary = Color(0xFF1976D2); // Blue 700

  // ============================================================================
  // CUSTOM APP-SPECIFIC COLORS
  // ============================================================================

  /// Success color for positive feedback and confirmations
  static const Color success = Color(0xFF4CAF50); // Green 500
  static const Color successDark = Color(0xFF81C784); // Green 300
  
  /// Warning color for cautionary messages
  static const Color warning = Color(0xFFFF9800); // Orange 500
  static const Color warningDark = Color(0xFFFFB74D); // Orange 300
  
  /// Info color for informational messages
  static const Color info = Color(0xFF2196F3); // Blue 500
  static const Color infoDark = Color(0xFF64B5F6); // Blue 300

  // ============================================================================
  // REWARD CATEGORY COLORS
  // ============================================================================

  /// Colors for reward categories - light theme
  static const List<Color> rewardCategoryColorsLight = [
    Color(0xFF1976D2), // Blue - Study/Learning
    Color(0xFF388E3C), // Green - Health/Fitness  
    Color(0xFFD32F2F), // Red - Work/Career
    Color(0xFF7B1FA2), // Purple - Personal Development
    Color(0xFFFF8F00), // Orange - Hobbies
    Color(0xFF0097A7), // Teal - Social
    Color(0xFFE64A19), // Deep Orange - Travel
    Color(0xFF5D4037), // Brown - Home/Family
    Color(0xFF455A64), // Blue Grey - Finance
    Color(0xFF689F38), // Light Green - Environment
  ];

  /// Colors for reward categories - dark theme
  static const List<Color> rewardCategoryColorsDark = [
    Color(0xFF90CAF9), // Blue 200 - Study/Learning
    Color(0xFF81C784), // Green 300 - Health/Fitness
    Color(0xFFEF5350), // Red 400 - Work/Career
    Color(0xFFBA68C8), // Purple 300 - Personal Development
    Color(0xFFFFB74D), // Orange 300 - Hobbies
    Color(0xFF4DD0E1), // Cyan 300 - Social
    Color(0xFFFFAB91), // Deep Orange 200 - Travel
    Color(0xFFA1887F), // Brown 200 - Home/Family
    Color(0xFF90A4AE), // Blue Grey 200 - Finance
    Color(0xFFAED581), // Light Green 200 - Environment
  ];

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get reward category color by index
  static Color getRewardCategoryColor(int index, bool isDark) {
    final colors = isDark ? rewardCategoryColorsDark : rewardCategoryColorsLight;
    return colors[index % colors.length];
  }

  /// Get success color based on theme
  static Color getSuccessColor(bool isDark) {
    return isDark ? successDark : success;
  }

  /// Get warning color based on theme
  static Color getWarningColor(bool isDark) {
    return isDark ? warningDark : warning;
  }

  /// Get info color based on theme
  static Color getInfoColor(bool isDark) {
    return isDark ? infoDark : info;
  }

  // ============================================================================
  // COLOR SCHEMES
  // ============================================================================

  /// Complete light color scheme for Material Design 3
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: lightPrimary,
    onPrimary: lightOnPrimary,
    primaryContainer: lightPrimaryContainer,
    onPrimaryContainer: lightOnPrimaryContainer,
    secondary: lightSecondary,
    onSecondary: lightOnSecondary,
    secondaryContainer: lightSecondaryContainer,
    onSecondaryContainer: lightOnSecondaryContainer,
    tertiary: lightTertiary,
    onTertiary: lightOnTertiary,
    tertiaryContainer: lightTertiaryContainer,
    onTertiaryContainer: lightOnTertiaryContainer,
    error: lightError,
    onError: lightOnError,
    errorContainer: lightErrorContainer,
    onErrorContainer: lightOnErrorContainer,
    surface: lightSurface,
    onSurface: lightOnSurface,
    surfaceContainerHighest: lightSurfaceVariant,
    onSurfaceVariant: lightOnSurfaceVariant,
    outline: lightOutline,
    outlineVariant: lightOutlineVariant,
    shadow: lightShadow,
    scrim: lightScrim,
    inverseSurface: lightInverseSurface,
    onInverseSurface: lightOnInverseSurface,
    inversePrimary: lightInversePrimary,
  );

  /// Complete dark color scheme for Material Design 3
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    primaryContainer: darkPrimaryContainer,
    onPrimaryContainer: darkOnPrimaryContainer,
    secondary: darkSecondary,
    onSecondary: darkOnSecondary,
    secondaryContainer: darkSecondaryContainer,
    onSecondaryContainer: darkOnSecondaryContainer,
    tertiary: darkTertiary,
    onTertiary: darkOnTertiary,
    tertiaryContainer: darkTertiaryContainer,
    onTertiaryContainer: darkOnTertiaryContainer,
    error: darkError,
    onError: darkOnError,
    errorContainer: darkErrorContainer,
    onErrorContainer: darkOnErrorContainer,
    surface: darkSurface,
    onSurface: darkOnSurface,
    surfaceContainerHighest: darkSurfaceVariant,
    onSurfaceVariant: darkOnSurfaceVariant,
    outline: darkOutline,
    outlineVariant: darkOutlineVariant,
    shadow: darkShadow,
    scrim: darkScrim,
    inverseSurface: darkInverseSurface,
    onInverseSurface: darkOnInverseSurface,
    inversePrimary: darkInversePrimary,
  );
}