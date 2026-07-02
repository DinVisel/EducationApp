import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/teacher.dart';

/// Token + teacher returned by register/login.
class AuthResult {
  const AuthResult({required this.token, required this.teacher});
  final String token;
  final Teacher teacher;
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

  AuthResult _parse(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        teacher: Teacher.fromJson(json['teacher'] as Map<String, dynamic>),
      );
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);
