import '../../../core/constants/app_constants.dart';
import '../../../core/storage/local_storage_service.dart';
import '../models/shared_incoming_file.dart';

/// 外部分享进入应用时，用户可能尚未完成会话恢复。
/// 这里先把待处理文件暂存起来，等应用进入主界面后再继续跳转上传页。
class ExternalSharePendingStore {
  const ExternalSharePendingStore();

  Future<void> save(SharedIncomingFile file) async {
    final storage = LocalStorageService();
    await storage.writeJsonMap(AppConstants.pendingExternalShareKey, {
      'path': file.path,
      'name': file.name,
      'mimeType': file.mimeType,
      'size': file.size,
      'source': file.source,
    });
  }

  Future<SharedIncomingFile?> load() async {
    final storage = LocalStorageService();
    final json = await storage.readJsonMap(AppConstants.pendingExternalShareKey);
    final path = json['path']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    if (path.isEmpty || name.isEmpty) return null;

    return SharedIncomingFile(
      path: path,
      name: name,
      mimeType: json['mimeType']?.toString(),
      size: int.tryParse('${json['size'] ?? ''}'),
      source: json['source']?.toString() ?? 'external_share',
    );
  }

  Future<void> clear() async {
    final storage = LocalStorageService();
    await storage.remove(AppConstants.pendingExternalShareKey);
  }
}
