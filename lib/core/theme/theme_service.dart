import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme service for managing app theme state and persistence
/// 
/// Handles theme mode switching (light/dark/system) with persistence
/// using SharedPreferences. Provides reactive theme changes through
/// ValueNotifier for real-time UI updates.
@lazySingleton
class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  
  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  bool _initialized = false;
  
  /// Current theme mode
  ThemeMode get themeMode => _themeMode;
  
  /// Initialize the theme service and load saved theme preference
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    await _loadThemeMode();
  }
  
  /// Load saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    if (_prefs == null) return;
    
    final savedTheme = _prefs!.getString(_themeModeKey);
    if (savedTheme != null) {
      _themeMode = _parseThemeMode(savedTheme);
      notifyListeners();
    }
  }
  
  /// Set new theme mode and persist to SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    
    // Only persist if initialized
    if (_initialized && _prefs != null) {
      await _prefs!.setString(_themeModeKey, mode.toString());
    }
    
    notifyListeners();
  }
  
  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newMode);
  }
  
  /// Set theme to system preference
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
  
  /// Set light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }
  
  /// Set dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  /// Check if current theme is dark
  bool isDark(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
  
  /// Get theme mode display name
  String getThemeModeDisplayName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
  
  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
}

/// Theme mode extension for additional functionality
extension ThemeModeExtension on ThemeMode {
  /// Get icon for theme mode
  IconData get icon {
    switch (this) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
  
  /// Get display name for theme mode
  String get displayName {
    switch (this) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
  
  /// Get description for theme mode
  String get description {
    switch (this) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system preference';
    }
  }
}