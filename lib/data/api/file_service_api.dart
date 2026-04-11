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
    final apiName = _getServiceApiName(serviceName.toUpperCase());

    DsmLogger.request(module: 'FileService', action: 'setFileServiceEnabled', method: 'POST', path: _baseUrl, sid: _sid, synoToken: _synoToken, cookieHeader: _cookieHeader, extra: {'serviceName': serviceName, 'enabled': enabled, 'api': apiName});

    try {
      // 先获取当前配置
      final getResponse = await client.post(
        '$_baseUrl/entry.cgi',
        data: {'api': apiName, 'method': 'get', 'version': 1},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (getResponse.data is! Map || getResponse.data['success'] != true) {
        throw Exception('获取服务配置失败');
      }

      final data = getResponse.data['data'] as Map? ?? {};
      final currentConfig = data['config'] as Map<String, dynamic>? ?? {};

      // 构建设置请求
      final setData = <String, dynamic>{
        'api': apiName,
        'method': 'set',
        'version': 1,
      };

      // 根据服务类型设置 enable 字段
      switch (serviceName.toUpperCase()) {
        case 'SMB':
          setData['enable_samba'] = enabled;
          break;
        case 'NFS':
          setData['enable_nfs'] = enabled;
          break;
        case 'FTP':
          setData['enable_ftp'] = enabled;
          break;
        case 'AFP':
          setData['enable_afp'] = enabled;
          break;
        case 'SFTP':
          setData['enable'] = enabled;
          break;
        default:
          throw Exception('不支持的服务：$serviceName');
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

  String _getServiceApiName(String serviceName) {
    switch (serviceName) {
      case 'SMB': return 'SYNO.Core.FileServ.SMB';
      case 'NFS': return 'SYNO.Core.FileServ.NFS';
      case 'FTP': return 'SYNO.Core.FileServ.FTP';
      case 'AFP': return 'SYNO.Core.FileServ.AFP';
      case 'SFTP': return 'SYNO.Core.FileServ.FTP.SFTP';
      default: throw Exception('不支持的服务：$serviceName');
    }
  }
}
