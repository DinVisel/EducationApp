class TrackingNote {
  const TrackingNote({
    required this.id,
    required this.category,
    required this.content,
    required this.createdAt,
    required this.studentId,
  });

  final int id;
  final String category;
  final String content;
  final DateTime createdAt;
  final int studentId;

  factory TrackingNote.fromJson(Map<String, dynamic> json) => TrackingNote(
        id: json['id'] as int,
        category: json['category'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        studentId: json['studentId'] as int,
      );

  static Map<String, dynamic> writeJson({
    required String category,
    required String content,
  }) =>
      {'category': category, 'content': content};
}
