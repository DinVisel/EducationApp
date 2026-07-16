import 'quiz.dart';

/// Mirrors `QuizPreviewChoiceDto`.
class QuizPreviewChoice {
  const QuizPreviewChoice({required this.text, required this.isCorrect});

  final String text;
  final bool isCorrect;

  factory QuizPreviewChoice.fromJson(Map<String, dynamic> json) =>
      QuizPreviewChoice(
        text: json['text'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
      );
}

/// Mirrors `QuizPreviewQuestionDto`.
class QuizPreviewQuestion {
  const QuizPreviewQuestion({required this.text, required this.choices});

  final String text;
  final List<QuizPreviewChoice> choices;

  factory QuizPreviewQuestion.fromJson(Map<String, dynamic> json) =>
      QuizPreviewQuestion(
        text: json['text'] as String? ?? '',
        choices: ((json['choices'] as List<dynamic>?) ?? [])
            .map((e) => QuizPreviewChoice.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Mirrors `QuizPreviewDto` — a shared quiz's full content for previewing
/// before cloning ("Assign to My Class").
class QuizPreview {
  const QuizPreview({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.bookReference,
    required this.authorName,
    required this.questions,
  });

  final int id;
  final String title;
  final String? description;
  final QuizCategory category;
  final String? bookReference;
  final String authorName;
  final List<QuizPreviewQuestion> questions;

  factory QuizPreview.fromJson(Map<String, dynamic> json) => QuizPreview(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        category: QuizCategory.fromJson(json['category'] as String?),
        bookReference: json['bookReference'] as String?,
        authorName: json['authorName'] as String? ?? '',
        questions: ((json['questions'] as List<dynamic>?) ?? [])
            .map((e) => QuizPreviewQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
