import 'quiz.dart';

/// Mirrors `StudentQuizSummaryDto` — a quiz in the student's list (their
/// attempt), with class context and status.
class StudentQuizSummary {
  const StudentQuizSummary({
    required this.attemptId,
    required this.quizId,
    required this.title,
    required this.category,
    required this.bookReference,
    required this.className,
    required this.questionCount,
    required this.isSubmitted,
    required this.score,
    required this.totalQuestions,
  });

  final int attemptId;
  final int quizId;
  final String title;
  final QuizCategory category;
  final String? bookReference;
  final String className;
  final int questionCount;
  final bool isSubmitted;
  final int score;
  final int totalQuestions;

  factory StudentQuizSummary.fromJson(Map<String, dynamic> json) =>
      StudentQuizSummary(
        attemptId: json['attemptId'] as int,
        quizId: (json['quizId'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        category: QuizCategory.fromJson(json['category'] as String?),
        bookReference: json['bookReference'] as String?,
        className: json['className'] as String? ?? '',
        questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
        isSubmitted: json['isSubmitted'] as bool? ?? false,
        score: (json['score'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      );
}

/// Mirrors `StudentQuizChoiceDto`. [isCorrect] is included so the gamified
/// client can give immediate per-card feedback.
class StudentQuizChoice {
  const StudentQuizChoice({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  final int id;
  final String text;
  final bool isCorrect;

  factory StudentQuizChoice.fromJson(Map<String, dynamic> json) =>
      StudentQuizChoice(
        id: json['id'] as int,
        text: json['text'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
      );
}

/// Mirrors `StudentQuizQuestionDto`.
class StudentQuizQuestion {
  const StudentQuizQuestion({
    required this.questionId,
    required this.text,
    required this.choices,
  });

  final int questionId;
  final String text;
  final List<StudentQuizChoice> choices;

  factory StudentQuizQuestion.fromJson(Map<String, dynamic> json) =>
      StudentQuizQuestion(
        questionId: json['questionId'] as int,
        text: json['text'] as String? ?? '',
        choices: ((json['choices'] as List<dynamic>?) ?? [])
            .map((e) => StudentQuizChoice.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Mirrors `StudentQuizDetailDto` — the full quiz a student solves.
class StudentQuizDetail {
  const StudentQuizDetail({
    required this.attemptId,
    required this.quizId,
    required this.title,
    required this.description,
    required this.category,
    required this.bookReference,
    required this.className,
    required this.isSubmitted,
    required this.score,
    required this.totalQuestions,
    required this.questions,
  });

  final int attemptId;
  final int quizId;
  final String title;
  final String? description;
  final QuizCategory category;
  final String? bookReference;
  final String className;
  final bool isSubmitted;
  final int score;
  final int totalQuestions;
  final List<StudentQuizQuestion> questions;

  factory StudentQuizDetail.fromJson(Map<String, dynamic> json) =>
      StudentQuizDetail(
        attemptId: json['attemptId'] as int,
        quizId: (json['quizId'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        category: QuizCategory.fromJson(json['category'] as String?),
        bookReference: json['bookReference'] as String?,
        className: json['className'] as String? ?? '',
        isSubmitted: json['isSubmitted'] as bool? ?? false,
        score: (json['score'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        questions: ((json['questions'] as List<dynamic>?) ?? [])
            .map((e) => StudentQuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Mirrors `QuizResultDto` — the graded result returned after submitting.
class QuizResult {
  const QuizResult({required this.score, required this.totalQuestions});

  final int score;
  final int totalQuestions;

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        score: (json['score'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      );
}
