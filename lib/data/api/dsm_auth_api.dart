import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../models/nas_server_model.dart';
import 'auth_api.dart';

class DsmAuthApi implements AuthApi {
  @override
  Future<AuthLoginResult> login({
    required NasServerModel server,
    required String username,
    required String password,
  }) async {
    final client = DioClient(baseUrl: server.baseUrl).dio;

    final response = await client.get(
      '/webapi/auth.cgi',
      queryParameters: {
        'api': 'SYNO.API.Auth',
        'version': '6',
        'method': 'login',
        'account': username,
        'passwd': password,
        'session': 'FileStation',
        'format': 'sid',
        'enable_syno_token': 'yes',
      },
    );

    final data = response.data;
    if (data is Map && data['success'] == true) {
      final responseData = data['data'] as Map? ?? const {};
      final sid = responseData['sid'];
      if (sid is String && sid.isNotEmpty) {
        return AuthLoginResult(
          sid: sid,
          synoToken: responseData['synotoken']?.toString(),
        );
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'DSM login failed',
      response: response,
    );
  }

  @override
  Future<void> logout({
    required NasServerModel server,
    required String sid,
  }) async {
    final client = DioClient(baseUrl: server.baseUrl).dio;
    await client.get(
      '/webapi/auth.cgi',
      queryParameters: {
        'api': 'SYNO.API.Auth',
        'version': '6',
        'method': 'logout',
        'session': 'FileStation',
        '_sid': sid,
      },
    );
  }
}
