import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_providers.dart';

/// 简单的内存缓存，避免重复下载相同的文件。
final _fileBytesCache = <String, Uint8List>{};

/// 下载文件字节，带内存缓存。
final fileBytesProvider = FutureProvider.family<Uint8List, String>((ref, path) async {
  // 先检查缓存
  if (_fileBytesCache.containsKey(path)) {
    return _fileBytesCache[path]!;
  }

  final bytes = await ref.read(fileRepositoryProvider).downloadFile(
        path: path,
      );

  // 缓存结果，但限制缓存大小（最多 50 个文件，避免内存爆炸）
  if (_fileBytesCache.length >= 50) {
    // 删除最旧的一半缓存
    final keysToRemove = _fileBytesCache.keys.take(25).toList();
    for (final key in keysToRemove) {
      _fileBytesCache.remove(key);
    }
  }
  _fileBytesCache[path] = bytes;

  return bytes;
});

/// 清空文件字节缓存。
