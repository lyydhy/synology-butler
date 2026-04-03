import 'dart:convert';

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
    final response = await client.post(
      '$_baseUrl/query.cgi',
      data: {
        'api': 'SYNO.Core.QueryRequest',
        'method': 'request',
        'version': '1',
        'mode': 'parallel',
        'compound': jsonEncode([
          {'api': 'SYNO.Core.FileService.SMB', 'method': 'get', 'version': 1, 'additional': ['all']},
          {'api': 'SYNO.Core.FileService.NFS', 'method': 'get', 'version': 1, 'additional': ['all']},
          {'api': 'SYNO.Core.FileService.FTP', 'method': 'get', 'version': 1, 'additional': ['all']},
          {'api': 'SYNO.Core.FileService.AFP', 'method': 'get', 'version': 1, 'additional': ['all']},
          {'api': 'SYNO.Core.FileService.SFTP', 'method': 'get', 'version': 1, 'additional': ['all']},
        ]),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载文件服务失败' : '加载文件服务失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    final result = (data['result'] as List?) ?? const [];

    FileServicesModel? model;

    for (final item in result.whereType<Map>()) {
      final api = item['api'] as String?;
      final apiData = item['data'] as Map?;
      if (apiData == null) continue;

      final config = apiData['config'] as Map?;
      if (config == null) continue;

      final smb = api == 'SYNO.Core.FileService.SMB' ? FileServiceStatus(serviceName: 'SMB', enabled: config['enable'] == true, version: apiData['version']?.toString(), port: config['port'] as int?, extraInfo: {'workgroup': config['workgroup']?.toString() ?? ''}) : model?.smb;
      final nfs = api == 'SYNO.Core.FileService.NFS' ? FileServiceStatus(serviceName: 'NFS', enabled: config['enable'] == true, version: apiData['version']?.toString(), port: config['port'] as int?, extraInfo: {'nfs_v4_domain': config['v4_domain']?.toString() ?? ''}) : model?.nfs;
      final ftp = api == 'SYNO.Core.FileService.FTP' ? FileServiceStatus(serviceName: 'FTP', enabled: config['enable'] == true, version: apiData['version']?.toString(), port: config['port'] as int?, extraInfo: {'enable_ftps': config['enable_ftps'] == true}) : model?.ftp;
      final afp = api == 'SYNO.Core.FileService.AFP' ? FileServiceStatus(serviceName: 'AFP', enabled: config['enable'] == true, version: apiData['version']?.toString(), port: config['port'] as int?) : model?.afp;
      final sftp = api == 'SYNO.Core.FileService.SFTP' ? FileServiceStatus(serviceName: 'SFTP', enabled: config['enable'] == true, version: apiData['version']?.toString(), port: config['port'] as int?) : model?.sftp;
      model = FileServicesModel(smb: smb, nfs: nfs, ftp: ftp, afp: afp, sftp: sftp);
    }

    return model ?? const FileServicesModel(smb: null, nfs: null, ftp: null, afp: null, sftp: null);
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
