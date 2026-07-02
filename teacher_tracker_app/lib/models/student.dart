/// Mirrors `StudentDto` from the backend (camelCase JSON).
class Student {
  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.studentNumber,
    required this.teacherId,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String studentNumber;
  final int teacherId;

  String get fullName => '$firstName $lastName'.trim();

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as int,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        studentNumber: json['studentNumber'] as String? ?? '',
        teacherId: json['teacherId'] as int,
      );

  /// Body for POST /api/students (CreateStudentDto). The server assigns
  /// teacherId from the auth token.
  Map<String, dynamic> toCreateJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'studentNumber': studentNumber,
      };

  /// Body for PUT /api/students/{id} (UpdateStudentDto — no teacherId).
  Map<String, dynamic> toUpdateJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'studentNumber': studentNumber,
      };

  Student copyWith({
    String? firstName,
    String? lastName,
    String? studentNumber,
  }) =>
      Student(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        studentNumber: studentNumber ?? this.studentNumber,
        teacherId: teacherId,
      );
}
