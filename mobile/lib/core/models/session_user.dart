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

  SessionUser copyWith({
    String? id,
    String? email,
    String? role,
    bool? isBanned,
    String? banReason,
    String? name,
    String? avatarLink,
  }) {
    return SessionUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      name: name ?? this.name,
      avatarLink: avatarLink ?? this.avatarLink,
    );
  }

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
