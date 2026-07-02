import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/token_store.dart';
import '../../../models/teacher.dart';
import '../data/auth_repository.dart';

/// Signed-in session: the current teacher (token lives in [TokenStore]).
class AuthState {
  const AuthState({required this.teacher});
  final Teacher teacher;
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
    state = AsyncData(AuthState(teacher: result.teacher));
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
    state = AsyncData(AuthState(teacher: result.teacher));
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
