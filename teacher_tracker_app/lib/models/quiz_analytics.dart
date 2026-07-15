/// Mirrors `QuizStudentResultDto` — one student's result on a quiz.
class QuizStudentResult {
  const QuizStudentResult({
    required this.studentId,
    required this.studentName,
    required this.isSubmitted,
    required this.score,
    required this.totalQuestions,
    required this.submittedAt,
  });

  final int studentId;
  final String studentName;
  final bool isSubmitted;
  final int score;
  final int totalQuestions;
  final DateTime? submittedAt;

  double get fraction =>
      totalQuestions == 0 ? 0 : score / totalQuestions;

  factory QuizStudentResult.fromJson(Map<String, dynamic> json) =>
      QuizStudentResult(
        studentId: (json['studentId'] as num?)?.toInt() ?? 0,
        studentName: json['studentName'] as String? ?? '',
        isSubmitted: json['isSubmitted'] as bool? ?? false,
        score: (json['score'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        submittedAt: json['submittedAt'] == null
            ? null
            : DateTime.tryParse(json['submittedAt'] as String),
      );
}

/// Mirrors `QuizChoiceStatDto` — how a single choice fared across submissions.
class QuizChoiceStat {
  const QuizChoiceStat({
    required this.choiceId,
    required this.text,
    required this.isCorrect,
    required this.chosenCount,
  });

  final int choiceId;
  final String text;
  final bool isCorrect;
  final int chosenCount;

  factory QuizChoiceStat.fromJson(Map<String, dynamic> json) => QuizChoiceStat(
        choiceId: (json['choiceId'] as num?)?.toInt() ?? 0,
        text: json['text'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
        chosenCount: (json['chosenCount'] as num?)?.toInt() ?? 0,
      );
}

/// Mirrors `QuizQuestionStatDto` — per-question correct-rate and distribution.
class QuizQuestionStat {
  const QuizQuestionStat({
    required this.questionId,
    required this.text,
    required this.correctRatePct,
    required this.choices,
  });

  final int questionId;
  final String text;
  final double correctRatePct;
  final List<QuizChoiceStat> choices;

  factory QuizQuestionStat.fromJson(Map<String, dynamic> json) =>
      QuizQuestionStat(
        questionId: (json['questionId'] as num?)?.toInt() ?? 0,
        text: json['text'] as String? ?? '',
        correctRatePct: (json['correctRatePct'] as num?)?.toDouble() ?? 0,
        choices: ((json['choices'] as List<dynamic>?) ?? [])
            .map((e) => QuizChoiceStat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Mirrors `QuizAnalyticsDto` — the full analytics payload for one quiz.
class QuizAnalytics {
  const QuizAnalytics({
    required this.quizId,
    required this.title,
    required this.questionCount,
    required this.assignedCount,
    required this.submittedCount,
    required this.averageScorePct,
    required this.results,
    required this.questions,
  });

  final int quizId;
  final String title;
  final int questionCount;
  final int assignedCount;
  final int submittedCount;
  final double? averageScorePct;
  final List<QuizStudentResult> results;
  final List<QuizQuestionStat> questions;

  double get participation =>
      assignedCount == 0 ? 0 : submittedCount / assignedCount;

  factory QuizAnalytics.fromJson(Map<String, dynamic> json) => QuizAnalytics(
        quizId: (json['quizId'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
        assignedCount: (json['assignedCount'] as num?)?.toInt() ?? 0,
        submittedCount: (json['submittedCount'] as num?)?.toInt() ?? 0,
        averageScorePct: (json['averageScorePct'] as num?)?.toDouble(),
        results: ((json['results'] as List<dynamic>?) ?? [])
            .map((e) => QuizStudentResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        questions: ((json['questions'] as List<dynamic>?) ?? [])
            .map((e) => QuizQuestionStat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
