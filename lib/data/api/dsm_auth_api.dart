import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/dio_client.dart';
import '../models/nas_server_model.dart';
import 'auth_api.dart';

class DsmAuthApi implements AuthApi {
  @override
  Future<DsmVersionInfo> probeVersion({
    required NasServerModel server,
  }) async {
    final client = DioClient(baseUrl: server.baseUrl).dio;

    final response = await client.get(
      '/webapi/query.cgi',
      queryParameters: {
        'api': 'SYNO.API.Info',
        'version': '1',
        'method': 'query',
        'query': 'SYNO.API.Auth',
      },
    );

    final data = response.data;
    final info = data is Map && data['success'] == true ? (data['data'] as Map? ?? const {}) : const {};
    final authInfo = info['SYNO.API.Auth'] as Map? ?? const {};
    final maxVersion = int.tryParse(authInfo['maxVersion']?.toString() ?? '');

    final major = authInfo['productmajor']?.toString() ?? authInfo['major']?.toString();
    final minor = authInfo['productminor']?.toString() ?? authInfo['minor']?.toString();
    final build = authInfo['buildnumber']?.toString() ?? authInfo['build']?.toString();
    final productVersion = authInfo['productversion']?.toString();
    final versionString = authInfo['version_string']?.toString() ?? authInfo['fullversion']?.toString();

    return DsmVersionInfo(
      major: major,
      minor: minor,
      build: build,
      productVersion: productVersion,
      fullVersionString: versionString,
      isDsm7OrAbove: maxVersion != null ? maxVersion >= 7 : ((int.tryParse(major ?? '') ?? 0) >= 7),
    );
  }

  @override
  Future<AuthLoginResult> refreshRealtimeSession({
    required NasServerModel server,
    required String sid,
  }) async {
    final client = DioClient(baseUrl: server.baseUrl).dio;

    debugPrint('[Auth][refresh] refreshing realtime session for ${server.baseUrl}');

    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.API.Auth',
        'version': '7',
        'method': 'login',
        'session': 'webui',
        'enable_syno_token': 'yes',
        '_sid': sid,
      },
    );

    final data = response.data;
    debugPrint('[Auth][refresh][Response] $data');

    if (data is Map && data['success'] == true) {
      final responseData = data['data'] as Map? ?? const {};
      final refreshedSid = responseData['sid']?.toString() ?? sid;
      final setCookies = response.headers.map['set-cookie'] ?? const <String>[];
      final cookieHeader = _buildCookieHeader(setCookies);

      return AuthLoginResult(
        sid: refreshedSid,
        synoToken: responseData['synotoken']?.toString(),
        cookieHeader: cookieHeader,
        requestHashSeed: responseData['synohash']?.toString(),
        authToken: responseData['did']?.toString(),
        noiseIkMessage: responseData['ik_message']?.toString(),
      );
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'DSM realtime refresh failed',
      response: response,
    );
  }

  @override
  Future<AuthLoginResult> login({
    required NasServerModel server,
    required String username,
    required String password,
  }) async {
    final client = DioClient(baseUrl: server.baseUrl).dio;

    debugPrint('[Auth][v7] starting DSM v7 login flow for ${server.baseUrl}');

    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.API.Auth',
        'version': '7',
        'method': 'login',
        'account': username,
        'passwd': password,
        'session': 'webui',
        'enable_syno_token': 'yes',
      },
    );

    final data = response.data;
    debugPrint('[Auth][v7][Response] $data');

    if (data is Map && data['success'] == true) {
      final responseData = data['data'] as Map? ?? const {};
      final sid = responseData['sid'];
      if (sid is String && sid.isNotEmpty) {
        final setCookies = response.headers.map['set-cookie'] ?? const <String>[];
        final cookieHeader = _buildCookieHeader(setCookies);

        return AuthLoginResult(
          sid: sid,
          synoToken: responseData['synotoken']?.toString(),
          cookieHeader: cookieHeader,
          requestHashSeed: responseData['synohash']?.toString(),
          authToken: responseData['did']?.toString(),
          noiseIkMessage: responseData['ik_message']?.toString(),
        );
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'DSM v7 login failed',
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
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.API.Auth',
        'version': '7',
        'method': 'logout',
        'session': 'webui',
        '_sid': sid,
      },
    );
  }

  String? _buildCookieHeader(List<String> setCookies) {
    if (setCookies.isEmpty) return null;

    final pairs = <String>[];
    for (final cookie in setCookies) {
      final firstPart = cookie.split(';').first.trim();
      if (firstPart.isNotEmpty && firstPart.contains('=')) {
        pairs.add(firstPart);
      }
    }

    if (pairs.isEmpty) return null;
    return pairs.join('; ');
  }
}
