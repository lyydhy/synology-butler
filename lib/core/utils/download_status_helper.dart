class DownloadStatusHelper {
  static String toDisplayText(String status) {
    switch (status) {
      case 'waiting':
        return '等待中';
      case 'downloading':
        return '下载中';
      case 'paused':
      case 'paused by user':
        return '已暂停';
      case 'finished':
      case 'seeding':
        return '已完成';
      case 'hash_checking':
        return '校验中';
      case 'extracting':
        return '解压中';
      case 'error':
        return '出错';
      default:
        return status.isEmpty ? '未知状态' : status;
    }
  }
}
