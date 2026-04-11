import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../../domain/entities/file_service.dart';

/// 文件服务 API
class FileServiceApi {
  Dio get _dio => businessDio();

  String get _baseUrl => '/webapi/';
  String? get _sid => connectionStore.session?.sid ?? '';
  String? get _synoToken => connectionStore.session?.synoToken;
  String? get _cookieHeader => connectionStore.session?.cookieHeader;

  /// 获取文件服务状态（SMB、NFS、FTP、AFP、SFTP）
  Future<FileServicesModel> fetchFileServices() async {
    final client = _dio;

    Future<Map<String, dynamic>?> fetchService(String api, String method) async {
      try {
        final response = await client.post(
          '$_baseUrl/entry.cgi',
          data: {
            'api': api,
            'method': method,
            'version': 1,
          },
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        if (response.data is Map && response.data['success'] == true) {
          return response.data['data'] as Map<String, dynamic>?;
        }
        return null;
      } catch (_) {
        return null;
      }
    }

    // 并行请求所有文件服务状态
    final results = await Future.wait([
      fetchService('SYNO.Core.FileServ.SMB', 'get'),
      fetchService('SYNO.Core.FileServ.NFS', 'get'),
      fetchService('SYNO.Core.FileServ.FTP', 'get'),
      fetchService('SYNO.Core.FileServ.AFP', 'get'),
      fetchService('SYNO.Core.FileServ.FTP.SFTP', 'get'),
    ]);

    return _parseFileServicesResults(results);
  }

  FileServicesModel _parseFileServicesResults(List<Map<String, dynamic>?> results) {
    FileServiceStatus? smb;
    FileServiceStatus? nfs;
    FileServiceStatus? ftp;
    FileServiceStatus? afp;
    FileServiceStatus? sftp;

    if (results[0] != null) {
      final data = results[0]!;
      final config = data['config'] as Map? ?? {};
      smb = FileServiceStatus(
        serviceName: 'SMB',
        enabled: config['enable_samba'] == true || config['enable'] == true,
        version: data['version']?.toString(),
        port: config['port'] as int?,
        extraInfo: {'workgroup': config['workgroup']?.toString() ?? ''},
      );
    }

    if (results[1] != null) {
      final data = results[1]!;
      final config = data['config'] as Map? ?? {};
      nfs = FileServiceStatus(
        serviceName: 'NFS',
        enabled: config['enable_nfs'] == true || config['enable'] == true,
        version: data['version']?.toString(),
        port: config['port'] as int?,
        extraInfo: {'nfs_v4_domain': config['nfs_v4_domain']?.toString() ?? ''},
      );
    }

    if (results[2] != null) {
      final data = results[2]!;
      final config = data['config'] as Map? ?? {};
      ftp = FileServiceStatus(
        serviceName: 'FTP',
        enabled: config['enable_ftp'] == true || config['enable'] == true,
        version: data['version']?.toString(),
        port: config['port'] as int?,
        extraInfo: {'enable_ftps': config['enable_ftps'] == true},
      );
    }

    if (results[3] != null) {
      final data = results[3]!;
      final config = data['config'] as Map? ?? {};
      afp = FileServiceStatus(
        serviceName: 'AFP',
        enabled: config['enable_afp'] == true || config['enable'] == true,
        version: data['version']?.toString(),
        port: config['port'] as int?,
      );
    }

    if (results[4] != null) {
      final data = results[4]!;
      final config = data['config'] as Map? ?? {};
      sftp = FileServiceStatus(
        serviceName: 'SFTP',
        enabled: config['enable'] == true,
        version: data['version']?.toString(),
        port: config['port'] as int?,
      );
    }

    return FileServicesModel(smb: smb, nfs: nfs, ftp: ftp, afp: afp, sftp: sftp);
  }

  /// 设置文件服务启用状态
  Future<void> setFileServiceEnabled({required String serviceName, required bool enabled}) async {
    final client = _dio;
    final serviceConfig = _getServiceConfig(serviceName.toUpperCase());
    final apiName = serviceConfig['api'] as String;
    final config = serviceConfig['config'] as Map<String, dynamic>;
    final version = config['version'] as int;
    final enableKey = config['enable_key'] as String;
    final extraKeys = (config['extra_keys'] as List).cast<String>();

    DsmLogger.request(module: 'FileService', action: 'setFileServiceEnabled', method: 'POST', path: _baseUrl, sid: _sid, synoToken: _synoToken, cookieHeader: _cookieHeader, extra: {'serviceName': serviceName, 'enabled': enabled, 'api': apiName, 'enable_key': enableKey});

    try {
      final getResponse = await client.post('$_baseUrl/query.cgi', data: {'api': 'SYNO.Core.QueryRequest', 'method': 'request', 'version': 1, 'mode': 'parallel', 'compound': jsonEncode([{'api': apiName, 'method': 'get', 'version': version, 'additional': jsonEncode(['all'])}])}, options: Options(contentType: Headers.formUrlEncodedContentType));

      if (getResponse.data is! Map || getResponse.data['success'] != true) throw Exception('获取服务配置失败');

      final getResult = (getResponse.data['data']?['result'] as List?) ?? const [];
      Map<String, dynamic>? currentConfig;
      for (final item in getResult.whereType<Map>()) {
        if (item['api'] == apiName) {
          final data = item['data'] as Map?;
          currentConfig = data?['config'] as Map<String, dynamic>?;
          break;
        }
      }
      if (currentConfig == null) throw Exception('未找到服务配置');

      final setData = <String, dynamic>{'api': apiName, 'method': 'set', 'version': version};
      for (final key in currentConfig.keys) {
        setData[key] = currentConfig[key];
      }
      setData[enableKey] = enabled;
      for (final key in extraKeys) {
        if (currentConfig.containsKey(key)) setData[key] = currentConfig[key];
      }
      if (serviceName.toUpperCase() == 'SFTP' && currentConfig.containsKey('portnum')) {
        setData['portnum'] = currentConfig['portnum'];
        setData['sftp_portnum'] = currentConfig['portnum'];
      }

      final response = await client.post('/webapi/entry.cgi', data: setData, options: Options(contentType: Headers.formUrlEncodedContentType));
      final responseData = response.data;
      
      if (responseData is! Map || responseData['success'] != true) {
        final errorData = responseData is Map ? responseData['error'] : null;
        final errorMessage = errorData is Map ? (errorData['message'] ?? errorData['code'] ?? '设置服务状态失败') : '设置服务状态失败';
        DsmLogger.failure(module: 'FileService', action: 'setFileServiceEnabled', reason: '设置服务状态失败', path: _baseUrl, sid: _sid, synoToken: _synoToken, cookieHeader: _cookieHeader, extra: {'responseData': responseData, 'serviceName': serviceName, 'enabled': enabled, 'setData': setData});
        throw Exception(errorMessage.toString());
      }

      DsmLogger.success(module: 'FileService', action: 'setFileServiceEnabled', path: _baseUrl, response: {'serviceName': serviceName, 'enabled': enabled});
    } catch (e) {
      if (e is Exception && e.toString().contains('设置服务状态')) rethrow;
      DsmLogger.failure(module: 'FileService', action: 'setFileServiceEnabled', path: _baseUrl, reason: '请求异常：$e', sid: _sid, synoToken: _synoToken, cookieHeader: _cookieHeader);
      rethrow;
    }
  }

  Map<String, dynamic> _getServiceConfig(String serviceName) {
    switch (serviceName) {
      case 'SMB': return {'api': 'SYNO.Core.FileService.SMB', 'config': {'version': 1, 'enable_key': 'enable', 'extra_keys': ['workgroup', 'port']}};
      case 'NFS': return {'api': 'SYNO.Core.FileService.NFS', 'config': {'version': 1, 'enable_key': 'enable', 'extra_keys': ['v4_domain', 'port']}};
      case 'FTP': return {'api': 'SYNO.Core.FileService.FTP', 'config': {'version': 1, 'enable_key': 'enable', 'extra_keys': ['enable_ftps', 'port']}};
      case 'AFP': return {'api': 'SYNO.Core.FileService.AFP', 'config': {'version': 1, 'enable_key': 'enable', 'extra_keys': ['port']}};
      case 'SFTP': return {'api': 'SYNO.Core.FileService.SFTP', 'config': {'version': 1, 'enable_key': 'enable', 'extra_keys': ['port', 'portnum']}};
      default: throw Exception('不支持的服务：$serviceName');
    }
  }
}
