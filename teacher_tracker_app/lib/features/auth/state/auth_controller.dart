import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/token_store.dart';
import '../../../models/teacher.dart';
import '../data/auth_repository.dart';

/// Signed-in session: the current teacher + account role (token lives in
/// [TokenStore]). Only teachers can sign in today; student sessions arrive in a
/// later phase, at which point [teacher] may be absent for those accounts.
class AuthState {
  const AuthState({required this.teacher, this.role = 'Teacher'});
  final Teacher teacher;
  final String role;
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
      final teacher = await ref.read(authRepositoryProvider).me();
      return AuthState(teacher: teacher);
    } on DioException {
      await store.clear();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email.trim(), password: password);
    await ref.read(tokenStoreProvider).save(result.token);
    state = AsyncData(AuthState(teacher: result.teacher!, role: result.role));
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
    await ref.read(tokenStoreProvider).save(result.token);
    state = AsyncData(AuthState(teacher: result.teacher!, role: result.role));
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(null);
  }

  /// Updates the current teacher's profile and refreshes session state.
  Future<void> updateProfile(Teacher updated) async {
    final saved = await ref.read(authRepositoryProvider).updateProfile(updated);
    state = AsyncData(AuthState(teacher: saved));
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState?>(AuthController.new);

/// Convenience: the signed-in teacher, or null.
final currentTeacherProvider = Provider<Teacher?>((ref) {
  return ref.watch(authControllerProvider).value?.teacher;
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
