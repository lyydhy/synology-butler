import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/dsm_logger.dart';
import '../models/package_item_model.dart';
import '../models/package_volume_model.dart';

abstract class PackageApi {
  Future<List<PackageItemModel>> fetchStorePackages({
    required String baseUrl,
    required String sid,
    String? synoToken,
    String? cookieHeader,
    bool others = false,
    int version = 2,
  });

  Future<List<PackageItemModel>> fetchInstalledPackages({
    required String baseUrl,
    required String sid,
    String? synoToken,
    String? cookieHeader,
    int version = 2,
  });

  Future<List<PackageVolumeModel>> fetchVolumes({
    required String baseUrl,
    required String sid,
    String? synoToken,
    String? cookieHeader,
  });

  Future<Map<String, dynamic>> checkInstallQueue({
    required String baseUrl,
    required String sid,
    required String packageId,
    required String version,
    String? synoToken,
    String? cookieHeader,
    bool beta = false,
  });

  Future<Map<String, dynamic>> installPackage({
    required String baseUrl,
    required String sid,
    required String packageId,
    required String volumePath,
    String? synoToken,
    String? cookieHeader,
  });

  Future<Map<String, dynamic>> getInstallStatus({
    required String baseUrl,
    required String sid,
    required String taskId,
    String? synoToken,
    String? cookieHeader,
  });

  Future<void> startPackage({
    required String baseUrl,
    required String sid,
    required String packageId,
    String? dsmAppName,
    String? synoToken,
    String? cookieHeader,
  });

  Future<void> stopPackage({
    required String baseUrl,
    required String sid,
    required String packageId,
    String? synoToken,
    String? cookieHeader,
  });

  Future<void> uninstallPackage({
    required String baseUrl,
    required String sid,
    required String packageId,
    String? synoToken,
    String? cookieHeader,
  });
}

class DsmPackageApi implements PackageApi {
  Options _buildOptions({
    String? synoToken,
    String? cookieHeader,
  }) {
    final headers = <String, dynamic>{};
    if (synoToken != null && synoToken.isNotEmpty) {
      headers['X-SYNO-TOKEN'] = synoToken;
    }
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }
    return Options(
      headers: headers,
      contentType: Headers.formUrlEncodedContentType,
    );
  }

  String _extractError({
    required String action,
    required dynamic data,
  }) {
    return DsmLogger.buildFailureMessage(
      module: 'Package',
      action: action,
      response: data,
    );
  }

  @override
  Future<List<PackageItemModel>> fetchStorePackages({
    required String baseUrl,
    required String sid,
    String? synoToken,
    String? cookieHeader,
    bool others = false,
    int version = 2,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    final action = others ? 'fetchThirdPartyStorePackages' : 'fetchStorePackages';

    DsmLogger.request(
      module: 'Package',
      action: action,
      method: 'POST',
      path: baseUrl,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.Package.Server',
        'method': 'list',
        'version': version,
        'others': others,
      },
    );

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Package.Server',
        'version': version.toString(),
        'method': 'list',
        'updateSprite': 'true',
        'blforcereload': 'false',
        'blloadothers': others.toString(),
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      final packages = (data['packages'] as List?) ?? (data['data'] as List?) ?? const [];
      final betaPackages = (data['beta_packages'] as List?) ?? const [];
      final merged = [...packages, ...betaPackages]
          .whereType<Map>()
          .map((item) => PackageItemModel.fromStorePayload(item))
          .toList();

      DsmLogger.success(
        module: 'Package',
        action: action,
        path: baseUrl,
        response: {
          'count': merged.length,
          'betaCount': betaPackages.length,
        },
      );

      return merged;
    }

    DsmLogger.failure(
      module: 'Package',
      action: action,
      path: baseUrl,
      response: payload,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: action, data: payload),
      response: response,
    );
  }

  @override
  Future<List<PackageItemModel>> fetchInstalledPackages({
    required String baseUrl,
    required String sid,
    String? synoToken,
    String? cookieHeader,
    int version = 2,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    final additional = [
      'description',
      'description_enu',
      'beta',
      'distributor',
      'distributor_url',
      'maintainer',
      'maintainer_url',
      'dsm_apps',
      'report_beta_url',
      'support_center',
      'startable',
      'installed_info',
      'support_url',
      'is_uninstall_pages',
      'install_type',
      'autoupdate',
      'silent_upgrade',
      'installing_progress',
      'ctl_uninstall',
      'status',
      'url',
      if (version >= 2) 'updated_at',
    ];

    DsmLogger.request(
      module: 'Package',
      action: 'fetchInstalledPackages',
      method: 'POST',
      path: baseUrl,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.Package',
        'method': 'list',
        'version': version,
      },
    );

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Package',
        'version': version.toString(),
        'method': 'list',
        'polling_interval': '15',
        'additional': jsonEncode(additional),
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      final packages = (data['packages'] as List?) ?? const [];
      final result = packages
          .whereType<Map>()
          .map((item) => PackageItemModel.fromInstalledPayload(item))
          .toList();

      DsmLogger.success(
        module: 'Package',
        action: 'fetchInstalledPackages',
        path: baseUrl,
        response: {
          'count': result.length,
        },
      );

      return result;
    }

    DsmLogger.failure(
      module: 'Package',
      action: 'fetchInstalledPackages',
      path: baseUrl,
      response: payload,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'fetchInstalledPackages', data: payload),
      response: response,
    );
  }

  @override
  Future<List<PackageVolumeModel>> fetchVolumes({
    required String baseUrl,
    required String sid,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    DsmLogger.request(
      module: 'Package',
      action: 'fetchVolumes',
      method: 'POST',
      path: baseUrl,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.Storage.Volume',
        'method': 'list',
      },
    );

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Storage.Volume',
        'version': '1',
        'method': 'list',
        'limit': '-1',
        'offset': '0',
        'location': 'internal',
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      final volumes = (data['volumes'] as List?) ?? const [];
      final result = volumes
          .whereType<Map>()
          .map((item) => PackageVolumeModel.fromMap(item))
          .toList();

      DsmLogger.success(
        module: 'Package',
        action: 'fetchVolumes',
        path: baseUrl,
        response: {
          'count': result.length,
        },
      );

      return result;
    }

    DsmLogger.failure(
      module: 'Package',
      action: 'fetchVolumes',
      path: baseUrl,
      response: payload,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'fetchVolumes', data: payload),
      response: response,
    );
  }

  @override
  Future<Map<String, dynamic>> checkInstallQueue({
    required String baseUrl,
    required String sid,
    required String packageId,
    required String version,
    String? synoToken,
    String? cookieHeader,
    bool beta = false,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    DsmLogger.request(
      module: 'Package',
      action: 'checkInstallQueue',
      method: 'POST',
      path: packageId,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.Package.Installation',
        'method': 'get_queue',
        'version': version,
        'beta': beta,
      },
    );

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Package.Installation',
        'version': '1',
        'method': 'get_queue',
        'pkgs': '[{"pkg":"$packageId", "version": "$version","beta":$beta}]',
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      DsmLogger.success(
        module: 'Package',
        action: 'checkInstallQueue',
        path: packageId,
        response: data,
      );
      return Map<String, dynamic>.from(data);
    }

    DsmLogger.failure(
      module: 'Package',
      action: 'checkInstallQueue',
      path: packageId,
      response: payload,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'checkInstallQueue', data: payload),
      response: response,
    );
  }

  @override
  Future<Map<String, dynamic>> installPackage({
    required String baseUrl,
    required String sid,
    required String packageId,
    required String volumePath,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    DsmLogger.request(
      module: 'Package',
      action: 'installPackage',
      method: 'POST',
      path: packageId,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.Package.Installation',
        'method': 'install',
        'volumePath': volumePath,
      },
    );

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Package.Installation',
        'version': '1',
        'method': 'install',
        'name': packageId,
        'blqinst': 'true',
        'volume_path': volumePath,
        'is_syno': 'true',
        'beta': 'false',
        'installrunpackage': 'true',
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      DsmLogger.success(
        module: 'Package',
        action: 'installPackage',
        path: packageId,
        response: data,
      );
      return Map<String, dynamic>.from(data);
    }

    DsmLogger.failure(
      module: 'Package',
      action: 'installPackage',
      path: packageId,
      response: payload,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'volumePath': volumePath,
      },
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'installPackage', data: payload),
      response: response,
    );
  }

  @override
  Future<Map<String, dynamic>> getInstallStatus({
    required String baseUrl,
    required String sid,
    required String taskId,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    DsmLogger.request(
      module: 'Package',
      action: 'getInstallStatus',
      method: 'POST',
      path: taskId,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.Package.Installation',
        'method': 'status',
      },
    );

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Package.Installation',
        'version': '1',
        'method': 'status',
        'task_id': taskId,
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      DsmLogger.success(
        module: 'Package',
        action: 'getInstallStatus',
        path: taskId,
        response: data,
      );
      return Map<String, dynamic>.from(data);
    }

    DsmLogger.failure(
      module: 'Package',
      action: 'getInstallStatus',
      path: taskId,
      response: payload,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'getInstallStatus', data: payload),
      response: response,
    );
  }

  @override
  Future<void> startPackage({
    required String baseUrl,
    required String sid,
    required String packageId,
    String? dsmAppName,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    DsmLogger.request(
      module: 'Package',
      action: 'startPackage',
      method: 'POST',
      path: packageId,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.Package.Control',
        'method': 'start',
      },
    );

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Package.Control',
        'version': '1',
        'method': 'start',
        'id': packageId,
        if (dsmAppName != null && dsmAppName.isNotEmpty) 'dsm_apps': jsonEncode([dsmAppName]),
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      DsmLogger.success(module: 'Package', action: 'startPackage', path: packageId);
      return;
    }

    DsmLogger.failure(
      module: 'Package',
      action: 'startPackage',
      path: packageId,
      response: payload,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'startPackage', data: payload),
      response: response,
    );
  }

  @override
  Future<void> stopPackage({
    required String baseUrl,
    required String sid,
    required String packageId,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    DsmLogger.request(
      module: 'Package',
      action: 'stopPackage',
      method: 'POST',
      path: packageId,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.Package.Control',
        'method': 'stop',
      },
    );

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Package.Control',
        'version': '1',
        'method': 'stop',
        'id': packageId,
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      DsmLogger.success(module: 'Package', action: 'stopPackage', path: packageId);
      return;
    }

    DsmLogger.failure(
      module: 'Package',
      action: 'stopPackage',
      path: packageId,
      response: payload,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'stopPackage', data: payload),
      response: response,
    );
  }

  @override
  Future<void> uninstallPackage({
    required String baseUrl,
    required String sid,
    required String packageId,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    DsmLogger.request(
      module: 'Package',
      action: 'uninstallPackage',
      method: 'POST',
      path: packageId,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.Package.Uninstallation',
        'method': 'uninstall',
      },
    );

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Package.Uninstallation',
        'version': '1',
        'method': 'uninstall',
        'id': packageId,
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      DsmLogger.success(module: 'Package', action: 'uninstallPackage', path: packageId);
      return;
    }

    DsmLogger.failure(
      module: 'Package',
      action: 'uninstallPackage',
      path: packageId,
      response: payload,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'uninstallPackage', data: payload),
      response: response,
    );
  }
}
