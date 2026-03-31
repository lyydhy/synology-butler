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
  /// **'IP'**
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
  /// **'登录到 NAS'**
  String get loginToNas;

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
  /// **'群晖管家 v0.1'**
  String get settingsAboutSubtitle;

  /// No description provided for @packageCenter.
  ///
  /// In zh, this message translates to:
  /// **'套件中心'**
  String get packageCenter;

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
