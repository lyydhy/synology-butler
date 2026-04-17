// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Synology Butler';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get themeColor => 'Theme color';

  @override
  String get language => 'Language';

  @override
  String get followSystem => 'Follow system';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get simplifiedChinese => 'Simplified Chinese';

  @override
  String get english => 'English';

  @override
  String get loginTitle => 'Connect to your Synology NAS';

  @override
  String get deviceName => 'Device name';

  @override
  String get addressOrHost => 'Address / Domain / IP';

  @override
  String get port => 'Port';

  @override
  String get basePathOptional => 'Base path (optional)';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get useHttps => 'Use HTTPS';

  @override
  String get login => 'Log in';

  @override
  String get testingConnection => 'Testing…';

  @override
  String get testConnection => 'Test connection';

  @override
  String get loggingIn => 'Logging in…';

  @override
  String get quickLoginNeedPassword =>
      'No password saved, please enter on login page';

  @override
  String get loginInProgress => 'Logging in…';

  @override
  String get dashboardTitle => 'Home';

  @override
  String get currentConnection => 'Current connection';

  @override
  String get sessionStatus => 'Session status';

  @override
  String get deviceInfo => 'Device info';

  @override
  String get uptime => 'Uptime';

  @override
  String get cpu => 'CPU';

  @override
  String get memory => 'Memory';

  @override
  String get storage => 'Storage';

  @override
  String get noSessionPleaseLogin =>
      'No active session. Please log in to your NAS first.';

  @override
  String get online => 'Online';

  @override
  String get sidEstablished => 'SID established. DSM API is available.';

  @override
  String get unknown => 'Unknown';

  @override
  String get notAvailableYet => 'Not available yet';

  @override
  String get currentDevice => 'Current device';

  @override
  String get loginStatus => 'Login status';

  @override
  String get loggedInSidEstablished => 'Logged in (SID established)';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get filesTitle => 'Files';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get notInstalled => 'Not Installed';

  @override
  String get currentPath => 'Current path';

  @override
  String get sortByName => 'Sort by name';

  @override
  String get sortBySize => 'Sort by size';

  @override
  String get goParent => 'Go to parent';

  @override
  String get folderIsEmpty => 'This folder is empty';

  @override
  String get retry => 'Retry';

  @override
  String get createFolder => 'Create folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get uploadFile => 'Upload file';

  @override
  String get targetFolder => 'Target folder';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get noFileSelected => 'No file selected';

  @override
  String get uploading => 'Uploading…';

  @override
  String get startUpload => 'Start upload';

  @override
  String get rename => 'Rename';

  @override
  String get newName => 'New name';

  @override
  String get processing => 'Processing…';

  @override
  String get deleteFile => 'Delete file';

  @override
  String get deleteConfirm => 'Delete';

  @override
  String deleteConfirmHint(Object name) {
    return 'Delete $name?';
  }

  @override
  String get deleteSuccess => 'Deleted successfully';

  @override
  String get shareLink => 'Share link';

  @override
  String get close => 'Close';

  @override
  String get detail => 'Details';

  @override
  String get generateShareLink => 'Generate share link';

  @override
  String get downloadFilterAll => 'All';

  @override
  String get downloadFilterDownloading => 'Downloading';

  @override
  String get downloadFilterPaused => 'Paused';

  @override
  String get downloadFilterFinished => 'Finished';

  @override
  String get noTasksForFilter => 'No tasks for the selected filter';

  @override
  String get createDownloadTask => 'Create download task';

  @override
  String get downloadLinkOrMagnet => 'Download link / Magnet';

  @override
  String get submitting => 'Submitting…';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get deleteTask => 'Delete download task';

  @override
  String get operationSuccess => 'Operation successful';

  @override
  String get debugInfo => 'Debug info';

  @override
  String get debugCurrentConnection => 'Current connection';

  @override
  String get debugLocalStorage => 'Local storage';

  @override
  String get debugTips => 'Debug tips';

  @override
  String get savedUsername => 'Saved username';

  @override
  String get savedDeviceCount => 'Saved device count';

  @override
  String get serverManagement => 'Connection management';

  @override
  String get savedDevices => 'Saved devices';

  @override
  String get addNewDevice => 'Add new device';

  @override
  String get editDevice => 'Edit device';

  @override
  String get deleteDevice => 'Delete device';

  @override
  String get deviceDeleted => 'Device deleted';

  @override
  String get deviceUpdated => 'Device updated';

  @override
  String get switchDeviceRelogin => 'Switched device. Please log in again.';

  @override
  String get filePath => 'Path';

  @override
  String get fileType => 'Type';

  @override
  String get fileSize => 'Size';

  @override
  String get folder => 'Folder';

  @override
  String get file => 'File';

  @override
  String get taskId => 'Task ID';

  @override
  String get status => 'Status';

  @override
  String get downloadStatusWaiting => 'Waiting';

  @override
  String get downloadStatusDownloading => 'Downloading';

  @override
  String get downloadStatusPaused => 'Paused';

  @override
  String get downloadStatusFinished => 'Finished';

  @override
  String get downloadStatusSeeding => 'Seeding';

  @override
  String get downloadStatusHashChecking => 'Hash Checking';

  @override
  String get downloadStatusExtracting => 'Extracting';

  @override
  String get downloadStatusError => 'Error';

  @override
  String get downloadStatusUnknown => 'Unknown';

  @override
  String get downloadStatusFileHostingWaiting => 'Waiting for Source';

  @override
  String get downloadStatusCaptchaNeeded => 'Captcha Needed';

  @override
  String get downloadStatusFinishing => 'Finishing';

  @override
  String get downloadStatusPreSeeding => 'Pre-Seeding';

  @override
  String get downloadStatusPreprocessing => 'Preprocessing';

  @override
  String get downloadStatusDownloaded => 'Downloaded';

  @override
  String get downloadStatusPostProcessing => 'Post-Processing';

  @override
  String get progress => 'Progress';

  @override
  String get appLogsTitle => 'App logs';

  @override
  String get appLogsSubtitle =>
      'View local log files, copy content, or clear them quickly';

  @override
  String get appLogsEmpty => 'No log files yet';

  @override
  String get appLogsEmptyContent => 'This log is empty';

  @override
  String get appLogsCopySanitized => 'Copy sanitized content';

  @override
  String get appLogsExportToLogsDir => 'Export to logs directory';

  @override
  String get appLogsExportToDirectory => 'Export to selected folder';

  @override
  String get appLogsDeleteCurrent => 'Delete current log';

  @override
  String get appLogsDeleteAll => 'Delete all logs';

  @override
  String get appLogsCopied => 'Sanitized log copied';

  @override
  String appLogsExported(Object path) {
    return 'Exported to: $path';
  }

  @override
  String appLogsExportedToInternal(Object path) {
    return 'Sanitized log exported: $path';
  }

  @override
  String appLogsFileCount(Object count) {
    return '$count log files';
  }

  @override
  String get appLogsSanitizedBadge => 'Sanitized';

  @override
  String get appLogsRawBadge => 'Raw log';

  @override
  String get appLogsViewerHint =>
      'You are viewing sanitized content, which is safer to copy or export for troubleshooting.';

  @override
  String get controlPanelTitle => 'Control Panel';

  @override
  String get taskSchedulerTitle => 'Task Scheduler';

  @override
  String get externalDevicesTitle => 'External Devices';

  @override
  String get externalAccessTitle => 'External Access';

  @override
  String get indexServiceTitle => 'Indexing Service';

  @override
  String get sharedFoldersTitle => 'Shared Folders';

  @override
  String get userGroupsTitle => 'Users & Groups';

  @override
  String get informationCenterTitle => 'Information Center';

  @override
  String get noTasks => 'No scheduled tasks';

  @override
  String get noExternalDevices => 'No external devices connected';

  @override
  String get noDdnsRecords => 'No DDNS records';

  @override
  String get noSharedFolders => 'No shared folders';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get noGroupsFound => 'No groups found';

  @override
  String get executeNow => 'Execute Now';

  @override
  String get taskSubmitted => 'Task submitted for execution';

  @override
  String get executeFailed => 'Execution failed';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get ejectDevice => 'Eject Device';

  @override
  String get ejectSubmitted => 'Eject request submitted';

  @override
  String get ejectFailed => 'Eject failed';

  @override
  String get fileSystem => 'File System';

  @override
  String get mountPath => 'Mount Path';

  @override
  String get capacity => 'Capacity';

  @override
  String get nextAutoUpdateTime => 'Next auto update time';

  @override
  String get ipAddress => 'IP Address';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get refreshNow => 'Refresh Now';

  @override
  String get thumbnailQuality => 'Thumbnail Quality';

  @override
  String get thumbnailQualityUpdated => 'Thumbnail quality updated';

  @override
  String get rebuildIndex => 'Rebuild Index';

  @override
  String get rebuildIndexDesc =>
      'Re-trigger media indexing. Useful for missing thumbnails or abnormal index status.';

  @override
  String get rebuildSubmitted => 'Rebuild index request submitted';

  @override
  String get rebuildFailed => 'Rebuild failed';

  @override
  String get currentIndexStatus => 'Current Status';

  @override
  String get currentTask => 'Current Task';

  @override
  String get noIndexTasks => 'No indexing tasks';

  @override
  String historyDeleted(Object name) {
    return 'History deleted for $name';
  }

  @override
  String get connectionTestFailed => 'Connection test failed';

  @override
  String get copy => 'Copy';

  @override
  String get switchedToHttp =>
      'Switched to HTTP. Only use in trusted local networks.';

  @override
  String get selectFromHistory => 'Select from history';

  @override
  String get historyDevices => 'History devices';

  @override
  String get selectDeviceFirst => 'Please select a device first to quick login';

  @override
  String get quickLogin => 'Quick Login';

  @override
  String get enterPasswordToLogin => 'Enter password to sign in';

  @override
  String get addDevice => 'Add Device';

  @override
  String get done => 'Done';

  @override
  String get newAccountDevice => 'New Account / Device';

  @override
  String get connectionInfo => 'Connection Info';

  @override
  String get enterNasCredentials => 'Enter NAS address and DSM credentials';

  @override
  String get ignoreSslCert => 'Ignore SSL Certificate';

  @override
  String get ignoreSslCertHint =>
      'Only for self-signed or abnormal certificates';

  @override
  String get httpsOnly => 'Only available for HTTPS';

  @override
  String get rememberPassword => 'Remember Password';

  @override
  String get loginDsm => 'Login to DSM';

  @override
  String get dsm7Plus => 'DSM 7+';

  @override
  String get quickLoginReady => 'Quick login ready for you.';

  @override
  String get connectToDsm => 'Connect to your Synology DSM.';

  @override
  String get quickRelogin => 'Quick Re-login';

  @override
  String get quickReloginHint =>
      'Show this interface when history is available to reduce input.';

  @override
  String loginToNas(Object name) {
    return 'Login to $name';
  }

  @override
  String get loginToNasHint => 'Supports LAN IP, domain and port.';

  @override
  String get noUsernameTapChange =>
      'No username recorded, tap to change account';

  @override
  String get fill => 'Fill';

  @override
  String get changeAccount => 'Change Account';

  @override
  String get justUsed => 'Just used';

  @override
  String minutesAgo(Object n) {
    return 'Used $n minutes ago';
  }

  @override
  String hoursAgo(Object n) {
    return 'Used $n hours ago';
  }

  @override
  String daysAgo(Object n) {
    return 'Used $n days ago';
  }

  @override
  String get usedEarlier => 'Used earlier';

  @override
  String get noLoginTimeRecorded => 'No login time recorded';

  @override
  String selectedEnterPassword(Object name) {
    return 'Selected $name, enter password to login';
  }

  @override
  String get connectionSuccess => 'Connection successful: DSM Web API detected';

  @override
  String dsm6NotSupported(Object version) {
    return 'Detected $version. This app only supports DSM 7, DSM 6 login is not supported yet.';
  }

  @override
  String get switchedToNewAccount => 'Switched to new account / device login';

  @override
  String get sessionExpired =>
      'Session expired. Please login again to restore real-time connection.';

  @override
  String get enterNasAddress => 'Please enter NAS address or domain';

  @override
  String get enterPort => 'Please enter port';

  @override
  String get portRange => 'Port should be between 1 - 65535';

  @override
  String get enterUsername => 'Please enter username';

  @override
  String get enterPassword => 'Please enter password';

  @override
  String get selectDeviceThenPassword =>
      'Select a device then enter password to login';

  @override
  String get deviceReadyEnterPassword =>
      'Device ready, enter password to login';

  @override
  String get previewImage => 'Preview Image';

  @override
  String get download => 'Download';

  @override
  String get downloadAndOpen => 'Download and Open';

  @override
  String startDownloading(Object name) {
    return 'Starting download $name';
  }

  @override
  String downloadCompleteOpen(Object name) {
    return 'Starting download $name, will open when complete';
  }

  @override
  String downloadTaskComplete(Object title) {
    return '$title download complete';
  }

  @override
  String confirmDelete(Object name) {
    return 'Are you sure you want to delete \\\"$name\\\"?';
  }

  @override
  String downloadDirSet(Object path) {
    return 'Download directory set to $path';
  }

  @override
  String get selectUploadDir => 'Select Upload Directory';

  @override
  String loadFilesFailed(Object error) {
    return 'Failed to load files: $error';
  }

  @override
  String selectCurrentDir(Object path) {
    return 'Select current directory: $path';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get discardChanges => 'Discard changes?';

  @override
  String get discardChangesHint =>
      'Current file has unsaved changes. Are you sure you want to go back?';

  @override
  String get discard => 'Discard';

  @override
  String get saveSuccess => 'Saved successfully';

  @override
  String get save => 'Save';

  @override
  String get savedToAlbum => 'Saved to album';

  @override
  String get loadingImage => 'Loading image...';

  @override
  String get videoLoadFailed => 'Video load failed';

  @override
  String get selectOneFile => 'Please select at least one file to download';

  @override
  String addedDownloadTasks(Object count) {
    return 'Added $count download tasks';
  }

  @override
  String get batchDelete => 'Batch Delete';

  @override
  String confirmBatchDelete(Object count) {
    return 'Are you sure you want to delete $count selected items?';
  }

  @override
  String deletedCount(Object count) {
    return 'Deleted $count items';
  }

  @override
  String get uploadTaskAdded => 'Upload task added';

  @override
  String get videoPreviewHint => 'Open video preview from list';

  @override
  String get pathCopied => 'Path copied';

  @override
  String get open => 'Open';

  @override
  String get backgroundTaskRunning => 'Background task running';

  @override
  String backgroundTaskRunningCount(Object count) {
    return 'Background task running ($count)';
  }

  @override
  String taskComplete(Object name) {
    return '$name task complete';
  }

  @override
  String taskCompleteMultiple(Object name, Object count) {
    return '$name and $count other tasks complete';
  }

  @override
  String get transfer => 'Transfer';

  @override
  String get downloadAndOpenTitle => 'Download and Open';

  @override
  String get processingLabel => 'Processing';

  @override
  String get fileServicesTitle => 'File Services';

  @override
  String get noFileServices => 'No file service information available';

  @override
  String get fileServiceEnabled => 'Enabled';

  @override
  String get fileServiceDisabled => 'Disabled';

  @override
  String get defaultDeviceName => 'My NAS';

  @override
  String get splashTitle => 'Synology Manager';

  @override
  String get splashSubtitleReady => 'Your DSM 7+ Assistant';

  @override
  String get splashSubtitleRestoring =>
      'Restoring your connection and device status';

  @override
  String get splashSubtitlePreparing => 'Preparing login screen';

  @override
  String get splashLoadingStart => 'Starting...';

  @override
  String get splashLoadingEnter => 'Entering...';

  @override
  String get splashLoadingLogin => 'Redirecting to login...';

  @override
  String get dashboardSectionApps => 'Apps';

  @override
  String get dashboardSectionAppsSubtitle => 'Quick access to common features';

  @override
  String get dashboardContainerManagement => 'Containers';

  @override
  String get dashboardContainerManagementDesc =>
      'View containers and Compose projects';

  @override
  String get dashboardTransfers => 'Transfers';

  @override
  String get dashboardTransfersDesc => 'Manage recent uploads and downloads';

  @override
  String get dashboardControlPanel => 'Control Panel';

  @override
  String get dashboardControlPanelDesc =>
      'Access system configuration by priority';

  @override
  String get dashboardInformationCenter => 'Info Center';

  @override
  String get dashboardInformationCenterDesc =>
      'View system and storage details';

  @override
  String get dashboardPerformance => 'Performance';

  @override
  String get dashboardPerformanceDesc => 'View CPU and memory status';

  @override
  String get dashboardStorage => 'Storage';

  @override
  String get dashboardStorageEmpty => 'Storage information not available';

  @override
  String get dashboardUptime => 'Uptime';

  @override
  String get storageLabel => 'Storage';

  @override
  String storageLabelN(Object n) {
    return 'Storage $n';
  }

  @override
  String usedSlashTotal(Object used, Object total) {
    return 'Used $used / Total $total';
  }

  @override
  String usedSlashUnknown(Object used) {
    return 'Used $used / Total --';
  }

  @override
  String unknownSlashTotal(Object total) {
    return 'Used -- / Total $total';
  }

  @override
  String get usedUnknown => 'Used -- / Total --';

  @override
  String confirmDeleteName(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String downloadDirSetTo(Object path) {
    return 'Download directory set to $path';
  }

  @override
  String startDownloadingName(Object name) {
    return 'Starting download of $name';
  }

  @override
  String get previewText => 'Preview Text';

  @override
  String get previewNfo => 'Preview NFO';

  @override
  String get settingsConnectionStorageSubtitle =>
      'Manage NAS connections and local download directory';

  @override
  String get serverManagementHint =>
      'View, switch, edit and delete saved devices';

  @override
  String settingsCurrentServer(String name) {
    return 'Current: $name';
  }

  @override
  String get downloadDirectoryHint =>
      'Choose on first download, modify here later';

  @override
  String get sharingLinksHint => 'View and copy created share links';

  @override
  String get themeColorGreen => 'Green';

  @override
  String get themeColorOrange => 'Orange';

  @override
  String get themeColorPurple => 'Purple';

  @override
  String get themeColorBlue => 'Blue';

  @override
  String get settingsConnectionStorage => 'Connection & Storage';

  @override
  String get settingsConnectionManagement => 'Connection Management';

  @override
  String get settingsDownloadDirectory => 'Download Directory';

  @override
  String get settingsDownloadDirUpdated => 'Download directory updated';

  @override
  String get settingsAppearanceLanguage => 'Appearance & Language';

  @override
  String get settingsAppearanceSubtitle =>
      'Adjust app display style and language';

  @override
  String get settingsAppSupport => 'App & Support';

  @override
  String get settingsAppSupportSubtitle =>
      'Keep common support entries, remove debug and low-frequency features';

  @override
  String get settingsLogout => 'Logout';

  @override
  String get settingsLogoutSubtitle =>
      'Clear current session and saved login state';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutSubtitle => 'About app';

  @override
  String get packageCenter => 'Package Center';

  @override
  String get synologyPhotos => 'Synology Photos';

  @override
  String get packageCenterDesc => 'Browse and install packages';

  @override
  String get packageAll => 'All';

  @override
  String get packageInstalled => 'Installed';

  @override
  String get packageUpdatable => 'Updatable';

  @override
  String packageTask(Object status) {
    return 'Package Task: $status';
  }

  @override
  String get packageListFailed => 'Failed to load package list';

  @override
  String get selectInstallLocation => 'Select Install Location';

  @override
  String get selectInstallLocationHint =>
      'Select the volume to install the package';

  @override
  String storeVersion(Object version) {
    return 'Store Version $version';
  }

  @override
  String installedVersion(Object version) {
    return 'Installed $version';
  }

  @override
  String startRequestSent(Object name) {
    return 'Start request sent: $name';
  }

  @override
  String stopRequestSent(Object name) {
    return 'Stop request sent: $name';
  }

  @override
  String get confirmUninstall => 'Confirm Uninstall';

  @override
  String confirmUninstallMessage(Object name) {
    return 'Are you sure you want to uninstall $name?';
  }

  @override
  String uninstallRequestSent(Object name) {
    return 'Uninstall request sent: $name';
  }

  @override
  String get confirmUpdateImpact => 'Confirm Update Impact';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get continueAction => 'Continue';

  @override
  String packageTaskComplete(Object name) {
    return '$name install/update task completed or submitted';
  }

  @override
  String packageInstallFailed(Object error) {
    return 'Package installation failed: $error';
  }

  @override
  String get transfersTitle => 'Transfers';

  @override
  String get clearCompleted => 'Clear completed records';

  @override
  String get clearFailed => 'Clear failed records';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get filterFailed => 'Failed';

  @override
  String get deleteCompleted => 'Clear Completed';

  @override
  String get deleteFailedRecords => 'Clear Failed Records';

  @override
  String get openedWithSystem => 'Opened with system handler';

  @override
  String directory(Object path) {
    return 'Directory: $path';
  }

  @override
  String get openDirectory => 'Open Directory';

  @override
  String get removeRecord => 'Remove Record';

  @override
  String get reasonCopied => 'Failure reason copied';

  @override
  String containerSuccess(Object action, Object name) {
    return '$action container success: $name';
  }

  @override
  String containerFailed(Object action, Object error) {
    return '$action container failed: $error';
  }

  @override
  String get containerManagement => 'Container Management';

  @override
  String get containerAll => '全部';

  @override
  String get containerRunning => 'Running';

  @override
  String get containerStopped => 'Stopped';

  @override
  String get createNew => 'Create New';

  @override
  String get filterLatest => 'latest';

  @override
  String get filterOtherTags => 'Other Tags';

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortNameAsc => 'Name A-Z';

  @override
  String get sortNameDesc => 'Name Z-A';

  @override
  String get sortTagAsc => 'Tag A-Z';

  @override
  String get sortTagDesc => 'Tag Z-A';

  @override
  String get sortSizeDesc => 'Size High to Low';

  @override
  String get sortSizeAsc => 'Size Low to High';

  @override
  String get restart => 'Restart';

  @override
  String get forceStop => 'Force Stop';

  @override
  String ports(Object ports) {
    return 'Ports: $ports';
  }

  @override
  String get viewAction => 'View';

  @override
  String get performanceMonitor => 'Performance Monitor';

  @override
  String get clearHistoryAndRefresh => 'Clear history and refresh';

  @override
  String get overview => 'Overview';

  @override
  String get network => 'Network';

  @override
  String get disk => 'Disk';

  @override
  String loadFailed(Object error) {
    return 'Load failed: $error';
  }

  @override
  String get connectionManagement => 'Connection Management';

  @override
  String get noSavedDevices => 'No saved devices';

  @override
  String get addDeviceHint =>
      'Add a NAS connection first, then you can quickly switch here.';

  @override
  String get addNewConnection => 'Add New Connection';

  @override
  String get savedConnections => 'Saved Connections';

  @override
  String get noCurrentDevice => 'No device connected';

  @override
  String currentDeviceName(Object name) {
    return 'Current device: $name';
  }

  @override
  String confirmDeleteDevice(Object name) {
    return 'Are you sure you want to delete device \"$name\"?';
  }

  @override
  String get recentTransfers => 'Recent Transfers';

  @override
  String get noTransfersHint =>
      'No tasks yet. New uploads and downloads will appear here.';

  @override
  String get transfersHint =>
      'Check active and failed tasks first. Completed records can be cleared anytime.';

  @override
  String get noTransfersInFilter => 'No transfer tasks in this filter';

  @override
  String get transfersAppearHere =>
      'New uploads, downloads, and retries will appear here.';

  @override
  String get upload => 'Upload';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String uploadTo(Object path) {
    return 'Upload to $path';
  }

  @override
  String saveTo(Object path) {
    return 'Save to $path';
  }

  @override
  String get moreActions => 'More actions';

  @override
  String get collapseDetails => 'Collapse details';

  @override
  String get viewDetails => 'View details';

  @override
  String get copyErrorReason => 'Copy error reason';

  @override
  String get copyPath => 'Copy path';

  @override
  String get errorCopied => 'Error reason copied';

  @override
  String get copyReason => 'Copy reason';

  @override
  String get removeRecordAndFile => 'Delete record and file';

  @override
  String resultLabel(Object message) {
    return 'Result: $message';
  }

  @override
  String reasonLabel(Object message) {
    return 'Reason: $message';
  }

  @override
  String get networkTitle => 'Network';

  @override
  String get networkInterfaces => 'Network Interfaces';

  @override
  String get proxySettings => 'Proxy Settings';

  @override
  String get gatewayInfo => 'Gateway Info';

  @override
  String get networkGeneral => 'General';

  @override
  String get noNetworkInfo => 'No network information available';

  @override
  String get hostname => 'Hostname';

  @override
  String get defaultGateway => 'Default Gateway';

  @override
  String get ipv6Gateway => 'IPv6 Gateway';

  @override
  String get dnsPrimary => 'Primary DNS';

  @override
  String get dnsSecondary => 'Secondary DNS';

  @override
  String get manual => 'Manual';

  @override
  String get workgroup => 'Workgroup';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get subnetMask => 'Subnet Mask';

  @override
  String get dhcp => 'DHCP';

  @override
  String get ipv6Address => 'IPv6 Address';

  @override
  String get interface => 'Interface';

  @override
  String get address => 'Address';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get coreFeatures => 'Core Features';

  @override
  String get systemManagement => 'System Management';

  @override
  String get infoCenterSubtitle => 'System info and status overview';

  @override
  String get updateStatusSubtitle => 'System version and update check';

  @override
  String get externalAccessSubtitle => 'DDNS and remote connection';

  @override
  String get indexServiceSubtitle => 'Thumbnail quality and index rebuild';

  @override
  String get taskSchedulerSubtitle => 'Scheduled tasks and execution';

  @override
  String get externalDevicesSubtitle => 'USB and storage device management';

  @override
  String get sharedFoldersSubtitle => 'File sharing and permissions';

  @override
  String get userGroupsSubtitle => 'Accounts and permission management';

  @override
  String get fileServicesSubtitle => 'SMB / NFS / FTP / SFTP';

  @override
  String get networkSubtitle => 'Interfaces, proxy and gateway';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get terminalTitle => 'Terminal Settings';

  @override
  String get terminalSubtitle => 'SSH and Telnet services';

  @override
  String get fileServicesStatusSummary => 'File Services Status Summary';

  @override
  String fileServicesEnabledCount(Object enabledCount, Object totalCount) {
    return 'Enabled $enabledCount / $totalCount total';
  }

  @override
  String get serviceVersion => 'Service Version';

  @override
  String get servicePort => 'Service Port';

  @override
  String get nfsV4Domain => 'NFSv4 Domain';

  @override
  String get ftpsEnabled => 'FTPS Enabled';

  @override
  String get smbTransferLogEnabled => 'SMB transfer log enabled';

  @override
  String get smbTransferLogDisabled => 'SMB transfer log disabled';

  @override
  String get smbTransferLog => 'SMB Transfer Log';

  @override
  String get smbTransferLogSubtitle => 'Record SMB file access and operations';

  @override
  String get afpTransferLogEnabled => 'AFP transfer log enabled';

  @override
  String get afpTransferLogDisabled => 'AFP transfer log disabled';

  @override
  String get afpTransferLog => 'AFP Transfer Log';

  @override
  String get afpTransferLogSubtitle => 'Record AFP file access and operations';

  @override
  String get transferLogTitle => 'Transfer Log Settings';

  @override
  String get transferLogSubtitle => 'Configure log levels for each protocol';

  @override
  String get needEnableServiceFirst => 'Please enable this service first';

  @override
  String get setLogLevel => 'Set log level';

  @override
  String get userAccountTab => 'User Accounts';

  @override
  String get userGroupTab => 'User Groups';

  @override
  String get noUsers => 'No users';

  @override
  String get noGroups => 'No groups';

  @override
  String get failedToGetLogLevel => 'Failed to get log level';

  @override
  String get logLevelSettingsSaved => 'Log level settings saved';

  @override
  String get failedToSave => 'Failed to save';

  @override
  String get transferLogLevel => 'Transfer Log Level';

  @override
  String get applyChanges => 'Apply Changes';

  @override
  String get noData => 'No data';

  @override
  String get noHistory => 'No history';

  @override
  String get failedToGetLogSettings => 'Failed to get log settings';

  @override
  String get saving => 'Saving…';

  @override
  String get logLevelCreate => 'Create';

  @override
  String get logLevelWrite => 'Write';

  @override
  String get logLevelMove => 'Move';

  @override
  String get logLevelDelete => 'Delete';

  @override
  String get logLevelRead => 'Read';

  @override
  String get logLevelRename => 'Rename';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusNormal => 'Normal';

  @override
  String get statusDisabled => 'Disabled';

  @override
  String get userInfoUpdated => 'User info updated';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get enableUser => 'Enable User';

  @override
  String get disableUser => 'Disable User';

  @override
  String confirmDisableUser(String name) {
    return 'Disable user \"$name\"? The user will not be able to log in after disabling.';
  }

  @override
  String confirmEnableUser(String name) {
    return 'Enable user \"$name\"?';
  }

  @override
  String get userDisabled => 'User disabled';

  @override
  String get userEnabled => 'User enabled';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String resetPasswordDialogTitle(String name) {
    return 'Set new password for user \"$name\"';
  }

  @override
  String get newPassword => 'New Password';

  @override
  String get passwordCannotBeEmpty => 'Password cannot be empty';

  @override
  String get passwordResetSuccess => 'Password reset';

  @override
  String get resetPasswordFailed => 'Failed to reset password';

  @override
  String get userName => 'Username';

  @override
  String get description => 'Description';

  @override
  String get email => 'Email';

  @override
  String get groupName => 'Group Name';

  @override
  String memberCount(int count) {
    return '$count members';
  }

  @override
  String get viewGroupMembersRequiresDsm =>
      'Viewing group members requires operation in DSM Web interface';

  @override
  String get none => 'None';

  @override
  String get reload => 'Reload';

  @override
  String get sharedFoldersLoadFailed => 'Failed to load shared folders';

  @override
  String get name => 'Name';

  @override
  String get path => 'Path';

  @override
  String get spaceUsage => 'Space Usage';

  @override
  String get quota => 'Quota';

  @override
  String get features => 'Features';

  @override
  String get statusEncrypted => 'Encrypted';

  @override
  String get statusHidden => 'Hidden';

  @override
  String get featureRecycleBin => 'Recycle Bin';

  @override
  String get featureReadOnly => 'Read Only';

  @override
  String get featureFileCompression => 'File Compression';

  @override
  String get featureDataIntegrityProtection => 'Data Integrity Protection';

  @override
  String get featureAdvancedPermissions => 'Advanced Permissions';

  @override
  String get featureSnapshot => 'Snapshot';

  @override
  String get featureMoving => 'Moving';

  @override
  String get searchDeviceOrPage => 'Search devices, features or pages';

  @override
  String get realtimePreparing => 'Realtime service preparing';

  @override
  String get realtimeConnecting => 'Realtime connecting';

  @override
  String get realtimeReconnecting => 'Realtime reconnecting';

  @override
  String get realtimeConnected => 'Realtime connected';

  @override
  String get systemVersionNotAvailable => 'System version not available';

  @override
  String get share => 'Share';

  @override
  String get errorContentCopied => 'Error content copied';

  @override
  String get logCenterLoadFailed => 'Failed to load log center';

  @override
  String get copyError => 'Copy Error';

  @override
  String appLogFileLabel(String fileName) {
    return 'App log: $fileName';
  }

  @override
  String get containerTab => 'Containers';

  @override
  String get composeTab => 'Compose';

  @override
  String get imageTab => 'Images';

  @override
  String get currentDataSource => 'Current Data Source';

  @override
  String get dsmDataSourceDescription =>
      'First version uses Synology native container data source by default.';

  @override
  String get dpanelDataSourceDescription =>
      'dpanel adapter reserved, showing module skeleton first.';

  @override
  String get dpanelDataSourceDeveloping =>
      'dpanel data source under development, using Synology data source for now.';

  @override
  String get containerDataLoadFailed => 'Failed to load container data';

  @override
  String get pleaseRetryLater => 'Please retry later';

  @override
  String get noContainerData => 'No container data';

  @override
  String get noComposeProjects => 'No Compose projects';

  @override
  String get usingDsmComposeProjects =>
      'Using DSM / Container Manager native Compose project data.';

  @override
  String get noImageData => 'No image data';

  @override
  String get running => 'Running';

  @override
  String get buildFailed => 'Build Failed';

  @override
  String get failed => 'Failed';

  @override
  String get containerUnknown => 'Unknown';

  @override
  String get view => 'View';

  @override
  String get create => 'Create';

  @override
  String get imageId => 'Image ID';

  @override
  String containerCount(int count) {
    return '$count containers';
  }

  @override
  String get noDsmComposeProjects => 'No DSM Compose projects fetched.';

  @override
  String get moreOptions => 'More Options';

  @override
  String get externalAccessLoadFailed => 'Failed to load external access';

  @override
  String get unnamedDevice => 'Unnamed Device';

  @override
  String get unrecognizedModel => 'Unrecognized Model';

  @override
  String get currentlyNotEjectable => 'Currently Not Ejectable';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get terminalSettings => 'Terminal Settings';

  @override
  String get terminalSettingsSubtitle => 'SSH & Telnet Services';

  @override
  String get powerManagement => 'Power Management';

  @override
  String get powerManagementSubtitle => 'Shutdown & Restart';

  @override
  String confirmDeleteDownloadTask(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get downloadTasksLoadFailed => 'Failed to load download tasks';

  @override
  String get logViewerComingSoon => 'Log viewer coming soon';

  @override
  String get shareLinkCreate => 'Create Share Link';

  @override
  String get shareLinkCopied => 'Link copied';

  @override
  String get shareLinkExpireDate => 'Expiration Date';

  @override
  String get shareLinkNoLimit => 'Never expires';

  @override
  String get shareLinkAccessCount => 'Access Count Limit';

  @override
  String get shareLinkAccessCountHint => '0 = unlimited';

  @override
  String get shareLinkSaveChanges => 'Save Changes';

  @override
  String get shareLinkSaveSuccess => 'Share link settings saved';

  @override
  String get shareLinkDelete => 'Delete Link';

  @override
  String get shareLinkDeleteConfirm => 'Delete this share link?';

  @override
  String get shareLinkDeleted => 'Share link deleted';

  @override
  String get sharingLinksTitle => 'Sharing Links';

  @override
  String get sharingLinksEmpty => 'No sharing links';

  @override
  String get sharingLinksEmptyHint =>
      'Create share links from the Files page to manage them here';

  @override
  String get sharingLinksLoadFailed => 'Failed to load';

  @override
  String get sharingLinksRetry => 'Retry';

  @override
  String get sharingLinksClearInvalid => 'Clear Invalid Links';

  @override
  String get sharingLinksClearInvalidConfirm =>
      'Clear all invalid share links?';

  @override
  String get sharingLinksClearSuccess => 'Invalid links cleared';

  @override
  String get sharingLinksEdit => 'Edit Share Link';

  @override
  String get sharingLinksDelete => 'Delete Share Link';

  @override
  String sharingLinksDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get sharingLinksDeleted => 'Deleted';

  @override
  String get sharingLinksSaveSuccess => 'Saved';

  @override
  String sharingLinksSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String sharingLinksClearFailed(String error) {
    return 'Clear failed: $error';
  }

  @override
  String sharingLinksDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get sharingLinksCopied => 'Link copied';

  @override
  String get sharingLinksAccessCount => 'Access Count';

  @override
  String get sharingLinksAccessCountUnlimited => 'Unlimited';

  @override
  String sharingLinksAccessCountRemaining(int count) {
    return '$count remaining';
  }

  @override
  String get sharingLinksExpireDate => 'Expiration Date';

  @override
  String get sharingLinksAvailableDate => 'Available From';

  @override
  String get sharingLinksExpireDateNone => 'No limit';

  @override
  String get sharingLinksPermanent => 'Permanent';

  @override
  String get sharingLinksOwner => 'Owner';

  @override
  String get sharingLinksStatusValid => 'Valid';

  @override
  String get sharingLinksStatusExpired => 'Expired';

  @override
  String get sharingLinksSecurityHint =>
      'For secure sharing, use the Web interface';

  @override
  String get sharingLinksNoLimit => 'No limit';

  @override
  String get downloadTargetDir => 'Target folder';

  @override
  String get downloadTaskWaiting => 'Waiting';

  @override
  String get downloadTaskDownloading => 'Downloading';

  @override
  String get downloadTaskPaused => 'Paused';

  @override
  String get downloadTaskFinishing => 'Finishing';

  @override
  String get downloadTaskFinished => 'Finished';

  @override
  String get downloadTaskHashChecking => 'Hash Checking';

  @override
  String get downloadTaskPreSeeding => 'Pre-seeding';

  @override
  String get downloadTaskSeeding => 'Seeding';

  @override
  String get downloadTaskExtracting => 'Extracting';

  @override
  String get downloadTaskCaptchaNeeded => 'Captcha Needed';

  @override
  String get downloadTaskError => 'Error';

  @override
  String get downloadTaskBrokenLink => 'Broken Link';

  @override
  String get downloadTaskDestNotExist => 'Destination Not Found';

  @override
  String get downloadTaskDestDeny => 'Destination Access Denied';

  @override
  String get downloadTaskDiskFull => 'Disk Full';

  @override
  String get downloadTaskQuotaReached => 'Quota Reached';

  @override
  String get downloadTaskTimeout => 'Connection Timeout';

  @override
  String get downloadBtnNew => 'New';

  @override
  String get downloadBtnOk => 'OK';

  @override
  String get downloadBtnCancel => 'Cancel';

  @override
  String get downloadBtnRefresh => 'Refresh';

  @override
  String get downloadBtnRemove => 'Remove';

  @override
  String get downloadBtnResume => 'Resume';

  @override
  String get downloadBtnStop => 'Stop';

  @override
  String get downloadBtnClear => 'Clear';

  @override
  String get downloadBtnEnd => 'End';

  @override
  String get downloadBtnChange => 'Change';

  @override
  String get downloadBtnHelp => 'Help';

  @override
  String get downloadLblInputUrl => 'Input URL';

  @override
  String get downloadLblInputFile => 'Open File';

  @override
  String get downloadLblDestFolder => 'Destination Folder';

  @override
  String get downloadLblFilename => 'File Name';

  @override
  String get downloadLblFileSize => 'File Size';

  @override
  String get downloadLblStatus => 'Status';

  @override
  String get downloadLblProgress => 'Progress';

  @override
  String get downloadLblSpeed => 'Speed';

  @override
  String get downloadLblDownloaded => 'Downloaded';

  @override
  String get downloadLblCreatedTime => 'Created Time';

  @override
  String get downloadLblStartedTime => 'Started Time';

  @override
  String get downloadLblConnectedPeers => 'Connected Peers';

  @override
  String get downloadLblPeer => 'Peers';

  @override
  String get downloadLblLeechers => 'Leechers';

  @override
  String get downloadLblSeeders => 'Seeders';

  @override
  String get downloadLblSeedElapsed => 'Seeding Time';

  @override
  String get downloadLblTransfered => 'Transferred';

  @override
  String get downloadLblUploadRate => 'Upload Speed';

  @override
  String get downloadLblDownRate => 'Download Speed';

  @override
  String get downloadLblUrl => 'URL';

  @override
  String get downloadLblUsername => 'Username';

  @override
  String get downloadLblTotalPieces => 'Total Pieces';

  @override
  String get downloadLblDownloadedPieces => 'Downloaded Pieces';

  @override
  String get downloadLblTimeLeft => 'Time Left';

  @override
  String get downloadMsgActionFailed => 'Action failed.';

  @override
  String get downloadMsgEndDoneDelErr =>
      'Task ended but failed to delete. Please delete manually.';

  @override
  String get downloadMsgInvalidUser => 'Invalid user.';

  @override
  String get downloadMsgReachLimit => 'Download limit reached.';

  @override
  String get downloadWarningSelectItems => 'Please select an item first.';

  @override
  String get downloadWarningSelectShare =>
      'Please select a destination folder first.';

  @override
  String get downloadWarningDiskFull => 'Not enough free space on this volume.';

  @override
  String get downloadErrorNoTask =>
      'Download task is invalid or has been deleted.';

  @override
  String get downloadErrorNoPrivilege =>
      'You do not have permission to access this task.';

  @override
  String get downloadErrorWrongFormat => 'File format is incorrect.';

  @override
  String get downloadErrorWrongUrl =>
      'URL must start with http://, https://, or ftp://.';

  @override
  String get downloadErrorEmptyInput => 'Please enter a URL.';

  @override
  String get downloadErrorNetwork => 'Failed to establish network connection.';

  @override
  String get downloadErrorServer => 'An unknown error occurred!';

  @override
  String get downloadErrorShareNotFound => 'No writable folder found.';

  @override
  String get downloadErrorUserRemoved =>
      'Account does not exist or has been removed.';

  @override
  String get downloadErrorSelectNum =>
      'Only one download task can be selected.';

  @override
  String get downloadErrorReadTorrentFail => 'Failed to read torrent file.';

  @override
  String get downloadErrorMagnet =>
      'Failed to get torrent info from magnet link.';

  @override
  String get downloadErrorNoFileToEnd => 'File does not exist.';

  @override
  String get downloadConfirmRemove =>
      'Are you sure you want to delete this download task?';

  @override
  String get downloadConfirmEnd =>
      'Are you sure you want to end this download task?';

  @override
  String get downloadEndDesc =>
      'This is only for tasks that cannot continue downloading or have errors.';

  @override
  String get downloadEndNoteFinished => 'Cannot end a completed download task.';

  @override
  String get downloadEndNoteNoFile =>
      'Cannot end a task that has not started downloading.';

  @override
  String get downloadRedirectConfirm =>
      'Download Station is not enabled. Would you like to configure it?';

  @override
  String get downloadNotEnabled => 'Download service is not enabled.';

  @override
  String get downloadSeedDays => 'days';

  @override
  String get downloadSeedHours => 'hours';

  @override
  String get downloadSeedMins => 'minutes';

  @override
  String get downloadSeedSeconds => 'seconds';

  @override
  String get downloadNextPage => 'Next Page';

  @override
  String get downloadPreviousPage => 'Previous Page';

  @override
  String get downloadTitle => 'BT/PT/HTTP/FTP/NZB Downloads';

  @override
  String get titleDownloadManager => 'BT/PT/HTTP/FTP/NZB';

  @override
  String get downloadEmptyInputFile => 'Please open a file to add.';

  @override
  String get downloadEmptyInputUrl => 'Please enter a URL.';

  @override
  String get downloadComplete => 'Download completed.';

  @override
  String get downloadFailed => 'Download failed.';

  @override
  String get downloadMsgAskHelp2 => 'Please contact your system administrator.';

  @override
  String get temporaryLocation => 'Temporary Location';

  @override
  String get userNoShareFolder =>
      'You have no access to any shared folders. Contact your administrator.';

  @override
  String get downloadErrorExceedFsMaxSize =>
      'File size exceeds the filesystem maximum.';

  @override
  String get downloadErrorEncryptionLongPath =>
      'Encrypted file path is too long.';

  @override
  String get downloadErrorLongPath => 'File path is too long.';

  @override
  String get downloadErrorDuplicateTorrent => 'Duplicate download task.';

  @override
  String get downloadErrorPremiumAccountRequire => 'Premium account required.';

  @override
  String get downloadErrorNotSupportType => 'File type not supported.';

  @override
  String get downloadErrorFtpEncryptionNotSupportType =>
      'FTP encryption file type not supported.';

  @override
  String get downloadErrorExtractFailed => 'Extraction failed.';

  @override
  String get downloadErrorInvalidTorrent => 'Invalid torrent file.';

  @override
  String get downloadErrorAccountRequireStatus =>
      'Account status requirement not met.';

  @override
  String get downloadErrorTryItLater => 'Please try again later.';

  @override
  String get downloadErrorTaskEncryption => 'Task encryption error.';

  @override
  String get downloadErrorMissingPython => 'Missing Python component.';

  @override
  String get downloadErrorPrivateVideo => 'Private video cannot be downloaded.';

  @override
  String get downloadErrorNzbMissingArticle => 'NZB file missing article.';

  @override
  String get downloadErrorParchiveRepairFailed => 'Parchive repair failed.';

  @override
  String get downloadErrorInvalidAccountPassword => 'Invalid account password.';
}
