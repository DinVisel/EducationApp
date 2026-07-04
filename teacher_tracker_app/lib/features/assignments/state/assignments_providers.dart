import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/assignment.dart';
import '../data/assignments_repository.dart';

/// Assignments published to a given classroom, keyed by classroom id.
final classroomAssignmentsProvider =
    FutureProvider.family<List<Assignment>, int>((ref, classroomId) {
  return ref.watch(assignmentsRepositoryProvider).getForClass(classroomId);
});

/// Create/delete helpers that refresh the per-class assignment list afterwards.
class AssignmentActions {
  AssignmentActions(this._ref);
  final Ref _ref;

  Future<Assignment> create(
    int classroomId, {
    required String title,
    String? description,
    DateTime? dueDate,
    List<int> fileIds = const [],
  }) async {
    final created = await _ref.read(assignmentsRepositoryProvider).create(
          classroomId,
          title: title,
          description: description,
          dueDate: dueDate,
          fileIds: fileIds,
        );
    _ref.invalidate(classroomAssignmentsProvider(classroomId));
    return created;
  }

  Future<void> delete(int classroomId, int id) async {
    await _ref.read(assignmentsRepositoryProvider).delete(classroomId, id);
    _ref.invalidate(classroomAssignmentsProvider(classroomId));
  }
}

final assignmentActionsProvider =
    Provider<AssignmentActions>((ref) => AssignmentActions(ref));
