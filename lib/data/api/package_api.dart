import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/utils/dsm_logger.dart';
import '../models/package_item_model.dart';
import '../models/package_volume_model.dart';

abstract class PackageApi {
  Future<List<PackageItemModel>> fetchStorePackages({
        bool others = false,
    int version = 2,
  });

  Future<List<PackageItemModel>> fetchInstalledPackages({
        int version = 2,
  });

  Future<List<PackageVolumeModel>> fetchVolumes();

  Future<Map<String, dynamic>> checkInstallQueue({
    required String packageId,
    required String version,
    bool beta = false,
  });

  Future<Map<String, dynamic>> installPackage({
    required String packageId,
    required String volumePath,
  });

  Future<Map<String, dynamic>> getInstallStatus({
    required String taskId,
  });

  Future<void> startPackage({
    required String packageId,
    String? dsmAppName,
  });

  Future<void> stopPackage({
    required String packageId,
  });

  Future<void> uninstallPackage({
    required String packageId,
  });
}

class DsmPackageApi implements PackageApi {
  DsmPackageApi({required Dio dio}) : _dio = dio;

  final Dio _dio;
  Options _buildOptions() {
    return Options(
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
        bool others = false,
    int version = 2,
  }) async {
    final client = _dio;
    final action = others ? 'fetchThirdPartyStorePackages' : 'fetchStorePackages';

    DsmLogger.request(
      module: 'Package',
      action: action,
      method: 'POST',
      path: '/webapi/entry.cgi',
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
              },
      options: _buildOptions(),
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
        path: '/webapi/entry.cgi',
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
      path: '/webapi/entry.cgi',
      response: payload,
                      );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: action, data: payload),
      response: response,
    );
  }

  @override
  Future<List<PackageItemModel>> fetchInstalledPackages({
        int version = 2,
  }) async {
    final client = _dio;
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
      path: '/webapi/entry.cgi',
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
              },
      options: _buildOptions(),
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
        path: '/webapi/entry.cgi',
        response: {
          'count': result.length,
        },
      );

      return result;
    }

    DsmLogger.failure(
      module: 'Package',
      action: 'fetchInstalledPackages',
      path: '/webapi/entry.cgi',
      response: payload,
                      );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'fetchInstalledPackages', data: payload),
      response: response,
    );
  }

  @override
  Future<List<PackageVolumeModel>> fetchVolumes() async {
    final client = _dio;

    DsmLogger.request(
      module: 'Package',
      action: 'fetchVolumes',
      method: 'POST',
      path: '/webapi/entry.cgi',
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
              },
      options: _buildOptions(),
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
        path: '/webapi/entry.cgi',
        response: {
          'count': result.length,
        },
      );

      return result;
    }

    DsmLogger.failure(
      module: 'Package',
      action: 'fetchVolumes',
      path: '/webapi/entry.cgi',
      response: payload,
                      );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'fetchVolumes', data: payload),
      response: response,
    );
  }

  @override
  Future<Map<String, dynamic>> checkInstallQueue({
    required String packageId,
    required String version,
    bool beta = false,
  }) async {
    final client = _dio;

    DsmLogger.request(
      module: 'Package',
      action: 'checkInstallQueue',
      method: 'POST',
      path: packageId,
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
              },
      options: _buildOptions(),
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
                      );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'checkInstallQueue', data: payload),
      response: response,
    );
  }

  @override
  Future<Map<String, dynamic>> installPackage({
    required String packageId,
    required String volumePath,
  }) async {
    final client = _dio;

    DsmLogger.request(
      module: 'Package',
      action: 'installPackage',
      method: 'POST',
      path: packageId,
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
              },
      options: _buildOptions(),
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
    required String taskId,
  }) async {
    final client = _dio;

    DsmLogger.request(
      module: 'Package',
      action: 'getInstallStatus',
      method: 'POST',
      path: taskId,
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
              },
      options: _buildOptions(),
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
                      );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'getInstallStatus', data: payload),
      response: response,
    );
  }

  @override
  Future<void> startPackage({
    required String packageId,
    String? dsmAppName,
  }) async {
    final client = _dio;

    DsmLogger.request(
      module: 'Package',
      action: 'startPackage',
      method: 'POST',
      path: packageId,
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
              },
      options: _buildOptions(),
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
                      );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'startPackage', data: payload),
      response: response,
    );
  }

  @override
  Future<void> stopPackage({
    required String packageId,
  }) async {
    final client = _dio;

    DsmLogger.request(
      module: 'Package',
      action: 'stopPackage',
      method: 'POST',
      path: packageId,
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
              },
      options: _buildOptions(),
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
                      );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'stopPackage', data: payload),
      response: response,
    );
  }

  @override
  Future<void> uninstallPackage({
    required String packageId,
  }) async {
    final client = _dio;

    DsmLogger.request(
      module: 'Package',
      action: 'uninstallPackage',
      method: 'POST',
      path: packageId,
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
              },
      options: _buildOptions(),
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
                      );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'uninstallPackage', data: payload),
      response: response,
    );
  }
}
