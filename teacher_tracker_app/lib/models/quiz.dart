import 'package:flutter/material.dart';

/// Mirrors the server `QuizCategory` enum. A [bookExam] pairs with a free-text
/// book reference; [practice]/[general] are homework-style quizzes.
enum QuizCategory {
  bookExam,
  practice,
  general;

  /// Parses the server's PascalCase name (defaults to [general]).
  static QuizCategory fromJson(String? name) {
    switch (name) {
      case 'BookExam':
        return QuizCategory.bookExam;
      case 'Practice':
        return QuizCategory.practice;
      default:
        return QuizCategory.general;
    }
  }

  /// The PascalCase name the server expects.
  String get wire => switch (this) {
        QuizCategory.bookExam => 'BookExam',
        QuizCategory.practice => 'Practice',
        QuizCategory.general => 'General',
      };

  String get label => switch (this) {
        QuizCategory.bookExam => 'Book Exam',
        QuizCategory.practice => 'Practice',
        QuizCategory.general => 'General',
      };

  IconData get icon => switch (this) {
        QuizCategory.bookExam => Icons.auto_stories_outlined,
        QuizCategory.practice => Icons.fitness_center_outlined,
        QuizCategory.general => Icons.quiz_outlined,
      };
}

/// Mirrors `QuizDto` — a quiz published to a class, with fan-out progress
/// ([submittedCount] of [assignedCount]) and the average score across submitted
/// attempts (0–100, null when nobody has submitted).
class Quiz {
  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.bookReference,
    required this.createdAt,
    required this.classroomId,
    required this.questionCount,
    required this.assignedCount,
    required this.submittedCount,
    required this.averageScorePct,
  });

  final int id;
  final String title;
  final String? description;
  final QuizCategory category;
  final String? bookReference;
  final DateTime createdAt;
  final int classroomId;
  final int questionCount;
  final int assignedCount;
  final int submittedCount;
  final double? averageScorePct;

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        category: QuizCategory.fromJson(json['category'] as String?),
        bookReference: json['bookReference'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        classroomId: (json['classroomId'] as num?)?.toInt() ?? 0,
        questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
        assignedCount: (json['assignedCount'] as num?)?.toInt() ?? 0,
        submittedCount: (json['submittedCount'] as num?)?.toInt() ?? 0,
        averageScorePct: (json['averageScorePct'] as num?)?.toDouble(),
      );
}
