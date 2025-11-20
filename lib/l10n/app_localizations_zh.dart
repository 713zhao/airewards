// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AI奖励系统';

  @override
  String get settings => '设置';

  @override
  String get general => '常规';

  @override
  String get notifications => '通知';

  @override
  String get notificationsDesc => '管理通知偏好设置';

  @override
  String get theme => '主题';

  @override
  String get themeDesc => '选择浅色或深色主题';

  @override
  String get language => '语言';

  @override
  String get languageDesc => '选择您的首选语言';

  @override
  String get privacySecurity => '隐私与安全';

  @override
  String get privacySettings => '隐私设置';

  @override
  String get privacySettingsDesc => '控制您的数据和隐私';

  @override
  String get accountSecurity => '账户安全';

  @override
  String get accountSecurityDesc => '管理密码和身份验证';

  @override
  String get parentControls => '家长控制';

  @override
  String get familyManagement => '家庭管理';

  @override
  String get familyManagementDesc => '管理家庭成员和设置';

  @override
  String get parentalControls => '家长控制';

  @override
  String get parentalControlsDesc => '为儿童设置控制和限制';

  @override
  String get dataManagement => '数据管理';

  @override
  String get exportData => '导出数据';

  @override
  String get exportDataDesc => '下载您的家庭数据';

  @override
  String get deleteAllData => '删除所有数据';

  @override
  String get deleteAllDataDesc => '永久删除所有数据（家长可删除全家数据）';

  @override
  String get restoreToDefault => '恢复默认设置';

  @override
  String get restoreToDefaultDesc => '重置所有数据并恢复默认任务/奖励';

  @override
  String get fixChildTasks => '修复儿童任务（调试）';

  @override
  String get fixChildTasksDesc => '为现有儿童分配默认任务';

  @override
  String get aboutSupport => '关于与支持';

  @override
  String get helpFaq => '帮助与常见问题';

  @override
  String get helpFaqDesc => '获取帮助并找到答案';

  @override
  String get about => '关于';

  @override
  String get aboutDesc => '应用版本和信息';

  @override
  String get contactSupport => '联系支持';

  @override
  String get contactSupportDesc => '与我们的支持团队取得联系';

  @override
  String comingSoon(String feature) {
    return '$feature即将推出！';
  }

  @override
  String get selectLanguage => '选择语言';

  @override
  String get english => 'English (英语)';

  @override
  String get chinese => '中文';

  @override
  String languageChanged(String language) {
    return '语言已更改为$language';
  }
}
