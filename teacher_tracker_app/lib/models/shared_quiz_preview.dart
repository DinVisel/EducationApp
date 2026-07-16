import 'quiz.dart';

/// Mirrors `SharedQuizPreviewDto` — the compact preview of a quiz shared to a
/// feed post. The full quiz (for cloning) is fetched separately.
class SharedQuizPreview {
  const SharedQuizPreview({
    required this.quizId,
    required this.title,
    required this.category,
    required this.questionCount,
  });

  final int quizId;
  final String title;
  final QuizCategory category;
  final int questionCount;

  factory SharedQuizPreview.fromJson(Map<String, dynamic> json) =>
      SharedQuizPreview(
        quizId: json['quizId'] as int,
        title: json['title'] as String? ?? '',
        category: QuizCategory.fromJson(json['category'] as String?),
        questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      );
}
