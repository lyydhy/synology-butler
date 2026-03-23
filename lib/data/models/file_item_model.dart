class FileItemModel {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;

  const FileItemModel({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
  });
}
