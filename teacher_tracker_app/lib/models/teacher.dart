/// Mirrors `TeacherDto` from the backend (camelCase JSON).
class Teacher {
  const Teacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;

  String get fullName => '$firstName $lastName'.trim();

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: json['id'] as int,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  /// Body for create/update (server assigns `id`).
  Map<String, dynamic> toWriteJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      };

  Teacher copyWith({String? firstName, String? lastName, String? email}) =>
      Teacher(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
      );
}
