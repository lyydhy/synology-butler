import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../models/nas_server_model.dart';
import 'auth_api.dart';

class DsmAuthApi implements AuthApi {
  @override
  Future<String> login({
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
      },
    );

    final data = response.data;
    if (data is Map && data['success'] == true) {
      final sid = data['data']?['sid'];
      if (sid is String && sid.isNotEmpty) {
        return sid;
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
