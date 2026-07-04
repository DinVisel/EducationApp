import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/student_assignment.dart';

/// The student-facing API: the signed-in student's classes, assignments, and
/// completion actions. All endpoints are scoped to the token's student id.
class StudentModuleRepository {
  StudentModuleRepository(this._dio);

  final Dio _dio;

  Future<List<StudentAssignmentItem>> getAssignments() async {
    final res = await _dio.get<List<dynamic>>('/api/student/assignments');
    return (res.data ?? [])
        .map((e) => StudentAssignmentItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudentClass>> getClasses() async {
    final res = await _dio.get<List<dynamic>>('/api/student/classes');
    return (res.data ?? [])
        .map((e) => StudentClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Marks the student's copy ([studentAssignmentId]) done or not done.
  Future<void> setDone(int studentAssignmentId, bool done) => _dio.post<void>(
        '/api/student/assignments/$studentAssignmentId/'
        '${done ? 'complete' : 'uncomplete'}',
      );
}

final studentModuleRepositoryProvider = Provider<StudentModuleRepository>(
  (ref) => StudentModuleRepository(ref.watch(dioProvider)),
);
