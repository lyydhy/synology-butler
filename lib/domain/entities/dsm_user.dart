class DsmUser {
  final String name;
  final String description;
  final String email;
  final String status;
  final bool isExpired;
  final bool canChangePassword;
  final bool passwordNeverExpires;

  const DsmUser({
    required this.name,
    required this.description,
    required this.email,
    required this.status,
    required this.isExpired,
    this.canChangePassword = true,
    this.passwordNeverExpires = false,
  });

  factory DsmUser.fromJson(Map<String, dynamic> json) {
    return DsmUser(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? 'normal',
      isExpired: json['expired'] == true,
      canChangePassword: json['cannot_chg_passwd'] != true,
      passwordNeverExpires: json['passwd_never_expire'] == true,
    );
  }

  DsmUser copyWith({
    String? name,
    String? description,
    String? email,
    String? status,
    bool? isExpired,
    bool? canChangePassword,
    bool? passwordNeverExpires,
  }) {
    return DsmUser(
      name: name ?? this.name,
      description: description ?? this.description,
      email: email ?? this.email,
      status: status ?? this.status,
      isExpired: isExpired ?? this.isExpired,
      canChangePassword: canChangePassword ?? this.canChangePassword,
      passwordNeverExpires: passwordNeverExpires ?? this.passwordNeverExpires,
    );
  }
}
