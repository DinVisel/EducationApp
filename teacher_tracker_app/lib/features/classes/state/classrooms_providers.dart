import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/classroom.dart';
import '../../auth/state/auth_controller.dart';
import '../data/classrooms_repository.dart';

/// The authenticated teacher's classrooms, with mutation helpers that refresh
/// the list (and any open roster) after each change.
class ClassroomsNotifier extends AsyncNotifier<List<Classroom>> {
  static const _pageSize = 20;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<Classroom>> build() async {
    // Rebuild on login/logout; only load when signed in.
    final auth = ref.watch(authControllerProvider).value;
    if (auth == null) return [];
    final page = await ref.read(classroomsRepositoryProvider).getAll(limit: _pageSize);
    _hasMore = page.length == _pageSize;
    return page;
  }

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final page = await ref.read(classroomsRepositoryProvider).getAll(limit: _pageSize);
      _hasMore = page.length == _pageSize;
      return page;
    });
  }

  /// Appends the next page after the last-loaded classroom.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isEmpty || !_hasMore) return;

    final next = await ref
        .read(classroomsRepositoryProvider)
        .getAll(beforeId: current.last.id, limit: _pageSize);
    _hasMore = next.length == _pageSize;
    state = AsyncData([...current, ...next]);
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
