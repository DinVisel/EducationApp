import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/my_quiz.dart';
import '../../../models/quiz.dart';
import '../../../models/quiz_analytics.dart';
import '../../../models/quiz_draft.dart';
import '../../../models/quiz_preview.dart';

/// Quizzes published to a class. Endpoints are nested under a classroom and
/// scoped to the authenticated teacher server-side.
class QuizzesRepository {
  QuizzesRepository(this._dio);

  final Dio _dio;

  Future<List<Quiz>> getForClass(int classroomId) async {
    final res =
        await _dio.get<List<dynamic>>('/api/v1/classrooms/$classroomId/quizzes');
    return (res.data ?? [])
        .map((e) => Quiz.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Publishes a quiz to [classroomId], fanning out an attempt to every enrolled
  /// student.
  Future<Quiz> create(int classroomId, QuizDraft draft) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/classrooms/$classroomId/quizzes',
      data: draft.toJson(),
    );
    return Quiz.fromJson(res.data!);
  }

  Future<void> delete(int classroomId, int id) =>
      _dio.delete<void>('/api/v1/classrooms/$classroomId/quizzes/$id');

  Future<QuizAnalytics> getAnalytics(int classroomId, int quizId) async {
    final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/classrooms/$classroomId/quizzes/$quizId/analytics');
    return QuizAnalytics.fromJson(res.data!);
  }

  /// The signed-in teacher's own quizzes across all their classes (share picker).
  Future<List<MyQuiz>> getMine() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/quizzes/mine');
    return (res.data ?? [])
        .map((e) => MyQuiz.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Full content of a shared quiz, to preview before cloning.
  Future<QuizPreview> getPreview(int quizId) async {
    final res =
        await _dio.get<Map<String, dynamic>>('/api/v1/quizzes/$quizId/preview');
    return QuizPreview.fromJson(res.data!);
  }

  /// Clones a shared quiz into one of the caller's classes ("Assign to My Class").
  Future<Quiz> clone(int quizId, int classroomId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/quizzes/$quizId/clone',
      data: {'classroomId': classroomId},
    );
    return Quiz.fromJson(res.data!);
  }
}

final quizzesRepositoryProvider = Provider<QuizzesRepository>(
  (ref) => QuizzesRepository(ref.watch(dioProvider)),
);
