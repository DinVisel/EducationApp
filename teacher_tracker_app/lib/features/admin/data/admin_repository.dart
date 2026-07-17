import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/admin_report.dart';
import '../../../models/admin_user.dart';

/// Admin-only moderation + account tooling. All endpoints require an Admin token.
class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  Future<List<AdminReport>> getReports({bool resolved = false}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/admin/reports',
      queryParameters: {'resolved': resolved},
    );
    return (res.data ?? [])
        .map((e) => AdminReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> dismiss(int reportId) =>
      _dio.post<void>('/api/v1/admin/reports/$reportId/dismiss');

  Future<void> removeContent(int reportId) =>
      _dio.post<void>('/api/v1/admin/reports/$reportId/remove');

  Future<List<AdminUser>> getUsers() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/admin/users');
    return (res.data ?? [])
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(dioProvider)),
);
