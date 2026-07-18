import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/token_store.dart';
import '../../../models/student_profile.dart';
import '../../../models/teacher.dart';
import '../data/auth_repository.dart';

/// Signed-in session: the account role plus the matching profile (token lives in
/// [TokenStore]). Teachers carry [teacher]; students carry [student]. Exactly
/// one is set for a valid session.
class AuthState {
  const AuthState({required this.role, this.teacher, this.student});
  final String role;
  final Teacher? teacher;
  final StudentProfile? student;

  bool get isTeacher => role == 'Teacher';
  bool get isStudent => role == 'Student';
  bool get isAdmin => role == 'Admin';
}

/// Owns authentication. `null` data = signed out.
///
/// On startup it restores a saved token and fetches the profile; an expired
/// or invalid token is cleared and treated as signed out.
class AuthController extends AsyncNotifier<AuthState?> {
  @override
  Future<AuthState?> build() async {
    final store = ref.watch(tokenStoreProvider);
    final token = await store.load();
    if (token == null) return null;

    try {
      final session = await ref.read(authRepositoryProvider).session();
      return AuthState(
        role: session.role,
        teacher: session.teacher,
        student: session.student,
      );
    } on DioException {
      await store.clear();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email.trim(), password: password);
    await ref.read(tokenStoreProvider).saveTokens(result.token, result.refreshToken);
    state = AsyncData(AuthState(
      role: result.role,
      teacher: result.teacher,
      student: result.student,
    ));
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final result = await ref.read(authRepositoryProvider).register(
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          email: email.trim(),
          password: password,
        );
    await ref.read(tokenStoreProvider).saveTokens(result.token, result.refreshToken);
    state = AsyncData(AuthState(
      role: result.role,
      teacher: result.teacher,
      student: result.student,
    ));
  }

  Future<void> logout() async {
    final store = ref.read(tokenStoreProvider);
    // Best-effort server-side revocation; never block sign-out on it.
    final refresh = store.currentRefresh;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await ref.read(authRepositoryProvider).logout(refresh);
      } on DioException {
        // Offline or already-invalid token — clearing locally is enough.
      }
    }
    await store.clear();
    state = const AsyncData(null);
  }

  /// Updates the current teacher's profile and refreshes session state.
  Future<void> updateProfile(Teacher updated) async {
    final saved = await ref.read(authRepositoryProvider).updateProfile(updated);
    state = AsyncData(AuthState(role: 'Teacher', teacher: saved));
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState?>(AuthController.new);

/// Convenience: the signed-in teacher, or null.
final currentTeacherProvider = Provider<Teacher?>((ref) {
  return ref.watch(authControllerProvider).value?.teacher;
});

/// Convenience: the signed-in student profile, or null.
final currentStudentProvider = Provider<StudentProfile?>((ref) {
  return ref.watch(authControllerProvider).value?.student;
});

/// Convenience: the signed-in account's role (e.g. `Teacher`), or null when
/// signed out. Used to guard role-specific routes and UI.
final currentRoleProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).value?.role;
});

/// Whether the signed-in account is a teacher. Teacher-only routes/features can
/// gate on this; other roles get their own experience in later phases.
final isTeacherProvider = Provider<bool>((ref) {
  return ref.watch(currentRoleProvider) == 'Teacher';
});
