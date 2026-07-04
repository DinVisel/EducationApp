import 'assignment.dart';

/// Mirrors `StudentAssignmentDto` — a student's own copy of a class assignment,
/// with the class context, teacher attachments, and their completion status.
class StudentAssignmentItem {
  const StudentAssignmentItem({
    required this.id,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.className,
    required this.isDone,
    required this.completedAt,
    required this.attachments,
  });

  /// The `StudentAssignment` id — used to mark this copy done/undone.
  final int id;
  final int assignmentId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String className;
  final bool isDone;
  final DateTime? completedAt;
  final List<AssignmentAttachment> attachments;

  factory StudentAssignmentItem.fromJson(Map<String, dynamic> json) =>
      StudentAssignmentItem(
        id: json['id'] as int,
        assignmentId: (json['assignmentId'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.tryParse(json['dueDate'] as String),
        className: json['className'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.tryParse(json['completedAt'] as String),
        attachments: ((json['attachments'] as List<dynamic>?) ?? [])
            .map((e) => AssignmentAttachment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Mirrors `StudentClassDto` — a class the student is enrolled in.
class StudentClass {
  const StudentClass({
    required this.id,
    required this.name,
    required this.teacherName,
  });

  final int id;
  final String name;
  final String teacherName;

  factory StudentClass.fromJson(Map<String, dynamic> json) => StudentClass(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        teacherName: json['teacherName'] as String? ?? '',
      );
}
