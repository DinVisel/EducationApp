/// Mirrors `AdminUserDto` — a user account as an admin sees it.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String role; // 'Teacher' / 'Student' / 'Admin'
  final String? name;
  final DateTime createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as int,
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
        name: json['name'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
