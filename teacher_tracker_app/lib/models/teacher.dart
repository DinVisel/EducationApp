/// Mirrors `TeacherDto` from the backend (camelCase JSON).
class Teacher {
  const Teacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarFileId,
    this.coverFileId,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final int? avatarFileId;
  final int? coverFileId;

  String get fullName => '$firstName $lastName'.trim();

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: json['id'] as int,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarFileId: json['avatarFileId'] as int?,
        coverFileId: json['coverFileId'] as int?,
      );

  /// Body for create/update (server assigns `id`). Includes the image ids so a
  /// profile-image change is persisted; nulls leave the server value unchanged.
  Map<String, dynamic> toWriteJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'avatarFileId': ?avatarFileId,
        'coverFileId': ?coverFileId,
      };

  Teacher copyWith({
    String? firstName,
    String? lastName,
    String? email,
    int? avatarFileId,
    int? coverFileId,
  }) =>
      Teacher(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        avatarFileId: avatarFileId ?? this.avatarFileId,
        coverFileId: coverFileId ?? this.coverFileId,
      );
}
