class AppConstants {
  static const savedServersKey = 'saved_servers';
  static const savedCurrentServerIdKey = 'saved_current_server_id';
  static const savedSidKey = 'saved_sid';
  static const savedSynoTokenKey = 'saved_syno_token';
  static const savedCookieHeaderKey = 'saved_cookie_header';
  static const savedRequestHashSeedKey = 'saved_request_hash_seed';
  static const savedAuthTokenKey = 'saved_auth_token';
  static const savedUsernameKey = 'saved_username';
  static const savedRememberPasswordKey = 'saved_remember_password';
  static const savedPasswordPrefix = 'saved_password_';
  static const savedServerUsernamesKey = 'saved_server_usernames';
  static const savedServerLastUsedKey = 'saved_server_last_used';
  static const sessionExpiredFlagKey = 'session_expired_flag';
  static const themeModeKey = 'theme_mode';
  static const themeColorKey = 'theme_color';
  static const localeKey = 'locale';
  static const downloadDirectoryKey = 'download_directory';
  static const transferHistoryKey = 'transfer_history';
  static const pendingExternalShareKey = 'pending_external_share';
  static const containerDataSourceKey = 'container_data_source';

  /// DSM realtime websocket 主动拉取当前利用率的轮询间隔（秒）。
  static const realtimeRequestIntervalSeconds = 3;

  /// Download Station 任务列表轮询间隔（秒）。
  static const downloadTaskPollIntervalSeconds = 5;

  /// Download Station 默认下载目标文件夹。
  static const downloadDefaultDestination = 'Download';

  /// SnackBar 默认显示时长（秒）
  static const snackBarDurationSeconds = 3;
}
