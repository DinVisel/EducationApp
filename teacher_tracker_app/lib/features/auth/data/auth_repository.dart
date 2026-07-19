import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config.dart';
import '../../../models/student_profile.dart';
import '../../../models/teacher.dart';

/// Thrown when a social provider completed but didn't hand back the ID token we
/// need to send to the backend (distinct from a user cancelling the sheet).
class SocialSignInException implements Exception {
  const SocialSignInException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when a social sign-in is for a brand-new account and the backend needs
/// the user to pick a role first. Carries the verified provider payload so the
/// caller can re-submit it (via [AuthRepository.completeSocialSignup]) once the
/// user chooses — without re-running the native provider flow.
class RoleSelectionRequired implements Exception {
  const RoleSelectionRequired(this.path, this.payload);
  final String path;
  final Map<String, dynamic> payload;
}

// google_sign_in requires a one-time initialize() per process; guard it.
bool _googleInitialized = false;

/// Access token + rotating refresh token + role + the profile matching the
/// role. Exactly one of [teacher] / [student] is set depending on the account
/// type.
class AuthResult {
  const AuthResult({
    required this.token,
    required this.refreshToken,
    required this.role,
    required this.teacher,
    required this.student,
    this.mustChangePassword = false,
  });
  final String token;
  final String refreshToken;
  final String role;
  final Teacher? teacher;
  final StudentProfile? student;

  /// True when the account must set a new password before continuing (e.g. a
  /// teacher-provisioned student on first sign-in).
  final bool mustChangePassword;
}

/// The current identity restored from a saved token (no token echoed back).
class Session {
  const Session({
    required this.role,
    this.teacher,
    this.student,
    this.mustChangePassword = false,
  });
  final String role;
  final Teacher? teacher;
  final StudentProfile? student;
  final bool mustChangePassword;
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

  /// Signs in with Google: runs the native flow to get an ID token, then trades
  /// it with the backend for our own token pair (creating/linking the account
  /// server-side). Throws [GoogleSignInException] (e.g. on cancel),
  /// [SocialSignInException], or [RoleSelectionRequired] when a new account must
  /// pick a role first.
  Future<AuthResult> signInWithGoogle() async {
    final signIn = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await signIn.initialize(
        clientId: googleIosClientId.isEmpty ? null : googleIosClientId,
        serverClientId:
            googleServerClientId.isEmpty ? null : googleServerClientId,
      );
      _googleInitialized = true;
    }

    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const SocialSignInException(
          'Google did not return an identity token.');
    }

    return _exchangeSocial('/api/v1/auth/google', {'idToken': idToken});
  }

  /// Signs in with Apple: runs the native flow (with a one-time nonce the server
  /// checks against the token) and forwards the ID token — plus the name, which
  /// Apple only returns on the first authorization — to the backend. Throws
  /// [SignInWithAppleAuthorizationException] (e.g. on cancel),
  /// [SocialSignInException], or [RoleSelectionRequired].
  Future<AuthResult> signInWithApple() async {
    final nonce = _randomNonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      // Apple echoes this verbatim into the token's `nonce` claim; the backend
      // compares it to bind the token to this attempt.
      nonce: nonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const SocialSignInException(
          'Apple did not return an identity token.');
    }

    return _exchangeSocial('/api/v1/auth/apple', {
      'idToken': idToken,
      'nonce': nonce,
      'firstName': credential.givenName,
      'lastName': credential.familyName,
    });
  }

  /// Retries a social sign-in once the user has picked a role, re-sending the
  /// same verified payload (no native re-prompt) with the chosen role.
  Future<AuthResult> completeSocialSignup(
      RoleSelectionRequired pending, String role) {
    return _exchangeSocial(pending.path, {...pending.payload, 'role': role});
  }

  // Posts a verified social payload to [path]; on the backend's 422
  // `role_required` signal, surfaces [RoleSelectionRequired] carrying the payload
  // so the caller can prompt and retry.
  Future<AuthResult> _exchangeSocial(
      String path, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: payload);
      return _parse(res.data!);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 422 &&
          data is Map &&
          data['code'] == 'role_required') {
        throw RoleSelectionRequired(path, payload);
      }
      rethrow;
    }
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
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    );
  }

  /// Exchanges a refresh token for a fresh access + refresh token pair. The
  /// server rotates the refresh token, so callers must persist the new one.
  Future<AuthResult> refresh(String refreshToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return _parse(res.data!);
  }

  /// Revokes a refresh token server-side (best-effort on sign-out).
  Future<void> logout(String refreshToken) async {
    await _dio.post('/api/v1/auth/logout', data: {'refreshToken': refreshToken});
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

  /// Changes the signed-in account's password (any role) by proving the current
  /// one. Clears the server's first-login gate and returns a fresh token pair
  /// (the server ends other sessions), which the caller must persist.
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return _parse(res.data!);
  }

  Future<Teacher> updateProfile(Teacher teacher) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/auth/me',
      data: teacher.toWriteJson(),
    );
    return Teacher.fromJson(res.data!);
  }

  // A random, single-use nonce for the Apple sign-in flow.
  static String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  AuthResult _parse(Map<String, dynamic> json) {
    final teacher = json['teacher'];
    final student = json['student'];
    return AuthResult(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      role: json['role'] as String? ?? 'Teacher',
      teacher:
          teacher == null ? null : Teacher.fromJson(teacher as Map<String, dynamic>),
      student: student == null
          ? null
          : StudentProfile.fromJson(student as Map<String, dynamic>),
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);
