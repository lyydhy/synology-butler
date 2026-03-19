import 'package:dio/dio.dart';

import 'app_exception.dart';

class ErrorMapper {
  static AppException map(Object error) {
    if (error is AppException) return error;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return const AppException('连接 NAS 超时，请检查地址和网络');
        case DioExceptionType.badCertificate:
          return const AppException('证书校验失败，请检查 HTTPS 配置');
        case DioExceptionType.connectionError:
          return const AppException('无法连接到 NAS，请确认地址、端口和网络');
        default:
          break;
      }

      final data = error.response?.data;
      if (data is Map && data['success'] == false) {
        final code = data['error']?['code'];
        return AppException(_mapDsmErrorCode(code));
      }

      return AppException(error.message ?? '请求失败');
    }

    return AppException(error.toString());
  }

  static String _mapDsmErrorCode(dynamic code) {
    switch (code) {
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
        return 'DSM 接口调用失败，错误码：$code';
    }
  }
}
