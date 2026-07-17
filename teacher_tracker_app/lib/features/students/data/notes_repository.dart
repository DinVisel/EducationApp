import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/tracking_note.dart';

class NotesRepository {
  NotesRepository(this._dio);

  final Dio _dio;

  String _base(int studentId) => '/api/v1/students/$studentId/notes';

  Future<List<TrackingNote>> getForStudent(int studentId) async {
    final res = await _dio.get<List<dynamic>>(_base(studentId));
    return (res.data ?? [])
        .map((e) => TrackingNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TrackingNote> create(
    int studentId, {
    required String category,
    required String content,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _base(studentId),
      data: TrackingNote.writeJson(category: category, content: content),
    );
    return TrackingNote.fromJson(res.data!);
  }

  Future<void> update(
    int studentId,
    int id, {
    required String category,
    required String content,
  }) async {
    await _dio.put(
      '${_base(studentId)}/$id',
      data: TrackingNote.writeJson(category: category, content: content),
    );
  }

  Future<void> delete(int studentId, int id) async {
    await _dio.delete('${_base(studentId)}/$id');
  }
}

final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => NotesRepository(ref.watch(dioProvider)),
);
