class Profile {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final int roleId;
  final String? roleSlug; // joined from roles.slug when available
  final String? roleName;
  final String? managerId;
  final bool isActive;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.roleId,
    this.roleSlug,
    this.roleName,
    this.managerId,
    required this.isActive,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    final role = map['role'] as Map<String, dynamic>?;
    return Profile(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? '',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      roleId: map['role_id'] as int,
      roleSlug: role?['slug'] as String? ?? map['role_slug'] as String?,
      roleName: role?['name'] as String? ?? map['role_name'] as String?,
      managerId: map['manager_id'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isAdmin => roleSlug == 'admin';
  bool get isManager => roleSlug == 'sales_manager';
  bool get isRep => roleSlug == 'sales_rep';
}

class RoleOption {
  final int id;
  final String name;
  final String slug;
  RoleOption({required this.id, required this.name, required this.slug});

  factory RoleOption.fromMap(Map<String, dynamic> map) => RoleOption(
    id: map['id'] as int,
    name: map['name'] as String,
    slug: map['slug'] as String,
  );
}
