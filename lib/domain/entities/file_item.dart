class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;

  const FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
  });
}
