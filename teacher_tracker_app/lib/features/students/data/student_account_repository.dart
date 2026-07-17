import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// Whether a student has a login account, and under which email.
class StudentAccount {
  const StudentAccount({required this.hasAccount, this.email});
  final bool hasAccount;
  final String? email;

  factory StudentAccount.fromJson(Map<String, dynamic> json) => StudentAccount(
        hasAccount: json['hasAccount'] as bool? ?? false,
        email: json['email'] as String?,
      );
}

/// Teacher-side management of a student's login account (credential flow).
class StudentAccountRepository {
  StudentAccountRepository(this._dio);

  final Dio _dio;

  Future<StudentAccount> get(int studentId) async {
    final res = await _dio
        .get<Map<String, dynamic>>('/api/v1/students/$studentId/account');
    return StudentAccount.fromJson(res.data!);
  }

  Future<StudentAccount> create(
    int studentId, {
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/students/$studentId/account',
      data: {'email': email, 'password': password},
    );
    return StudentAccount.fromJson(res.data!);
  }

  Future<void> delete(int studentId) =>
      _dio.delete<void>('/api/v1/students/$studentId/account');
}

final studentAccountRepositoryProvider = Provider<StudentAccountRepository>(
  (ref) => StudentAccountRepository(ref.watch(dioProvider)),
);

/// A student's account status, keyed by student id.
final studentAccountProvider =
    FutureProvider.family<StudentAccount, int>((ref, studentId) {
  return ref.watch(studentAccountRepositoryProvider).get(studentId);
});
