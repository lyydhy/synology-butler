import '../utils/l10n.dart';

/// DownloadStation 数字状态码 → 显示文本映射
class DownloadStatusHelper {
  /// 将 API 返回的 status 数字码（字符串）转为本地化显示文本
  static String toDisplayText(String statusCode) {
    switch (statusCode) {
      case '0':
        return l10n.downloadStatusWaiting;
      case '1':
        return l10n.downloadStatusDownloading;
      case '2':
        return l10n.downloadStatusPaused;
      case '3':
        return l10n.downloadStatusFinished;
      case '4':
        return l10n.downloadStatusSeeding;
      case '5':
        return l10n.downloadStatusHashChecking;
      case '6':
        return l10n.downloadStatusExtracting;
      case '7':
        return l10n.downloadStatusFileHostingWaiting;
      case '8':
        return l10n.downloadStatusCaptchaNeeded;
      case '9':
        return l10n.downloadStatusError;
      default:
        return statusCode.isEmpty ? l10n.downloadStatusUnknown : statusCode;
    }
  }

  /// 判断 status 是否属于「下载中」
  static bool isDownloading(String statusCode) => statusCode == '1';

  /// 判断 status 是否属于「已暂停」
  static bool isPaused(String statusCode) => statusCode == '2';

  /// 判断 status 是否属于「已完成」(包括 finished + seeding)
  static bool isFinished(String statusCode) => statusCode == '3' || statusCode == '4';

  /// 判断 status 是否属于「出错」
  static bool isError(String statusCode) => statusCode == '9';
}
