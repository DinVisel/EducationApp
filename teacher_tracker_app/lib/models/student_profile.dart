/// Mirrors `StudentProfileDto` — the signed-in student's view of themselves.
/// Lighter than the teacher-facing [Student]; this is what a student account
/// carries in its session.
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.studentNumber,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String studentNumber;

  String get fullName => '$firstName $lastName'.trim();

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        id: json['id'] as int,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        studentNumber: json['studentNumber'] as String? ?? '',
      );
}
