import 'quiz.dart';

/// Mirrors `MyQuizDto` — one of the signed-in teacher's quizzes, for the
/// "share a quiz" picker in the compose screen.
class MyQuiz {
  const MyQuiz({
    required this.id,
    required this.title,
    required this.category,
    required this.className,
    required this.questionCount,
  });

  final int id;
  final String title;
  final QuizCategory category;
  final String className;
  final int questionCount;

  factory MyQuiz.fromJson(Map<String, dynamic> json) => MyQuiz(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        category: QuizCategory.fromJson(json['category'] as String?),
        className: json['className'] as String? ?? '',
        questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      );
}
