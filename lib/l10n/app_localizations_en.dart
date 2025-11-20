// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Rewards';

  @override
  String get settings => 'Settings';

  @override
  String get general => 'General';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDesc => 'Manage notification preferences';

  @override
  String get theme => 'Theme';

  @override
  String get themeDesc => 'Choose light or dark theme';

  @override
  String get language => 'Language';

  @override
  String get languageDesc => 'Select your preferred language';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get privacySettingsDesc => 'Control your data and privacy';

  @override
  String get accountSecurity => 'Account Security';

  @override
  String get accountSecurityDesc => 'Manage passwords and authentication';

  @override
  String get parentControls => 'Parent Controls';

  @override
  String get familyManagement => 'Family Management';

  @override
  String get familyManagementDesc => 'Manage family members and settings';

  @override
  String get parentalControls => 'Parental Controls';

  @override
  String get parentalControlsDesc =>
      'Set controls and restrictions for children';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataDesc => 'Download your family data';

  @override
  String get deleteAllData => 'Delete ALL Data';

  @override
  String get deleteAllDataDesc =>
      'Permanently delete all data (family-wide for parent)';

  @override
  String get restoreToDefault => 'Restore to Default';

  @override
  String get restoreToDefaultDesc =>
      'Reset all data and restore default tasks/rewards';

  @override
  String get fixChildTasks => 'Fix Child Tasks (Debug)';

  @override
  String get fixChildTasksDesc => 'Assign default tasks to existing children';

  @override
  String get aboutSupport => 'About & Support';

  @override
  String get helpFaq => 'Help & FAQ';

  @override
  String get helpFaqDesc => 'Get help and find answers';

  @override
  String get about => 'About';

  @override
  String get aboutDesc => 'App version and information';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get contactSupportDesc => 'Get in touch with our support team';

  @override
  String comingSoon(String feature) {
    return '$feature coming soon!';
  }

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文 (Chinese)';

  @override
  String languageChanged(String language) {
    return 'Language changed to $language';
  }
}
