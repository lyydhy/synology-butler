import 'dart:async';
import 'dart:io';

import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';

import '../models/shared_incoming_file.dart';

/// 对 flutter_sharing_intent 做一层项目内封装，避免页面直接依赖第三方插件。
///
/// 这样后续如果插件不兼容、或者需要补平台兼容逻辑，只改这一层即可。
class ExternalShareService {
  ExternalShareService._();

  static final ExternalShareService instance = ExternalShareService._();

  Stream<SharedIncomingFile> watchIncomingFiles() {
    return FlutterSharingIntent.instance.getMediaStream().asyncMap((files) async {
      final file = await _pickFirstValidFile(files);
      if (file == null) {
        throw StateError('未收到可用的外部文件');
      }
      return file;
    });
  }

  Future<SharedIncomingFile?> getInitialSharedFile() async {
    final files = await FlutterSharingIntent.instance.getInitialSharing();
    return _pickFirstValidFile(files);
  }

  Future<void> reset() async {
    FlutterSharingIntent.instance.reset();
  }

  Future<SharedIncomingFile?> _pickFirstValidFile(List<SharedFile> files) async {
    for (final file in files) {
      final mapped = await _mapSharedFile(file);
      if (mapped != null) return mapped;
    }
    return null;
  }

  Future<SharedIncomingFile?> _mapSharedFile(SharedFile file) async {
    final path = file.value?.trim() ?? '';
    if (path.isEmpty) return null;

    final localFile = File(path);
    if (!await localFile.exists()) {
      return null;
    }

    final stat = await localFile.stat();
    final segments = path.split(Platform.pathSeparator);
    final fallbackName = segments.isEmpty ? path : segments.last;

    return SharedIncomingFile(
      path: path,
      name: fallbackName,
      mimeType: file.mimeType ?? file.type.name,
      size: stat.size,
      source: Platform.isIOS ? 'ios_share' : 'android_share',
    );
  }
}
