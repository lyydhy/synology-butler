import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'群晖管家'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @themeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @themeColor.
  ///
  /// In zh, this message translates to:
  /// **'主题色'**
  String get themeColor;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @followSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get followSystem;

  /// No description provided for @lightMode.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get darkMode;

  /// No description provided for @simplifiedChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// No description provided for @english.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @loginTitle.
  ///
  /// In zh, this message translates to:
  /// **'连接你的群晖 NAS'**
  String get loginTitle;

  /// No description provided for @deviceName.
  ///
  /// In zh, this message translates to:
  /// **'设备名称'**
  String get deviceName;

  /// No description provided for @addressOrHost.
  ///
  /// In zh, this message translates to:
  /// **'地址 / 域名 / IP'**
  String get addressOrHost;

  /// No description provided for @port.
  ///
  /// In zh, this message translates to:
  /// **'端口'**
  String get port;

  /// No description provided for @basePathOptional.
  ///
  /// In zh, this message translates to:
  /// **'基础路径（可选）'**
  String get basePathOptional;

  /// No description provided for @username.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get username;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @useHttps.
  ///
  /// In zh, this message translates to:
  /// **'使用 HTTPS'**
  String get useHttps;

  /// No description provided for @login.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @testingConnection.
  ///
  /// In zh, this message translates to:
  /// **'测试中…'**
  String get testingConnection;

  /// No description provided for @testConnection.
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get testConnection;

  /// No description provided for @loggingIn.
  ///
  /// In zh, this message translates to:
  /// **'登录中…'**
  String get loggingIn;

  /// No description provided for @dashboardTitle.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get dashboardTitle;

  /// No description provided for @currentConnection.
  ///
  /// In zh, this message translates to:
  /// **'当前连接'**
  String get currentConnection;

  /// No description provided for @sessionStatus.
  ///
  /// In zh, this message translates to:
  /// **'会话状态'**
  String get sessionStatus;

  /// No description provided for @deviceInfo.
  ///
  /// In zh, this message translates to:
  /// **'设备信息'**
  String get deviceInfo;

  /// No description provided for @uptime.
  ///
  /// In zh, this message translates to:
  /// **'运行时间'**
  String get uptime;

  /// No description provided for @cpu.
  ///
  /// In zh, this message translates to:
  /// **'CPU'**
  String get cpu;

  /// No description provided for @memory.
  ///
  /// In zh, this message translates to:
  /// **'内存'**
  String get memory;

  /// No description provided for @storage.
  ///
  /// In zh, this message translates to:
  /// **'存储'**
  String get storage;

  /// No description provided for @noSessionPleaseLogin.
  ///
  /// In zh, this message translates to:
  /// **'当前没有可用会话，请先登录 NAS'**
  String get noSessionPleaseLogin;

  /// No description provided for @online.
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get online;

  /// No description provided for @sidEstablished.
  ///
  /// In zh, this message translates to:
  /// **'SID 已建立，可访问 DSM API'**
  String get sidEstablished;

  /// No description provided for @unknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get unknown;

  /// No description provided for @notAvailableYet.
  ///
  /// In zh, this message translates to:
  /// **'暂未获取'**
  String get notAvailableYet;

  /// No description provided for @currentDevice.
  ///
  /// In zh, this message translates to:
  /// **'当前设备'**
  String get currentDevice;

  /// No description provided for @loginStatus.
  ///
  /// In zh, this message translates to:
  /// **'登录状态'**
  String get loginStatus;

  /// No description provided for @loggedInSidEstablished.
  ///
  /// In zh, this message translates to:
  /// **'已登录（SID 已建立）'**
  String get loggedInSidEstablished;

  /// No description provided for @notLoggedIn.
  ///
  /// In zh, this message translates to:
  /// **'未登录'**
  String get notLoggedIn;

  /// No description provided for @filesTitle.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get filesTitle;

  /// No description provided for @downloadsTitle.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get downloadsTitle;

  /// No description provided for @currentPath.
  ///
  /// In zh, this message translates to:
  /// **'当前路径'**
  String get currentPath;

  /// No description provided for @sortByName.
  ///
  /// In zh, this message translates to:
  /// **'按名称排序'**
  String get sortByName;

  /// No description provided for @sortBySize.
  ///
  /// In zh, this message translates to:
  /// **'按大小排序'**
  String get sortBySize;

  /// No description provided for @goParent.
  ///
  /// In zh, this message translates to:
  /// **'返回上一级'**
  String get goParent;

  /// No description provided for @folderIsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前目录为空'**
  String get folderIsEmpty;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @createFolder.
  ///
  /// In zh, this message translates to:
  /// **'新建文件夹'**
  String get createFolder;

  /// No description provided for @folderName.
  ///
  /// In zh, this message translates to:
  /// **'文件夹名称'**
  String get folderName;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @uploadFile.
  ///
  /// In zh, this message translates to:
  /// **'上传文件'**
  String get uploadFile;

  /// No description provided for @targetFolder.
  ///
  /// In zh, this message translates to:
  /// **'目标目录'**
  String get targetFolder;

  /// No description provided for @chooseFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get chooseFile;

  /// No description provided for @noFileSelected.
  ///
  /// In zh, this message translates to:
  /// **'尚未选择文件'**
  String get noFileSelected;

  /// No description provided for @uploading.
  ///
  /// In zh, this message translates to:
  /// **'上传中…'**
  String get uploading;

  /// No description provided for @startUpload.
  ///
  /// In zh, this message translates to:
  /// **'开始上传'**
  String get startUpload;

  /// No description provided for @rename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get rename;

  /// No description provided for @newName.
  ///
  /// In zh, this message translates to:
  /// **'新名称'**
  String get newName;

  /// No description provided for @processing.
  ///
  /// In zh, this message translates to:
  /// **'处理中…'**
  String get processing;

  /// No description provided for @deleteFile.
  ///
  /// In zh, this message translates to:
  /// **'删除文件'**
  String get deleteFile;

  /// No description provided for @deleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get deleteConfirm;

  /// No description provided for @deleteSuccess.
  ///
  /// In zh, this message translates to:
  /// **'删除成功'**
  String get deleteSuccess;

  /// No description provided for @shareLink.
  ///
  /// In zh, this message translates to:
  /// **'分享链接'**
  String get shareLink;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @detail.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get detail;

  /// No description provided for @generateShareLink.
  ///
  /// In zh, this message translates to:
  /// **'生成分享链接'**
  String get generateShareLink;

  /// No description provided for @downloadFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get downloadFilterAll;

  /// No description provided for @downloadFilterDownloading.
  ///
  /// In zh, this message translates to:
  /// **'下载中'**
  String get downloadFilterDownloading;

  /// No description provided for @downloadFilterPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get downloadFilterPaused;

  /// No description provided for @downloadFilterFinished.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get downloadFilterFinished;

  /// No description provided for @noTasksForFilter.
  ///
  /// In zh, this message translates to:
  /// **'当前筛选下暂无下载任务'**
  String get noTasksForFilter;

  /// No description provided for @createDownloadTask.
  ///
  /// In zh, this message translates to:
  /// **'新增下载任务'**
  String get createDownloadTask;

  /// No description provided for @downloadLinkOrMagnet.
  ///
  /// In zh, this message translates to:
  /// **'下载链接 / Magnet'**
  String get downloadLinkOrMagnet;

  /// No description provided for @submitting.
  ///
  /// In zh, this message translates to:
  /// **'提交中…'**
  String get submitting;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get resume;

  /// No description provided for @deleteTask.
  ///
  /// In zh, this message translates to:
  /// **'删除下载任务'**
  String get deleteTask;

  /// No description provided for @operationSuccess.
  ///
  /// In zh, this message translates to:
  /// **'操作成功'**
  String get operationSuccess;

  /// No description provided for @debugInfo.
  ///
  /// In zh, this message translates to:
  /// **'调试信息'**
  String get debugInfo;

  /// No description provided for @debugCurrentConnection.
  ///
  /// In zh, this message translates to:
  /// **'当前连接'**
  String get debugCurrentConnection;

  /// No description provided for @debugLocalStorage.
  ///
  /// In zh, this message translates to:
  /// **'本地保存'**
  String get debugLocalStorage;

  /// No description provided for @debugTips.
  ///
  /// In zh, this message translates to:
  /// **'联调提示'**
  String get debugTips;

  /// No description provided for @savedUsername.
  ///
  /// In zh, this message translates to:
  /// **'已记住用户名'**
  String get savedUsername;

  /// No description provided for @savedDeviceCount.
  ///
  /// In zh, this message translates to:
  /// **'已保存设备数量'**
  String get savedDeviceCount;

  /// No description provided for @serverManagement.
  ///
  /// In zh, this message translates to:
  /// **'连接管理'**
  String get serverManagement;

  /// No description provided for @savedDevices.
  ///
  /// In zh, this message translates to:
  /// **'已保存设备'**
  String get savedDevices;

  /// No description provided for @addNewDevice.
  ///
  /// In zh, this message translates to:
  /// **'添加新设备'**
  String get addNewDevice;

  /// No description provided for @editDevice.
  ///
  /// In zh, this message translates to:
  /// **'编辑设备'**
  String get editDevice;

  /// No description provided for @deleteDevice.
  ///
  /// In zh, this message translates to:
  /// **'删除设备'**
  String get deleteDevice;

  /// No description provided for @deviceDeleted.
  ///
  /// In zh, this message translates to:
  /// **'设备已删除'**
  String get deviceDeleted;

  /// No description provided for @deviceUpdated.
  ///
  /// In zh, this message translates to:
  /// **'设备配置已更新'**
  String get deviceUpdated;

  /// No description provided for @switchDeviceRelogin.
  ///
  /// In zh, this message translates to:
  /// **'已切换设备，请重新登录'**
  String get switchDeviceRelogin;

  /// No description provided for @filePath.
  ///
  /// In zh, this message translates to:
  /// **'路径'**
  String get filePath;

  /// No description provided for @fileType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get fileType;

  /// No description provided for @fileSize.
  ///
  /// In zh, this message translates to:
  /// **'大小'**
  String get fileSize;

  /// No description provided for @folder.
  ///
  /// In zh, this message translates to:
  /// **'文件夹'**
  String get folder;

  /// No description provided for @file.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get file;

  /// No description provided for @taskId.
  ///
  /// In zh, this message translates to:
  /// **'任务 ID'**
  String get taskId;

  /// No description provided for @status.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get status;

  /// No description provided for @progress.
  ///
  /// In zh, this message translates to:
  /// **'进度'**
  String get progress;

  /// No description provided for @appLogsTitle.
  ///
  /// In zh, this message translates to:
  /// **'应用日志'**
  String get appLogsTitle;

  /// No description provided for @appLogsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看本地日志文件、复制内容或快速清空'**
  String get appLogsSubtitle;

  /// No description provided for @appLogsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有日志文件'**
  String get appLogsEmpty;

  /// No description provided for @appLogsEmptyContent.
  ///
  /// In zh, this message translates to:
  /// **'当前日志为空'**
  String get appLogsEmptyContent;

  /// No description provided for @appLogsCopySanitized.
  ///
  /// In zh, this message translates to:
  /// **'复制脱敏内容'**
  String get appLogsCopySanitized;

  /// No description provided for @appLogsExportToLogsDir.
  ///
  /// In zh, this message translates to:
  /// **'导出到日志目录'**
  String get appLogsExportToLogsDir;

  /// No description provided for @appLogsExportToDirectory.
  ///
  /// In zh, this message translates to:
  /// **'导出到指定目录'**
  String get appLogsExportToDirectory;

  /// No description provided for @appLogsDeleteCurrent.
  ///
  /// In zh, this message translates to:
  /// **'删除当前日志'**
  String get appLogsDeleteCurrent;

  /// No description provided for @appLogsDeleteAll.
  ///
  /// In zh, this message translates to:
  /// **'删除全部日志'**
  String get appLogsDeleteAll;

  /// No description provided for @appLogsCopied.
  ///
  /// In zh, this message translates to:
  /// **'脱敏日志已复制'**
  String get appLogsCopied;

  /// No description provided for @appLogsExported.
  ///
  /// In zh, this message translates to:
  /// **'已导出到：{path}'**
  String appLogsExported(Object path);

  /// No description provided for @appLogsExportedToInternal.
  ///
  /// In zh, this message translates to:
  /// **'已导出脱敏日志：{path}'**
  String appLogsExportedToInternal(Object path);

  /// No description provided for @appLogsFileCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 个日志文件'**
  String appLogsFileCount(Object count);

  /// No description provided for @appLogsSanitizedBadge.
  ///
  /// In zh, this message translates to:
  /// **'已脱敏'**
  String get appLogsSanitizedBadge;

  /// No description provided for @appLogsRawBadge.
  ///
  /// In zh, this message translates to:
  /// **'原始日志'**
  String get appLogsRawBadge;

  /// No description provided for @appLogsViewerHint.
  ///
  /// In zh, this message translates to:
  /// **'当前展示的是脱敏后的内容，适合复制或导出给别人排查问题。'**
  String get appLogsViewerHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
