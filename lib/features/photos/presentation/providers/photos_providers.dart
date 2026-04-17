import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/synology_photos_api.dart';

/// 当前 Space
enum PhotoSpace { personal, shared }

/// Space 切换
final photoSpaceProvider = StateProvider<PhotoSpace>((ref) => PhotoSpace.personal);

// ============================================================
// API providers（按 Space 分开）
// ============================================================
final _personalApiProvider = Provider<SynologyPhotosApi>((ref) {
  return DsmSynologyPhotosApi();
});

final _sharedApiProvider = Provider<SynologyFotoTeamApi>((ref) {
  return DsmSynologyFotoTeamApi();
});

/// 当前 Space 对应的照片 API
final _currentApiProvider = Provider<Object>((ref) {
  final space = ref.watch(photoSpaceProvider);
  return space == PhotoSpace.personal
      ? ref.watch(_personalApiProvider)
      : ref.watch(_sharedApiProvider);
});

// ============================================================
// 数据 providers
// ============================================================

/// 照片时间线
final photoTimelineProvider = FutureProvider.autoDispose
    .family<FotoTimelineResponse, int>((ref, page) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    return ref.read(_personalApiProvider).listTimelineItem(offset: page * 30, limit: 30);
  } else {
    return ref.read(_sharedApiProvider).listTimelineItem(offset: page * 30, limit: 30);
  }
});

/// 相册列表
final photoAlbumsProvider = FutureProvider.autoDispose
    .family<FotoAlbumListResponse, int>((ref, page) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    return ref.read(_personalApiProvider).listAlbum(offset: page * 30, limit: 30);
  } else {
    return ref.read(_sharedApiProvider).listAlbum(offset: page * 30, limit: 30);
  }
});

/// 照片详情
final photoItemProvider =
    FutureProvider.autoDispose.family<FotoItem, String>((ref, id) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    return ref.read(_personalApiProvider).getItem(itemId: id);
  } else {
    return ref.read(_sharedApiProvider).getItem(itemId: id);
  }
});

/// 相册详情
final albumDetailProvider =
    FutureProvider.autoDispose.family<FotoAlbum, String>((ref, id) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    return ref.read(_personalApiProvider).getAlbum(albumId: int.tryParse(id) ?? 0);
  } else {
    return ref.read(_sharedApiProvider).getAlbum(albumId: int.tryParse(id) ?? 0);
  }
});

/// 缩略图
final photoThumbnailProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, id) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    return ref.read(_personalApiProvider).getThumbnail(id: id);
  } else {
    return ref.read(_sharedApiProvider).getThumbnail(id: id);
  }
});

/// 收藏操作
final photoToggleFavoriteProvider =
    FutureProvider.autoDispose.family<void, ({String id, bool fav})>(
  (ref, params) async {
    final space = ref.watch(photoSpaceProvider);
    if (space == PhotoSpace.personal) {
      await ref.read(_personalApiProvider).setFavorite(itemId: params.id, favorite: params.fav);
    } else {
      await ref.read(_sharedApiProvider).setFavorite(itemId: params.id, favorite: params.fav);
    }
    ref.invalidate(photoItemProvider(params.id));
  },
);

/// 照片搜索
final photoSearchResultsProvider =
    FutureProvider.autoDispose.family<List<FotoItem>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    final response = await ref.read(_personalApiProvider).listItem(
        limit: 50, sortBy: 'created_time', sortDirection: 'desc');
    final q = query.toLowerCase();
    return response.items.where((item) {
      return item.name.toLowerCase().contains(q) ||
          (item.filePath?.toLowerCase().contains(q) ?? false);
    }).toList();
  } else {
    final response = await ref.read(_sharedApiProvider).listItem(
        limit: 50, sortBy: 'created_time', sortDirection: 'desc');
    final q = query.toLowerCase();
    return response.items.where((item) {
      return item.name.toLowerCase().contains(q) ||
          (item.filePath?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
});

/// 当前选中的照片（用于详情页滑动）
final selectedPhotoIndexProvider = StateProvider.family<int, List<String>>(
  (ref, ids) => 0,
);
