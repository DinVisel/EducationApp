import 'quiz.dart';

/// Mutable form state used by the quiz authoring screen and serialized by the
/// repository into the `CreateQuizDto` request body. Not a server model.
class QuizChoiceDraft {
  QuizChoiceDraft({this.text = '', this.isCorrect = false});

  String text;
  bool isCorrect;

  Map<String, dynamic> toJson() => {'text': text.trim(), 'isCorrect': isCorrect};
}

class QuizQuestionDraft {
  QuizQuestionDraft({this.text = '', List<QuizChoiceDraft>? choices})
      : choices = choices ??
            [QuizChoiceDraft(isCorrect: true), QuizChoiceDraft()];

  String text;
  final List<QuizChoiceDraft> choices;

  Map<String, dynamic> toJson() => {
        'text': text.trim(),
        'choices': choices.map((c) => c.toJson()).toList(),
      };
}

class QuizDraft {
  QuizDraft({
    this.title = '',
    this.description = '',
    this.category = QuizCategory.bookExam,
    this.bookReference = '',
    List<QuizQuestionDraft>? questions,
  }) : questions = questions ?? [QuizQuestionDraft()];

  String title;
  String description;
  QuizCategory category;
  String bookReference;
  final List<QuizQuestionDraft> questions;

  Map<String, dynamic> toJson() => {
        'title': title.trim(),
        if (description.trim().isNotEmpty) 'description': description.trim(),
        'category': category.wire,
        if (category == QuizCategory.bookExam && bookReference.trim().isNotEmpty)
          'bookReference': bookReference.trim(),
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
