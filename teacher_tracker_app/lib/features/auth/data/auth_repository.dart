import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/student_profile.dart';
import '../../../models/teacher.dart';

/// Token + role + the profile matching the role. Exactly one of [teacher] /
/// [student] is set depending on the account type.
class AuthResult {
  const AuthResult({
    required this.token,
    required this.role,
    required this.teacher,
    required this.student,
  });
  final String token;
  final String role;
  final Teacher? teacher;
  final StudentProfile? student;
}

/// The current identity restored from a saved token (no token echoed back).
class Session {
  const Session({required this.role, this.teacher, this.student});
  final String role;
  final Teacher? teacher;
  final StudentProfile? student;
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
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/auth/register', data: {
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
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _parse(res.data!);
  }

  /// Restores the current identity (any role) from the saved token.
  Future<Session> session() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/auth/session');
    final json = res.data!;
    final teacher = json['teacher'];
    final student = json['student'];
    return Session(
      role: json['role'] as String? ?? 'Teacher',
      teacher: teacher == null
          ? null
          : Teacher.fromJson(teacher as Map<String, dynamic>),
      student: student == null
          ? null
          : StudentProfile.fromJson(student as Map<String, dynamic>),
    );
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/api/v1/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post('/api/v1/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  Future<Teacher> updateProfile(Teacher teacher) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/auth/me',
      data: teacher.toWriteJson(),
    );
    return Teacher.fromJson(res.data!);
  }

  AuthResult _parse(Map<String, dynamic> json) {
    final teacher = json['teacher'];
    final student = json['student'];
    return AuthResult(
      token: json['token'] as String,
      role: json['role'] as String? ?? 'Teacher',
      teacher:
          teacher == null ? null : Teacher.fromJson(teacher as Map<String, dynamic>),
      student: student == null
          ? null
          : StudentProfile.fromJson(student as Map<String, dynamic>),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);
