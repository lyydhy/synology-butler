class SharedFolderModel {
  final String name;
  final String description;
  final String volumePath;
  final String fileSystem;
  final bool isReadOnly;
  final bool isHidden;
  final bool recycleBinEnabled;
  final bool encrypted;
  final String usageText;

  const SharedFolderModel({
    required this.name,
    required this.description,
    required this.volumePath,
    required this.fileSystem,
    required this.isReadOnly,
    required this.isHidden,
    required this.recycleBinEnabled,
    required this.encrypted,
    required this.usageText,
  });
}
