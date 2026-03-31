class DsmUserModel {
  final String name;
  final String description;
  final String email;
  final String status;
  final bool isExpired;

  const DsmUserModel({
    required this.name,
    required this.description,
    required this.email,
    required this.status,
    required this.isExpired,
  });
}
