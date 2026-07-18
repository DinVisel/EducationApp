import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/attendance.dart';

/// Attendance for a teacher's class. All endpoints are nested under the
/// classroom and scoped to the teacher server-side.
class AttendanceRepository {
  AttendanceRepository(this._dio);

  final Dio _dio;

  /// `yyyy-MM-dd`, matching the backend `DateOnly` wire format.
  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<AttendanceDay> getDay(int classroomId, DateTime date) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/classrooms/$classroomId/attendance',
      queryParameters: {'date': formatDate(date)},
    );
    return AttendanceDay.fromJson(res.data!);
  }

  /// Bulk-marks the class for a day. Each entry is (studentId, status, note?).
  Future<void> mark(
    int classroomId,
    DateTime date,
    List<AttendanceStudent> entries,
  ) {
    return _dio.put<void>(
      '/api/v1/classrooms/$classroomId/attendance',
      data: {
        'date': formatDate(date),
        'entries': [
          for (final e in entries)
            if (e.status != null)
              {
                'studentId': e.studentId,
                'status': e.status!.apiValue,
                'note': e.note,
              },
        ],
      },
    );
  }

  Future<List<AttendanceHistory>> history(
    int classroomId,
    int studentId, {
    int? beforeId,
    int limit = 30,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/classrooms/$classroomId/attendance/students/$studentId/history',
      queryParameters: {
        if (beforeId != null) 'beforeId': beforeId,
        'limit': limit,
      },
    );
    return (res.data ?? [])
        .map((e) => AttendanceHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(dioProvider)),
);
