// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '群晖管家';

  @override
  String get settingsTitle => '设置';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeColor => '主题色';

  @override
  String get language => '语言';

  @override
  String get followSystem => '跟随系统';

  @override
  String get lightMode => '浅色';

  @override
  String get darkMode => '深色';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get loginTitle => '连接你的群晖 NAS';

  @override
  String get deviceName => '设备名称';

  @override
  String get addressOrHost => '地址 / 域名 / IP';

  @override
  String get port => '端口';

  @override
  String get basePathOptional => '基础路径（可选）';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get useHttps => '使用 HTTPS';

  @override
  String get login => '登录';

  @override
  String get testingConnection => '测试中…';

  @override
  String get testConnection => '测试连接';

  @override
  String get loggingIn => '登录中…';

  @override
  String get dashboardTitle => '首页';

  @override
  String get currentConnection => '当前连接';

  @override
  String get sessionStatus => '会话状态';

  @override
  String get deviceInfo => '设备信息';

  @override
  String get uptime => '运行时间';

  @override
  String get cpu => 'CPU';

  @override
  String get memory => '内存';

  @override
  String get storage => '存储';

  @override
  String get noSessionPleaseLogin => '当前没有可用会话，请先登录 NAS';

  @override
  String get online => '在线';

  @override
  String get sidEstablished => 'SID 已建立，可访问 DSM API';

  @override
  String get unknown => '未知';

  @override
  String get notAvailableYet => '暂未获取';

  @override
  String get currentDevice => '当前设备';

  @override
  String get loginStatus => '登录状态';

  @override
  String get loggedInSidEstablished => '已登录（SID 已建立）';

  @override
  String get notLoggedIn => '未登录';

  @override
  String get filesTitle => '文件';

  @override
  String get downloadsTitle => '下载';

  @override
  String get notInstalled => '未安装';

  @override
  String get currentPath => '当前路径';

  @override
  String get sortByName => '按名称排序';

  @override
  String get sortBySize => '按大小排序';

  @override
  String get goParent => '返回上一级';

  @override
  String get folderIsEmpty => '当前目录为空';

  @override
  String get retry => '重试';

  @override
  String get createFolder => '新建文件夹';

  @override
  String get folderName => '文件夹名称';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get uploadFile => '上传文件';

  @override
  String get targetFolder => '目标目录';

  @override
  String get chooseFile => '选择文件';

  @override
  String get noFileSelected => '尚未选择文件';

  @override
  String get uploading => '上传中…';

  @override
  String get startUpload => '开始上传';

  @override
  String get rename => '重命名';

  @override
  String get newName => '新名称';

  @override
  String get processing => '处理中…';

  @override
  String get deleteFile => '删除文件';

  @override
  String get deleteConfirm => '删除';

  @override
  String deleteConfirmHint(Object name) {
    return '确定删除 $name 吗？';
  }

  @override
  String get deleteSuccess => '删除成功';

  @override
  String get shareLink => '分享链接';

  @override
  String get close => '关闭';

  @override
  String get detail => '详情';

  @override
  String get generateShareLink => '生成分享链接';

  @override
  String get downloadFilterAll => '全部';

  @override
  String get downloadFilterDownloading => '下载中';

  @override
  String get downloadFilterPaused => '已暂停';

  @override
  String get downloadFilterFinished => '已完成';

  @override
  String get noTasksForFilter => '当前筛选下暂无下载任务';

  @override
  String get createDownloadTask => '新增下载任务';

  @override
  String get downloadLinkOrMagnet => '下载链接 / Magnet';

  @override
  String get submitting => '提交中…';

  @override
  String get pause => '暂停';

  @override
  String get resume => '恢复';

  @override
  String get deleteTask => '删除下载任务';

  @override
  String get operationSuccess => '操作成功';

  @override
  String get debugInfo => '调试信息';

  @override
  String get debugCurrentConnection => '当前连接';

  @override
  String get debugLocalStorage => '本地保存';

  @override
  String get debugTips => '联调提示';

  @override
  String get savedUsername => '已记住用户名';

  @override
  String get savedDeviceCount => '已保存设备数量';

  @override
  String get serverManagement => '连接管理';

  @override
  String get savedDevices => '已保存设备';

  @override
  String get addNewDevice => '添加新设备';

  @override
  String get editDevice => '编辑设备';

  @override
  String get deleteDevice => '删除设备';

  @override
  String get deviceDeleted => '设备已删除';

  @override
  String get deviceUpdated => '设备配置已更新';

  @override
  String get switchDeviceRelogin => '已切换设备，请重新登录';

  @override
  String get filePath => '路径';

  @override
  String get fileType => '类型';

  @override
  String get fileSize => '大小';

  @override
  String get folder => '文件夹';

  @override
  String get file => '文件';

  @override
  String get taskId => '任务 ID';

  @override
  String get status => '状态';

  @override
  String get downloadStatusWaiting => '等待中';

  @override
  String get downloadStatusDownloading => '下载中';

  @override
  String get downloadStatusPaused => '已暂停';

  @override
  String get downloadStatusFinished => '已完成';

  @override
  String get downloadStatusSeeding => '做种中';

  @override
  String get downloadStatusHashChecking => '校验中';

  @override
  String get downloadStatusExtracting => '解压中';

  @override
  String get downloadStatusError => '出错';

  @override
  String get downloadStatusUnknown => '未知';

  @override
  String get downloadStatusFileHostingWaiting => '等待资源';

  @override
  String get downloadStatusCaptchaNeeded => '需要验证码';

  @override
  String get downloadStatusFinishing => '即将完成';

  @override
  String get downloadStatusPreSeeding => '等待做种';

  @override
  String get downloadStatusPreprocessing => '预处理中';

  @override
  String get downloadStatusDownloaded => '已下载';

  @override
  String get downloadStatusPostProcessing => '后处理中';

  @override
  String get progress => '进度';

  @override
  String get appLogsTitle => '应用日志';

  @override
  String get appLogsSubtitle => '查看本地日志文件、复制内容或快速清空';

  @override
  String get appLogsEmpty => '还没有日志文件';

  @override
  String get appLogsEmptyContent => '当前日志为空';

  @override
  String get appLogsCopySanitized => '复制脱敏内容';

  @override
  String get appLogsExportToLogsDir => '导出到日志目录';

  @override
  String get appLogsExportToDirectory => '导出到指定目录';

  @override
  String get appLogsDeleteCurrent => '删除当前日志';

  @override
  String get appLogsDeleteAll => '删除全部日志';

  @override
  String get appLogsCopied => '脱敏日志已复制';

  @override
  String appLogsExported(Object path) {
    return '已导出到：$path';
  }

  @override
  String appLogsExportedToInternal(Object path) {
    return '已导出脱敏日志：$path';
  }

  @override
  String appLogsFileCount(Object count) {
    return '共 $count 个日志文件';
  }

  @override
  String get appLogsSanitizedBadge => '已脱敏';

  @override
  String get appLogsRawBadge => '原始日志';

  @override
  String get appLogsViewerHint => '当前展示的是脱敏后的内容，适合复制或导出给别人排查问题。';

  @override
  String get controlPanelTitle => '控制面板';

  @override
  String get taskSchedulerTitle => '任务计划';

  @override
  String get externalDevicesTitle => '外接设备';

  @override
  String get externalAccessTitle => '外部访问';

  @override
  String get indexServiceTitle => '索引服务';

  @override
  String get sharedFoldersTitle => '共享文件夹';

  @override
  String get userGroupsTitle => '用户与群组';

  @override
  String get informationCenterTitle => '信息中心';

  @override
  String get noTasks => '当前没有任务计划';

  @override
  String get noExternalDevices => '当前没有连接外接设备';

  @override
  String get noDdnsRecords => '当前没有 DDNS 记录';

  @override
  String get noSharedFolders => '当前没有共享文件夹';

  @override
  String get noUsersFound => '没有找到用户';

  @override
  String get noGroupsFound => '没有找到群组';

  @override
  String get executeNow => '立即执行';

  @override
  String get taskSubmitted => '任务已提交执行';

  @override
  String get executeFailed => '执行失败';

  @override
  String get updateFailed => '更新失败';

  @override
  String get ejectDevice => '弹出设备';

  @override
  String get ejectSubmitted => '已提交弹出设备请求';

  @override
  String get ejectFailed => '弹出失败';

  @override
  String get fileSystem => '文件系统';

  @override
  String get mountPath => '挂载路径';

  @override
  String get capacity => '容量';

  @override
  String get nextAutoUpdateTime => '下次自动更新时间';

  @override
  String get ipAddress => 'IP 地址';

  @override
  String get lastUpdated => '上次更新';

  @override
  String get refreshNow => '立即刷新';

  @override
  String get thumbnailQuality => '缩图质量';

  @override
  String get thumbnailQualityUpdated => '缩图质量已更新';

  @override
  String get rebuildIndex => '重建索引';

  @override
  String get rebuildIndexDesc => '重新触发媒体索引，适合补救缩图缺失或索引状态异常。';

  @override
  String get rebuildSubmitted => '已提交重建索引请求';

  @override
  String get rebuildFailed => '重建失败';

  @override
  String get currentIndexStatus => '当前状态';

  @override
  String get currentTask => '当前任务';

  @override
  String get noIndexTasks => '当前没有索引任务';

  @override
  String historyDeleted(Object name) {
    return '已删除 $name 的历史记录';
  }

  @override
  String get connectionTestFailed => '测试连接失败';

  @override
  String get copy => '复制';

  @override
  String get switchedToHttp => '已切换为 HTTP，请仅在可信局域网中使用';

  @override
  String get selectFromHistory => '从历史登录设备中选择';

  @override
  String get historyDevices => '历史登录设备';

  @override
  String get selectDeviceFirst => '请选择一个历史设备后再快速登录';

  @override
  String get quickLogin => '快速登录';

  @override
  String get enterPasswordToLogin => '输入密码即可登录';

  @override
  String get addDevice => '添加设备';

  @override
  String get done => '完成';

  @override
  String get newAccountDevice => '新账号 / 新设备登录';

  @override
  String get connectionInfo => '连接信息';

  @override
  String get enterNasCredentials => '填写 NAS 地址与 DSM 账号信息';

  @override
  String get ignoreSslCert => '忽略 SSL 证书';

  @override
  String get ignoreSslCertHint => '仅适用于自签名或异常证书场景';

  @override
  String get httpsOnly => '仅 HTTPS 下可用';

  @override
  String get rememberPassword => '记住密码';

  @override
  String get loginDsm => '登录 DSM';

  @override
  String get dsm7Plus => 'DSM 7+';

  @override
  String get quickLoginReady => '已为你准备好快速登录。';

  @override
  String get connectToDsm => '连接你的群晖 DSM。';

  @override
  String get quickRelogin => '快速重新登录';

  @override
  String get quickReloginHint => '有历史记录时优先显示这个界面，减少输入内容。';

  @override
  String loginToNas(Object name) {
    return '登录到 $name';
  }

  @override
  String get loginToNasHint => '支持局域网 IP、域名和端口。';

  @override
  String get noUsernameTapChange => '未记录用户名，请点击更换账号';

  @override
  String get fill => '填写';

  @override
  String get changeAccount => '更换账号';

  @override
  String get justUsed => '刚刚使用';

  @override
  String minutesAgo(Object n) {
    return '$n 分钟前使用';
  }

  @override
  String hoursAgo(Object n) {
    return '$n 小时前使用';
  }

  @override
  String daysAgo(Object n) {
    return '$n 天前使用';
  }

  @override
  String get usedEarlier => '较早前使用';

  @override
  String get noLoginTimeRecorded => '未记录登录时间';

  @override
  String selectedEnterPassword(Object name) {
    return '已选择 $name，输入密码即可重新登录';
  }

  @override
  String get connectionSuccess => '连接成功：已探测到 DSM Web API';

  @override
  String dsm6NotSupported(Object version) {
    return '检测到当前设备为 $version。本应用当前仅支持 DSM 7，暂不支持 DSM 6 登录。';
  }

  @override
  String get switchedToNewAccount => '已切换到新账号 / 新设备登录';

  @override
  String get sessionExpired => '登录状态已过期，请重新登录以恢复实时连接。';

  @override
  String get enterNasAddress => '请输入 NAS 地址或域名';

  @override
  String get enterPort => '请输入端口';

  @override
  String get portRange => '端口范围应为 1 - 65535';

  @override
  String get enterUsername => '请输入用户名';

  @override
  String get enterPassword => '请输入密码';

  @override
  String get selectDeviceThenPassword => '选择设备后输入密码即可登录';

  @override
  String get deviceReadyEnterPassword => '设备已就绪，输入密码即可登录';

  @override
  String get previewImage => '预览图片';

  @override
  String get download => '下载';

  @override
  String get downloadAndOpen => '下载并打开';

  @override
  String startDownloading(Object name) {
    return '开始下载 $name';
  }

  @override
  String downloadCompleteOpen(Object name) {
    return '开始下载 $name，完成后可直接打开';
  }

  @override
  String downloadTaskComplete(Object title) {
    return '$title 下载完成';
  }

  @override
  String confirmDelete(Object name) {
    return '确定要删除\\\"$name\\\"吗？';
  }

  @override
  String downloadDirSet(Object path) {
    return '下载目录已设置为 $path';
  }

  @override
  String get selectUploadDir => '选择上传目录';

  @override
  String loadFilesFailed(Object error) {
    return '加载文件失败：$error';
  }

  @override
  String selectCurrentDir(Object path) {
    return '选择当前目录：$path';
  }

  @override
  String get refresh => '刷新';

  @override
  String get discardChanges => '放弃修改？';

  @override
  String get discardChangesHint => '当前文件有未保存修改，确定直接返回吗？';

  @override
  String get discard => '放弃';

  @override
  String get saveSuccess => '保存成功';

  @override
  String get save => '保存';

  @override
  String get savedToAlbum => '已保存到相册';

  @override
  String get loadingImage => '正在加载图片...';

  @override
  String get videoLoadFailed => '视频加载失败';

  @override
  String get selectOneFile => '请至少选择一个文件进行下载';

  @override
  String addedDownloadTasks(Object count) {
    return '已加入 $count 个下载任务';
  }

  @override
  String get batchDelete => '批量删除';

  @override
  String confirmBatchDelete(Object count) {
    return '确定要删除选中的 $count 项吗？';
  }

  @override
  String deletedCount(Object count) {
    return '已删除 $count 项';
  }

  @override
  String get uploadTaskAdded => '已加入上传任务';

  @override
  String get videoPreviewHint => '视频预览请从列表打开';

  @override
  String get pathCopied => '路径已复制';

  @override
  String get open => '打开';

  @override
  String get backgroundTaskRunning => '后台任务进行中';

  @override
  String backgroundTaskRunningCount(Object count) {
    return '后台任务进行中（$count）';
  }

  @override
  String taskComplete(Object name) {
    return '$name任务已完成';
  }

  @override
  String taskCompleteMultiple(Object name, Object count) {
    return '$name等$count个后台任务已完成';
  }

  @override
  String get transfer => '传输';

  @override
  String get downloadAndOpenTitle => '下载并打开';

  @override
  String get processingLabel => '处理中';

  @override
  String get fileServicesTitle => '文件服务';

  @override
  String get noFileServices => '未获取到文件服务信息';

  @override
  String get fileServiceEnabled => '已启用';

  @override
  String get fileServiceDisabled => '未启用';

  @override
  String get defaultDeviceName => '我的 NAS';

  @override
  String get splashTitle => '群晖管家';

  @override
  String get splashSubtitleReady => '你的 DSM 7+ 掌上助手';

  @override
  String get splashSubtitleRestoring => '正在恢复你的连接与设备状态';

  @override
  String get splashSubtitlePreparing => '正在准备登录界面';

  @override
  String get splashLoadingStart => '正在启动...';

  @override
  String get splashLoadingEnter => '正在进入...';

  @override
  String get splashLoadingLogin => '正在跳转登录...';

  @override
  String get dashboardSectionApps => '应用';

  @override
  String get dashboardSectionAppsSubtitle => '常用功能快捷入口';

  @override
  String get dashboardContainerManagement => '容器管理';

  @override
  String get dashboardContainerManagementDesc => '查看容器与 Compose 项目';

  @override
  String get dashboardTransfers => '传输中心';

  @override
  String get dashboardTransfersDesc => '管理最近上传下载任务';

  @override
  String get dashboardControlPanel => '控制面板';

  @override
  String get dashboardControlPanelDesc => '按优先级进入系统功能配置';

  @override
  String get dashboardInformationCenter => '信息中心';

  @override
  String get dashboardInformationCenterDesc => '查看系统与存储详情';

  @override
  String get dashboardPerformance => '性能监控';

  @override
  String get dashboardPerformanceDesc => '查看 CPU 与内存状态';

  @override
  String get dashboardStorage => '存储空间';

  @override
  String get dashboardStorageEmpty => '暂未获取到存储空间信息';

  @override
  String get dashboardUptime => '运行时间';

  @override
  String get storageLabel => '存储空间';

  @override
  String storageLabelN(Object n) {
    return '存储空间 $n';
  }

  @override
  String usedSlashTotal(Object used, Object total) {
    return '已用 $used / 总计 $total';
  }

  @override
  String usedSlashUnknown(Object used) {
    return '已用 $used / 总计 --';
  }

  @override
  String unknownSlashTotal(Object total) {
    return '已用 -- / 总计 $total';
  }

  @override
  String get usedUnknown => '已用 -- / 总计 --';

  @override
  String confirmDeleteName(Object name) {
    return '确定要删除\"$name\"吗？';
  }

  @override
  String downloadDirSetTo(Object path) {
    return '下载目录已设置为 $path';
  }

  @override
  String startDownloadingName(Object name) {
    return '开始下载 $name';
  }

  @override
  String get previewText => '预览文本';

  @override
  String get previewNfo => '预览 NFO';

  @override
  String get settingsConnectionStorageSubtitle => '管理 NAS 连接和本地下载目录';

  @override
  String get serverManagementHint => '查看、切换、编辑和删除已保存设备';

  @override
  String settingsCurrentServer(String name) {
    return '当前设备：$name';
  }

  @override
  String get downloadDirectoryHint => '首次下载时选择，之后可在这里修改';

  @override
  String get sharingLinksHint => '查看和复制已创建的分享链接';

  @override
  String get themeColorGreen => '绿色';

  @override
  String get themeColorOrange => '橙色';

  @override
  String get themeColorPurple => '紫色';

  @override
  String get themeColorBlue => '蓝色';

  @override
  String get settingsConnectionStorage => '连接与存储';

  @override
  String get settingsConnectionManagement => '连接管理';

  @override
  String get settingsDownloadDirectory => '下载目录';

  @override
  String get settingsDownloadDirUpdated => '下载目录已更新';

  @override
  String get settingsAppearanceLanguage => '外观与语言';

  @override
  String get settingsAppearanceSubtitle => '调整应用显示风格和语言';

  @override
  String get settingsAppSupport => '应用与支持';

  @override
  String get settingsAppSupportSubtitle => '保留常用支持入口，移除偏调试和低频功能';

  @override
  String get settingsLogout => '退出登录';

  @override
  String get settingsLogoutSubtitle => '清除当前会话和本地保存的登录态';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsAboutSubtitle => '群晖管家 v0.1';

  @override
  String get packageCenter => '套件中心';

  @override
  String get packageAll => '全部';

  @override
  String get packageInstalled => '已安装';

  @override
  String get packageUpdatable => '可更新';

  @override
  String packageTask(Object status) {
    return '套件任务：$status';
  }

  @override
  String get packageListFailed => '套件列表加载失败';

  @override
  String get selectInstallLocation => '选择安装位置';

  @override
  String get selectInstallLocationHint => '先选择套件要安装到哪个存储卷';

  @override
  String storeVersion(Object version) {
    return '商店版本 $version';
  }

  @override
  String installedVersion(Object version) {
    return '已装 $version';
  }

  @override
  String startRequestSent(Object name) {
    return '已发送启动请求：$name';
  }

  @override
  String stopRequestSent(Object name) {
    return '已发送停止请求：$name';
  }

  @override
  String get confirmUninstall => '确认卸载';

  @override
  String confirmUninstallMessage(Object name) {
    return '确定要卸载 $name 吗？';
  }

  @override
  String uninstallRequestSent(Object name) {
    return '已发送卸载请求：$name';
  }

  @override
  String get confirmUpdateImpact => '确认更新影响';

  @override
  String get start => '启动';

  @override
  String get stop => '停止';

  @override
  String get uninstall => '卸载';

  @override
  String get continueAction => '继续';

  @override
  String packageTaskComplete(Object name) {
    return '$name 安装/更新任务已完成或已提交';
  }

  @override
  String packageInstallFailed(Object error) {
    return '套件安装失败：$error';
  }

  @override
  String get transfersTitle => '传输中心';

  @override
  String get clearCompleted => '删除已完成记录';

  @override
  String get clearFailed => '删除失败记录';

  @override
  String get filterAll => '全部';

  @override
  String get filterActive => '进行中';

  @override
  String get filterCompleted => '已完成';

  @override
  String get filterFailed => '失败';

  @override
  String get deleteCompleted => '清除已完成';

  @override
  String get deleteFailedRecords => '清除失败记录';

  @override
  String get openedWithSystem => '已调用系统打开方式';

  @override
  String directory(Object path) {
    return '目录：$path';
  }

  @override
  String get openDirectory => '打开目录';

  @override
  String get removeRecord => '移除记录';

  @override
  String get reasonCopied => '失败原因已复制';

  @override
  String containerSuccess(Object action, Object name) {
    return '$action容器成功：$name';
  }

  @override
  String containerFailed(Object action, Object error) {
    return '$action容器失败：$error';
  }

  @override
  String get containerManagement => '容器管理';

  @override
  String get containerAll => '全部';

  @override
  String get containerRunning => '运行中';

  @override
  String get containerStopped => '已停止';

  @override
  String get createNew => '新建';

  @override
  String get filterLatest => 'latest';

  @override
  String get filterOtherTags => '其他标签';

  @override
  String get sortBy => '排序';

  @override
  String get sortNameAsc => '名称 A-Z';

  @override
  String get sortNameDesc => '名称 Z-A';

  @override
  String get sortTagAsc => '标签 A-Z';

  @override
  String get sortTagDesc => '标签 Z-A';

  @override
  String get sortSizeDesc => '大小 从大到小';

  @override
  String get sortSizeAsc => '大小 从小到大';

  @override
  String get restart => '重启';

  @override
  String get forceStop => '强制停止';

  @override
  String ports(Object ports) {
    return '端口：$ports';
  }

  @override
  String get viewAction => '查看';

  @override
  String get performanceMonitor => '性能监控';

  @override
  String get clearHistoryAndRefresh => '清除历史并刷新';

  @override
  String get overview => '概览';

  @override
  String get network => '网络';

  @override
  String get disk => '磁盘';

  @override
  String loadFailed(Object error) {
    return '加载失败: $error';
  }

  @override
  String get connectionManagement => '连接管理';

  @override
  String get noSavedDevices => '还没有保存的设备';

  @override
  String get addDeviceHint => '先添加一个 NAS 连接，后面就可以在这里快速切换。';

  @override
  String get addNewConnection => '添加新连接';

  @override
  String get savedConnections => '已保存的连接';

  @override
  String get noCurrentDevice => '当前未连接设备';

  @override
  String currentDeviceName(Object name) {
    return '当前设备：$name';
  }

  @override
  String confirmDeleteDevice(Object name) {
    return '确定要删除设备「$name」吗？';
  }

  @override
  String get recentTransfers => '最近传输';

  @override
  String get noTransfersHint => '还没有任务，新的上传和下载会显示在这里';

  @override
  String get transfersHint => '优先看进行中和失败任务，已完成记录可以随时清理';

  @override
  String get noTransfersInFilter => '这个筛选下暂时没有传输任务';

  @override
  String get transfersAppearHere => '新的上传、下载、失败重试都会出现在这里。';

  @override
  String get upload => '上传';

  @override
  String get statusQueued => '排队中';

  @override
  String get statusRunning => '进行中';

  @override
  String get statusPaused => '已暂停';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusFailed => '失败';

  @override
  String uploadTo(Object path) {
    return '上传到 $path';
  }

  @override
  String saveTo(Object path) {
    return '保存到 $path';
  }

  @override
  String get moreActions => '更多操作';

  @override
  String get collapseDetails => '收起详情';

  @override
  String get viewDetails => '查看详情';

  @override
  String get copyErrorReason => '复制失败原因';

  @override
  String get copyPath => '复制路径';

  @override
  String get errorCopied => '失败原因已复制';

  @override
  String get copyReason => '复制原因';

  @override
  String get removeRecordAndFile => '删除记录和文件';

  @override
  String resultLabel(Object message) {
    return '结果：$message';
  }

  @override
  String reasonLabel(Object message) {
    return '原因：$message';
  }

  @override
  String get networkTitle => '网络';

  @override
  String get networkInterfaces => '网络接口';

  @override
  String get proxySettings => '代理设置';

  @override
  String get gatewayInfo => '网关信息';

  @override
  String get networkGeneral => '常规';

  @override
  String get noNetworkInfo => '暂无网络信息';

  @override
  String get hostname => '主机名';

  @override
  String get defaultGateway => '默认网关';

  @override
  String get ipv6Gateway => 'IPv6 网关';

  @override
  String get dnsPrimary => '首选 DNS';

  @override
  String get dnsSecondary => '备用 DNS';

  @override
  String get manual => '手动';

  @override
  String get workgroup => '工作组';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '未连接';

  @override
  String get subnetMask => '子网掩码';

  @override
  String get dhcp => 'DHCP';

  @override
  String get ipv6Address => 'IPv6 地址';

  @override
  String get interface => '接口';

  @override
  String get address => '地址';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已禁用';

  @override
  String get coreFeatures => '核心功能';

  @override
  String get systemManagement => '系统管理';

  @override
  String get infoCenterSubtitle => '系统信息与状态总览';

  @override
  String get updateStatusSubtitle => '系统版本与更新检查';

  @override
  String get externalAccessSubtitle => 'DDNS 与远程连接';

  @override
  String get indexServiceSubtitle => '缩图质量与索引重建';

  @override
  String get taskSchedulerSubtitle => '定时任务与执行管理';

  @override
  String get externalDevicesSubtitle => 'USB 与存储设备管理';

  @override
  String get sharedFoldersSubtitle => '文件共享与权限设置';

  @override
  String get userGroupsSubtitle => '账户与权限管理';

  @override
  String get fileServicesSubtitle => 'SMB / NFS / FTP / SFTP';

  @override
  String get networkSubtitle => '接口、代理与网关';

  @override
  String get updateStatus => '更新状态';

  @override
  String get terminalTitle => '终端设置';

  @override
  String get terminalSubtitle => 'SSH 与 Telnet 服务';

  @override
  String get fileServicesStatusSummary => '文件服务状态总览';

  @override
  String fileServicesEnabledCount(Object enabledCount, Object totalCount) {
    return '已启用 $enabledCount / 共 $totalCount';
  }

  @override
  String get serviceVersion => '服务版本';

  @override
  String get servicePort => '服务端口';

  @override
  String get nfsV4Domain => 'NFSv4 域名';

  @override
  String get ftpsEnabled => 'FTPS 已启用';

  @override
  String get smbTransferLogEnabled => 'SMB 传输日志已启用';

  @override
  String get smbTransferLogDisabled => 'SMB 传输日志已禁用';

  @override
  String get smbTransferLog => 'SMB 传输日志';

  @override
  String get smbTransferLogSubtitle => '记录 SMB 文件访问与操作';

  @override
  String get afpTransferLogEnabled => 'AFP 传输日志已启用';

  @override
  String get afpTransferLogDisabled => 'AFP 传输日志已禁用';

  @override
  String get afpTransferLog => 'AFP 传输日志';

  @override
  String get afpTransferLogSubtitle => '记录 AFP 文件访问与操作';

  @override
  String get transferLogTitle => '传输日志设置';

  @override
  String get transferLogSubtitle => '配置各协议的日志记录级别';

  @override
  String get needEnableServiceFirst => '请先启用该服务';

  @override
  String get setLogLevel => '设置日志级别';

  @override
  String get userAccountTab => '用户账户';

  @override
  String get userGroupTab => '用户组';

  @override
  String get noUsers => '暂无用户';

  @override
  String get noGroups => '暂无用户组';

  @override
  String get failedToGetLogLevel => '获取日志级别失败';

  @override
  String get logLevelSettingsSaved => '日志级别设置已保存';

  @override
  String get failedToSave => '保存失败';

  @override
  String get transferLogLevel => '传输日志级别';

  @override
  String get applyChanges => '应用更改';

  @override
  String get noData => '暂无数据';

  @override
  String get noHistory => '暂无历史记录';

  @override
  String get failedToGetLogSettings => '获取日志设置失败';

  @override
  String get saving => '保存中…';

  @override
  String get logLevelCreate => '创建';

  @override
  String get logLevelWrite => '写入';

  @override
  String get logLevelMove => '移动';

  @override
  String get logLevelDelete => '删除';

  @override
  String get logLevelRead => '读取';

  @override
  String get logLevelRename => '重命名';

  @override
  String get statusExpired => '已过期';

  @override
  String get statusNormal => '正常';

  @override
  String get statusDisabled => '已禁用';

  @override
  String get userInfoUpdated => '用户信息已更新';

  @override
  String get saveFailed => '保存失败';

  @override
  String get enableUser => '启用用户';

  @override
  String get disableUser => '禁用用户';

  @override
  String confirmDisableUser(String name) {
    return '确定要禁用用户 \"$name\" 吗？禁用后该用户将无法登录。';
  }

  @override
  String confirmEnableUser(String name) {
    return '确定要启用用户 \"$name\" 吗？';
  }

  @override
  String get userDisabled => '用户已禁用';

  @override
  String get userEnabled => '用户已启用';

  @override
  String get operationFailed => '操作失败';

  @override
  String get resetPassword => '重置密码';

  @override
  String resetPasswordDialogTitle(String name) {
    return '为用户 \"$name\" 设置新密码';
  }

  @override
  String get newPassword => '新密码';

  @override
  String get passwordCannotBeEmpty => '密码不能为空';

  @override
  String get passwordResetSuccess => '密码已重置';

  @override
  String get resetPasswordFailed => '重置密码失败';

  @override
  String get userName => '用户名';

  @override
  String get description => '描述';

  @override
  String get email => '邮箱';

  @override
  String get groupName => '群组名称';

  @override
  String memberCount(int count) {
    return '$count 个成员';
  }

  @override
  String get viewGroupMembersRequiresDsm => '查看群组成员列表需要在 DSM Web 界面中操作';

  @override
  String get none => '无';

  @override
  String get reload => '重新加载';

  @override
  String get sharedFoldersLoadFailed => '共享文件夹加载失败';

  @override
  String get name => '名称';

  @override
  String get path => '路径';

  @override
  String get spaceUsage => '空间使用';

  @override
  String get quota => '配额';

  @override
  String get features => '特性';

  @override
  String get statusEncrypted => '加密';

  @override
  String get statusHidden => '隐藏';

  @override
  String get featureRecycleBin => '回收站';

  @override
  String get featureReadOnly => '只读';

  @override
  String get featureFileCompression => '文件压缩';

  @override
  String get featureDataIntegrityProtection => '数据完整性保护';

  @override
  String get featureAdvancedPermissions => '高级权限';

  @override
  String get featureSnapshot => '快照';

  @override
  String get featureMoving => '移动中';

  @override
  String get searchDeviceOrPage => '搜索设备、功能或页面';

  @override
  String get realtimePreparing => '实时服务准备中';

  @override
  String get realtimeConnecting => '实时连接中';

  @override
  String get realtimeReconnecting => '实时重连中';

  @override
  String get realtimeConnected => '实时已连接';

  @override
  String get systemVersionNotAvailable => '暂未获取到系统版本';

  @override
  String get share => '分享';

  @override
  String get errorContentCopied => '错误内容已复制';

  @override
  String get logCenterLoadFailed => '日志中心加载失败';

  @override
  String get copyError => '复制错误';

  @override
  String appLogFileLabel(String fileName) {
    return '应用日志：$fileName';
  }

  @override
  String get containerTab => '容器';

  @override
  String get composeTab => 'Compose';

  @override
  String get imageTab => '镜像';

  @override
  String get currentDataSource => '当前数据源';

  @override
  String get dsmDataSourceDescription => '第一版默认使用群晖原生容器数据源。';

  @override
  String get dpanelDataSourceDescription => 'dpanel 适配预留中，当前先展示模块骨架。';

  @override
  String get dpanelDataSourceDeveloping => 'dpanel 数据源开发中，当前先使用群晖数据源。';

  @override
  String get containerDataLoadFailed => '容器数据加载失败';

  @override
  String get pleaseRetryLater => '请稍后重试';

  @override
  String get noContainerData => '暂无容器数据';

  @override
  String get noComposeProjects => '暂无 Compose 项目';

  @override
  String get usingDsmComposeProjects =>
      '当前使用 DSM / Container Manager 原生 Compose 项目数据。';

  @override
  String get noImageData => '暂无镜像数据';

  @override
  String get running => '运行中';

  @override
  String get buildFailed => '构建失败';

  @override
  String get failed => '失败';

  @override
  String get containerUnknown => '未知';

  @override
  String get view => '查看';

  @override
  String get create => '新建';

  @override
  String get imageId => '镜像 ID';

  @override
  String containerCount(int count) {
    return '$count 个容器';
  }

  @override
  String get noDsmComposeProjects => '当前未获取到 DSM Compose 项目。';

  @override
  String get moreOptions => '更多操作';

  @override
  String get externalAccessLoadFailed => '外部访问加载失败';

  @override
  String get unnamedDevice => '未命名设备';

  @override
  String get unrecognizedModel => '未识别型号';

  @override
  String get currentlyNotEjectable => '当前不可弹出';

  @override
  String get updateAvailable => '有更新';

  @override
  String get terminalSettings => '终端设置';

  @override
  String get terminalSettingsSubtitle => 'SSH 与 Telnet 服务';

  @override
  String get powerManagement => '电源管理';

  @override
  String get powerManagementSubtitle => '关机与重启';

  @override
  String confirmDeleteDownloadTask(String title) {
    return '确定要删除 \"$title\" 吗？';
  }

  @override
  String get downloadTasksLoadFailed => '加载下载任务失败';

  @override
  String get logViewerComingSoon => '日志查看功能开发中';

  @override
  String get shareLinkCreate => '创建分享链接';

  @override
  String get shareLinkCopied => '链接已复制';

  @override
  String get shareLinkExpireDate => '过期时间';

  @override
  String get shareLinkNoLimit => '永不过期';

  @override
  String get shareLinkAccessCount => '允许访问次数';

  @override
  String get shareLinkAccessCountHint => '0 = 无限制';

  @override
  String get shareLinkSaveChanges => '保存修改';

  @override
  String get shareLinkSaveSuccess => '分享链接设置已保存';

  @override
  String get shareLinkDelete => '删除链接';

  @override
  String get shareLinkDeleteConfirm => '确定要取消此分享链接吗？';

  @override
  String get shareLinkDeleted => '分享链接已取消';

  @override
  String get sharingLinksTitle => '分享链接';

  @override
  String get sharingLinksEmpty => '暂无分享链接';

  @override
  String get sharingLinksEmptyHint => '在文件页面创建分享链接后可在此管理';

  @override
  String get sharingLinksLoadFailed => '加载失败';

  @override
  String get sharingLinksRetry => '重试';

  @override
  String get sharingLinksClearInvalid => '清除无效链接';

  @override
  String get sharingLinksClearInvalidConfirm => '确定要清除所有无效的分享链接吗？';

  @override
  String get sharingLinksClearSuccess => '已清除无效链接';

  @override
  String get sharingLinksEdit => '编辑分享链接';

  @override
  String get sharingLinksDelete => '删除分享链接';

  @override
  String sharingLinksDeleteConfirm(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get sharingLinksDeleted => '已删除';

  @override
  String get sharingLinksSaveSuccess => '已保存';

  @override
  String sharingLinksSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String sharingLinksClearFailed(String error) {
    return '清除失败：$error';
  }

  @override
  String sharingLinksDeleteFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String get sharingLinksCopied => '链接已复制';

  @override
  String get sharingLinksAccessCount => '访问次数';

  @override
  String get sharingLinksAccessCountUnlimited => '不限次数';

  @override
  String sharingLinksAccessCountRemaining(int count) {
    return '剩余 $count 次';
  }

  @override
  String get sharingLinksExpireDate => '有效期截止日期';

  @override
  String get sharingLinksAvailableDate => '生效开始日期';

  @override
  String get sharingLinksExpireDateNone => '不限制';

  @override
  String get sharingLinksPermanent => '永久';

  @override
  String get sharingLinksOwner => '所有者';

  @override
  String get sharingLinksStatusValid => '有效';

  @override
  String get sharingLinksStatusExpired => '已过期';

  @override
  String get sharingLinksSecurityHint => '安全共享请到 Web 界面操作';

  @override
  String get sharingLinksNoLimit => '不限制';

  @override
  String get downloadTargetDir => '目标文件夹';

  @override
  String get downloadTaskWaiting => '等待中';

  @override
  String get downloadTaskDownloading => '下载中';

  @override
  String get downloadTaskPaused => '已暂停';

  @override
  String get downloadTaskFinishing => '即将完成';

  @override
  String get downloadTaskFinished => '已完成';

  @override
  String get downloadTaskHashChecking => '校验中';

  @override
  String get downloadTaskPreSeeding => '等待做种';

  @override
  String get downloadTaskSeeding => '做种中';

  @override
  String get downloadTaskExtracting => '解压中';

  @override
  String get downloadTaskCaptchaNeeded => '需要验证码';

  @override
  String get downloadTaskError => '下载出错';

  @override
  String get downloadTaskBrokenLink => '错误链接';

  @override
  String get downloadTaskDestNotExist => '目标目录不存在';

  @override
  String get downloadTaskDestDeny => '目标目录无权限';

  @override
  String get downloadTaskDiskFull => '硬盘已满';

  @override
  String get downloadTaskQuotaReached => '已达空间配额';

  @override
  String get downloadTaskTimeout => '联机超时';

  @override
  String get downloadBtnNew => '新增';

  @override
  String get downloadBtnOk => '确定';

  @override
  String get downloadBtnCancel => '取消';

  @override
  String get downloadBtnRefresh => '刷新';

  @override
  String get downloadBtnRemove => '删除';

  @override
  String get downloadBtnResume => '恢复';

  @override
  String get downloadBtnStop => '暂停';

  @override
  String get downloadBtnClear => '清除';

  @override
  String get downloadBtnEnd => '结束';

  @override
  String get downloadBtnChange => '变更';

  @override
  String get downloadBtnHelp => '说明';

  @override
  String get downloadLblInputUrl => '输入网址';

  @override
  String get downloadLblInputFile => '打开文件';

  @override
  String get downloadLblDestFolder => '目的地文件夹';

  @override
  String get downloadLblFilename => '文件名称';

  @override
  String get downloadLblFileSize => '文件大小';

  @override
  String get downloadLblStatus => '状态';

  @override
  String get downloadLblProgress => '进度';

  @override
  String get downloadLblSpeed => '速度';

  @override
  String get downloadLblDownloaded => '已下载';

  @override
  String get downloadLblCreatedTime => '创建时间';

  @override
  String get downloadLblStartedTime => '开始时间';

  @override
  String get downloadLblConnectedPeers => '已联机的Peer数';

  @override
  String get downloadLblPeer => 'Peer数';

  @override
  String get downloadLblLeechers => '下载用户数';

  @override
  String get downloadLblSeeders => '种子数';

  @override
  String get downloadLblSeedElapsed => '已作种时间';

  @override
  String get downloadLblTransfered => '已传输';

  @override
  String get downloadLblUploadRate => '上传速度';

  @override
  String get downloadLblDownRate => '下载速度';

  @override
  String get downloadLblUrl => '网址';

  @override
  String get downloadLblUsername => '用户名';

  @override
  String get downloadLblTotalPieces => '分块总数';

  @override
  String get downloadLblDownloadedPieces => '已下载的分块数';

  @override
  String get downloadLblTimeLeft => '剩余时间';

  @override
  String get downloadMsgActionFailed => '要求的动作无法完成。';

  @override
  String get downloadMsgEndDoneDelErr => '成功结束选择的下载任务，但系统无法删除此下载任务。请手动删除。';

  @override
  String get downloadMsgInvalidUser => '不合法的用户。';

  @override
  String get downloadMsgReachLimit => '下载任务数已达到上限。';

  @override
  String get downloadWarningSelectItems => '请先勾选项目。';

  @override
  String get downloadWarningSelectShare => '请先选择目的地文件夹。';

  @override
  String get downloadWarningDiskFull => '此存储空间的可用空间不足。';

  @override
  String get downloadErrorNoTask => '下载任务不正确或已被删除。';

  @override
  String get downloadErrorNoPrivilege => '您没有权限读取此下载任务。';

  @override
  String get downloadErrorWrongFormat => '文件格式不正确。';

  @override
  String get downloadErrorWrongUrl => '网址的开头必须是http://、https://，或ftp://。';

  @override
  String get downloadErrorEmptyInput => '请输入网址。';

  @override
  String get downloadErrorNetwork => '创建网络联机失败。';

  @override
  String get downloadErrorServer => '发生未知的错误！';

  @override
  String get downloadErrorShareNotFound => '找不到有写入权限的文件夹。';

  @override
  String get downloadErrorUserRemoved => '帐号不存在或已被删除。';

  @override
  String get downloadErrorSelectNum => '只能选择一个下载任务。';

  @override
  String get downloadErrorReadTorrentFail => '无法读取 torrent 文件。';

  @override
  String get downloadErrorMagnet => '无法由磁力链接取得 torrent 文件的信息。';

  @override
  String get downloadErrorNoFileToEnd => '文件不存在。';

  @override
  String get downloadConfirmRemove => '您确定要删除此下载任务吗？';

  @override
  String get downloadConfirmEnd => '您确定要结束此下载任务吗？';

  @override
  String get downloadEndDesc => '此功能只适合无法继续下载的任务或有错误的任务。';

  @override
  String get downloadEndNoteFinished => '您无法结束此下载任务，下载任务已经完成。';

  @override
  String get downloadEndNoteNoFile => '您无法结束此下载任务，此任务还未开始下载。';

  @override
  String get downloadRedirectConfirm =>
      'Download Station 未启用。您要设置Download Station 吗？';

  @override
  String get downloadNotEnabled => '下载服务尚未启用。';

  @override
  String get downloadSeedDays => '天';

  @override
  String get downloadSeedHours => '小时';

  @override
  String get downloadSeedMins => '分钟';

  @override
  String get downloadSeedSeconds => '秒';

  @override
  String get downloadNextPage => '下一页';

  @override
  String get downloadPreviousPage => '上一页';

  @override
  String get downloadTitle => 'BT/PT/HTTP/FTP/NZB下载';

  @override
  String get titleDownloadManager => 'BT/PT/HTTP/FTP/NZB';

  @override
  String get downloadEmptyInputFile => '请打开要新增的文件。';

  @override
  String get downloadEmptyInputUrl => '请输入网址。';

  @override
  String get downloadComplete => '下载已完成。';

  @override
  String get downloadFailed => '下载失败。';

  @override
  String get downloadMsgAskHelp2 => '请求系统管理员解决此问题。';

  @override
  String get temporaryLocation => '暂存位置';

  @override
  String get userNoShareFolder => '您没有权限存取任何共享文件夹，请与系统管理员联络。';

  @override
  String get downloadErrorExceedFsMaxSize => '超过文件系统最大文件大小。';

  @override
  String get downloadErrorEncryptionLongPath => '加密文件路径过长。';

  @override
  String get downloadErrorLongPath => '文件路径过长。';

  @override
  String get downloadErrorDuplicateTorrent => '下载任务重复。';

  @override
  String get downloadErrorPremiumAccountRequire => '需要Premium账户。';

  @override
  String get downloadErrorNotSupportType => '不支持的文件类型。';

  @override
  String get downloadErrorFtpEncryptionNotSupportType => 'FTP加密不支持的文件类型。';

  @override
  String get downloadErrorExtractFailed => '解压失败。';

  @override
  String get downloadErrorInvalidTorrent => '无效的torrent文件。';

  @override
  String get downloadErrorAccountRequireStatus => '账户状态不符合要求。';

  @override
  String get downloadErrorTryItLater => '请稍后再试。';

  @override
  String get downloadErrorTaskEncryption => '任务加密出错。';

  @override
  String get downloadErrorMissingPython => '缺少Python组件。';

  @override
  String get downloadErrorPrivateVideo => '私有视频无法下载。';

  @override
  String get downloadErrorNzbMissingArticle => 'NZB文件缺少Article。';

  @override
  String get downloadErrorParchiveRepairFailed => 'Parchive修复失败。';

  @override
  String get downloadErrorInvalidAccountPassword => '账户密码无效。';
}
