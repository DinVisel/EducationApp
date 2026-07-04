import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/assignment.dart';

/// Assignments published to a class. Endpoints are nested under a classroom and
/// scoped to the authenticated teacher server-side.
class AssignmentsRepository {
  AssignmentsRepository(this._dio);

  final Dio _dio;

  Future<List<Assignment>> getForClass(int classroomId) async {
    final res = await _dio
        .get<List<dynamic>>('/api/classrooms/$classroomId/assignments');
    return (res.data ?? [])
        .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Publishes an assignment to [classroomId], fanning out to enrolled students.
  /// [fileIds] are ids of files already uploaded via the files endpoint.
  Future<Assignment> create(
    int classroomId, {
    required String title,
    String? description,
    DateTime? dueDate,
    List<int> fileIds = const [],
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/classrooms/$classroomId/assignments',
      data: {
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (dueDate != null)
          'dueDate':
              '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
        'fileIds': fileIds,
      },
    );
    return Assignment.fromJson(res.data!);
  }

  Future<void> delete(int classroomId, int id) =>
      _dio.delete<void>('/api/classrooms/$classroomId/assignments/$id');
}

final assignmentsRepositoryProvider = Provider<AssignmentsRepository>(
  (ref) => AssignmentsRepository(ref.watch(dioProvider)),
);
