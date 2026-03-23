import '../entities/nas_server.dart';
import '../entities/nas_session.dart';
import '../entities/package_item.dart';
import '../entities/package_volume.dart';

abstract class PackageRepository {
  Future<List<PackageItem>> fetchStorePackages({
    required NasServer server,
    required NasSession session,
    bool others = false,
  });

  Future<List<PackageItem>> fetchInstalledPackages({
    required NasServer server,
    required NasSession session,
  });

  Future<List<PackageVolume>> fetchVolumes({
    required NasServer server,
    required NasSession session,
  });

  Future<PackageQueueCheckResult> checkInstallQueue({
    required NasServer server,
    required NasSession session,
    required String packageId,
    required String version,
    bool beta = false,
  });

  Future<String> installPackage({
    required NasServer server,
    required NasSession session,
    required String packageId,
    required String volumePath,
  });

  Future<PackageInstallStatus> getInstallStatus({
    required NasServer server,
    required NasSession session,
    required String taskId,
  });

  Future<void> startPackage({
    required NasServer server,
    required NasSession session,
    required String packageId,
    String? dsmAppName,
  });

  Future<void> stopPackage({
    required NasServer server,
    required NasSession session,
    required String packageId,
  });

  Future<void> uninstallPackage({
    required NasServer server,
    required NasSession session,
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
