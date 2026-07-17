import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/student.dart';
import '../../auth/state/auth_controller.dart';
import '../data/students_repository.dart';

/// The authenticated teacher's students, with mutation helpers that refresh
/// the list after each change. Rebuilds when the session changes.
class StudentsNotifier extends AsyncNotifier<List<Student>> {
  static const _pageSize = 20;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<Student>> build() async {
    // Rebuild on login/logout; only load when signed in.
    final auth = ref.watch(authControllerProvider).value;
    if (auth == null) return [];
    final page = await ref.read(studentsRepositoryProvider).getAll(limit: _pageSize);
    _hasMore = page.length == _pageSize;
    return page;
  }

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final page = await ref.read(studentsRepositoryProvider).getAll(limit: _pageSize);
      _hasMore = page.length == _pageSize;
      return page;
    });
  }

  /// Appends the next page after the last-loaded student.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isEmpty || !_hasMore) return;

    final next = await ref
        .read(studentsRepositoryProvider)
        .getAll(beforeId: current.last.id, limit: _pageSize);
    _hasMore = next.length == _pageSize;
    state = AsyncData([...current, ...next]);
  }

  Future<Student> add(Student draft) async {
    // id/teacherId are assigned server-side; the draft carries the fields.
    final created = await ref.read(studentsRepositoryProvider).create(draft);
    await _reload();
    return created;
  }

  Future<void> edit(Student student) async {
    await ref.read(studentsRepositoryProvider).update(student);
    await _reload();
  }

  Future<void> remove(int id) async {
    await ref.read(studentsRepositoryProvider).delete(id);
    await _reload();
  }
}

final studentsProvider =
    AsyncNotifierProvider<StudentsNotifier, List<Student>>(
  StudentsNotifier.new,
);
