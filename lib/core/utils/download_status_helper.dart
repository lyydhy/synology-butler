import '../utils/l10n.dart';

/// DownloadStation 数字状态码 → 显示文本映射
/// 代码体系（来自 SYNO.DownloadStation2.Task v2 API）:
///   1=TASK_WAITING, 2=TASK_DOWNLOADING, 3=TASK_PAUSED,
///   4=TASK_FINISHING, 5=TASK_FINISHED, 6=TASK_HASH_CHECKING,
///   7=TASK_PRE_SEEDING, 8=TASK_SEEDING, 9=TASK_FILEHOSTING_WAITING,
///   10=TASK_EXTRACTING, 11=TASK_PREPROCESSING, 13=TASK_DOWNLOADED,
///   14=TASK_POSTPROCESSING, 15=TASK_CAPTCHA_NEEDED,
///   101+=TASK_ERROR*
class DownloadStatusHelper {
  /// 将 API 返回的 status 数字码（字符串）转为本地化显示文本
  static String toDisplayText(String statusCode) {
    switch (statusCode) {
      case '1':
        return l10n.downloadStatusWaiting;
      case '2':
        return l10n.downloadStatusDownloading;
      case '3':
        return l10n.downloadStatusPaused;
      case '4':
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
      case '11':
        return l10n.downloadStatusPreprocessing;
      case '13':
        return l10n.downloadStatusDownloaded;
      case '14':
        return l10n.downloadStatusPostProcessing;
      case '15':
        return l10n.downloadStatusCaptchaNeeded;
      default:
        // 101+ 为错误码，统一显示为 Error
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
      case '2': // TASK_DOWNLOADING
      case '4': // TASK_FINISHING
      case '6': // TASK_HASH_CHECKING
      case '11': // TASK_PREPROCESSING
      case '13': // TASK_DOWNLOADED
      case '14': // TASK_POSTPROCESSING
        return true;
      default:
        return false;
    }
  }

  /// 判断 status 是否属于「已暂停」
  static bool isPaused(String statusCode) => statusCode == '3'; // TASK_PAUSED

  /// 判断 status 是否属于「已完成」（finished / seeding / pre-seeding）
  static bool isFinished(String statusCode) {
    switch (statusCode) {
      case '5': // TASK_FINISHED
      case '7': // TASK_PRE_SEEDING
      case '8': // TASK_SEEDING
        return true;
      default:
        return false;
    }
  }

  /// 判断 status 是否属于「出错」
  static bool isError(String statusCode) {
    final code = int.tryParse(statusCode);
    return code != null && code >= 101;
  }
}
