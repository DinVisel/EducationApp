import 'student.dart' show formatDateOnly;

class Homework {
  const Homework({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.studentId,
    this.description,
    this.dueDate,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isDone;
  final DateTime createdAt;
  final int studentId;

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.tryParse(json['dueDate'] as String),
        isDone: json['isDone'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        studentId: json['studentId'] as int,
      );

  static Map<String, dynamic> writeJson({
    required String title,
    String? description,
    DateTime? dueDate,
    required bool isDone,
  }) =>
      {
        'title': title,
        'description': (description == null || description.trim().isEmpty)
            ? null
            : description.trim(),
        'dueDate': dueDate == null ? null : formatDateOnly(dueDate),
        'isDone': isDone,
      };
}
