import 'student.dart';

/// Mirrors `ClassroomDto` — a class in list form with its enrolled count.
class Classroom {
  const Classroom({
    required this.id,
    required this.name,
    required this.studentCount,
  });

  final int id;
  final String name;
  final int studentCount;

  factory Classroom.fromJson(Map<String, dynamic> json) => Classroom(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      );
}

/// Mirrors `ClassroomDetailDto` — a class with its full roster.
class ClassroomDetail {
  const ClassroomDetail({
    required this.id,
    required this.name,
    required this.students,
  });

  final int id;
  final String name;
  final List<Student> students;

  factory ClassroomDetail.fromJson(Map<String, dynamic> json) => ClassroomDetail(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        students: ((json['students'] as List<dynamic>?) ?? [])
            .map((e) => Student.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
