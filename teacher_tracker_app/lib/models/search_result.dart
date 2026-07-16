/// Mirrors `TeacherResultDto` — a teacher matched in discovery search.
class TeacherResult {
  const TeacherResult({
    required this.userId,
    required this.name,
    required this.avatarFileId,
  });

  final int userId;
  final String name;
  final int? avatarFileId;

  factory TeacherResult.fromJson(Map<String, dynamic> json) => TeacherResult(
        userId: json['userId'] as int,
        name: json['name'] as String? ?? '',
        avatarFileId: json['avatarFileId'] as int?,
      );
}

/// Mirrors `MaterialResultDto` — a discoverable material (a quiz or document
/// shared to the feed). [postId] opens the feed post; [quizId] is set for
/// quizzes, [fileId] for documents.
class MaterialResult {
  const MaterialResult({
    required this.type,
    required this.postId,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.authorName,
    required this.quizId,
    required this.fileId,
  });

  final String type; // "Quiz" | "Document"
  final int postId;
  final String title;
  final String subject;
  final String? gradeLevel;
  final String authorName;
  final int? quizId;
  final int? fileId;

  bool get isQuiz => type == 'Quiz';

  factory MaterialResult.fromJson(Map<String, dynamic> json) => MaterialResult(
        type: json['type'] as String? ?? 'Document',
        postId: json['postId'] as int,
        title: json['title'] as String? ?? '',
        subject: json['subject'] as String? ?? 'General',
        gradeLevel: json['gradeLevel'] as String?,
        authorName: json['authorName'] as String? ?? '',
        quizId: json['quizId'] as int?,
        fileId: json['fileId'] as int?,
      );
}

/// Mirrors `SearchResultsDto` — grouped discovery results.
class SearchResults {
  const SearchResults({required this.teachers, required this.materials});

  final List<TeacherResult> teachers;
  final List<MaterialResult> materials;

  bool get isEmpty => teachers.isEmpty && materials.isEmpty;

  factory SearchResults.fromJson(Map<String, dynamic> json) => SearchResults(
        teachers: ((json['teachers'] as List<dynamic>?) ?? [])
            .map((e) => TeacherResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        materials: ((json['materials'] as List<dynamic>?) ?? [])
            .map((e) => MaterialResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
