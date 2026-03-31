class DsmUser {
  final String name;
  final String description;
  final String email;
  final String status;
  final bool isExpired;

  const DsmUser({
    required this.name,
    required this.description,
    required this.email,
    required this.status,
    required this.isExpired,
  });
}
