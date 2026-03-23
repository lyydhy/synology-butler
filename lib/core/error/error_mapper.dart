import 'package:dio/dio.dart';

import '../utils/dsm_error_helper.dart';
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
        final code = DsmErrorHelper.extractErrorCode(data);
        return AppException(DsmErrorHelper.mapErrorCode(code) ?? '请求失败');
      }

      return AppException(error.message ?? '请求失败');
    }

    return AppException(error.toString());
  }
}
