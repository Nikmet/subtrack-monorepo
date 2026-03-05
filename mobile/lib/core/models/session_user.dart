class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isBanned,
    required this.banReason,
    this.name,
    this.avatarLink,
  });

  final String id;
  final String email;
  final String role;
  final bool isBanned;
  final String? banReason;
  final String? name;
  final String? avatarLink;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'USER').toString(),
      isBanned: json['isBanned'] == true,
      banReason: json['banReason']?.toString(),
      name: json['name']?.toString(),
      avatarLink: json['avatarLink']?.toString(),
    );
  }
}
