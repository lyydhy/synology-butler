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

/// 相册内照片列表
final albumItemsProvider =
    FutureProvider.autoDispose.family<List<FotoItem>, String>((ref, albumId) async {
  final space = ref.watch(photoSpaceProvider);
  if (space == PhotoSpace.personal) {
    final res = await ref.read(_personalApiProvider).listItem(
      offset: 0,
      limit: 100,
      folderId: albumId,
    );
    return res.items;
  } else {
    final res = await ref.read(_sharedApiProvider).listItem(
      offset: 0,
      limit: 100,
      folderId: albumId,
    );
    return res.items;
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
// ============================================================
// 搜索过滤器
// ============================================================
enum PhotoSearchType { all, photo, video }
enum PhotoSearchTime { all, today, thisWeek, thisMonth }

final photoSearchTypeProvider = StateProvider<PhotoSearchType>((ref) => PhotoSearchType.all);
final photoSearchTimeProvider = StateProvider<PhotoSearchTime>((ref) => PhotoSearchTime.all);

final photoSearchResultsProvider =
    FutureProvider.autoDispose.family<List<FotoItem>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final space = ref.watch(photoSpaceProvider);
  final typeFilter = ref.watch(photoSearchTypeProvider);
  final timeFilter = ref.watch(photoSearchTimeProvider);

  List<FotoItem> response;
  if (space == PhotoSpace.personal) {
    final res = await ref.read(_personalApiProvider).listItem(
        limit: 100, sortBy: 'created_time', sortDirection: 'desc');
    response = res.items;
  } else {
    final res = await ref.read(_sharedApiProvider).listItem(
        limit: 100, sortBy: 'created_time', sortDirection: 'desc');
    response = res.items;
  }

  final q = query.toLowerCase();
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  return response.where((item) {
    // 关键词过滤
    if (q.isNotEmpty &&
        !item.name.toLowerCase().contains(q) &&
        !(item.filePath?.toLowerCase().contains(q) ?? false)) {
      return false;
    }
    // 类型过滤
    if (typeFilter == PhotoSearchType.photo && item.isVideo) return false;
    if (typeFilter == PhotoSearchType.video && !item.isVideo) return false;
    // 时间过滤
    if (item.createdTime != null) {
      final itemDate = DateTime.fromMillisecondsSinceEpoch(item.createdTime! * 1000);
      if (timeFilter == PhotoSearchTime.today) {
        if (itemDate.isBefore(todayStart)) return false;
      } else if (timeFilter == PhotoSearchTime.thisWeek) {
        if (itemDate.isBefore(weekStart)) return false;
      } else if (timeFilter == PhotoSearchTime.thisMonth) {
        if (itemDate.isBefore(monthStart)) return false;
      }
    } else if (timeFilter != PhotoSearchTime.all) {
      return false;
    }
    return true;
  }).toList();
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
