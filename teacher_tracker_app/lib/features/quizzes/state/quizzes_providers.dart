import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/quiz.dart';
import '../../../models/quiz_analytics.dart';
import '../../../models/quiz_draft.dart';
import '../data/quizzes_repository.dart';

/// Quizzes published to a given classroom, keyed by classroom id.
final classroomQuizzesProvider =
    FutureProvider.family<List<Quiz>, int>((ref, classroomId) {
  return ref.watch(quizzesRepositoryProvider).getForClass(classroomId);
});

/// Analytics for a single quiz, keyed by (classroomId, quizId).
final quizAnalyticsProvider =
    FutureProvider.family<QuizAnalytics, ({int classroomId, int quizId})>(
        (ref, key) {
  return ref
      .watch(quizzesRepositoryProvider)
      .getAnalytics(key.classroomId, key.quizId);
});

/// Create/delete helpers that refresh the per-class quiz list afterwards.
class QuizActions {
  QuizActions(this._ref);
  final Ref _ref;

  Future<Quiz> create(int classroomId, QuizDraft draft) async {
    final created =
        await _ref.read(quizzesRepositoryProvider).create(classroomId, draft);
    _ref.invalidate(classroomQuizzesProvider(classroomId));
    return created;
  }

  Future<void> delete(int classroomId, int id) async {
    await _ref.read(quizzesRepositoryProvider).delete(classroomId, id);
    _ref.invalidate(classroomQuizzesProvider(classroomId));
  }
}

final quizActionsProvider = Provider<QuizActions>((ref) => QuizActions(ref));
