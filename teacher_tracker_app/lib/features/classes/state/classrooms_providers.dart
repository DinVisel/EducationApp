import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/classroom.dart';
import '../../auth/state/auth_controller.dart';
import '../data/classrooms_repository.dart';

/// The authenticated teacher's classrooms, with mutation helpers that refresh
/// the list (and any open roster) after each change.
class ClassroomsNotifier extends AsyncNotifier<List<Classroom>> {
  @override
  Future<List<Classroom>> build() async {
    // Rebuild on login/logout; only load when signed in.
    final auth = ref.watch(authControllerProvider).value;
    if (auth == null) return [];
    return ref.read(classroomsRepositoryProvider).getAll();
  }

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(classroomsRepositoryProvider).getAll(),
    );
  }

  Future<Classroom> add(String name) async {
    final created = await ref.read(classroomsRepositoryProvider).create(name);
    await _reload();
    return created;
  }

  Future<void> rename(int id, String name) async {
    await ref.read(classroomsRepositoryProvider).rename(id, name);
    ref.invalidate(classroomDetailProvider(id));
    await _reload();
  }

  Future<void> remove(int id) async {
    await ref.read(classroomsRepositoryProvider).delete(id);
    await _reload();
  }

  Future<void> enroll(int classroomId, int studentId) async {
    await ref.read(classroomsRepositoryProvider).enroll(classroomId, studentId);
    ref.invalidate(classroomDetailProvider(classroomId));
    await _reload();
  }

  Future<void> unenroll(int classroomId, int studentId) async {
    await ref.read(classroomsRepositoryProvider).unenroll(classroomId, studentId);
    ref.invalidate(classroomDetailProvider(classroomId));
    await _reload();
  }
}

final classroomsProvider =
    AsyncNotifierProvider<ClassroomsNotifier, List<Classroom>>(
  ClassroomsNotifier.new,
);

/// A single classroom's roster, keyed by classroom id.
final classroomDetailProvider =
    FutureProvider.family<ClassroomDetail, int>((ref, id) {
  return ref.watch(classroomsRepositoryProvider).getById(id);
});
