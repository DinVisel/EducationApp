import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/onboarding.dart';
import '../../../models/student_assignment.dart';
import '../../../models/student_quiz.dart';

/// The student-facing API: the signed-in student's classes, assignments, and
/// completion actions. All endpoints are scoped to the token's student id.
class StudentModuleRepository {
  StudentModuleRepository(this._dio);

  final Dio _dio;

  Future<List<StudentAssignmentItem>> getAssignments() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/student/assignments');
    return (res.data ?? [])
        .map((e) => StudentAssignmentItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudentClass>> getClasses() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/student/classes');
    return (res.data ?? [])
        .map((e) => StudentClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Marks the student's copy ([studentAssignmentId]) done or not done.
  Future<void> setDone(int studentAssignmentId, bool done) => _dio.post<void>(
        '/api/v1/student/assignments/$studentAssignmentId/'
        '${done ? 'complete' : 'uncomplete'}',
      );

  Future<List<StudentQuizSummary>> getQuizzes() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/student/quizzes');
    return (res.data ?? [])
        .map((e) => StudentQuizSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The full quiz for one [attemptId] (the student's own attempt).
  Future<StudentQuizDetail> getQuiz(int attemptId) async {
    final res =
        await _dio.get<Map<String, dynamic>>('/api/v1/student/quizzes/$attemptId');
    return StudentQuizDetail.fromJson(res.data!);
  }

  /// Submits answers for [attemptId]; the server grades authoritatively and
  /// returns the score. [answers] maps question id → chosen choice id.
  Future<QuizResult> submitQuiz(int attemptId, Map<int, int> answers) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/student/quizzes/$attemptId/submit',
      data: {
        'answers': answers.entries
            .map((e) => {'questionId': e.key, 'choiceId': e.value})
            .toList(),
      },
    );
    return QuizResult.fromJson(res.data!);
  }

  // ── Method B: join a class by code (Waiting Lobby) ────────────────────────

  /// Submits a class code to request to join. The student stays out of the class
  /// (a Pending request) until the teacher approves.
  Future<ClassJoinRequest> requestToJoin(String classCode) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/student/class-requests',
      data: {'classCode': classCode},
    );
    return ClassJoinRequest.fromJson(res.data!);
  }

  /// The student's own join requests (pending and decided), newest first.
  Future<List<ClassJoinRequest>> myRequests() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/student/class-requests');
    return (res.data ?? [])
        .map((e) => ClassJoinRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cancels the student's own pending request.
  Future<void> cancelRequest(int requestId) =>
      _dio.delete<void>('/api/v1/student/class-requests/$requestId');
}

final studentModuleRepositoryProvider = Provider<StudentModuleRepository>(
  (ref) => StudentModuleRepository(ref.watch(dioProvider)),
);
