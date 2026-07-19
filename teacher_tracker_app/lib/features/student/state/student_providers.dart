import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/onboarding.dart';
import '../../../models/student_assignment.dart';
import '../../../models/student_quiz.dart';
import '../../auth/state/auth_controller.dart';
import '../data/student_module_repository.dart';

/// The signed-in student's assignments, with an optimistic mark-done helper that
/// refreshes the list afterwards. Empty unless a student is signed in.
class StudentAssignmentsNotifier
    extends AsyncNotifier<List<StudentAssignmentItem>> {
  @override
  Future<List<StudentAssignmentItem>> build() async {
    final auth = ref.watch(authControllerProvider).value;
    if (auth == null || !auth.isStudent) return [];
    return ref.read(studentModuleRepositoryProvider).getAssignments();
  }

  Future<void> setDone(int studentAssignmentId, bool done) async {
    await ref
        .read(studentModuleRepositoryProvider)
        .setDone(studentAssignmentId, done);
    state = await AsyncValue.guard(
      () => ref.read(studentModuleRepositoryProvider).getAssignments(),
    );
  }
}

final studentAssignmentsProvider = AsyncNotifierProvider<
    StudentAssignmentsNotifier, List<StudentAssignmentItem>>(
  StudentAssignmentsNotifier.new,
);

/// The signed-in student's enrolled classes.
final studentClassesProvider =
    FutureProvider<List<StudentClass>>((ref) async {
  final auth = ref.watch(authControllerProvider).value;
  if (auth == null || !auth.isStudent) return [];
  return ref.read(studentModuleRepositoryProvider).getClasses();
});

/// The signed-in student's class join requests (Method B lobby status).
final studentJoinRequestsProvider =
    FutureProvider<List<ClassJoinRequest>>((ref) async {
  final auth = ref.watch(authControllerProvider).value;
  if (auth == null || !auth.isStudent) return [];
  return ref.read(studentModuleRepositoryProvider).myRequests();
});

/// The signed-in student's quizzes (their attempts across all classes). Empty
/// unless a student is signed in.
final studentQuizzesProvider =
    FutureProvider<List<StudentQuizSummary>>((ref) async {
  final auth = ref.watch(authControllerProvider).value;
  if (auth == null || !auth.isStudent) return [];
  return ref.read(studentModuleRepositoryProvider).getQuizzes();
});
