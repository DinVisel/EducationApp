import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/classroom.dart';
import '../../../models/onboarding.dart';

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

  // ── Method A: Access Cards ────────────────────────────────────────────────

  /// Bulk-provisions access-card students from a list of names. The returned
  /// cards carry their raw QR tokens (shown once) for printing.
  Future<List<AccessCard>> createAccessCards(
      int classroomId, List<String> names) async {
    final res = await _dio.post<List<dynamic>>(
      '/api/v1/classrooms/$classroomId/access-cards',
      data: {'names': names},
    );
    return (res.data ?? [])
        .map((e) => AccessCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists a class's access cards (typed codes only; no QR secret) for reprint.
  Future<List<AccessCard>> getAccessCards(int classroomId) async {
    final res =
        await _dio.get<List<dynamic>>('/api/v1/classrooms/$classroomId/access-cards');
    return (res.data ?? [])
        .map((e) => AccessCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Rotates one student's access code + QR (e.g. a lost card). Returns the new
  /// card with its raw QR token.
  Future<AccessCard> rotateAccessCard(int classroomId, int studentId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/classrooms/$classroomId/access-cards/$studentId/rotate',
    );
    return AccessCard.fromJson(res.data!);
  }

  // ── Method B: Waiting Lobby (teacher side) ────────────────────────────────

  Future<List<LobbyEntry>> getJoinRequests(int classroomId) async {
    final res = await _dio
        .get<List<dynamic>>('/api/v1/classrooms/$classroomId/join-requests');
    return (res.data ?? [])
        .map((e) => LobbyEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveJoinRequest(int classroomId, int requestId) =>
      _dio.post<void>(
          '/api/v1/classrooms/$classroomId/join-requests/$requestId/approve');

  Future<void> rejectJoinRequest(int classroomId, int requestId) =>
      _dio.post<void>(
          '/api/v1/classrooms/$classroomId/join-requests/$requestId/reject');
}

final classroomsRepositoryProvider = Provider<ClassroomsRepository>(
  (ref) => ClassroomsRepository(ref.watch(dioProvider)),
);
