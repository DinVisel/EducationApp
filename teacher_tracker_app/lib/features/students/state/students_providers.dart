import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/student.dart';
import '../../teacher/state/teacher_providers.dart';
import '../data/students_repository.dart';

/// The list of students for the current teacher, with mutation helpers that
/// refresh the list after each change.
class StudentsNotifier extends AsyncNotifier<List<Student>> {
  @override
  Future<List<Student>> build() async {
    // Rebuilds automatically if the current teacher changes.
    final teacher = await ref.watch(currentTeacherProvider.future);
    return ref.read(studentsRepositoryProvider).getForTeacher(teacher.id);
  }

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final teacher = await ref.read(currentTeacherProvider.future);
      return ref.read(studentsRepositoryProvider).getForTeacher(teacher.id);
    });
  }

  Future<Student> add({
    required String firstName,
    required String lastName,
    required String studentNumber,
  }) async {
    final teacher = await ref.read(currentTeacherProvider.future);
    final created = await ref.read(studentsRepositoryProvider).create(
          Student(
            id: 0,
            firstName: firstName,
            lastName: lastName,
            studentNumber: studentNumber,
            teacherId: teacher.id,
          ),
        );
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
