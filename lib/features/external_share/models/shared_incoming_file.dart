class SharedIncomingFile {
  const SharedIncomingFile({
    required this.path,
    required this.name,
    required this.source,
    this.mimeType,
    this.size,
  });

  /// 插件返回的本地可读文件路径。
  final String path;

  /// 用于展示和上传时的原始文件名。
  final String name;

  /// 外部应用传入时的 MIME 类型，可能为空。
  final String? mimeType;

  /// 文件大小，某些来源可能拿不到。
  final int? size;

  /// 来源标记，便于后续定位平台差异问题。
  final String source;
}
