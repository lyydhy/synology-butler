import '../entities/package_item.dart';
import '../entities/package_volume.dart';

abstract class PackageRepository {
  Future<List<PackageItem>> fetchStorePackages({
    bool others = false,
  });

  Future<List<PackageItem>> fetchInstalledPackages();

  Future<List<PackageVolume>> fetchVolumes();

  Future<PackageQueueCheckResult> checkInstallQueue({
    required String packageId,
    required String version,
    bool beta = false,
  });

  Future<String> installPackage({
    required String packageId,
    required String volumePath,
  });

  Future<PackageInstallStatus> getInstallStatus({
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

class PackageQueueCheckResult {
  final List<String> pausedPackages;
  final List<String> causePausingPackages;

  const PackageQueueCheckResult({
    required this.pausedPackages,
    required this.causePausingPackages,
  });
}

class PackageInstallStatus {
  final bool finished;
  final double? progress;
  final String? status;

  const PackageInstallStatus({
    required this.finished,
    required this.progress,
    required this.status,
  });
}
