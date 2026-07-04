import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/teacher.dart';

/// Token + role + teacher profile returned by register/login. `teacher` is null
/// for non-teacher accounts (student login lands in a later phase).
class AuthResult {
  const AuthResult({
    required this.token,
    required this.role,
    required this.teacher,
  });
  final String token;
  final String role;
  final Teacher? teacher;
}

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/auth/register', data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    });
    return _parse(res.data!);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _parse(res.data!);
  }

  Future<Teacher> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/auth/me');
    return Teacher.fromJson(res.data!);
  }

  Future<Teacher> updateProfile(Teacher teacher) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/auth/me',
      data: teacher.toWriteJson(),
    );
    return Teacher.fromJson(res.data!);
  }

  AuthResult _parse(Map<String, dynamic> json) {
    final teacher = json['teacher'];
    return AuthResult(
      token: json['token'] as String,
      role: json['role'] as String? ?? 'Teacher',
      teacher:
          teacher == null ? null : Teacher.fromJson(teacher as Map<String, dynamic>),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);
