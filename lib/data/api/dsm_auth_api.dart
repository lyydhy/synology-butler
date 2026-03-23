import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/dsm_logger.dart';
import '../models/nas_server_model.dart';
import 'auth_api.dart';

class DsmAuthApi implements AuthApi {
  @override
  Future<DsmVersionInfo> probeVersion({
    required NasServerModel server,
  }) async {
    final client = DioClient(baseUrl: server.baseUrl).dio;

    DsmLogger.request(
      module: 'Auth',
      action: 'probeVersion',
      method: 'GET',
      path: server.baseUrl,
      extra: {
        'api': 'SYNO.API.Info',
        'query': 'SYNO.API.Auth',
      },
    );

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

    final infoResult = DsmVersionInfo(
      major: major,
      minor: minor,
      build: build,
      productVersion: productVersion,
      fullVersionString: versionString,
      isDsm7OrAbove: maxVersion != null ? maxVersion >= 7 : ((int.tryParse(major ?? '') ?? 0) >= 7),
    );

    DsmLogger.success(
      module: 'Auth',
      action: 'probeVersion',
      path: server.baseUrl,
      response: {
        'displayText': infoResult.displayText,
        'isDsm7OrAbove': infoResult.isDsm7OrAbove,
        'major': infoResult.major,
        'minor': infoResult.minor,
        'build': infoResult.build,
      },
    );

    return infoResult;
  }

  @override
  Future<AuthLoginResult> refreshSynoToken({
    required NasServerModel server,
    required String sid,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: server.baseUrl).dio;

    DsmLogger.request(
      module: 'Auth',
      action: 'refreshSynoToken',
      method: 'POST',
      path: server.baseUrl,
      sid: sid,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.API.Auth',
        'method': 'token',
        'version': '6',
        'updateSynoToken': true,
      },
    );

    final headers = <String, dynamic>{};
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }

    final response = await client.post(
      '/webapi/entry.cgi/SYNO.API.Auth',
      data: {
        'api': 'SYNO.API.Auth',
        'method': 'token',
        'version': '6',
        'updateSynoToken': 'true',
      },
      options: Options(
        headers: headers,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final data = response.data;
    if (data is Map && data['success'] == true) {
      final responseData = data['data'] as Map? ?? const {};
      final result = AuthLoginResult(
        sid: sid,
        synoToken: responseData['synotoken']?.toString(),
        cookieHeader: cookieHeader,
      );

      DsmLogger.success(
        module: 'Auth',
        action: 'refreshSynoToken',
        path: server.baseUrl,
        response: {
          'synoToken': result.synoToken != null && result.synoToken!.isNotEmpty ? 'present' : 'missing',
        },
      );

      return result;
    }

    DsmLogger.failure(
      module: 'Auth',
      action: 'refreshSynoToken',
      path: server.baseUrl,
      response: data,
      sid: sid,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'DSM synotoken refresh failed',
      response: response,
    );
  }

  @override
  Future<AuthLoginResult> refreshRealtimeSession({
    required NasServerModel server,
    required String sid,
  }) async {
    final client = DioClient(baseUrl: server.baseUrl).dio;

    DsmLogger.request(
      module: 'Auth',
      action: 'refreshRealtimeSession',
      method: 'GET',
      path: server.baseUrl,
      sid: sid,
      extra: {
        'session': 'webui',
        'enable_syno_token': true,
      },
    );

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

    if (data is Map && data['success'] == true) {
      final responseData = data['data'] as Map? ?? const {};
      final refreshedSid = responseData['sid']?.toString() ?? sid;
      final setCookies = response.headers.map['set-cookie'] ?? const <String>[];
      final cookieHeader = _buildCookieHeader(setCookies);

      final result = AuthLoginResult(
        sid: refreshedSid,
        synoToken: responseData['synotoken']?.toString(),
        cookieHeader: cookieHeader,
        requestHashSeed: responseData['synohash']?.toString(),
        authToken: responseData['did']?.toString(),
        noiseIkMessage: responseData['ik_message']?.toString(),
      );

      DsmLogger.success(
        module: 'Auth',
        action: 'refreshRealtimeSession',
        path: server.baseUrl,
        response: {
          'sidChanged': refreshedSid != sid,
          'synoToken': result.synoToken != null && result.synoToken!.isNotEmpty ? 'present' : 'missing',
          'cookieHeader': result.cookieHeader != null && result.cookieHeader!.isNotEmpty ? 'present' : 'missing',
          'requestHashSeed': result.requestHashSeed != null && result.requestHashSeed!.isNotEmpty ? 'present' : 'missing',
          'authToken': result.authToken != null && result.authToken!.isNotEmpty ? 'present' : 'missing',
        },
      );

      return result;
    }

    DsmLogger.failure(
      module: 'Auth',
      action: 'refreshRealtimeSession',
      path: server.baseUrl,
      response: data,
      sid: sid,
    );

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
    final client = DioClient(baseUrl: server.baseUrl, ignoreBadCertificate: server.ignoreBadCertificate).dio;

    DsmLogger.request(
      module: 'Auth',
      action: 'login',
      method: 'GET',
      path: server.baseUrl,
      extra: {
        'username': username,
        'session': 'webui',
        'enable_syno_token': true,
        'enable_device_token': true,
        'enable_sync_token': true,
        'isIframeLogin': true,
        'otp_code': 'empty',
      },
    );

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
        'enable_device_token': 'yes',
        'enable_sync_token': 'yes',
        'isIframeLogin': 'yes',
        'otp_code': '',
      },
    );

    final data = response.data;

    if (data is Map && data['success'] == true) {
      final responseData = data['data'] as Map? ?? const {};
      final sid = responseData['sid'];
      if (sid is String && sid.isNotEmpty) {
        final setCookies = response.headers.map['set-cookie'] ?? const <String>[];
        final cookieHeader = _buildCookieHeader(setCookies);

        final result = AuthLoginResult(
          sid: sid,
          synoToken: responseData['synotoken']?.toString(),
          cookieHeader: cookieHeader,
          requestHashSeed: responseData['synohash']?.toString(),
          authToken: responseData['did']?.toString(),
          noiseIkMessage: responseData['ik_message']?.toString(),
        );

        DsmLogger.success(
          module: 'Auth',
          action: 'login',
          path: server.baseUrl,
          response: {
            'sid': 'present',
            'synoToken': result.synoToken != null && result.synoToken!.isNotEmpty ? 'present' : 'missing',
            'cookieHeader': result.cookieHeader != null && result.cookieHeader!.isNotEmpty ? 'present' : 'missing',
            'requestHashSeed': result.requestHashSeed != null && result.requestHashSeed!.isNotEmpty ? 'present' : 'missing',
            'authToken': result.authToken != null && result.authToken!.isNotEmpty ? 'present' : 'missing',
          },
        );

        return result;
      }
    }

    DsmLogger.failure(
      module: 'Auth',
      action: 'login',
      path: server.baseUrl,
      response: data,
    );

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
    final client = DioClient(baseUrl: server.baseUrl, ignoreBadCertificate: server.ignoreBadCertificate).dio;
    DsmLogger.request(
      module: 'Auth',
      action: 'logout',
      method: 'GET',
      path: server.baseUrl,
      sid: sid,
      extra: {
        'session': 'webui',
      },
    );
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
