import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'app_colors.dart';
import '../constants/app_constants.dart';
import '../../features/redemption/presentation/theme/kids_theme_extension.dart';

/// App theme configuration implementing Material Design 3
/// 
/// This class provides complete theme configurations for both light and dark modes,
/// including typography, component themes, and custom styling that aligns with
/// Material Design 3 guidelines while maintaining app-specific branding.
@lazySingleton
class AppTheme {
  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================

  /// Base text theme using Inter font family for modern, clean typography
  static const TextTheme _baseTextTheme = TextTheme(
    // Display styles - largest text
    displayLarge: TextStyle(
      fontSize: 57.0,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      height: 1.22,
    ),

    // Headline styles - high emphasis text
    headlineLarge: TextStyle(
      fontSize: 32.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      height: 1.33,
    ),

    // Title styles - medium emphasis text
    titleLarge: TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    titleSmall: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),

    // Body styles - default text
    bodyLarge: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    bodyMedium: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),

    // Label styles - UI labels and captions
    labelLarge: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );

  // ============================================================================
  // LIGHT THEME
  // ============================================================================

  /// Complete light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: AppColors.lightColorScheme,
      
      // Typography
      textTheme: _baseTextTheme.apply(
        bodyColor: AppColors.lightOnSurface,
        displayColor: AppColors.lightOnSurface,
      ),
      
      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Material Theme Data
      materialTapTargetSize: MaterialTapTargetSize.padded,
      
      // Splash Factory
      splashFactory: InkRipple.splashFactory,
      
      // Component Themes
      appBarTheme: _lightAppBarTheme,
      bottomNavigationBarTheme: _lightBottomNavTheme,
      elevatedButtonTheme: _lightElevatedButtonTheme,
      textButtonTheme: _lightTextButtonTheme,
      outlinedButtonTheme: _lightOutlinedButtonTheme,
      floatingActionButtonTheme: _lightFabTheme,
      cardTheme: _lightCardTheme,
      inputDecorationTheme: _lightInputDecorationTheme,
      snackBarTheme: _lightSnackBarTheme,
      dialogTheme: _lightDialogTheme,
      bottomSheetTheme: _lightBottomSheetTheme,
      chipTheme: _lightChipTheme,
      dividerTheme: _lightDividerTheme,
      listTileTheme: _lightListTileTheme,
      navigationBarTheme: _lightNavigationBarTheme,
      
      // Theme Extensions
      extensions: const <ThemeExtension<dynamic>>[
        KidsThemeExtension.light,
      ],
    );
  }

  // ============================================================================
  // DARK THEME
  // ============================================================================

  /// Complete dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: AppColors.darkColorScheme,
      
      // Typography
      textTheme: _baseTextTheme.apply(
        bodyColor: AppColors.darkOnSurface,
        displayColor: AppColors.darkOnSurface,
      ),
      
      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Material Theme Data
      materialTapTargetSize: MaterialTapTargetSize.padded,
      
      // Splash Factory
      splashFactory: InkRipple.splashFactory,
      
      // Component Themes
      appBarTheme: _darkAppBarTheme,
      bottomNavigationBarTheme: _darkBottomNavTheme,
      elevatedButtonTheme: _darkElevatedButtonTheme,
      textButtonTheme: _darkTextButtonTheme,
      outlinedButtonTheme: _darkOutlinedButtonTheme,
      floatingActionButtonTheme: _darkFabTheme,
      cardTheme: _darkCardTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      snackBarTheme: _darkSnackBarTheme,
      dialogTheme: _darkDialogTheme,
      bottomSheetTheme: _darkBottomSheetTheme,
      chipTheme: _darkChipTheme,
      dividerTheme: _darkDividerTheme,
      listTileTheme: _darkListTileTheme,
      navigationBarTheme: _darkNavigationBarTheme,
      
      // Theme Extensions
      extensions: const <ThemeExtension<dynamic>>[
        KidsThemeExtension.dark,
      ],
    );
  }

  // ============================================================================
  // LIGHT THEME COMPONENT CONFIGURATIONS
  // ============================================================================

  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.lightSurface,
    foregroundColor: AppColors.lightOnSurface,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.w500,
      color: AppColors.lightOnSurface,
    ),
    iconTheme: IconThemeData(
      color: AppColors.lightOnSurface,
      size: 24,
    ),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.lightSurface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  static const BottomNavigationBarThemeData _lightBottomNavTheme = BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedItemColor: AppColors.lightPrimary,
    unselectedItemColor: AppColors.lightOnSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );

  static final ElevatedButtonThemeData _lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: AppColors.lightOnPrimary,
      elevation: 1,
      shadowColor: AppColors.lightShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      minimumSize: const Size(double.infinity, 48),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
  );

  static final TextButtonThemeData _lightTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.lightPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static final OutlinedButtonThemeData _lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.lightPrimary,
      side: const BorderSide(color: AppColors.lightOutline, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      minimumSize: const Size(double.infinity, 48),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  );

  static const FloatingActionButtonThemeData _lightFabTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.lightPrimary,
    foregroundColor: AppColors.lightOnPrimary,
    elevation: 6,
    shape: CircleBorder(),
  );

  static final CardThemeData _lightCardTheme = CardThemeData(
    color: AppColors.lightSurface,
    shadowColor: AppColors.lightShadow,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
    ),
    margin: const EdgeInsets.all(4),
  );

  static final InputDecorationTheme _lightInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      borderSide: const BorderSide(color: AppColors.lightOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      borderSide: const BorderSide(color: AppColors.lightOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      borderSide: const BorderSide(color: AppColors.lightError),
    ),
    contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
    labelStyle: const TextStyle(color: AppColors.lightOnSurfaceVariant),
    hintStyle: const TextStyle(color: AppColors.lightOnSurfaceVariant),
  );

  static final SnackBarThemeData _lightSnackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.lightInverseSurface,
    contentTextStyle: const TextStyle(color: AppColors.lightOnInverseSurface),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.smallRadius),
    ),
    behavior: SnackBarBehavior.floating,
  );

  static final DialogThemeData _lightDialogTheme = DialogThemeData(
    backgroundColor: AppColors.lightSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
    ),
    elevation: 6,
  );

  static final BottomSheetThemeData _lightBottomSheetTheme = BottomSheetThemeData(
    backgroundColor: AppColors.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    elevation: 8,
  );

  static final ChipThemeData _lightChipTheme = ChipThemeData(
    backgroundColor: AppColors.lightSurfaceVariant,
    selectedColor: AppColors.lightSecondaryContainer,
    labelStyle: const TextStyle(color: AppColors.lightOnSurface),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.smallRadius),
    ),
  );

  static const DividerThemeData _lightDividerTheme = DividerThemeData(
    color: AppColors.lightOutlineVariant,
    thickness: 1,
  );

  static const ListTileThemeData _lightListTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  static const NavigationBarThemeData _lightNavigationBarTheme = NavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    elevation: 3,
    height: 80,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  );

  // ============================================================================
  // DARK THEME COMPONENT CONFIGURATIONS
  // ============================================================================

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkOnSurface,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.w500,
      color: AppColors.darkOnSurface,
    ),
    iconTheme: IconThemeData(
      color: AppColors.darkOnSurface,
      size: 24,
    ),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkSurface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  static const BottomNavigationBarThemeData _darkBottomNavTheme = BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.darkPrimary,
    unselectedItemColor: AppColors.darkOnSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );

  static final ElevatedButtonThemeData _darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: AppColors.darkOnPrimary,
      elevation: 1,
      shadowColor: AppColors.darkShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      minimumSize: const Size(double.infinity, 48),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
  );

  static final TextButtonThemeData _darkTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.darkPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static final OutlinedButtonThemeData _darkOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.darkPrimary,
      side: const BorderSide(color: AppColors.darkOutline, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      minimumSize: const Size(double.infinity, 48),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  );

  static const FloatingActionButtonThemeData _darkFabTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.darkPrimary,
    foregroundColor: AppColors.darkOnPrimary,
    elevation: 6,
    shape: CircleBorder(),
  );

  static final CardThemeData _darkCardTheme = CardThemeData(
    color: AppColors.darkSurface,
    shadowColor: AppColors.darkShadow,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
    ),
    margin: const EdgeInsets.all(4),
  );

  static final InputDecorationTheme _darkInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      borderSide: const BorderSide(color: AppColors.darkOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      borderSide: const BorderSide(color: AppColors.darkOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      borderSide: const BorderSide(color: AppColors.darkError),
    ),
    contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
    labelStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
    hintStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
  );

  static final SnackBarThemeData _darkSnackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.darkInverseSurface,
    contentTextStyle: const TextStyle(color: AppColors.darkOnInverseSurface),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.smallRadius),
    ),
    behavior: SnackBarBehavior.floating,
  );

  static final DialogThemeData _darkDialogTheme = DialogThemeData(
    backgroundColor: AppColors.darkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
    ),
    elevation: 6,
  );

  static final BottomSheetThemeData _darkBottomSheetTheme = BottomSheetThemeData(
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    elevation: 8,
  );

  static final ChipThemeData _darkChipTheme = ChipThemeData(
    backgroundColor: AppColors.darkSurfaceVariant,
    selectedColor: AppColors.darkSecondaryContainer,
    labelStyle: const TextStyle(color: AppColors.darkOnSurface),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.smallRadius),
    ),
  );

  static const DividerThemeData _darkDividerTheme = DividerThemeData(
    color: AppColors.darkOutlineVariant,
    thickness: 1,
  );

  static const ListTileThemeData _darkListTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  static const NavigationBarThemeData _darkNavigationBarTheme = NavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    elevation: 3,
    height: 80,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  );
}
