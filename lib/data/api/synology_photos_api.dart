import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';

/// 群晖照片 API（个人空间 SYNO.Foto.*）
abstract class SynologyPhotosApi {
  /// 列出照片/媒体时间线（按日期分组）
  /// [offset] 起始偏移，[limit] 每页数量
  Future<FotoTimelineResponse> listTimelineItem({
    int offset = 0,
    int limit = 30,
    String? sortBy,
    String? sortDirection,
  });

  /// 统计时间线项目数量
  Future<int> countTimelineItem();

  /// 列出相册
  Future<FotoAlbumListResponse> listAlbum({
    int offset = 0,
    int limit = 30,
  });

  /// 获取单个相册详情
  Future<FotoAlbum> getAlbum({
    required int albumId,
  });

  /// 列出照片（通用，可过滤）
  Future<FotoItemListResponse> listItem({
    int offset = 0,
    int limit = 30,
    String? folderId,
    String? sortBy,
    String? sortDirection,
  });

  /// 获取照片详情
  Future<FotoItem> getItem({
    required String itemId,
  });

  /// 获取照片缩略图
  Future<Uint8List> getThumbnail({
    required String id,
    int? size,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  });

  /// 获取照片原图/Streaming URL
  Future<String> getDownloadUrl({
    required String id,
  });

  /// 收藏/取消收藏照片
  Future<void> setFavorite({
    required String itemId,
    required bool favorite,
  });

  /// 删除照片
  Future<void> deleteItem({
    required List<String> itemIds,
  });
}

/// 时间线响应
class FotoTimelineResponse {
  final List<FotoItem> items;
  final int total;
  final int offset;
  final int limit;

  FotoTimelineResponse({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });
}

/// 相册列表响应
class FotoAlbumListResponse {
  final List<FotoAlbum> albums;
  final int total;
  final int offset;
  final int limit;

  FotoAlbumListResponse({
    required this.albums,
    required this.total,
    required this.offset,
    required this.limit,
  });
}

/// 照片项
class FotoItem {
  final String id;
  final String name;
  final int? size;
  final String? mimeType;
  final String? thumbnailUrl;
  final String? downloadUrl;
  final int? createdTime;
  final int? modifiedTime;
  final int? ownerUserId;
  final String? ownerUserName;
  final bool isFavorite;
  final String? filePath;
  final String? resolution;
  final String? latitude;
  final String? longitude;
  final String? unitId;
  final String? cacheKey;

  FotoItem({
    required this.id,
    required this.name,
    this.size,
    this.mimeType,
    this.thumbnailUrl,
    this.downloadUrl,
    this.createdTime,
    this.modifiedTime,
    this.ownerUserId,
    this.ownerUserName,
    this.isFavorite = false,
    this.filePath,
    this.resolution,
    this.latitude,
    this.longitude,
    this.unitId,
    this.cacheKey,
  });

  factory FotoItem.fromJson(Map<String, dynamic> json) {
    return FotoItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      size: json['size'] as int?,
      mimeType: json['mime_type']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      downloadUrl: json['download_url']?.toString(),
      createdTime: json['created_time'] as int?,
      modifiedTime: json['modified_time'] as int?,
      ownerUserId: json['owner_user_id'] as int?,
      ownerUserName: json['owner_user_name']?.toString(),
      isFavorite: json['is_favorite'] == true || json['is_favorite'] == 'true',
      filePath: json['file_path']?.toString(),
      resolution: json['resolution']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      unitId: (json['additional']?['thumbnail']?['unit_id'])?.toString(),
      cacheKey: (json['additional']?['thumbnail']?['cache_key'])?.toString(),
    );
  }

  bool get isVideo {
    final mime = mimeType ?? '';
    return mime.startsWith('video/');
  }

  bool get isImage {
    final mime = mimeType ?? '';
    return mime.startsWith('image/');
  }
}

/// 相册
class FotoAlbum {
  final String id;
  final String name;
  final String? description;
  final int? photoCount;
  final String? coverItemId;
  final String? coverThumbnailUrl;
  final int? createdTime;
  final int? modifiedTime;
  final String? additionalInfo;

  FotoAlbum({
    required this.id,
    required this.name,
    this.description,
    this.photoCount,
    this.coverItemId,
    this.coverThumbnailUrl,
    this.createdTime,
    this.modifiedTime,
    this.additionalInfo,
  });

  factory FotoAlbum.fromJson(Map<String, dynamic> json) {
    return FotoAlbum(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      photoCount: json['photo_count'] as int?,
      coverItemId: json['cover_item_id']?.toString(),
      coverThumbnailUrl: json['cover_thumbnail_url']?.toString(),
      createdTime: json['created_time'] as int?,
      modifiedTime: json['modified_time'] as int?,
      additionalInfo: json['additional']?.toString(),
    );
  }
}

/// 照片列表响应
class FotoItemListResponse {
  final List<FotoItem> items;
  final int total;
  final int offset;
  final int limit;

  FotoItemListResponse({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });
}

class DsmSynologyPhotosApi implements SynologyPhotosApi {
  Dio get _dio => businessDio();

  @override
  Future<FotoTimelineResponse> listTimelineItem({
    int offset = 0,
    int limit = 30,
    String? sortBy,
    String? sortDirection,
  }) async {
    DsmLogger.request(
      module: 'SynologyPhotos',
      action: 'list_basic_timeline_info',
      method: 'GET',
    );

    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.Foto.Browse.Item',
        'method': 'list',
        'version': 1,
        'offset': offset,
        'limit': limit,
        'sort_by': sortBy ?? 'created_time',
        'sort_direction': sortDirection ?? 'desc',
        'additional': '["thumbnail","resolution","orientation","video_convert","video_meta","address"]',
      },
    );

    final data = response.data;
    final dataSection = data['data'] as Map<String, dynamic>?;
    if (dataSection == null) {
      return FotoTimelineResponse(items: [], total: 0, offset: offset, limit: limit);
    }
    final items = (dataSection['items'] as List? ?? [])
        .map((e) => FotoItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return FotoTimelineResponse(
      items: items,
      total: dataSection['total'] as int? ?? items.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<int> countTimelineItem() async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.Foto.Browse.Item',
        'method': 'count',
        'version': 1,
      },
    );
    return response.data['data']['count'] as int? ?? 0;
  }

  @override
  Future<FotoAlbumListResponse> listAlbum({
    int offset = 0,
    int limit = 30,
  }) async {
    DsmLogger.request(
      module: 'SynologyPhotos',
      action: 'listAlbum',
      method: 'GET',
    );

    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.Foto.Browse.Album',
        'method': 'list',
        'version': 1,
        'offset': offset,
        'limit': limit,
      },
    );

    final data = response.data;
    final dataSection = data['data'] as Map<String, dynamic>?;
    if (dataSection == null) {
      return FotoAlbumListResponse(albums: [], total: 0, offset: offset, limit: limit);
    }
    final albums = (dataSection['albums'] as List? ?? [])
        .map((e) => FotoAlbum.fromJson(e as Map<String, dynamic>))
        .toList();

    return FotoAlbumListResponse(
      albums: albums,
      total: dataSection['total'] as int? ?? albums.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<FotoAlbum> getAlbum({required int albumId}) async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.Foto.Browse.Album',
        'method': 'get',
        'version': 1,
        'id': albumId,
        'additional': '["thumbnail_url","photo_count"]',
      },
    );
    return FotoAlbum.fromJson(response.data['data']);
  }

  @override
  Future<FotoItemListResponse> listItem({
    int offset = 0,
    int limit = 30,
    String? folderId,
    String? sortBy,
    String? sortDirection,
  }) async {
    DsmLogger.request(
      module: 'SynologyPhotos',
      action: 'listItem',
      method: 'GET',
    );

    final params = {
      'api': 'SYNO.Foto.Browse.Item',
      'method': 'list',
      'version': 1,
      'offset': offset,
      'limit': limit,
      'sort_by': sortBy ?? 'created_time',
      'sort_direction': sortDirection ?? 'desc',
    };
    if (folderId != null) {
      params['folder_id'] = folderId;
    }

    final response = await _dio.get('/webapi/entry.cgi', queryParameters: params);

    final data = response.data;
    final dataSection = data['data'] as Map<String, dynamic>?;
    if (dataSection == null) {
      return FotoItemListResponse(items: [], total: 0, offset: offset, limit: limit);
    }
    final items = (dataSection['items'] as List? ?? [])
        .map((e) => FotoItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return FotoItemListResponse(
      items: items,
      total: dataSection['total'] as int? ?? items.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<FotoItem> getItem({required String itemId}) async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.Foto.Browse.Item',
        'method': 'get',
        'version': 1,
        'id': itemId,
        'additional': '["thumbnail_url","download_url","exif","resolution"]',
      },
    );
    return FotoItem.fromJson(response.data['data']);
  }

  @override
  Future<Uint8List> getThumbnail({
    required String id,
    int? size,
    String? unitId,
    String? cacheKey,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final params = <String, dynamic>{
      'api': 'SYNO.Foto.Thumbnail',
      'method': 'get',
      'version': 1,
      'type': 'unit',
      'size': size ?? 'sm',
    };
    // 优先用 unit_id + cache_key（来自 additional.thumbnail）
    if (unitId != null && cacheKey != null) {
      params['id'] = unitId;
      params['cache_key'] = '""$cacheKey""';
    } else {
      params['id'] = id;
    }

    DsmLogger.request(
      module: 'SynologyPhotos',
      action: 'getThumbnail',
      method: 'GET',
    );

    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );

    return Uint8List.fromList(response.data);
  }

  @override
  Future<String> getDownloadUrl({required String id}) async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.Foto.Browse.Item',
        'method': 'get',
        'version': 1,
        'id': id,
        'additional': '["download_url"]',
      },
    );
    return response.data['data']['download_url']?.toString() ?? '';
  }

  @override
  Future<void> setFavorite({required String itemId, required bool favorite}) async {
    DsmLogger.request(
      module: 'SynologyPhotos',
      action: 'setFavorite',
      method: 'POST',
    );

    await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Foto.Browse.Item',
        'method': 'set',
        'version': 1,
        'id': itemId,
        'is_favorite': favorite,
      },
    );
  }

  @override
  Future<void> deleteItem({required List<String> itemIds}) async {
    DsmLogger.request(
      module: 'SynologyPhotos',
      action: 'deleteItem',
      method: 'POST',
    );

    await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Foto.Browse.Item',
        'method': 'delete',
        'version': 1,
        'id': itemIds.join(','),
      },
    );
  }
}

// ============================================================
// SYNO.FotoTeam API（共享空间）
// ============================================================
abstract class SynologyFotoTeamApi {
  Future<String> getDownloadUrl({required String id});

  Future<FotoTimelineResponse> listTimelineItem({
    int offset = 0,
    int limit = 30,
    String? sortBy,
    String? sortDirection,
  });

  Future<int> countTimelineItem();

  Future<FotoAlbumListResponse> listAlbum({
    int offset = 0,
    int limit = 30,
  });

  Future<FotoAlbum> getAlbum({required int albumId});

  Future<FotoItemListResponse> listItem({
    int offset = 0,
    int limit = 30,
    String? folderId,
    String? sortBy,
    String? sortDirection,
  });

  Future<FotoItem> getItem({required String itemId});

  Future<Uint8List> getThumbnail({
    required String id,
    int? size,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  });

  Future<void> setFavorite({required String itemId, required bool favorite});

  Future<void> deleteItem({required List<String> itemIds});
}

class DsmSynologyFotoTeamApi implements SynologyFotoTeamApi {
  Dio get _dio => businessDio();

  @override
  Future<String> getDownloadUrl({required String id}) async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FotoTeam.Browse.Item',
        'method': 'get',
        'version': 1,
        'id': id,
        'additional': '["download_url"]',
      },
    );
    return response.data['data']['download_url']?.toString() ?? '';
  }

  @override
  Future<FotoTimelineResponse> listTimelineItem({
    int offset = 0,
    int limit = 30,
    String? sortBy,
    String? sortDirection,
  }) async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FotoTeam.Browse.Item',
        'method': 'list',
        'version': 1,
        'offset': offset,
        'limit': limit,
        'sort_by': sortBy ?? 'created_time',
        'sort_direction': sortDirection ?? 'desc',
        'additional': '["thumbnail","resolution","orientation","video_convert","video_meta","address"]',
      },
    );

    final data = response.data;
    final dataSection = data['data'] as Map<String, dynamic>?;
    if (dataSection == null) {
      return FotoTimelineResponse(items: [], total: 0, offset: offset, limit: limit);
    }
    final items = (dataSection['items'] as List? ?? [])
        .map((e) => FotoItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return FotoTimelineResponse(
      items: items,
      total: dataSection['total'] as int? ?? items.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<int> countTimelineItem() async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FotoTeam.Browse.Item',
        'method': 'count',
        'version': 1,
      },
    );
    return response.data['data']['count'] as int? ?? 0;
  }

  @override
  Future<FotoAlbumListResponse> listAlbum({
    int offset = 0,
    int limit = 30,
  }) async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FotoTeam.Browse.Folder',
        'method': 'list',
        'version': 1,
        'offset': offset,
        'limit': limit,
      },
    );

    final data = response.data;
    final dataSection = data['data'] as Map<String, dynamic>?;
    if (dataSection == null) {
      return FotoAlbumListResponse(albums: [], total: 0, offset: offset, limit: limit);
    }
    final folders = (dataSection['items'] as List? ?? []);
    final albums = folders.map((e) => FotoAlbum.fromJson(e as Map<String, dynamic>)).toList();

    return FotoAlbumListResponse(
      albums: albums,
      total: dataSection['total'] as int? ?? albums.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<FotoAlbum> getAlbum({required int albumId}) async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FotoTeam.Browse.Folder',
        'method': 'get',
        'version': 1,
        'id': albumId,
      },
    );
    return FotoAlbum.fromJson(response.data['data']);
  }

  @override
  Future<FotoItemListResponse> listItem({
    int offset = 0,
    int limit = 30,
    String? folderId,
    String? sortBy,
    String? sortDirection,
  }) async {
    final params = {
      'api': 'SYNO.FotoTeam.Browse.Item',
      'method': 'list',
      'version': 1,
      'offset': offset,
      'limit': limit,
      'sort_by': sortBy ?? 'created_time',
      'sort_direction': sortDirection ?? 'desc',
    };
    if (folderId != null) params['folder_id'] = folderId;

    final response = await _dio.get('/webapi/entry.cgi', queryParameters: params);
    final data = response.data;
    final dataSection = data['data'] as Map<String, dynamic>?;
    if (dataSection == null) {
      return FotoItemListResponse(items: [], total: 0, offset: offset, limit: limit);
    }
    final items = (dataSection['items'] as List? ?? [])
        .map((e) => FotoItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return FotoItemListResponse(
      items: items,
      total: dataSection['total'] as int? ?? items.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<FotoItem> getItem({required String itemId}) async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FotoTeam.Browse.Item',
        'method': 'get',
        'version': 1,
        'id': itemId,
        'additional': '["thumbnail_url","download_url","exif","resolution"]',
      },
    );
    return FotoItem.fromJson(response.data['data']);
  }

  @override
  Future<Uint8List> getThumbnail({
    required String id,
    int? size,
    String? unitId,
    String? cacheKey,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final params = <String, dynamic>{
      'api': 'SYNO.FotoTeam.Thumbnail',
      'method': 'get',
      'version': 1,
      'type': 'unit',
      'size': size ?? 'sm',
    };
    if (unitId != null && cacheKey != null) {
      params['id'] = unitId;
      params['cache_key'] = '""$cacheKey""';
    } else {
      params['id'] = id;
    }
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    return Uint8List.fromList(response.data);
  }

  @override
  Future<void> setFavorite({required String itemId, required bool favorite}) async {
    await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.FotoTeam.Browse.Item',
        'method': 'set',
        'version': 1,
        'id': itemId,
        'is_favorite': favorite,
      },
    );
  }

  @override
  Future<void> deleteItem({required List<String> itemIds}) async {
    await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.FotoTeam.Browse.Item',
        'method': 'delete',
        'version': 1,
        'id': itemIds.join(','),
      },
    );
  }
}
