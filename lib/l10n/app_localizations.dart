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

  /// No description provided for @quickLoginNeedPassword.
  ///
  /// In zh, this message translates to:
  /// **'没有保存密码，请到登录页输入'**
  String get quickLoginNeedPassword;

  /// No description provided for @loginInProgress.
  ///
  /// In zh, this message translates to:
  /// **'正在登录…'**
  String get loginInProgress;

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

  /// 套件未安装
  ///
  /// In zh, this message translates to:
  /// **'未安装'**
  String get notInstalled;

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

  /// No description provided for @deleteConfirmHint.
  ///
  /// In zh, this message translates to:
  /// **'确定删除 {name} 吗？'**
  String deleteConfirmHint(Object name);

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

  /// No description provided for @downloadStatusWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待中'**
  String get downloadStatusWaiting;

  /// No description provided for @downloadStatusDownloading.
  ///
  /// In zh, this message translates to:
  /// **'下载中'**
  String get downloadStatusDownloading;

  /// No description provided for @downloadStatusPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get downloadStatusPaused;

  /// No description provided for @downloadStatusFinished.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get downloadStatusFinished;

  /// No description provided for @downloadStatusSeeding.
  ///
  /// In zh, this message translates to:
  /// **'做种中'**
  String get downloadStatusSeeding;

  /// No description provided for @downloadStatusHashChecking.
  ///
  /// In zh, this message translates to:
  /// **'校验中'**
  String get downloadStatusHashChecking;

  /// No description provided for @downloadStatusExtracting.
  ///
  /// In zh, this message translates to:
  /// **'解压中'**
  String get downloadStatusExtracting;

  /// No description provided for @downloadStatusError.
  ///
  /// In zh, this message translates to:
  /// **'出错'**
  String get downloadStatusError;

  /// No description provided for @downloadStatusUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get downloadStatusUnknown;

  /// No description provided for @downloadStatusFileHostingWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待资源'**
  String get downloadStatusFileHostingWaiting;

  /// No description provided for @downloadStatusCaptchaNeeded.
  ///
  /// In zh, this message translates to:
  /// **'需要验证码'**
  String get downloadStatusCaptchaNeeded;

  /// No description provided for @downloadStatusFinishing.
  ///
  /// In zh, this message translates to:
  /// **'即将完成'**
  String get downloadStatusFinishing;

  /// No description provided for @downloadStatusPreSeeding.
  ///
  /// In zh, this message translates to:
  /// **'等待做种'**
  String get downloadStatusPreSeeding;

  /// No description provided for @downloadStatusPreprocessing.
  ///
  /// In zh, this message translates to:
  /// **'预处理中'**
  String get downloadStatusPreprocessing;

  /// No description provided for @downloadStatusDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'已下载'**
  String get downloadStatusDownloaded;

  /// No description provided for @downloadStatusPostProcessing.
  ///
  /// In zh, this message translates to:
  /// **'后处理中'**
  String get downloadStatusPostProcessing;

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

  /// No description provided for @controlPanelTitle.
  ///
  /// In zh, this message translates to:
  /// **'控制面板'**
  String get controlPanelTitle;

  /// No description provided for @taskSchedulerTitle.
  ///
  /// In zh, this message translates to:
  /// **'任务计划'**
  String get taskSchedulerTitle;

  /// No description provided for @externalDevicesTitle.
  ///
  /// In zh, this message translates to:
  /// **'外接设备'**
  String get externalDevicesTitle;

  /// No description provided for @externalAccessTitle.
  ///
  /// In zh, this message translates to:
  /// **'外部访问'**
  String get externalAccessTitle;

  /// No description provided for @indexServiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'索引服务'**
  String get indexServiceTitle;

  /// No description provided for @sharedFoldersTitle.
  ///
  /// In zh, this message translates to:
  /// **'共享文件夹'**
  String get sharedFoldersTitle;

  /// No description provided for @userGroupsTitle.
  ///
  /// In zh, this message translates to:
  /// **'用户与群组'**
  String get userGroupsTitle;

  /// No description provided for @informationCenterTitle.
  ///
  /// In zh, this message translates to:
  /// **'信息中心'**
  String get informationCenterTitle;

  /// No description provided for @noTasks.
  ///
  /// In zh, this message translates to:
  /// **'当前没有任务计划'**
  String get noTasks;

  /// No description provided for @noExternalDevices.
  ///
  /// In zh, this message translates to:
  /// **'当前没有连接外接设备'**
  String get noExternalDevices;

  /// No description provided for @noDdnsRecords.
  ///
  /// In zh, this message translates to:
  /// **'当前没有 DDNS 记录'**
  String get noDdnsRecords;

  /// No description provided for @noSharedFolders.
  ///
  /// In zh, this message translates to:
  /// **'当前没有共享文件夹'**
  String get noSharedFolders;

  /// No description provided for @noUsersFound.
  ///
  /// In zh, this message translates to:
  /// **'没有找到用户'**
  String get noUsersFound;

  /// No description provided for @noGroupsFound.
  ///
  /// In zh, this message translates to:
  /// **'没有找到群组'**
  String get noGroupsFound;

  /// No description provided for @executeNow.
  ///
  /// In zh, this message translates to:
  /// **'立即执行'**
  String get executeNow;

  /// No description provided for @taskSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'任务已提交执行'**
  String get taskSubmitted;

  /// No description provided for @executeFailed.
  ///
  /// In zh, this message translates to:
  /// **'执行失败'**
  String get executeFailed;

  /// No description provided for @updateFailed.
  ///
  /// In zh, this message translates to:
  /// **'更新失败'**
  String get updateFailed;

  /// No description provided for @ejectDevice.
  ///
  /// In zh, this message translates to:
  /// **'弹出设备'**
  String get ejectDevice;

  /// No description provided for @ejectSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'已提交弹出设备请求'**
  String get ejectSubmitted;

  /// No description provided for @ejectFailed.
  ///
  /// In zh, this message translates to:
  /// **'弹出失败'**
  String get ejectFailed;

  /// No description provided for @fileSystem.
  ///
  /// In zh, this message translates to:
  /// **'文件系统'**
  String get fileSystem;

  /// No description provided for @mountPath.
  ///
  /// In zh, this message translates to:
  /// **'挂载路径'**
  String get mountPath;

  /// No description provided for @capacity.
  ///
  /// In zh, this message translates to:
  /// **'容量'**
  String get capacity;

  /// No description provided for @nextAutoUpdateTime.
  ///
  /// In zh, this message translates to:
  /// **'下次自动更新时间'**
  String get nextAutoUpdateTime;

  /// No description provided for @ipAddress.
  ///
  /// In zh, this message translates to:
  /// **'IP 地址'**
  String get ipAddress;

  /// No description provided for @lastUpdated.
  ///
  /// In zh, this message translates to:
  /// **'上次更新'**
  String get lastUpdated;

  /// No description provided for @refreshNow.
  ///
  /// In zh, this message translates to:
  /// **'立即刷新'**
  String get refreshNow;

  /// No description provided for @thumbnailQuality.
  ///
  /// In zh, this message translates to:
  /// **'缩图质量'**
  String get thumbnailQuality;

  /// No description provided for @thumbnailQualityUpdated.
  ///
  /// In zh, this message translates to:
  /// **'缩图质量已更新'**
  String get thumbnailQualityUpdated;

  /// No description provided for @rebuildIndex.
  ///
  /// In zh, this message translates to:
  /// **'重建索引'**
  String get rebuildIndex;

  /// No description provided for @rebuildIndexDesc.
  ///
  /// In zh, this message translates to:
  /// **'重新触发媒体索引，适合补救缩图缺失或索引状态异常。'**
  String get rebuildIndexDesc;

  /// No description provided for @rebuildSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'已提交重建索引请求'**
  String get rebuildSubmitted;

  /// No description provided for @rebuildFailed.
  ///
  /// In zh, this message translates to:
  /// **'重建失败'**
  String get rebuildFailed;

  /// No description provided for @currentIndexStatus.
  ///
  /// In zh, this message translates to:
  /// **'当前状态'**
  String get currentIndexStatus;

  /// No description provided for @currentTask.
  ///
  /// In zh, this message translates to:
  /// **'当前任务'**
  String get currentTask;

  /// No description provided for @noIndexTasks.
  ///
  /// In zh, this message translates to:
  /// **'当前没有索引任务'**
  String get noIndexTasks;

  /// No description provided for @historyDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除 {name} 的历史记录'**
  String historyDeleted(Object name);

  /// No description provided for @connectionTestFailed.
  ///
  /// In zh, this message translates to:
  /// **'测试连接失败'**
  String get connectionTestFailed;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @switchedToHttp.
  ///
  /// In zh, this message translates to:
  /// **'已切换为 HTTP，请仅在可信局域网中使用'**
  String get switchedToHttp;

  /// No description provided for @selectFromHistory.
  ///
  /// In zh, this message translates to:
  /// **'从历史登录设备中选择'**
  String get selectFromHistory;

  /// No description provided for @historyDevices.
  ///
  /// In zh, this message translates to:
  /// **'历史登录设备'**
  String get historyDevices;

  /// No description provided for @selectDeviceFirst.
  ///
  /// In zh, this message translates to:
  /// **'请选择一个历史设备后再快速登录'**
  String get selectDeviceFirst;

  /// No description provided for @quickLogin.
  ///
  /// In zh, this message translates to:
  /// **'快速登录'**
  String get quickLogin;

  /// No description provided for @enterPasswordToLogin.
  ///
  /// In zh, this message translates to:
  /// **'输入密码即可登录'**
  String get enterPasswordToLogin;

  /// No description provided for @addDevice.
  ///
  /// In zh, this message translates to:
  /// **'添加设备'**
  String get addDevice;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @newAccountDevice.
  ///
  /// In zh, this message translates to:
  /// **'新账号 / 新设备登录'**
  String get newAccountDevice;

  /// No description provided for @connectionInfo.
  ///
  /// In zh, this message translates to:
  /// **'连接信息'**
  String get connectionInfo;

  /// No description provided for @enterNasCredentials.
  ///
  /// In zh, this message translates to:
  /// **'填写 NAS 地址与 DSM 账号信息'**
  String get enterNasCredentials;

  /// No description provided for @ignoreSslCert.
  ///
  /// In zh, this message translates to:
  /// **'忽略 SSL 证书'**
  String get ignoreSslCert;

  /// No description provided for @ignoreSslCertHint.
  ///
  /// In zh, this message translates to:
  /// **'仅适用于自签名或异常证书场景'**
  String get ignoreSslCertHint;

  /// No description provided for @httpsOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅 HTTPS 下可用'**
  String get httpsOnly;

  /// No description provided for @rememberPassword.
  ///
  /// In zh, this message translates to:
  /// **'记住密码'**
  String get rememberPassword;

  /// No description provided for @loginDsm.
  ///
  /// In zh, this message translates to:
  /// **'登录 DSM'**
  String get loginDsm;

  /// No description provided for @dsm7Plus.
  ///
  /// In zh, this message translates to:
  /// **'DSM 7+'**
  String get dsm7Plus;

  /// No description provided for @quickLoginReady.
  ///
  /// In zh, this message translates to:
  /// **'已为你准备好快速登录。'**
  String get quickLoginReady;

  /// No description provided for @connectToDsm.
  ///
  /// In zh, this message translates to:
  /// **'连接你的群晖 DSM。'**
  String get connectToDsm;

  /// No description provided for @quickRelogin.
  ///
  /// In zh, this message translates to:
  /// **'快速重新登录'**
  String get quickRelogin;

  /// No description provided for @quickReloginHint.
  ///
  /// In zh, this message translates to:
  /// **'有历史记录时优先显示这个界面，减少输入内容。'**
  String get quickReloginHint;

  /// No description provided for @loginToNas.
  ///
  /// In zh, this message translates to:
  /// **'登录到 {name}'**
  String loginToNas(Object name);

  /// No description provided for @loginToNasHint.
  ///
  /// In zh, this message translates to:
  /// **'支持局域网 IP、域名和端口。'**
  String get loginToNasHint;

  /// No description provided for @noUsernameTapChange.
  ///
  /// In zh, this message translates to:
  /// **'未记录用户名，请点击更换账号'**
  String get noUsernameTapChange;

  /// No description provided for @fill.
  ///
  /// In zh, this message translates to:
  /// **'填写'**
  String get fill;

  /// No description provided for @changeAccount.
  ///
  /// In zh, this message translates to:
  /// **'更换账号'**
  String get changeAccount;

  /// No description provided for @justUsed.
  ///
  /// In zh, this message translates to:
  /// **'刚刚使用'**
  String get justUsed;

  /// No description provided for @minutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 分钟前使用'**
  String minutesAgo(Object n);

  /// No description provided for @hoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 小时前使用'**
  String hoursAgo(Object n);

  /// No description provided for @daysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 天前使用'**
  String daysAgo(Object n);

  /// No description provided for @usedEarlier.
  ///
  /// In zh, this message translates to:
  /// **'较早前使用'**
  String get usedEarlier;

  /// No description provided for @noLoginTimeRecorded.
  ///
  /// In zh, this message translates to:
  /// **'未记录登录时间'**
  String get noLoginTimeRecorded;

  /// No description provided for @selectedEnterPassword.
  ///
  /// In zh, this message translates to:
  /// **'已选择 {name}，输入密码即可重新登录'**
  String selectedEnterPassword(Object name);

  /// No description provided for @connectionSuccess.
  ///
  /// In zh, this message translates to:
  /// **'连接成功：已探测到 DSM Web API'**
  String get connectionSuccess;

  /// No description provided for @dsm6NotSupported.
  ///
  /// In zh, this message translates to:
  /// **'检测到当前设备为 {version}。本应用当前仅支持 DSM 7，暂不支持 DSM 6 登录。'**
  String dsm6NotSupported(Object version);

  /// No description provided for @switchedToNewAccount.
  ///
  /// In zh, this message translates to:
  /// **'已切换到新账号 / 新设备登录'**
  String get switchedToNewAccount;

  /// No description provided for @sessionExpired.
  ///
  /// In zh, this message translates to:
  /// **'登录状态已过期，请重新登录以恢复实时连接。'**
  String get sessionExpired;

  /// No description provided for @enterNasAddress.
  ///
  /// In zh, this message translates to:
  /// **'请输入 NAS 地址或域名'**
  String get enterNasAddress;

  /// No description provided for @enterPort.
  ///
  /// In zh, this message translates to:
  /// **'请输入端口'**
  String get enterPort;

  /// No description provided for @portRange.
  ///
  /// In zh, this message translates to:
  /// **'端口范围应为 1 - 65535'**
  String get portRange;

  /// No description provided for @enterUsername.
  ///
  /// In zh, this message translates to:
  /// **'请输入用户名'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get enterPassword;

  /// No description provided for @selectDeviceThenPassword.
  ///
  /// In zh, this message translates to:
  /// **'选择设备后输入密码即可登录'**
  String get selectDeviceThenPassword;

  /// No description provided for @deviceReadyEnterPassword.
  ///
  /// In zh, this message translates to:
  /// **'设备已就绪，输入密码即可登录'**
  String get deviceReadyEnterPassword;

  /// No description provided for @previewImage.
  ///
  /// In zh, this message translates to:
  /// **'预览图片'**
  String get previewImage;

  /// No description provided for @download.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get download;

  /// No description provided for @downloadAndOpen.
  ///
  /// In zh, this message translates to:
  /// **'下载并打开'**
  String get downloadAndOpen;

  /// No description provided for @startDownloading.
  ///
  /// In zh, this message translates to:
  /// **'开始下载 {name}'**
  String startDownloading(Object name);

  /// No description provided for @downloadCompleteOpen.
  ///
  /// In zh, this message translates to:
  /// **'开始下载 {name}，完成后可直接打开'**
  String downloadCompleteOpen(Object name);

  /// No description provided for @downloadTaskComplete.
  ///
  /// In zh, this message translates to:
  /// **'{title} 下载完成'**
  String downloadTaskComplete(Object title);

  /// No description provided for @confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除\\\"{name}\\\"吗？'**
  String confirmDelete(Object name);

  /// No description provided for @downloadDirSet.
  ///
  /// In zh, this message translates to:
  /// **'下载目录已设置为 {path}'**
  String downloadDirSet(Object path);

  /// No description provided for @selectUploadDir.
  ///
  /// In zh, this message translates to:
  /// **'选择上传目录'**
  String get selectUploadDir;

  /// No description provided for @loadFilesFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载文件失败：{error}'**
  String loadFilesFailed(Object error);

  /// No description provided for @selectCurrentDir.
  ///
  /// In zh, this message translates to:
  /// **'选择当前目录：{path}'**
  String selectCurrentDir(Object path);

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @discardChanges.
  ///
  /// In zh, this message translates to:
  /// **'放弃修改？'**
  String get discardChanges;

  /// No description provided for @discardChangesHint.
  ///
  /// In zh, this message translates to:
  /// **'当前文件有未保存修改，确定直接返回吗？'**
  String get discardChangesHint;

  /// No description provided for @discard.
  ///
  /// In zh, this message translates to:
  /// **'放弃'**
  String get discard;

  /// No description provided for @saveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get saveSuccess;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @savedToAlbum.
  ///
  /// In zh, this message translates to:
  /// **'已保存到相册'**
  String get savedToAlbum;

  /// No description provided for @loadingImage.
  ///
  /// In zh, this message translates to:
  /// **'正在加载图片...'**
  String get loadingImage;

  /// No description provided for @videoLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'视频加载失败'**
  String get videoLoadFailed;

  /// No description provided for @selectOneFile.
  ///
  /// In zh, this message translates to:
  /// **'请至少选择一个文件进行下载'**
  String get selectOneFile;

  /// No description provided for @addedDownloadTasks.
  ///
  /// In zh, this message translates to:
  /// **'已加入 {count} 个下载任务'**
  String addedDownloadTasks(Object count);

  /// No description provided for @batchDelete.
  ///
  /// In zh, this message translates to:
  /// **'批量删除'**
  String get batchDelete;

  /// No description provided for @confirmBatchDelete.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除选中的 {count} 项吗？'**
  String confirmBatchDelete(Object count);

  /// No description provided for @deletedCount.
  ///
  /// In zh, this message translates to:
  /// **'已删除 {count} 项'**
  String deletedCount(Object count);

  /// No description provided for @uploadTaskAdded.
  ///
  /// In zh, this message translates to:
  /// **'已加入上传任务'**
  String get uploadTaskAdded;

  /// No description provided for @videoPreviewHint.
  ///
  /// In zh, this message translates to:
  /// **'视频预览请从列表打开'**
  String get videoPreviewHint;

  /// No description provided for @pathCopied.
  ///
  /// In zh, this message translates to:
  /// **'路径已复制'**
  String get pathCopied;

  /// No description provided for @open.
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get open;

  /// No description provided for @backgroundTaskRunning.
  ///
  /// In zh, this message translates to:
  /// **'后台任务进行中'**
  String get backgroundTaskRunning;

  /// No description provided for @backgroundTaskRunningCount.
  ///
  /// In zh, this message translates to:
  /// **'后台任务进行中（{count}）'**
  String backgroundTaskRunningCount(Object count);

  /// No description provided for @taskComplete.
  ///
  /// In zh, this message translates to:
  /// **'{name}任务已完成'**
  String taskComplete(Object name);

  /// No description provided for @taskCompleteMultiple.
  ///
  /// In zh, this message translates to:
  /// **'{name}等{count}个后台任务已完成'**
  String taskCompleteMultiple(Object name, Object count);

  /// No description provided for @transfer.
  ///
  /// In zh, this message translates to:
  /// **'传输'**
  String get transfer;

  /// No description provided for @downloadAndOpenTitle.
  ///
  /// In zh, this message translates to:
  /// **'下载并打开'**
  String get downloadAndOpenTitle;

  /// No description provided for @processingLabel.
  ///
  /// In zh, this message translates to:
  /// **'处理中'**
  String get processingLabel;

  /// No description provided for @fileServicesTitle.
  ///
  /// In zh, this message translates to:
  /// **'文件服务'**
  String get fileServicesTitle;

  /// No description provided for @noFileServices.
  ///
  /// In zh, this message translates to:
  /// **'未获取到文件服务信息'**
  String get noFileServices;

  /// No description provided for @fileServiceEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get fileServiceEnabled;

  /// No description provided for @fileServiceDisabled.
  ///
  /// In zh, this message translates to:
  /// **'未启用'**
  String get fileServiceDisabled;

  /// No description provided for @defaultDeviceName.
  ///
  /// In zh, this message translates to:
  /// **'我的 NAS'**
  String get defaultDeviceName;

  /// No description provided for @splashTitle.
  ///
  /// In zh, this message translates to:
  /// **'群晖管家'**
  String get splashTitle;

  /// No description provided for @splashSubtitleReady.
  ///
  /// In zh, this message translates to:
  /// **'你的 DSM 7+ 掌上助手'**
  String get splashSubtitleReady;

  /// No description provided for @splashSubtitleRestoring.
  ///
  /// In zh, this message translates to:
  /// **'正在恢复你的连接与设备状态'**
  String get splashSubtitleRestoring;

  /// No description provided for @splashSubtitlePreparing.
  ///
  /// In zh, this message translates to:
  /// **'正在准备登录界面'**
  String get splashSubtitlePreparing;

  /// No description provided for @splashLoadingStart.
  ///
  /// In zh, this message translates to:
  /// **'正在启动...'**
  String get splashLoadingStart;

  /// No description provided for @splashLoadingEnter.
  ///
  /// In zh, this message translates to:
  /// **'正在进入...'**
  String get splashLoadingEnter;

  /// No description provided for @splashLoadingLogin.
  ///
  /// In zh, this message translates to:
  /// **'正在跳转登录...'**
  String get splashLoadingLogin;

  /// No description provided for @dashboardSectionApps.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get dashboardSectionApps;

  /// No description provided for @dashboardSectionAppsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'常用功能快捷入口'**
  String get dashboardSectionAppsSubtitle;

  /// No description provided for @dashboardContainerManagement.
  ///
  /// In zh, this message translates to:
  /// **'容器管理'**
  String get dashboardContainerManagement;

  /// No description provided for @dashboardContainerManagementDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看容器与 Compose 项目'**
  String get dashboardContainerManagementDesc;

  /// No description provided for @dashboardTransfers.
  ///
  /// In zh, this message translates to:
  /// **'传输中心'**
  String get dashboardTransfers;

  /// No description provided for @dashboardTransfersDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理最近上传下载任务'**
  String get dashboardTransfersDesc;

  /// No description provided for @dashboardControlPanel.
  ///
  /// In zh, this message translates to:
  /// **'控制面板'**
  String get dashboardControlPanel;

  /// No description provided for @dashboardControlPanelDesc.
  ///
  /// In zh, this message translates to:
  /// **'按优先级进入系统功能配置'**
  String get dashboardControlPanelDesc;

  /// No description provided for @dashboardInformationCenter.
  ///
  /// In zh, this message translates to:
  /// **'信息中心'**
  String get dashboardInformationCenter;

  /// No description provided for @dashboardInformationCenterDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看系统与存储详情'**
  String get dashboardInformationCenterDesc;

  /// No description provided for @dashboardPerformance.
  ///
  /// In zh, this message translates to:
  /// **'性能监控'**
  String get dashboardPerformance;

  /// No description provided for @dashboardPerformanceDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看 CPU 与内存状态'**
  String get dashboardPerformanceDesc;

  /// No description provided for @dashboardStorage.
  ///
  /// In zh, this message translates to:
  /// **'存储空间'**
  String get dashboardStorage;

  /// No description provided for @dashboardStorageEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂未获取到存储空间信息'**
  String get dashboardStorageEmpty;

  /// No description provided for @dashboardUptime.
  ///
  /// In zh, this message translates to:
  /// **'运行时间'**
  String get dashboardUptime;

  /// No description provided for @storageLabel.
  ///
  /// In zh, this message translates to:
  /// **'存储空间'**
  String get storageLabel;

  /// No description provided for @storageLabelN.
  ///
  /// In zh, this message translates to:
  /// **'存储空间 {n}'**
  String storageLabelN(Object n);

  /// No description provided for @usedSlashTotal.
  ///
  /// In zh, this message translates to:
  /// **'已用 {used} / 总计 {total}'**
  String usedSlashTotal(Object used, Object total);

  /// No description provided for @usedSlashUnknown.
  ///
  /// In zh, this message translates to:
  /// **'已用 {used} / 总计 --'**
  String usedSlashUnknown(Object used);

  /// No description provided for @unknownSlashTotal.
  ///
  /// In zh, this message translates to:
  /// **'已用 -- / 总计 {total}'**
  String unknownSlashTotal(Object total);

  /// No description provided for @usedUnknown.
  ///
  /// In zh, this message translates to:
  /// **'已用 -- / 总计 --'**
  String get usedUnknown;

  /// No description provided for @confirmDeleteName.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除\"{name}\"吗？'**
  String confirmDeleteName(Object name);

  /// No description provided for @downloadDirSetTo.
  ///
  /// In zh, this message translates to:
  /// **'下载目录已设置为 {path}'**
  String downloadDirSetTo(Object path);

  /// No description provided for @startDownloadingName.
  ///
  /// In zh, this message translates to:
  /// **'开始下载 {name}'**
  String startDownloadingName(Object name);

  /// No description provided for @previewText.
  ///
  /// In zh, this message translates to:
  /// **'预览文本'**
  String get previewText;

  /// No description provided for @previewNfo.
  ///
  /// In zh, this message translates to:
  /// **'预览 NFO'**
  String get previewNfo;

  /// 连接与存储副标题
  ///
  /// In zh, this message translates to:
  /// **'管理 NAS 连接和本地下载目录'**
  String get settingsConnectionStorageSubtitle;

  /// 服务器管理提示
  ///
  /// In zh, this message translates to:
  /// **'查看、切换、编辑和删除已保存设备'**
  String get serverManagementHint;

  /// 当前连接服务器
  ///
  /// In zh, this message translates to:
  /// **'当前设备：{name}'**
  String settingsCurrentServer(String name);

  /// 下载目录提示
  ///
  /// In zh, this message translates to:
  /// **'首次下载时选择，之后可在这里修改'**
  String get downloadDirectoryHint;

  /// 分享链接管理提示
  ///
  /// In zh, this message translates to:
  /// **'查看和复制已创建的分享链接'**
  String get sharingLinksHint;

  /// 绿色主题
  ///
  /// In zh, this message translates to:
  /// **'绿色'**
  String get themeColorGreen;

  /// 橙色主题
  ///
  /// In zh, this message translates to:
  /// **'橙色'**
  String get themeColorOrange;

  /// 紫色主题
  ///
  /// In zh, this message translates to:
  /// **'紫色'**
  String get themeColorPurple;

  /// 蓝色主题
  ///
  /// In zh, this message translates to:
  /// **'蓝色'**
  String get themeColorBlue;

  /// No description provided for @settingsConnectionStorage.
  ///
  /// In zh, this message translates to:
  /// **'连接与存储'**
  String get settingsConnectionStorage;

  /// No description provided for @settingsConnectionManagement.
  ///
  /// In zh, this message translates to:
  /// **'连接管理'**
  String get settingsConnectionManagement;

  /// No description provided for @settingsDownloadDirectory.
  ///
  /// In zh, this message translates to:
  /// **'下载目录'**
  String get settingsDownloadDirectory;

  /// No description provided for @settingsDownloadDirUpdated.
  ///
  /// In zh, this message translates to:
  /// **'下载目录已更新'**
  String get settingsDownloadDirUpdated;

  /// No description provided for @settingsAppearanceLanguage.
  ///
  /// In zh, this message translates to:
  /// **'外观与语言'**
  String get settingsAppearanceLanguage;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'调整应用显示风格和语言'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsAppSupport.
  ///
  /// In zh, this message translates to:
  /// **'应用与支持'**
  String get settingsAppSupport;

  /// No description provided for @settingsAppSupportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'保留常用支持入口，移除偏调试和低频功能'**
  String get settingsAppSupportSubtitle;

  /// No description provided for @settingsLogout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'清除当前会话和本地保存的登录态'**
  String get settingsLogoutSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'关于应用'**
  String get settingsAboutSubtitle;

  /// No description provided for @packageCenter.
  ///
  /// In zh, this message translates to:
  /// **'套件中心'**
  String get packageCenter;

  /// No description provided for @synologyPhotos.
  ///
  /// In zh, this message translates to:
  /// **'群晖照片'**
  String get synologyPhotos;

  /// No description provided for @packageCenterDesc.
  ///
  /// In zh, this message translates to:
  /// **'浏览和安装套件'**
  String get packageCenterDesc;

  /// No description provided for @packageAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get packageAll;

  /// No description provided for @packageInstalled.
  ///
  /// In zh, this message translates to:
  /// **'已安装'**
  String get packageInstalled;

  /// No description provided for @packageUpdatable.
  ///
  /// In zh, this message translates to:
  /// **'可更新'**
  String get packageUpdatable;

  /// No description provided for @packageTask.
  ///
  /// In zh, this message translates to:
  /// **'套件任务：{status}'**
  String packageTask(Object status);

  /// No description provided for @packageListFailed.
  ///
  /// In zh, this message translates to:
  /// **'套件列表加载失败'**
  String get packageListFailed;

  /// No description provided for @selectInstallLocation.
  ///
  /// In zh, this message translates to:
  /// **'选择安装位置'**
  String get selectInstallLocation;

  /// No description provided for @selectInstallLocationHint.
  ///
  /// In zh, this message translates to:
  /// **'先选择套件要安装到哪个存储卷'**
  String get selectInstallLocationHint;

  /// No description provided for @storeVersion.
  ///
  /// In zh, this message translates to:
  /// **'商店版本 {version}'**
  String storeVersion(Object version);

  /// No description provided for @installedVersion.
  ///
  /// In zh, this message translates to:
  /// **'已装 {version}'**
  String installedVersion(Object version);

  /// No description provided for @startRequestSent.
  ///
  /// In zh, this message translates to:
  /// **'已发送启动请求：{name}'**
  String startRequestSent(Object name);

  /// No description provided for @stopRequestSent.
  ///
  /// In zh, this message translates to:
  /// **'已发送停止请求：{name}'**
  String stopRequestSent(Object name);

  /// No description provided for @confirmUninstall.
  ///
  /// In zh, this message translates to:
  /// **'确认卸载'**
  String get confirmUninstall;

  /// No description provided for @confirmUninstallMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要卸载 {name} 吗？'**
  String confirmUninstallMessage(Object name);

  /// No description provided for @uninstallRequestSent.
  ///
  /// In zh, this message translates to:
  /// **'已发送卸载请求：{name}'**
  String uninstallRequestSent(Object name);

  /// No description provided for @confirmUpdateImpact.
  ///
  /// In zh, this message translates to:
  /// **'确认更新影响'**
  String get confirmUpdateImpact;

  /// No description provided for @start.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stop;

  /// No description provided for @uninstall.
  ///
  /// In zh, this message translates to:
  /// **'卸载'**
  String get uninstall;

  /// No description provided for @continueAction.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get continueAction;

  /// No description provided for @packageTaskComplete.
  ///
  /// In zh, this message translates to:
  /// **'{name} 安装/更新任务已完成或已提交'**
  String packageTaskComplete(Object name);

  /// No description provided for @packageInstallFailed.
  ///
  /// In zh, this message translates to:
  /// **'套件安装失败：{error}'**
  String packageInstallFailed(Object error);

  /// No description provided for @transfersTitle.
  ///
  /// In zh, this message translates to:
  /// **'传输中心'**
  String get transfersTitle;

  /// No description provided for @clearCompleted.
  ///
  /// In zh, this message translates to:
  /// **'删除已完成记录'**
  String get clearCompleted;

  /// No description provided for @clearFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败记录'**
  String get clearFailed;

  /// No description provided for @filterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get filterActive;

  /// No description provided for @filterCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get filterCompleted;

  /// No description provided for @filterFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get filterFailed;

  /// No description provided for @deleteCompleted.
  ///
  /// In zh, this message translates to:
  /// **'清除已完成'**
  String get deleteCompleted;

  /// No description provided for @deleteFailedRecords.
  ///
  /// In zh, this message translates to:
  /// **'清除失败记录'**
  String get deleteFailedRecords;

  /// No description provided for @openedWithSystem.
  ///
  /// In zh, this message translates to:
  /// **'已调用系统打开方式'**
  String get openedWithSystem;

  /// No description provided for @directory.
  ///
  /// In zh, this message translates to:
  /// **'目录：{path}'**
  String directory(Object path);

  /// No description provided for @openDirectory.
  ///
  /// In zh, this message translates to:
  /// **'打开目录'**
  String get openDirectory;

  /// No description provided for @removeRecord.
  ///
  /// In zh, this message translates to:
  /// **'移除记录'**
  String get removeRecord;

  /// No description provided for @reasonCopied.
  ///
  /// In zh, this message translates to:
  /// **'失败原因已复制'**
  String get reasonCopied;

  /// No description provided for @containerSuccess.
  ///
  /// In zh, this message translates to:
  /// **'{action}容器成功：{name}'**
  String containerSuccess(Object action, Object name);

  /// No description provided for @containerFailed.
  ///
  /// In zh, this message translates to:
  /// **'{action}容器失败：{error}'**
  String containerFailed(Object action, Object error);

  /// No description provided for @containerManagement.
  ///
  /// In zh, this message translates to:
  /// **'容器管理'**
  String get containerManagement;

  /// No description provided for @containerAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get containerAll;

  /// No description provided for @containerRunning.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get containerRunning;

  /// 已停止状态
  ///
  /// In zh, this message translates to:
  /// **'已停止'**
  String get containerStopped;

  /// No description provided for @createNew.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get createNew;

  /// No description provided for @filterLatest.
  ///
  /// In zh, this message translates to:
  /// **'latest'**
  String get filterLatest;

  /// No description provided for @filterOtherTags.
  ///
  /// In zh, this message translates to:
  /// **'其他标签'**
  String get filterOtherTags;

  /// No description provided for @sortBy.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get sortBy;

  /// No description provided for @sortNameAsc.
  ///
  /// In zh, this message translates to:
  /// **'名称 A-Z'**
  String get sortNameAsc;

  /// No description provided for @sortNameDesc.
  ///
  /// In zh, this message translates to:
  /// **'名称 Z-A'**
  String get sortNameDesc;

  /// No description provided for @sortTagAsc.
  ///
  /// In zh, this message translates to:
  /// **'标签 A-Z'**
  String get sortTagAsc;

  /// No description provided for @sortTagDesc.
  ///
  /// In zh, this message translates to:
  /// **'标签 Z-A'**
  String get sortTagDesc;

  /// No description provided for @sortSizeDesc.
  ///
  /// In zh, this message translates to:
  /// **'大小 从大到小'**
  String get sortSizeDesc;

  /// No description provided for @sortSizeAsc.
  ///
  /// In zh, this message translates to:
  /// **'大小 从小到大'**
  String get sortSizeAsc;

  /// No description provided for @restart.
  ///
  /// In zh, this message translates to:
  /// **'重启'**
  String get restart;

  /// No description provided for @forceStop.
  ///
  /// In zh, this message translates to:
  /// **'强制停止'**
  String get forceStop;

  /// No description provided for @ports.
  ///
  /// In zh, this message translates to:
  /// **'端口：{ports}'**
  String ports(Object ports);

  /// No description provided for @viewAction.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get viewAction;

  /// No description provided for @performanceMonitor.
  ///
  /// In zh, this message translates to:
  /// **'性能监控'**
  String get performanceMonitor;

  /// No description provided for @clearHistoryAndRefresh.
  ///
  /// In zh, this message translates to:
  /// **'清除历史并刷新'**
  String get clearHistoryAndRefresh;

  /// No description provided for @overview.
  ///
  /// In zh, this message translates to:
  /// **'概览'**
  String get overview;

  /// No description provided for @network.
  ///
  /// In zh, this message translates to:
  /// **'网络'**
  String get network;

  /// No description provided for @disk.
  ///
  /// In zh, this message translates to:
  /// **'磁盘'**
  String get disk;

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败: {error}'**
  String loadFailed(Object error);

  /// No description provided for @connectionManagement.
  ///
  /// In zh, this message translates to:
  /// **'连接管理'**
  String get connectionManagement;

  /// No description provided for @noSavedDevices.
  ///
  /// In zh, this message translates to:
  /// **'还没有保存的设备'**
  String get noSavedDevices;

  /// No description provided for @addDeviceHint.
  ///
  /// In zh, this message translates to:
  /// **'先添加一个 NAS 连接，后面就可以在这里快速切换。'**
  String get addDeviceHint;

  /// No description provided for @addNewConnection.
  ///
  /// In zh, this message translates to:
  /// **'添加新连接'**
  String get addNewConnection;

  /// No description provided for @savedConnections.
  ///
  /// In zh, this message translates to:
  /// **'已保存的连接'**
  String get savedConnections;

  /// No description provided for @noCurrentDevice.
  ///
  /// In zh, this message translates to:
  /// **'当前未连接设备'**
  String get noCurrentDevice;

  /// No description provided for @currentDeviceName.
  ///
  /// In zh, this message translates to:
  /// **'当前设备：{name}'**
  String currentDeviceName(Object name);

  /// No description provided for @confirmDeleteDevice.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除设备「{name}」吗？'**
  String confirmDeleteDevice(Object name);

  /// No description provided for @recentTransfers.
  ///
  /// In zh, this message translates to:
  /// **'最近传输'**
  String get recentTransfers;

  /// No description provided for @noTransfersHint.
  ///
  /// In zh, this message translates to:
  /// **'还没有任务，新的上传和下载会显示在这里'**
  String get noTransfersHint;

  /// No description provided for @transfersHint.
  ///
  /// In zh, this message translates to:
  /// **'优先看进行中和失败任务，已完成记录可以随时清理'**
  String get transfersHint;

  /// No description provided for @noTransfersInFilter.
  ///
  /// In zh, this message translates to:
  /// **'这个筛选下暂时没有传输任务'**
  String get noTransfersInFilter;

  /// No description provided for @transfersAppearHere.
  ///
  /// In zh, this message translates to:
  /// **'新的上传、下载、失败重试都会出现在这里。'**
  String get transfersAppearHere;

  /// No description provided for @upload.
  ///
  /// In zh, this message translates to:
  /// **'上传'**
  String get upload;

  /// No description provided for @statusQueued.
  ///
  /// In zh, this message translates to:
  /// **'排队中'**
  String get statusQueued;

  /// No description provided for @statusRunning.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get statusRunning;

  /// No description provided for @statusPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get statusPaused;

  /// No description provided for @statusCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get statusFailed;

  /// No description provided for @uploadTo.
  ///
  /// In zh, this message translates to:
  /// **'上传到 {path}'**
  String uploadTo(Object path);

  /// No description provided for @saveTo.
  ///
  /// In zh, this message translates to:
  /// **'保存到 {path}'**
  String saveTo(Object path);

  /// No description provided for @moreActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get moreActions;

  /// No description provided for @collapseDetails.
  ///
  /// In zh, this message translates to:
  /// **'收起详情'**
  String get collapseDetails;

  /// No description provided for @viewDetails.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get viewDetails;

  /// No description provided for @copyErrorReason.
  ///
  /// In zh, this message translates to:
  /// **'复制失败原因'**
  String get copyErrorReason;

  /// No description provided for @copyPath.
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get copyPath;

  /// No description provided for @errorCopied.
  ///
  /// In zh, this message translates to:
  /// **'失败原因已复制'**
  String get errorCopied;

  /// No description provided for @copyReason.
  ///
  /// In zh, this message translates to:
  /// **'复制原因'**
  String get copyReason;

  /// No description provided for @removeRecordAndFile.
  ///
  /// In zh, this message translates to:
  /// **'删除记录和文件'**
  String get removeRecordAndFile;

  /// No description provided for @resultLabel.
  ///
  /// In zh, this message translates to:
  /// **'结果：{message}'**
  String resultLabel(Object message);

  /// No description provided for @reasonLabel.
  ///
  /// In zh, this message translates to:
  /// **'原因：{message}'**
  String reasonLabel(Object message);

  /// No description provided for @networkTitle.
  ///
  /// In zh, this message translates to:
  /// **'网络'**
  String get networkTitle;

  /// No description provided for @networkInterfaces.
  ///
  /// In zh, this message translates to:
  /// **'网络接口'**
  String get networkInterfaces;

  /// No description provided for @proxySettings.
  ///
  /// In zh, this message translates to:
  /// **'代理设置'**
  String get proxySettings;

  /// No description provided for @gatewayInfo.
  ///
  /// In zh, this message translates to:
  /// **'网关信息'**
  String get gatewayInfo;

  /// No description provided for @networkGeneral.
  ///
  /// In zh, this message translates to:
  /// **'常规'**
  String get networkGeneral;

  /// No description provided for @noNetworkInfo.
  ///
  /// In zh, this message translates to:
  /// **'暂无网络信息'**
  String get noNetworkInfo;

  /// No description provided for @hostname.
  ///
  /// In zh, this message translates to:
  /// **'主机名'**
  String get hostname;

  /// No description provided for @defaultGateway.
  ///
  /// In zh, this message translates to:
  /// **'默认网关'**
  String get defaultGateway;

  /// No description provided for @ipv6Gateway.
  ///
  /// In zh, this message translates to:
  /// **'IPv6 网关'**
  String get ipv6Gateway;

  /// No description provided for @dnsPrimary.
  ///
  /// In zh, this message translates to:
  /// **'首选 DNS'**
  String get dnsPrimary;

  /// No description provided for @dnsSecondary.
  ///
  /// In zh, this message translates to:
  /// **'备用 DNS'**
  String get dnsSecondary;

  /// No description provided for @manual.
  ///
  /// In zh, this message translates to:
  /// **'手动'**
  String get manual;

  /// No description provided for @workgroup.
  ///
  /// In zh, this message translates to:
  /// **'工作组'**
  String get workgroup;

  /// No description provided for @connected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In zh, this message translates to:
  /// **'未连接'**
  String get disconnected;

  /// No description provided for @subnetMask.
  ///
  /// In zh, this message translates to:
  /// **'子网掩码'**
  String get subnetMask;

  /// No description provided for @dhcp.
  ///
  /// In zh, this message translates to:
  /// **'DHCP'**
  String get dhcp;

  /// No description provided for @ipv6Address.
  ///
  /// In zh, this message translates to:
  /// **'IPv6 地址'**
  String get ipv6Address;

  /// No description provided for @interface.
  ///
  /// In zh, this message translates to:
  /// **'接口'**
  String get interface;

  /// No description provided for @address.
  ///
  /// In zh, this message translates to:
  /// **'地址'**
  String get address;

  /// No description provided for @enabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get disabled;

  /// No description provided for @coreFeatures.
  ///
  /// In zh, this message translates to:
  /// **'核心功能'**
  String get coreFeatures;

  /// No description provided for @systemManagement.
  ///
  /// In zh, this message translates to:
  /// **'系统管理'**
  String get systemManagement;

  /// No description provided for @infoCenterSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'系统信息与状态总览'**
  String get infoCenterSubtitle;

  /// No description provided for @updateStatusSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'系统版本与更新检查'**
  String get updateStatusSubtitle;

  /// No description provided for @externalAccessSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'DDNS 与远程连接'**
  String get externalAccessSubtitle;

  /// No description provided for @indexServiceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'缩图质量与索引重建'**
  String get indexServiceSubtitle;

  /// No description provided for @taskSchedulerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'定时任务与执行管理'**
  String get taskSchedulerSubtitle;

  /// No description provided for @externalDevicesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'USB 与存储设备管理'**
  String get externalDevicesSubtitle;

  /// No description provided for @sharedFoldersSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'文件共享与权限设置'**
  String get sharedFoldersSubtitle;

  /// No description provided for @userGroupsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'账户与权限管理'**
  String get userGroupsSubtitle;

  /// No description provided for @fileServicesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'SMB / NFS / FTP / SFTP'**
  String get fileServicesSubtitle;

  /// No description provided for @networkSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'接口、代理与网关'**
  String get networkSubtitle;

  /// No description provided for @updateStatus.
  ///
  /// In zh, this message translates to:
  /// **'更新状态'**
  String get updateStatus;

  /// No description provided for @terminalTitle.
  ///
  /// In zh, this message translates to:
  /// **'终端设置'**
  String get terminalTitle;

  /// No description provided for @terminalSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'SSH 与 Telnet 服务'**
  String get terminalSubtitle;

  /// No description provided for @fileServicesStatusSummary.
  ///
  /// In zh, this message translates to:
  /// **'文件服务状态总览'**
  String get fileServicesStatusSummary;

  /// No description provided for @fileServicesEnabledCount.
  ///
  /// In zh, this message translates to:
  /// **'已启用 {enabledCount} / 共 {totalCount}'**
  String fileServicesEnabledCount(Object enabledCount, Object totalCount);

  /// No description provided for @serviceVersion.
  ///
  /// In zh, this message translates to:
  /// **'服务版本'**
  String get serviceVersion;

  /// No description provided for @servicePort.
  ///
  /// In zh, this message translates to:
  /// **'服务端口'**
  String get servicePort;

  /// No description provided for @nfsV4Domain.
  ///
  /// In zh, this message translates to:
  /// **'NFSv4 域名'**
  String get nfsV4Domain;

  /// No description provided for @ftpsEnabled.
  ///
  /// In zh, this message translates to:
  /// **'FTPS 已启用'**
  String get ftpsEnabled;

  /// No description provided for @smbTransferLogEnabled.
  ///
  /// In zh, this message translates to:
  /// **'SMB 传输日志已启用'**
  String get smbTransferLogEnabled;

  /// No description provided for @smbTransferLogDisabled.
  ///
  /// In zh, this message translates to:
  /// **'SMB 传输日志已禁用'**
  String get smbTransferLogDisabled;

  /// No description provided for @smbTransferLog.
  ///
  /// In zh, this message translates to:
  /// **'SMB 传输日志'**
  String get smbTransferLog;

  /// No description provided for @smbTransferLogSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'记录 SMB 文件访问与操作'**
  String get smbTransferLogSubtitle;

  /// No description provided for @afpTransferLogEnabled.
  ///
  /// In zh, this message translates to:
  /// **'AFP 传输日志已启用'**
  String get afpTransferLogEnabled;

  /// No description provided for @afpTransferLogDisabled.
  ///
  /// In zh, this message translates to:
  /// **'AFP 传输日志已禁用'**
  String get afpTransferLogDisabled;

  /// No description provided for @afpTransferLog.
  ///
  /// In zh, this message translates to:
  /// **'AFP 传输日志'**
  String get afpTransferLog;

  /// No description provided for @afpTransferLogSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'记录 AFP 文件访问与操作'**
  String get afpTransferLogSubtitle;

  /// No description provided for @transferLogTitle.
  ///
  /// In zh, this message translates to:
  /// **'传输日志设置'**
  String get transferLogTitle;

  /// No description provided for @transferLogSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'配置各协议的日志记录级别'**
  String get transferLogSubtitle;

  /// No description provided for @needEnableServiceFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先启用该服务'**
  String get needEnableServiceFirst;

  /// No description provided for @setLogLevel.
  ///
  /// In zh, this message translates to:
  /// **'设置日志级别'**
  String get setLogLevel;

  /// No description provided for @userAccountTab.
  ///
  /// In zh, this message translates to:
  /// **'用户账户'**
  String get userAccountTab;

  /// No description provided for @userGroupTab.
  ///
  /// In zh, this message translates to:
  /// **'用户组'**
  String get userGroupTab;

  /// No description provided for @noUsers.
  ///
  /// In zh, this message translates to:
  /// **'暂无用户'**
  String get noUsers;

  /// No description provided for @noGroups.
  ///
  /// In zh, this message translates to:
  /// **'暂无用户组'**
  String get noGroups;

  /// No description provided for @failedToGetLogLevel.
  ///
  /// In zh, this message translates to:
  /// **'获取日志级别失败'**
  String get failedToGetLogLevel;

  /// No description provided for @logLevelSettingsSaved.
  ///
  /// In zh, this message translates to:
  /// **'日志级别设置已保存'**
  String get logLevelSettingsSaved;

  /// No description provided for @failedToSave.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get failedToSave;

  /// No description provided for @transferLogLevel.
  ///
  /// In zh, this message translates to:
  /// **'传输日志级别'**
  String get transferLogLevel;

  /// No description provided for @applyChanges.
  ///
  /// In zh, this message translates to:
  /// **'应用更改'**
  String get applyChanges;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// No description provided for @noHistory.
  ///
  /// In zh, this message translates to:
  /// **'暂无历史记录'**
  String get noHistory;

  /// No description provided for @failedToGetLogSettings.
  ///
  /// In zh, this message translates to:
  /// **'获取日志设置失败'**
  String get failedToGetLogSettings;

  /// No description provided for @saving.
  ///
  /// In zh, this message translates to:
  /// **'保存中…'**
  String get saving;

  /// No description provided for @logLevelCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get logLevelCreate;

  /// No description provided for @logLevelWrite.
  ///
  /// In zh, this message translates to:
  /// **'写入'**
  String get logLevelWrite;

  /// No description provided for @logLevelMove.
  ///
  /// In zh, this message translates to:
  /// **'移动'**
  String get logLevelMove;

  /// No description provided for @logLevelDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get logLevelDelete;

  /// No description provided for @logLevelRead.
  ///
  /// In zh, this message translates to:
  /// **'读取'**
  String get logLevelRead;

  /// 日志级别-重命名
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get logLevelRename;

  /// 用户状态-已过期
  ///
  /// In zh, this message translates to:
  /// **'已过期'**
  String get statusExpired;

  /// 用户状态-正常
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get statusNormal;

  /// 用户状态-已禁用
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get statusDisabled;

  /// 用户信息更新成功提示
  ///
  /// In zh, this message translates to:
  /// **'用户信息已更新'**
  String get userInfoUpdated;

  /// 保存失败提示
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get saveFailed;

  /// 启用用户按钮/标题
  ///
  /// In zh, this message translates to:
  /// **'启用用户'**
  String get enableUser;

  /// 禁用用户按钮/标题
  ///
  /// In zh, this message translates to:
  /// **'禁用用户'**
  String get disableUser;

  /// 确认禁用用户对话框
  ///
  /// In zh, this message translates to:
  /// **'确定要禁用用户 \"{name}\" 吗？禁用后该用户将无法登录。'**
  String confirmDisableUser(String name);

  /// 确认启用用户对话框
  ///
  /// In zh, this message translates to:
  /// **'确定要启用用户 \"{name}\" 吗？'**
  String confirmEnableUser(String name);

  /// 用户已禁用提示
  ///
  /// In zh, this message translates to:
  /// **'用户已禁用'**
  String get userDisabled;

  /// 用户已启用提示
  ///
  /// In zh, this message translates to:
  /// **'用户已启用'**
  String get userEnabled;

  /// 操作失败通用提示
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get operationFailed;

  /// 重置密码按钮/标题
  ///
  /// In zh, this message translates to:
  /// **'重置密码'**
  String get resetPassword;

  /// 重置密码对话框标题
  ///
  /// In zh, this message translates to:
  /// **'为用户 \"{name}\" 设置新密码'**
  String resetPasswordDialogTitle(String name);

  /// 新密码输入框标签
  ///
  /// In zh, this message translates to:
  /// **'新密码'**
  String get newPassword;

  /// 密码为空提示
  ///
  /// In zh, this message translates to:
  /// **'密码不能为空'**
  String get passwordCannotBeEmpty;

  /// 密码重置成功提示
  ///
  /// In zh, this message translates to:
  /// **'密码已重置'**
  String get passwordResetSuccess;

  /// 重置密码失败提示
  ///
  /// In zh, this message translates to:
  /// **'重置密码失败'**
  String get resetPasswordFailed;

  /// 用户名标签
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get userName;

  /// 描述标签
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get description;

  /// 邮箱标签
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get email;

  /// 群组名称标签
  ///
  /// In zh, this message translates to:
  /// **'群组名称'**
  String get groupName;

  /// 群组成员数量
  ///
  /// In zh, this message translates to:
  /// **'{count} 个成员'**
  String memberCount(int count);

  /// 查看群组成员需在DSM中操作的提示
  ///
  /// In zh, this message translates to:
  /// **'查看群组成员列表需要在 DSM Web 界面中操作'**
  String get viewGroupMembersRequiresDsm;

  /// 无数据占位
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get none;

  /// 重新加载按钮
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get reload;

  /// 共享文件夹加载失败错误状态标题
  ///
  /// In zh, this message translates to:
  /// **'共享文件夹加载失败'**
  String get sharedFoldersLoadFailed;

  /// 名称标签
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get name;

  /// 路径标签
  ///
  /// In zh, this message translates to:
  /// **'路径'**
  String get path;

  /// 空间使用标签
  ///
  /// In zh, this message translates to:
  /// **'空间使用'**
  String get spaceUsage;

  /// 配额标签
  ///
  /// In zh, this message translates to:
  /// **'配额'**
  String get quota;

  /// 特性标签
  ///
  /// In zh, this message translates to:
  /// **'特性'**
  String get features;

  /// 加密状态标签
  ///
  /// In zh, this message translates to:
  /// **'加密'**
  String get statusEncrypted;

  /// 隐藏状态标签
  ///
  /// In zh, this message translates to:
  /// **'隐藏'**
  String get statusHidden;

  /// 特性标签-回收站
  ///
  /// In zh, this message translates to:
  /// **'回收站'**
  String get featureRecycleBin;

  /// 特性标签-只读
  ///
  /// In zh, this message translates to:
  /// **'只读'**
  String get featureReadOnly;

  /// 特性标签-文件压缩
  ///
  /// In zh, this message translates to:
  /// **'文件压缩'**
  String get featureFileCompression;

  /// 特性标签-数据完整性保护
  ///
  /// In zh, this message translates to:
  /// **'数据完整性保护'**
  String get featureDataIntegrityProtection;

  /// 特性标签-高级权限
  ///
  /// In zh, this message translates to:
  /// **'高级权限'**
  String get featureAdvancedPermissions;

  /// 特性标签-快照
  ///
  /// In zh, this message translates to:
  /// **'快照'**
  String get featureSnapshot;

  /// 特性标签-移动中
  ///
  /// In zh, this message translates to:
  /// **'移动中'**
  String get featureMoving;

  /// 仪表盘搜索框占位符
  ///
  /// In zh, this message translates to:
  /// **'搜索设备、功能或页面'**
  String get searchDeviceOrPage;

  /// 实时连接状态-准备中
  ///
  /// In zh, this message translates to:
  /// **'实时服务准备中'**
  String get realtimePreparing;

  /// 实时连接状态-连接中
  ///
  /// In zh, this message translates to:
  /// **'实时连接中'**
  String get realtimeConnecting;

  /// 实时连接状态-重连中
  ///
  /// In zh, this message translates to:
  /// **'实时重连中'**
  String get realtimeReconnecting;

  /// 实时连接状态-已连接
  ///
  /// In zh, this message translates to:
  /// **'实时已连接'**
  String get realtimeConnected;

  /// 系统版本不可用占位
  ///
  /// In zh, this message translates to:
  /// **'暂未获取到系统版本'**
  String get systemVersionNotAvailable;

  /// 分享按钮
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// 错误内容已复制提示
  ///
  /// In zh, this message translates to:
  /// **'错误内容已复制'**
  String get errorContentCopied;

  /// 日志中心加载失败错误状态标题
  ///
  /// In zh, this message translates to:
  /// **'日志中心加载失败'**
  String get logCenterLoadFailed;

  /// 复制错误按钮
  ///
  /// In zh, this message translates to:
  /// **'复制错误'**
  String get copyError;

  /// 应用日志文件名标签
  ///
  /// In zh, this message translates to:
  /// **'应用日志：{fileName}'**
  String appLogFileLabel(String fileName);

  /// 容器管理标签页
  ///
  /// In zh, this message translates to:
  /// **'容器'**
  String get containerTab;

  /// Compose项目标签页
  ///
  /// In zh, this message translates to:
  /// **'Compose'**
  String get composeTab;

  /// 镜像标签页
  ///
  /// In zh, this message translates to:
  /// **'镜像'**
  String get imageTab;

  /// 当前数据源标签
  ///
  /// In zh, this message translates to:
  /// **'当前数据源'**
  String get currentDataSource;

  /// 群晖数据源描述
  ///
  /// In zh, this message translates to:
  /// **'第一版默认使用群晖原生容器数据源。'**
  String get dsmDataSourceDescription;

  /// dpanel数据源描述
  ///
  /// In zh, this message translates to:
  /// **'dpanel 适配预留中，当前先展示模块骨架。'**
  String get dpanelDataSourceDescription;

  /// dpanel数据源开发中提示
  ///
  /// In zh, this message translates to:
  /// **'dpanel 数据源开发中，当前先使用群晖数据源。'**
  String get dpanelDataSourceDeveloping;

  /// 容器数据加载失败
  ///
  /// In zh, this message translates to:
  /// **'容器数据加载失败'**
  String get containerDataLoadFailed;

  /// 请稍后重试
  ///
  /// In zh, this message translates to:
  /// **'请稍后重试'**
  String get pleaseRetryLater;

  /// 暂无容器数据
  ///
  /// In zh, this message translates to:
  /// **'暂无容器数据'**
  String get noContainerData;

  /// 暂无Compose项目
  ///
  /// In zh, this message translates to:
  /// **'暂无 Compose 项目'**
  String get noComposeProjects;

  /// 使用DSM原生Compose项目
  ///
  /// In zh, this message translates to:
  /// **'当前使用 DSM / Container Manager 原生 Compose 项目数据。'**
  String get usingDsmComposeProjects;

  /// 暂无镜像数据
  ///
  /// In zh, this message translates to:
  /// **'暂无镜像数据'**
  String get noImageData;

  /// 运行中状态
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get running;

  /// 构建失败状态
  ///
  /// In zh, this message translates to:
  /// **'构建失败'**
  String get buildFailed;

  /// 失败状态
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get failed;

  /// 未知状态
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get containerUnknown;

  /// 查看按钮
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get view;

  /// 新建按钮
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get create;

  /// 镜像ID标签
  ///
  /// In zh, this message translates to:
  /// **'镜像 ID'**
  String get imageId;

  /// 容器数量
  ///
  /// In zh, this message translates to:
  /// **'{count} 个容器'**
  String containerCount(int count);

  /// 未获取到DSM Compose项目
  ///
  /// In zh, this message translates to:
  /// **'当前未获取到 DSM Compose 项目。'**
  String get noDsmComposeProjects;

  /// 更多操作菜单提示
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get moreOptions;

  /// 外部访问加载失败
  ///
  /// In zh, this message translates to:
  /// **'外部访问加载失败'**
  String get externalAccessLoadFailed;

  /// 未命名设备
  ///
  /// In zh, this message translates to:
  /// **'未命名设备'**
  String get unnamedDevice;

  /// 未识别型号
  ///
  /// In zh, this message translates to:
  /// **'未识别型号'**
  String get unrecognizedModel;

  /// 当前不可弹出
  ///
  /// In zh, this message translates to:
  /// **'当前不可弹出'**
  String get currentlyNotEjectable;

  /// 有更新徽章
  ///
  /// In zh, this message translates to:
  /// **'有更新'**
  String get updateAvailable;

  /// 终端设置
  ///
  /// In zh, this message translates to:
  /// **'终端设置'**
  String get terminalSettings;

  /// 终端设置副标题
  ///
  /// In zh, this message translates to:
  /// **'SSH 与 Telnet 服务'**
  String get terminalSettingsSubtitle;

  /// 电源管理
  ///
  /// In zh, this message translates to:
  /// **'电源管理'**
  String get powerManagement;

  /// 电源管理副标题
  ///
  /// In zh, this message translates to:
  /// **'关机与重启'**
  String get powerManagementSubtitle;

  /// 确认删除下载任务
  ///
  /// In zh, this message translates to:
  /// **'确定要删除 \"{title}\" 吗？'**
  String confirmDeleteDownloadTask(String title);

  /// 加载下载任务失败
  ///
  /// In zh, this message translates to:
  /// **'加载下载任务失败'**
  String get downloadTasksLoadFailed;

  /// 日志查看功能开发中提示
  ///
  /// In zh, this message translates to:
  /// **'日志查看功能开发中'**
  String get logViewerComingSoon;

  /// 创建分享链接页面标题
  ///
  /// In zh, this message translates to:
  /// **'创建分享链接'**
  String get shareLinkCreate;

  /// 链接复制成功提示
  ///
  /// In zh, this message translates to:
  /// **'链接已复制'**
  String get shareLinkCopied;

  /// 分享链接过期时间标签
  ///
  /// In zh, this message translates to:
  /// **'过期时间'**
  String get shareLinkExpireDate;

  /// 永不过期选项
  ///
  /// In zh, this message translates to:
  /// **'永不过期'**
  String get shareLinkNoLimit;

  /// 允许访问次数标签
  ///
  /// In zh, this message translates to:
  /// **'允许访问次数'**
  String get shareLinkAccessCount;

  /// 允许访问次数提示
  ///
  /// In zh, this message translates to:
  /// **'0 = 无限制'**
  String get shareLinkAccessCountHint;

  /// 保存修改按钮
  ///
  /// In zh, this message translates to:
  /// **'保存修改'**
  String get shareLinkSaveChanges;

  /// 分享链接保存成功提示
  ///
  /// In zh, this message translates to:
  /// **'分享链接设置已保存'**
  String get shareLinkSaveSuccess;

  /// 删除分享链接按钮
  ///
  /// In zh, this message translates to:
  /// **'删除链接'**
  String get shareLinkDelete;

  /// 确认删除分享链接对话框
  ///
  /// In zh, this message translates to:
  /// **'确定要取消此分享链接吗？'**
  String get shareLinkDeleteConfirm;

  /// 分享链接已删除提示
  ///
  /// In zh, this message translates to:
  /// **'分享链接已取消'**
  String get shareLinkDeleted;

  /// 分享链接管理页面标题
  ///
  /// In zh, this message translates to:
  /// **'分享链接'**
  String get sharingLinksTitle;

  /// 空状态提示
  ///
  /// In zh, this message translates to:
  /// **'暂无分享链接'**
  String get sharingLinksEmpty;

  /// 空状态副标题
  ///
  /// In zh, this message translates to:
  /// **'在文件页面创建分享链接后可在此管理'**
  String get sharingLinksEmptyHint;

  /// 加载失败文字
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get sharingLinksLoadFailed;

  /// 重试按钮
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get sharingLinksRetry;

  /// 清除无效链接按钮
  ///
  /// In zh, this message translates to:
  /// **'清除无效链接'**
  String get sharingLinksClearInvalid;

  /// 确认清除无效链接对话框
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有无效的分享链接吗？'**
  String get sharingLinksClearInvalidConfirm;

  /// 清除成功提示
  ///
  /// In zh, this message translates to:
  /// **'已清除无效链接'**
  String get sharingLinksClearSuccess;

  /// 编辑分享链接标题
  ///
  /// In zh, this message translates to:
  /// **'编辑分享链接'**
  String get sharingLinksEdit;

  /// 删除分享链接标题
  ///
  /// In zh, this message translates to:
  /// **'删除分享链接'**
  String get sharingLinksDelete;

  /// 确认删除对话框
  ///
  /// In zh, this message translates to:
  /// **'确定要删除「{name}」吗？'**
  String sharingLinksDeleteConfirm(String name);

  /// 删除成功提示
  ///
  /// In zh, this message translates to:
  /// **'已删除'**
  String get sharingLinksDeleted;

  /// 保存成功提示
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get sharingLinksSaveSuccess;

  /// 保存失败提示
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{error}'**
  String sharingLinksSaveFailed(String error);

  /// 清除失败提示
  ///
  /// In zh, this message translates to:
  /// **'清除失败：{error}'**
  String sharingLinksClearFailed(String error);

  /// 删除失败提示
  ///
  /// In zh, this message translates to:
  /// **'删除失败：{error}'**
  String sharingLinksDeleteFailed(String error);

  /// 复制成功提示
  ///
  /// In zh, this message translates to:
  /// **'链接已复制'**
  String get sharingLinksCopied;

  /// 访问次数标签
  ///
  /// In zh, this message translates to:
  /// **'访问次数'**
  String get sharingLinksAccessCount;

  /// 不限次数
  ///
  /// In zh, this message translates to:
  /// **'不限次数'**
  String get sharingLinksAccessCountUnlimited;

  /// 剩余次数
  ///
  /// In zh, this message translates to:
  /// **'剩余 {count} 次'**
  String sharingLinksAccessCountRemaining(int count);

  /// 有效期截止日期标签
  ///
  /// In zh, this message translates to:
  /// **'有效期截止日期'**
  String get sharingLinksExpireDate;

  /// 生效开始日期标签
  ///
  /// In zh, this message translates to:
  /// **'生效开始日期'**
  String get sharingLinksAvailableDate;

  /// 不限制日期
  ///
  /// In zh, this message translates to:
  /// **'不限制'**
  String get sharingLinksExpireDateNone;

  /// 永久有效
  ///
  /// In zh, this message translates to:
  /// **'永久'**
  String get sharingLinksPermanent;

  /// 所有者标签
  ///
  /// In zh, this message translates to:
  /// **'所有者'**
  String get sharingLinksOwner;

  /// 状态：有效
  ///
  /// In zh, this message translates to:
  /// **'有效'**
  String get sharingLinksStatusValid;

  /// 状态：已过期
  ///
  /// In zh, this message translates to:
  /// **'已过期'**
  String get sharingLinksStatusExpired;

  /// 安全提示
  ///
  /// In zh, this message translates to:
  /// **'安全共享请到 Web 界面操作'**
  String get sharingLinksSecurityHint;

  /// 不限制
  ///
  /// In zh, this message translates to:
  /// **'不限制'**
  String get sharingLinksNoLimit;

  /// No description provided for @downloadTargetDir.
  ///
  /// In zh, this message translates to:
  /// **'目标文件夹'**
  String get downloadTargetDir;

  /// No description provided for @downloadTaskWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待中'**
  String get downloadTaskWaiting;

  /// No description provided for @downloadTaskDownloading.
  ///
  /// In zh, this message translates to:
  /// **'下载中'**
  String get downloadTaskDownloading;

  /// No description provided for @downloadTaskPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get downloadTaskPaused;

  /// No description provided for @downloadTaskFinishing.
  ///
  /// In zh, this message translates to:
  /// **'即将完成'**
  String get downloadTaskFinishing;

  /// No description provided for @downloadTaskFinished.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get downloadTaskFinished;

  /// No description provided for @downloadTaskHashChecking.
  ///
  /// In zh, this message translates to:
  /// **'校验中'**
  String get downloadTaskHashChecking;

  /// No description provided for @downloadTaskPreSeeding.
  ///
  /// In zh, this message translates to:
  /// **'等待做种'**
  String get downloadTaskPreSeeding;

  /// No description provided for @downloadTaskSeeding.
  ///
  /// In zh, this message translates to:
  /// **'做种中'**
  String get downloadTaskSeeding;

  /// No description provided for @downloadTaskExtracting.
  ///
  /// In zh, this message translates to:
  /// **'解压中'**
  String get downloadTaskExtracting;

  /// No description provided for @downloadTaskCaptchaNeeded.
  ///
  /// In zh, this message translates to:
  /// **'需要验证码'**
  String get downloadTaskCaptchaNeeded;

  /// No description provided for @downloadTaskError.
  ///
  /// In zh, this message translates to:
  /// **'下载出错'**
  String get downloadTaskError;

  /// No description provided for @downloadTaskBrokenLink.
  ///
  /// In zh, this message translates to:
  /// **'错误链接'**
  String get downloadTaskBrokenLink;

  /// No description provided for @downloadTaskDestNotExist.
  ///
  /// In zh, this message translates to:
  /// **'目标目录不存在'**
  String get downloadTaskDestNotExist;

  /// No description provided for @downloadTaskDestDeny.
  ///
  /// In zh, this message translates to:
  /// **'目标目录无权限'**
  String get downloadTaskDestDeny;

  /// No description provided for @downloadTaskDiskFull.
  ///
  /// In zh, this message translates to:
  /// **'硬盘已满'**
  String get downloadTaskDiskFull;

  /// No description provided for @downloadTaskQuotaReached.
  ///
  /// In zh, this message translates to:
  /// **'已达空间配额'**
  String get downloadTaskQuotaReached;

  /// No description provided for @downloadTaskTimeout.
  ///
  /// In zh, this message translates to:
  /// **'联机超时'**
  String get downloadTaskTimeout;

  /// No description provided for @downloadBtnNew.
  ///
  /// In zh, this message translates to:
  /// **'新增'**
  String get downloadBtnNew;

  /// No description provided for @downloadBtnOk.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get downloadBtnOk;

  /// No description provided for @downloadBtnCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get downloadBtnCancel;

  /// No description provided for @downloadBtnRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get downloadBtnRefresh;

  /// No description provided for @downloadBtnRemove.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get downloadBtnRemove;

  /// No description provided for @downloadBtnResume.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get downloadBtnResume;

  /// No description provided for @downloadBtnStop.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get downloadBtnStop;

  /// No description provided for @downloadBtnClear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get downloadBtnClear;

  /// No description provided for @downloadBtnEnd.
  ///
  /// In zh, this message translates to:
  /// **'结束'**
  String get downloadBtnEnd;

  /// No description provided for @downloadBtnChange.
  ///
  /// In zh, this message translates to:
  /// **'变更'**
  String get downloadBtnChange;

  /// No description provided for @downloadBtnHelp.
  ///
  /// In zh, this message translates to:
  /// **'说明'**
  String get downloadBtnHelp;

  /// No description provided for @downloadLblInputUrl.
  ///
  /// In zh, this message translates to:
  /// **'输入网址'**
  String get downloadLblInputUrl;

  /// No description provided for @downloadLblInputFile.
  ///
  /// In zh, this message translates to:
  /// **'打开文件'**
  String get downloadLblInputFile;

  /// No description provided for @downloadLblDestFolder.
  ///
  /// In zh, this message translates to:
  /// **'目的地文件夹'**
  String get downloadLblDestFolder;

  /// No description provided for @downloadLblFilename.
  ///
  /// In zh, this message translates to:
  /// **'文件名称'**
  String get downloadLblFilename;

  /// No description provided for @downloadLblFileSize.
  ///
  /// In zh, this message translates to:
  /// **'文件大小'**
  String get downloadLblFileSize;

  /// No description provided for @downloadLblStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get downloadLblStatus;

  /// No description provided for @downloadLblProgress.
  ///
  /// In zh, this message translates to:
  /// **'进度'**
  String get downloadLblProgress;

  /// No description provided for @downloadLblSpeed.
  ///
  /// In zh, this message translates to:
  /// **'速度'**
  String get downloadLblSpeed;

  /// No description provided for @downloadLblDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'已下载'**
  String get downloadLblDownloaded;

  /// No description provided for @downloadLblCreatedTime.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get downloadLblCreatedTime;

  /// No description provided for @downloadLblStartedTime.
  ///
  /// In zh, this message translates to:
  /// **'开始时间'**
  String get downloadLblStartedTime;

  /// No description provided for @downloadLblConnectedPeers.
  ///
  /// In zh, this message translates to:
  /// **'已联机的Peer数'**
  String get downloadLblConnectedPeers;

  /// No description provided for @downloadLblPeer.
  ///
  /// In zh, this message translates to:
  /// **'Peer数'**
  String get downloadLblPeer;

  /// No description provided for @downloadLblLeechers.
  ///
  /// In zh, this message translates to:
  /// **'下载用户数'**
  String get downloadLblLeechers;

  /// No description provided for @downloadLblSeeders.
  ///
  /// In zh, this message translates to:
  /// **'种子数'**
  String get downloadLblSeeders;

  /// No description provided for @downloadLblSeedElapsed.
  ///
  /// In zh, this message translates to:
  /// **'已作种时间'**
  String get downloadLblSeedElapsed;

  /// No description provided for @downloadLblTransfered.
  ///
  /// In zh, this message translates to:
  /// **'已传输'**
  String get downloadLblTransfered;

  /// No description provided for @downloadLblUploadRate.
  ///
  /// In zh, this message translates to:
  /// **'上传速度'**
  String get downloadLblUploadRate;

  /// No description provided for @downloadLblDownRate.
  ///
  /// In zh, this message translates to:
  /// **'下载速度'**
  String get downloadLblDownRate;

  /// No description provided for @downloadLblUrl.
  ///
  /// In zh, this message translates to:
  /// **'网址'**
  String get downloadLblUrl;

  /// No description provided for @downloadLblUsername.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get downloadLblUsername;

  /// No description provided for @downloadLblTotalPieces.
  ///
  /// In zh, this message translates to:
  /// **'分块总数'**
  String get downloadLblTotalPieces;

  /// No description provided for @downloadLblDownloadedPieces.
  ///
  /// In zh, this message translates to:
  /// **'已下载的分块数'**
  String get downloadLblDownloadedPieces;

  /// No description provided for @downloadLblTimeLeft.
  ///
  /// In zh, this message translates to:
  /// **'剩余时间'**
  String get downloadLblTimeLeft;

  /// No description provided for @downloadMsgActionFailed.
  ///
  /// In zh, this message translates to:
  /// **'要求的动作无法完成。'**
  String get downloadMsgActionFailed;

  /// No description provided for @downloadMsgEndDoneDelErr.
  ///
  /// In zh, this message translates to:
  /// **'成功结束选择的下载任务，但系统无法删除此下载任务。请手动删除。'**
  String get downloadMsgEndDoneDelErr;

  /// No description provided for @downloadMsgInvalidUser.
  ///
  /// In zh, this message translates to:
  /// **'不合法的用户。'**
  String get downloadMsgInvalidUser;

  /// No description provided for @downloadMsgReachLimit.
  ///
  /// In zh, this message translates to:
  /// **'下载任务数已达到上限。'**
  String get downloadMsgReachLimit;

  /// No description provided for @downloadWarningSelectItems.
  ///
  /// In zh, this message translates to:
  /// **'请先勾选项目。'**
  String get downloadWarningSelectItems;

  /// No description provided for @downloadWarningSelectShare.
  ///
  /// In zh, this message translates to:
  /// **'请先选择目的地文件夹。'**
  String get downloadWarningSelectShare;

  /// No description provided for @downloadWarningDiskFull.
  ///
  /// In zh, this message translates to:
  /// **'此存储空间的可用空间不足。'**
  String get downloadWarningDiskFull;

  /// No description provided for @downloadErrorNoTask.
  ///
  /// In zh, this message translates to:
  /// **'下载任务不正确或已被删除。'**
  String get downloadErrorNoTask;

  /// No description provided for @downloadErrorNoPrivilege.
  ///
  /// In zh, this message translates to:
  /// **'您没有权限读取此下载任务。'**
  String get downloadErrorNoPrivilege;

  /// No description provided for @downloadErrorWrongFormat.
  ///
  /// In zh, this message translates to:
  /// **'文件格式不正确。'**
  String get downloadErrorWrongFormat;

  /// No description provided for @downloadErrorWrongUrl.
  ///
  /// In zh, this message translates to:
  /// **'网址的开头必须是http://、https://，或ftp://。'**
  String get downloadErrorWrongUrl;

  /// No description provided for @downloadErrorEmptyInput.
  ///
  /// In zh, this message translates to:
  /// **'请输入网址。'**
  String get downloadErrorEmptyInput;

  /// No description provided for @downloadErrorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'创建网络联机失败。'**
  String get downloadErrorNetwork;

  /// No description provided for @downloadErrorServer.
  ///
  /// In zh, this message translates to:
  /// **'发生未知的错误！'**
  String get downloadErrorServer;

  /// No description provided for @downloadErrorShareNotFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到有写入权限的文件夹。'**
  String get downloadErrorShareNotFound;

  /// No description provided for @downloadErrorUserRemoved.
  ///
  /// In zh, this message translates to:
  /// **'帐号不存在或已被删除。'**
  String get downloadErrorUserRemoved;

  /// No description provided for @downloadErrorSelectNum.
  ///
  /// In zh, this message translates to:
  /// **'只能选择一个下载任务。'**
  String get downloadErrorSelectNum;

  /// No description provided for @downloadErrorReadTorrentFail.
  ///
  /// In zh, this message translates to:
  /// **'无法读取 torrent 文件。'**
  String get downloadErrorReadTorrentFail;

  /// No description provided for @downloadErrorMagnet.
  ///
  /// In zh, this message translates to:
  /// **'无法由磁力链接取得 torrent 文件的信息。'**
  String get downloadErrorMagnet;

  /// No description provided for @downloadErrorNoFileToEnd.
  ///
  /// In zh, this message translates to:
  /// **'文件不存在。'**
  String get downloadErrorNoFileToEnd;

  /// No description provided for @downloadConfirmRemove.
  ///
  /// In zh, this message translates to:
  /// **'您确定要删除此下载任务吗？'**
  String get downloadConfirmRemove;

  /// No description provided for @downloadConfirmEnd.
  ///
  /// In zh, this message translates to:
  /// **'您确定要结束此下载任务吗？'**
  String get downloadConfirmEnd;

  /// No description provided for @downloadEndDesc.
  ///
  /// In zh, this message translates to:
  /// **'此功能只适合无法继续下载的任务或有错误的任务。'**
  String get downloadEndDesc;

  /// No description provided for @downloadEndNoteFinished.
  ///
  /// In zh, this message translates to:
  /// **'您无法结束此下载任务，下载任务已经完成。'**
  String get downloadEndNoteFinished;

  /// No description provided for @downloadEndNoteNoFile.
  ///
  /// In zh, this message translates to:
  /// **'您无法结束此下载任务，此任务还未开始下载。'**
  String get downloadEndNoteNoFile;

  /// No description provided for @downloadRedirectConfirm.
  ///
  /// In zh, this message translates to:
  /// **'Download Station 未启用。您要设置Download Station 吗？'**
  String get downloadRedirectConfirm;

  /// No description provided for @downloadNotEnabled.
  ///
  /// In zh, this message translates to:
  /// **'下载服务尚未启用。'**
  String get downloadNotEnabled;

  /// No description provided for @downloadSeedDays.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get downloadSeedDays;

  /// No description provided for @downloadSeedHours.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get downloadSeedHours;

  /// No description provided for @downloadSeedMins.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get downloadSeedMins;

  /// No description provided for @downloadSeedSeconds.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get downloadSeedSeconds;

  /// No description provided for @downloadNextPage.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get downloadNextPage;

  /// No description provided for @downloadPreviousPage.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get downloadPreviousPage;

  /// No description provided for @downloadTitle.
  ///
  /// In zh, this message translates to:
  /// **'BT/PT/HTTP/FTP/NZB下载'**
  String get downloadTitle;

  /// No description provided for @titleDownloadManager.
  ///
  /// In zh, this message translates to:
  /// **'BT/PT/HTTP/FTP/NZB'**
  String get titleDownloadManager;

  /// No description provided for @downloadEmptyInputFile.
  ///
  /// In zh, this message translates to:
  /// **'请打开要新增的文件。'**
  String get downloadEmptyInputFile;

  /// No description provided for @downloadEmptyInputUrl.
  ///
  /// In zh, this message translates to:
  /// **'请输入网址。'**
  String get downloadEmptyInputUrl;

  /// No description provided for @downloadComplete.
  ///
  /// In zh, this message translates to:
  /// **'下载已完成。'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载失败。'**
  String get downloadFailed;

  /// No description provided for @downloadMsgAskHelp2.
  ///
  /// In zh, this message translates to:
  /// **'请求系统管理员解决此问题。'**
  String get downloadMsgAskHelp2;

  /// No description provided for @temporaryLocation.
  ///
  /// In zh, this message translates to:
  /// **'暂存位置'**
  String get temporaryLocation;

  /// No description provided for @userNoShareFolder.
  ///
  /// In zh, this message translates to:
  /// **'您没有权限存取任何共享文件夹，请与系统管理员联络。'**
  String get userNoShareFolder;

  /// No description provided for @downloadErrorExceedFsMaxSize.
  ///
  /// In zh, this message translates to:
  /// **'超过文件系统最大文件大小。'**
  String get downloadErrorExceedFsMaxSize;

  /// No description provided for @downloadErrorEncryptionLongPath.
  ///
  /// In zh, this message translates to:
  /// **'加密文件路径过长。'**
  String get downloadErrorEncryptionLongPath;

  /// No description provided for @downloadErrorLongPath.
  ///
  /// In zh, this message translates to:
  /// **'文件路径过长。'**
  String get downloadErrorLongPath;

  /// No description provided for @downloadErrorDuplicateTorrent.
  ///
  /// In zh, this message translates to:
  /// **'下载任务重复。'**
  String get downloadErrorDuplicateTorrent;

  /// No description provided for @downloadErrorPremiumAccountRequire.
  ///
  /// In zh, this message translates to:
  /// **'需要Premium账户。'**
  String get downloadErrorPremiumAccountRequire;

  /// No description provided for @downloadErrorNotSupportType.
  ///
  /// In zh, this message translates to:
  /// **'不支持的文件类型。'**
  String get downloadErrorNotSupportType;

  /// No description provided for @downloadErrorFtpEncryptionNotSupportType.
  ///
  /// In zh, this message translates to:
  /// **'FTP加密不支持的文件类型。'**
  String get downloadErrorFtpEncryptionNotSupportType;

  /// No description provided for @downloadErrorExtractFailed.
  ///
  /// In zh, this message translates to:
  /// **'解压失败。'**
  String get downloadErrorExtractFailed;

  /// No description provided for @downloadErrorInvalidTorrent.
  ///
  /// In zh, this message translates to:
  /// **'无效的torrent文件。'**
  String get downloadErrorInvalidTorrent;

  /// No description provided for @downloadErrorAccountRequireStatus.
  ///
  /// In zh, this message translates to:
  /// **'账户状态不符合要求。'**
  String get downloadErrorAccountRequireStatus;

  /// No description provided for @downloadErrorTryItLater.
  ///
  /// In zh, this message translates to:
  /// **'请稍后再试。'**
  String get downloadErrorTryItLater;

  /// No description provided for @downloadErrorTaskEncryption.
  ///
  /// In zh, this message translates to:
  /// **'任务加密出错。'**
  String get downloadErrorTaskEncryption;

  /// No description provided for @downloadErrorMissingPython.
  ///
  /// In zh, this message translates to:
  /// **'缺少Python组件。'**
  String get downloadErrorMissingPython;

  /// No description provided for @downloadErrorPrivateVideo.
  ///
  /// In zh, this message translates to:
  /// **'私有视频无法下载。'**
  String get downloadErrorPrivateVideo;

  /// No description provided for @downloadErrorNzbMissingArticle.
  ///
  /// In zh, this message translates to:
  /// **'NZB文件缺少Article。'**
  String get downloadErrorNzbMissingArticle;

  /// No description provided for @downloadErrorParchiveRepairFailed.
  ///
  /// In zh, this message translates to:
  /// **'Parchive修复失败。'**
  String get downloadErrorParchiveRepairFailed;

  /// No description provided for @downloadErrorInvalidAccountPassword.
  ///
  /// In zh, this message translates to:
  /// **'账户密码无效。'**
  String get downloadErrorInvalidAccountPassword;
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
