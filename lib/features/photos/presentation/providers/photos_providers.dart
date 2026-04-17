import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/synology_photos_api.dart';

/// API provider
final synologyPhotosApiProvider = Provider<SynologyPhotosApi>((ref) {
  return DsmSynologyPhotosApi();
});

/// 当前 Space
enum PhotoSpace { personal, shared }

/// Space 切换
final photoSpaceProvider = StateProvider<PhotoSpace>((ref) => PhotoSpace.personal);

/// 照片时间线
final photoTimelineProvider = FutureProvider.autoDispose
    .family<FotoTimelineResponse, int>((ref, page) async {
  final api = ref.watch(synologyPhotosApiProvider);
  return api.listTimelineItem(offset: page * 30, limit: 30);
});

/// 相册列表
final photoAlbumsProvider = FutureProvider.autoDispose
    .family<FotoAlbumListResponse, int>((ref, page) async {
  final api = ref.watch(synologyPhotosApiProvider);
  return api.listAlbum(offset: page * 30, limit: 30);
});

/// 照片详情
final photoItemProvider =
    FutureProvider.autoDispose.family<FotoItem, String>((ref, id) async {
  final api = ref.watch(synologyPhotosApiProvider);
  return api.getItem(itemId: id);
});

/// 缩略图缓存
final photoThumbnailProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, id) async {
  final api = ref.watch(synologyPhotosApiProvider);
  return api.getThumbnail(id: id);
});

/// 收藏操作
final photoToggleFavoriteProvider =
    FutureProvider.autoDispose.family<void, ({String id, bool fav})>(
  (ref, params) async {
    final api = ref.watch(synologyPhotosApiProvider);
    await api.setFavorite(itemId: params.id, favorite: params.fav);
    // 刷新详情
    ref.invalidate(photoItemProvider(params.id));
  },
);

/// 当前选中的照片（用于详情页滑动）
final selectedPhotoIndexProvider = StateProvider.family<int, List<String>>(
  (ref, ids) => 0,
);
