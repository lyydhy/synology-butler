class DsmGroup {
  final String name;
  final String description;
  final int memberCount;

  const DsmGroup({
    required this.name,
    required this.description,
    required this.memberCount,
  });

  factory DsmGroup.fromJson(Map<String, dynamic> json) {
    return DsmGroup(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      memberCount: json['member_count'] as int? ?? json['members'] as int? ?? 0,
    );
  }
}
