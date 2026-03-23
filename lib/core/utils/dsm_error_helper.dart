class DsmErrorHelper {
  static dynamic extractErrorCode(dynamic response) {
    if (response is Map) {
      final error = response['error'];
      if (error is Map) {
        return error['code'];
      }
    }
    return null;
  }

  static String? mapErrorCode(dynamic code) {
    switch (code) {
      case 103:
        return '请求参数或订阅条件不符合 DSM 当前要求';
      case 119:
        return '会话失效或鉴权失败，需要刷新登录态';
      case 400:
        return '请求参数错误';
      case 401:
        return '认证失败，请检查用户名和密码';
      case 402:
        return '权限不足，当前账号无法执行此操作';
      case 403:
        return '目标不存在或路径无效';
      case 404:
        return '接口不存在或 DSM 版本不支持';
      case 407:
        return '文件或任务已存在，或当前状态不允许该操作';
      case 408:
        return '会话失效，请重新登录';
      case 409:
        return '操作冲突，请稍后重试';
      case 410:
        return '上传失败，可能是文件过大或网络中断';
      case 418:
        return '分享链接创建失败';
      case 500:
        return 'NAS 内部错误，请稍后再试';
      default:
        if (code == null) return null;
        return 'DSM 接口调用失败，错误码：$code';
    }
  }
}
