import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/homework.dart';

class HomeworkRepository {
  HomeworkRepository(this._dio);

  final Dio _dio;

  String _base(int studentId) => '/api/students/$studentId/homework';

  /// Newest first. Pass [beforeId] (the last-loaded item's id) to fetch the
  /// next page.
  Future<List<Homework>> getForStudent(
    int studentId, {
    int? beforeId,
    int limit = 20,
  }) async {
    final res = await _dio.get<List<dynamic>>(_base(studentId), queryParameters: {
      if (beforeId != null) 'beforeId': beforeId,
      'limit': limit,
    });
    return (res.data ?? [])
        .map((e) => Homework.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Homework> create(
    int studentId, {
    required String title,
    String? description,
    DateTime? dueDate,
    bool isDone = false,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _base(studentId),
      data: Homework.writeJson(
        title: title,
        description: description,
        dueDate: dueDate,
        isDone: isDone,
      ),
    );
    return Homework.fromJson(res.data!);
  }

  Future<void> update(int studentId, Homework hw) async {
    await _dio.put(
      '${_base(studentId)}/${hw.id}',
      data: Homework.writeJson(
        title: hw.title,
        description: hw.description,
        dueDate: hw.dueDate,
        isDone: hw.isDone,
      ),
    );
  }

  Future<void> delete(int studentId, int id) async {
    await _dio.delete('${_base(studentId)}/$id');
  }
}

final homeworkRepositoryProvider = Provider<HomeworkRepository>(
  (ref) => HomeworkRepository(ref.watch(dioProvider)),
);
