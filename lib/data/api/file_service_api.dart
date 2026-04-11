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
      smb = FileServiceStatus(
        serviceName: 'SMB',
        enabled: data['enable_samba'] == true || data['enable'] == true,
        version: data['max_protocol'] != null || data['min_protocol'] != null
            ? 'SMB ${data['min_protocol'] ?? '1'} - ${data['max_protocol'] ?? '3'}'
            : 'SMB 1/2/3',
        port: 445,
        extraInfo: {
          'workgroup': data['workgroup']?.toString() ?? '',
          'netbios': data['netbios_name']?.toString() ?? '',
          'max_protocol': data['max_protocol']?.toString() ?? '',
          'min_protocol': data['min_protocol']?.toString() ?? '',
        },
      );
    }

    if (results[1] != null) {
      final data = results[1]!;
      nfs = FileServiceStatus(
        serviceName: 'NFS',
        enabled: data['enable_nfs'] == true || data['enable'] == true,
        port: 2049,
        extraInfo: {
          'enable_nfs_v4': data['enable_nfs_v4'],
          'nfs_v4_domain': data['nfs_v4_domain']?.toString() ?? '',
        },
      );
    }

    if (results[2] != null) {
      final data = results[2]!;
      ftp = FileServiceStatus(
        serviceName: 'FTP',
        enabled: data['enable_ftp'] == true || data['enable'] == true,
        port: data['portnum'] ?? data['ftp_port'] ?? 21,
        extraInfo: {
          'enable_ftps': data['enable_ftps'],
          'anonymous': data['anonymous'],
          'timeout': data['timeout'],
          'utf8_mode': data['utf8_mode'],
        },
      );
    }

    if (results[3] != null) {
      final data = results[3]!;
      afp = FileServiceStatus(
        serviceName: 'AFP',
        enabled: data['enable_afp'] == true || data['enable'] == true,
        port: 548,
        extraInfo: {
          'ddns': data['ddns_hostname']?.toString() ?? '',
        },
      );
    }

    if (results[4] != null) {
      final data = results[4]!;
      sftp = FileServiceStatus(
        serviceName: 'SFTP',
        enabled: data['enable'] == true,
        port: data['portnum'] ?? data['sftp_portnum'] ?? 22,
        extraInfo: {
          'sftp_portnum': data['sftp_portnum'],
        },
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
          // FTP 的 set 需要完整配置，与 dsm_helper 对齐
          // version 改为 3（与 get 使用的版本一致）
          setData['version'] = 3;
          setData['enable_ftp'] = enabled;
          // 保留 FTP 现有配置字段
          final ftpData = data['ftp'] as Map<String, dynamic>? ?? {};
          if (ftpData['enable_ftps'] != null) setData['enable_ftps'] = ftpData['enable_ftps'];
          if (ftpData['timeout'] != null) setData['timeout'] = ftpData['timeout'];
          if (ftpData['portnum'] != null) setData['portnum'] = ftpData['portnum'];
          if (ftpData['utf8_mode'] != null) setData['utf8_mode'] = ftpData['utf8_mode'];
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
