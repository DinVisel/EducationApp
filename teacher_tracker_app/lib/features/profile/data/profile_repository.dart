import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/teacher.dart';

/// Reads other teachers' public profiles (name, avatar, cover) so the feed's
/// author can be opened as a profile.
class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<Teacher> getTeacher(int userId) async {
    final res =
        await _dio.get<Map<String, dynamic>>('/api/teachers/$userId/profile');
    return Teacher.fromJson(res.data!);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);

/// A teacher's public profile, keyed by account (User) id.
final teacherProfileProvider = FutureProvider.family<Teacher, int>(
  (ref, userId) => ref.watch(profileRepositoryProvider).getTeacher(userId),
);
