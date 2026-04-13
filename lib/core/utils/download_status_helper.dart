import '../utils/l10n.dart';

/// DownloadStation2 Task 数字状态码 → 显示文本映射
/// 来源：DSM Download Station JS getStatusString()
///
/// 常规状态：
///   1/11/12 = waiting（等待）
///   2 = downloading（下载中）
///   3 = paused（已暂停）
///   4/13/14 = finishing（完成中/后处理）
///   5 = finished（已完成）
///   6 = hash_checking（哈希校验）
///   7 = preseeding（做种准备）
///   8 = seeding（做种中）
///   9 = filehosting_waiting（站源等待）
///   10 = extracting（解压中）
///   15 = captcha_needed（需要验证码）
///
/// 错误状态（101+）：
///   102 = broken_link（链接失效）
///   103 = dest_not_exist（目标目录不存在）
///   104 = dest_deny（目标目录无权限）
///   105 = disk_full（磁盘已满）
///   106 = quota_reached（配额已满）
///   107 = timeout（下载超时）
///   108/109/110 = 超过文件系统最大文件大小
///   111/112 = 路径过长（加密/普通）
///   113 = duplicate_torrent（任务重复）
///   114 = no_file_to_end
///   115 = premium_account_require
///   116 = not_support_type
///   117 = ftp加密不支持类型
///   118-122 = 解压失败（无密码/无效压缩包/配额/磁盘/目录不存在）
///   123 = invalid_torrent
///   124 = account_require_status
///   125 = try_it_later
///   126 = task_encryption
///   127 = missing_python
///   128 = private_video
///   130 = nzb_missing_article
///   133 = parchive_repair_failed
///   134 = invalid_account_password
class DownloadStatusHelper {
  /// 将 API 返回的 status 数字码（字符串）转为本地化显示文本
  static String toDisplayText(String statusCode) {
    switch (statusCode) {
      case '1':
      case '11':
      case '12':
        return l10n.downloadStatusWaiting;
      case '2':
        return l10n.downloadStatusDownloading;
      case '3':
        return l10n.downloadStatusPaused;
      case '4':
      case '13':
      case '14':
        return l10n.downloadStatusFinishing;
      case '5':
        return l10n.downloadStatusFinished;
      case '6':
        return l10n.downloadStatusHashChecking;
      case '7':
        return l10n.downloadStatusPreSeeding;
      case '8':
        return l10n.downloadStatusSeeding;
      case '9':
        return l10n.downloadStatusFileHostingWaiting;
      case '10':
        return l10n.downloadStatusExtracting;
      case '15':
        return l10n.downloadStatusCaptchaNeeded;
      case '102':
        return 'broken_link';
      case '103':
        return 'dest_not_exist';
      case '104':
        return 'dest_deny';
      case '105':
        return 'disk_full';
      case '106':
        return 'quota_reached';
      case '107':
        return 'timeout';
      case '108':
      case '109':
      case '110':
        return 'exceed_fs_max_size';
      case '111':
        return 'encryption_long_path';
      case '112':
        return 'long_path';
      case '113':
        return 'duplicate_torrent';
      case '114':
        return 'no_file_to_end';
      case '115':
        return 'premium_account_require';
      case '116':
        return 'not_support_type';
      case '117':
        return 'ftp_not_support_type';
      case '118':
      case '119':
      case '120':
      case '121':
      case '122':
      case '129':
        return 'extract_failed';
      case '123':
        return 'invalid_torrent';
      case '124':
        return 'account_require_status';
      case '125':
        return 'try_it_later';
      case '126':
        return 'task_encryption';
      case '127':
        return 'missing_python';
      case '128':
        return 'private_video';
      case '130':
        return 'nzb_missing_article';
      case '133':
        return 'parchive_repair_failed';
      case '134':
        return 'invalid_account_password';
      default:
        final code = int.tryParse(statusCode);
        if (code != null && code >= 101) {
          return l10n.downloadStatusError;
        }
        return statusCode.isEmpty ? l10n.downloadStatusUnknown : statusCode;
    }
  }

  /// 判断 status 是否属于「下载中」（下载 + 校验 + 后处理等活跃状态）
  static bool isDownloading(String statusCode) {
    switch (statusCode) {
      case '2':
      case '4':
      case '6':
      case '11':
      case '12':
      case '13':
      case '14':
        return true;
      default:
        return false;
    }
  }

  /// 判断 status 是否属于「已暂停」
  static bool isPaused(String statusCode) => statusCode == '3';

  /// 判断 status 是否属于「已完成」（finished / seeding / pre-seeding）
  static bool isFinished(String statusCode) {
    switch (statusCode) {
      case '5':
      case '7':
      case '8':
        return true;
      default:
        return false;
    }
  }

  /// 判断 status 是否属于「出错」（101+ 或已知错误码）
  static bool isError(String statusCode) {
    final code = int.tryParse(statusCode);
    if (code != null && code >= 101) return true;
    switch (statusCode) {
      case '102':
      case '103':
      case '104':
      case '105':
      case '106':
      case '107':
      case '113':
      case '115':
      case '116':
      case '117':
      case '123':
      case '124':
      case '125':
      case '126':
      case '127':
      case '128':
      case '130':
      case '133':
      case '134':
        return true;
      default:
        return false;
    }
  }
}
