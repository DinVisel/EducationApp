import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/classroom.dart';

/// Classrooms owned by the authenticated teacher, plus roster management.
/// All endpoints are scoped to the teacher server-side.
class ClassroomsRepository {
  ClassroomsRepository(this._dio);

  final Dio _dio;

  /// Newest first. Pass [beforeId] (the last-loaded classroom's id) to fetch
  /// the next page.
  Future<List<Classroom>> getAll({int? beforeId, int limit = 20}) async {
    final res = await _dio.get<List<dynamic>>('/api/v1/classrooms', queryParameters: {
      if (beforeId != null) 'beforeId': beforeId,
      'limit': limit,
    });
    return (res.data ?? [])
        .map((e) => Classroom.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClassroomDetail> getById(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/classrooms/$id');
    return ClassroomDetail.fromJson(res.data!);
  }

  Future<Classroom> create(String name) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/classrooms',
      data: {'name': name},
    );
    return Classroom.fromJson(res.data!);
  }

  Future<void> rename(int id, String name) =>
      _dio.put<void>('/api/v1/classrooms/$id', data: {'name': name});

  Future<void> delete(int id) => _dio.delete<void>('/api/v1/classrooms/$id');

  Future<void> enroll(int classroomId, int studentId) =>
      _dio.post<void>('/api/v1/classrooms/$classroomId/students/$studentId');

  Future<void> unenroll(int classroomId, int studentId) =>
      _dio.delete<void>('/api/v1/classrooms/$classroomId/students/$studentId');
}

final classroomsRepositoryProvider = Provider<ClassroomsRepository>(
  (ref) => ClassroomsRepository(ref.watch(dioProvider)),
);
