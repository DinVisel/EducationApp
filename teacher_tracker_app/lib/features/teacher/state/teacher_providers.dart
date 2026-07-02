import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/teacher.dart';
import '../data/teacher_repository.dart';

/// Resolves the "current" teacher for the app.
///
/// Auth is not built yet, so we pick the first teacher returned by the API and
/// create a default one if the database is empty. When real login lands, this
/// is the single place that changes — everything else reads from here.
class CurrentTeacher extends AsyncNotifier<Teacher> {
  @override
  Future<Teacher> build() => _resolve();

  Future<Teacher> _resolve() async {
    final repo = ref.read(teacherRepositoryProvider);
    final teachers = await repo.getAll();
    if (teachers.isNotEmpty) return teachers.first;

    // No teacher yet — seed a placeholder so the rest of the app works.
    return repo.create(
      const Teacher(
        id: 0,
        firstName: 'Demo',
        lastName: 'Teacher',
        email: 'demo.teacher@example.com',
      ),
    );
  }

  Future<void> save(Teacher updated) async {
    final repo = ref.read(teacherRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.update(updated);
      return updated;
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_resolve);
  }
}

final currentTeacherProvider =
    AsyncNotifierProvider<CurrentTeacher, Teacher>(CurrentTeacher.new);
