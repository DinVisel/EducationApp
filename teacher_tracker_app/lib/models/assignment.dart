/// Mirrors `AssignmentAttachmentDto` — a file attached to an assignment.
/// [fileId] is used with the files endpoint to fetch a download URL.
class AssignmentAttachment {
  const AssignmentAttachment({
    required this.fileId,
    required this.fileName,
    required this.contentType,
    required this.size,
  });

  final int fileId;
  final String fileName;
  final String contentType;
  final int size;

  bool get isImage => contentType.startsWith('image/');
  bool get isVideo => contentType.startsWith('video/');

  factory AssignmentAttachment.fromJson(Map<String, dynamic> json) =>
      AssignmentAttachment(
        fileId: json['fileId'] as int,
        fileName: json['fileName'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );
}

/// Mirrors `AssignmentDto` — work published to a class, with fan-out progress
/// ([completedCount] of [studentCount]) and downloadable [attachments].
class Assignment {
  const Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.createdAt,
    required this.classroomId,
    required this.studentCount,
    required this.completedCount,
    required this.attachments,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final DateTime createdAt;
  final int classroomId;
  final int studentCount;
  final int completedCount;
  final List<AssignmentAttachment> attachments;

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.tryParse(json['dueDate'] as String),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        classroomId: (json['classroomId'] as num?)?.toInt() ?? 0,
        studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
        completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
        attachments: ((json['attachments'] as List<dynamic>?) ?? [])
            .map((e) => AssignmentAttachment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
