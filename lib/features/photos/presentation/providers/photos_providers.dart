import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/synology_photos_api.dart';

/// 当前 Space
enum PhotoSpace { personal, shared }

/// Space 切换
final photoSpaceProvider = StateProvider<PhotoSpace>((ref) => PhotoSpace.personal);

// ============================================================
// API providers
// ============================================================
final _personalApiProvider = Provider<SynologyPhotosApi>((ref) {
  return DsmSynologyPhotosApi();
});

final _sharedApiProvider = Provider<SynologyFotoTeamApi>((ref) {
  return DsmSynologyFotoTeamApi();
});

// ============================================================
// 照片时间线（分页）
// ============================================================
final photoTimelineProvider = FutureProvider.autoDispose
    .family<FotoTimelineResponse, int>((ref, page) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    return ref.read(_personalApiProvider).listTimelineItem(offset: page * 30, limit: 30);
  } else {
    return ref.read(_sharedApiProvider).listTimelineItem(offset: page * 30, limit: 30);
  }
});

/// 累积的时间线数据（合并多页）
final photoTimelineAllProvider = StateNotifierProvider.autoDispose<
    PhotoTimelineNotifier, AsyncValue<List<FotoItem>>>((ref) {
  return PhotoTimelineNotifier(ref);
});

class PhotoTimelineNotifier extends StateNotifier<AsyncValue<List<FotoItem>>> {
  final Ref _ref;
  int _nextPage = 0;
  bool _hasMore = true;

  PhotoTimelineNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  bool get hasMore => _hasMore;

  Future<void> _load() async {
    final space = _ref.read(photoSpaceProvider);
    try {
      final items = space == PhotoSpace.personal
          ? await _ref.read(_personalApiProvider).listTimelineItem(offset: _nextPage * 30, limit: 30)
          : await _ref.read(_sharedApiProvider).listTimelineItem(offset: _nextPage * 30, limit: 30);

      state = AsyncValue.data(items.items);
      _hasMore = items.items.length >= 30;
      _nextPage++;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    final currentItems = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentItems]); // prevent duplicate load

    final space = _ref.read(photoSpaceProvider);
    try {
      final items = space == PhotoSpace.personal
          ? await _ref.read(_personalApiProvider).listTimelineItem(offset: _nextPage * 30, limit: 30)
          : await _ref.read(_sharedApiProvider).listTimelineItem(offset: _nextPage * 30, limit: 30);

      state = AsyncValue.data([...currentItems, ...items.items]);
      _hasMore = items.items.length >= 30;
      _nextPage++;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _nextPage = 0;
    _hasMore = true;
    await _load();
  }
}

// ============================================================
// 相册列表（分页）
// ============================================================
final photoAlbumsAllProvider = StateNotifierProvider.autoDispose<
    PhotoAlbumsNotifier, AsyncValue<List<FotoAlbum>>>((ref) {
  return PhotoAlbumsNotifier(ref);
});

class PhotoAlbumsNotifier extends StateNotifier<AsyncValue<List<FotoAlbum>>> {
  final Ref _ref;
  int _nextPage = 0;
  bool _hasMore = true;

  PhotoAlbumsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  bool get hasMore => _hasMore;

  Future<void> _load() async {
    final space = _ref.read(photoSpaceProvider);
    try {
      final items = space == PhotoSpace.personal
          ? await _ref.read(_personalApiProvider).listAlbum(offset: _nextPage * 30, limit: 30)
          : await _ref.read(_sharedApiProvider).listAlbum(offset: _nextPage * 30, limit: 30);

      state = AsyncValue.data(items.albums);
      _hasMore = items.albums.length >= 30;
      _nextPage++;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    final current = state.valueOrNull ?? [];
    final space = _ref.read(photoSpaceProvider);
    try {
      final items = space == PhotoSpace.personal
          ? await _ref.read(_personalApiProvider).listAlbum(offset: _nextPage * 30, limit: 30)
          : await _ref.read(_sharedApiProvider).listAlbum(offset: _nextPage * 30, limit: 30);

      state = AsyncValue.data([...current, ...items.albums]);
      _hasMore = items.albums.length >= 30;
      _nextPage++;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _nextPage = 0;
    _hasMore = true;
    await _load();
  }
}

// ============================================================
// 照片详情
// ============================================================
final photoItemProvider =
    FutureProvider.autoDispose.family<FotoItem, String>((ref, id) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    return ref.read(_personalApiProvider).getItem(itemId: id);
  } else {
    return ref.read(_sharedApiProvider).getItem(itemId: id);
  }
});

// ============================================================
// 相册详情
// ============================================================
final albumDetailProvider =
    FutureProvider.autoDispose.family<FotoAlbum, String>((ref, id) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    return ref.read(_personalApiProvider).getAlbum(albumId: int.tryParse(id) ?? 0);
  } else {
    return ref.read(_sharedApiProvider).getAlbum(albumId: int.tryParse(id) ?? 0);
  }
});

// ============================================================
// 缩略图
// ============================================================
final photoThumbnailProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, id) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    return ref.read(_personalApiProvider).getThumbnail(id: id);
  } else {
    return ref.read(_sharedApiProvider).getThumbnail(id: id);
  }
});

// ============================================================
// 收藏操作
// ============================================================
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

// ============================================================
// 搜索
// ============================================================
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

// ============================================================
// 多选模式
// ============================================================
/// 多选模式
final photoMultiSelectProvider =
    StateNotifierProvider.autoDispose<PhotoMultiSelectNotifier, Set<String>>((ref) {
  return PhotoMultiSelectNotifier();
});

class PhotoMultiSelectNotifier extends StateNotifier<Set<String>> {
  PhotoMultiSelectNotifier() : super({});

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  void selectAll(List<String> ids) {
    state = {...ids};
  }

  void clear() {
    state = {};
  }

  bool isSelected(String id) => state.contains(id);
}

// ============================================================
// 批量删除
// ============================================================
final photoBatchDeleteProvider = FutureProvider.autoDispose
    .family<void, List<String>>((ref, ids) async {
  if (ids.isEmpty) return;
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    await ref.read(_personalApiProvider).deleteItem(itemIds: ids);
  } else {
    await ref.read(_sharedApiProvider).deleteItem(itemIds: ids);
  }
  ref.invalidate(photoTimelineAllProvider);
});

/// 选中的照片原图URL
final photoDownloadUrlProvider = FutureProvider.autoDispose
    .family<String, String>((ref, id) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    return ref.read(_personalApiProvider).getDownloadUrl(id: id);
  } else {
    return ref.read(_sharedApiProvider).getDownloadUrl(id: id);
  }
});
