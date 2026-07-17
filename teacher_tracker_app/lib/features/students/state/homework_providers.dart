import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/homework.dart';
import '../data/homework_repository.dart';

/// Homework for one student, keyed by studentId.
class HomeworkNotifier extends AsyncNotifier<List<Homework>> {
  HomeworkNotifier(this.studentId);

  static const _pageSize = 20;

  final int studentId;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<Homework>> build() async {
    final page = await ref
        .read(homeworkRepositoryProvider)
        .getForStudent(studentId, limit: _pageSize);
    _hasMore = page.length == _pageSize;
    return page;
  }

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(homeworkRepositoryProvider)
          .getForStudent(studentId, limit: _pageSize);
      _hasMore = page.length == _pageSize;
      return page;
    });
  }

  /// Appends the next page after the last-loaded homework item.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isEmpty || !_hasMore) return;

    final next = await ref.read(homeworkRepositoryProvider).getForStudent(
          studentId,
          beforeId: current.last.id,
          limit: _pageSize,
        );
    _hasMore = next.length == _pageSize;
    state = AsyncData([...current, ...next]);
  }

  Future<void> add({
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    await ref.read(homeworkRepositoryProvider).create(
          studentId,
          title: title,
          description: description,
          dueDate: dueDate,
        );
    await _reload();
  }

  Future<void> toggleDone(Homework hw, bool isDone) async {
    await ref.read(homeworkRepositoryProvider).update(
          studentId,
          Homework(
            id: hw.id,
            title: hw.title,
            description: hw.description,
            dueDate: hw.dueDate,
            isDone: isDone,
            createdAt: hw.createdAt,
            studentId: hw.studentId,
          ),
        );
    await _reload();
  }

  Future<void> remove(int id) async {
    await ref.read(homeworkRepositoryProvider).delete(studentId, id);
    await _reload();
  }
}

final homeworkProvider =
    AsyncNotifierProvider.family<HomeworkNotifier, List<Homework>, int>(
  HomeworkNotifier.new,
);
