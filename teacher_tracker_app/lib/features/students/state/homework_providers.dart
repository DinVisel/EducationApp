import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/homework.dart';
import '../data/homework_repository.dart';

/// Homework for one student, keyed by studentId.
class HomeworkNotifier extends AsyncNotifier<List<Homework>> {
  HomeworkNotifier(this.studentId);

  final int studentId;

  @override
  Future<List<Homework>> build() =>
      ref.read(homeworkRepositoryProvider).getForStudent(studentId);

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(homeworkRepositoryProvider).getForStudent(studentId),
    );
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
