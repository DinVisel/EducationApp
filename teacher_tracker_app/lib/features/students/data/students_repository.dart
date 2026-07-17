import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/student.dart';

class StudentsRepository {
  StudentsRepository(this._dio);

  final Dio _dio;

  /// Students belonging to the authenticated teacher (scoped server-side),
  /// newest first. Pass [beforeId] (the last-loaded student's id) to fetch the
  /// next page.
  Future<List<Student>> getAll({int? beforeId, int limit = 20}) async {
    final res = await _dio.get<List<dynamic>>('/api/students', queryParameters: {
      if (beforeId != null) 'beforeId': beforeId,
      'limit': limit,
    });
    return (res.data ?? [])
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Student> getById(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/students/$id');
    return Student.fromJson(res.data!);
  }

  Future<Student> create(Student student) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/students',
      data: student.toCreateJson(),
    );
    return Student.fromJson(res.data!);
  }

  Future<void> update(Student student) async {
    await _dio.put('/api/students/${student.id}', data: student.toUpdateJson());
  }

  Future<void> delete(int id) async {
    await _dio.delete('/api/students/$id');
  }
}

final studentsRepositoryProvider = Provider<StudentsRepository>(
  (ref) => StudentsRepository(ref.watch(dioProvider)),
);
