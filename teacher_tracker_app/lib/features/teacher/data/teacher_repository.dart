import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/teacher.dart';

class TeacherRepository {
  TeacherRepository(this._dio);

  final Dio _dio;

  Future<List<Teacher>> getAll() async {
    final res = await _dio.get<List<dynamic>>('/api/teachers');
    return (res.data ?? [])
        .map((e) => Teacher.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Teacher> getById(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/teachers/$id');
    return Teacher.fromJson(res.data!);
  }

  Future<Teacher> create(Teacher teacher) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/teachers',
      data: teacher.toWriteJson(),
    );
    return Teacher.fromJson(res.data!);
  }

  Future<void> update(Teacher teacher) async {
    await _dio.put('/api/teachers/${teacher.id}', data: teacher.toWriteJson());
  }

  Future<void> delete(int id) async {
    await _dio.delete('/api/teachers/$id');
  }
}

final teacherRepositoryProvider = Provider<TeacherRepository>(
  (ref) => TeacherRepository(ref.watch(dioProvider)),
);
