import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/app_notification.dart';

/// The signed-in user's in-app notifications. Everything is scoped to the token
/// server-side.
class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  /// Newest first. Pass [beforeId] (the last-loaded notification's id) to
  /// fetch the next page.
  Future<List<AppNotification>> getAll({int? beforeId, int limit = 20}) async {
    final res = await _dio.get<List<dynamic>>('/api/notifications', queryParameters: {
      if (beforeId != null) 'beforeId': beforeId,
      'limit': limit,
    });
    return (res.data ?? [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final res =
        await _dio.get<Map<String, dynamic>>('/api/notifications/unread-count');
    return (res.data?['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int id) =>
      _dio.post<void>('/api/notifications/$id/read');

  Future<void> markAllRead() =>
      _dio.post<void>('/api/notifications/read-all');
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(dioProvider)),
);
