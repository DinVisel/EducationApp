import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/classroom.dart';
import '../../../models/student.dart';
import '../../assignments/screens/class_assignments_screen.dart';
import '../../students/state/students_providers.dart';
import '../state/classrooms_providers.dart';

/// A class's roster: view enrolled students, add more, or remove them.
class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({super.key, required this.classroom});

  final Classroom classroom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(classroomDetailProvider(classroom.id));

    return GlassScaffold(
      appBar: AppBar(
        title: Text(classroom.name),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Assignments',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ClassAssignmentsScreen(classroom: classroom),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addStudents(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Students'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          if (detail.students.isEmpty) {
            return const _EmptyRoster();
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(classroomDetailProvider(classroom.id).future),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: detail.students.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final s = detail.students[i];
                return _RosterTile(
                  student: s,
                  onRemove: () => _removeStudent(ctx, ref, s),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeStudent(
      BuildContext ctx, WidgetRef ref, Student s) async {
    try {
      await ref
          .read(classroomsProvider.notifier)
          .unenroll(classroom.id, s.id);
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Could not remove: $e')));
      }
    }
  }

  Future<void> _addStudents(BuildContext context, WidgetRef ref) async {
    final detail = ref.read(classroomDetailProvider(classroom.id)).value;
    final enrolledIds = {for (final s in detail?.students ?? <Student>[]) s.id};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddStudentsSheet(
        classroomId: classroom.id,
        enrolledIds: enrolledIds,
      ),
    );
  }
}

class _RosterTile extends StatelessWidget {
  const _RosterTile({required this.student, required this.onRemove});
  final Student student;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
            child: Text(_initials(student),
                style: tt.labelLarge?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName,
                    style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (student.studentNumber.isNotEmpty)
                  Text('No. ${student.studentNumber}',
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: cs.error),
            tooltip: 'Remove from class',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  String _initials(Student s) {
    final f = s.firstName.isNotEmpty ? s.firstName[0] : '';
    final l = s.lastName.isNotEmpty ? s.lastName[0] : '';
    final res = '$f$l'.toUpperCase();
    return res.isEmpty ? '?' : res;
  }
}

/// Bottom sheet listing the teacher's students who aren't in the class yet.
class _AddStudentsSheet extends ConsumerWidget {
  const _AddStudentsSheet({
    required this.classroomId,
    required this.enrolledIds,
  });

  final int classroomId;
  final Set<int> enrolledIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: studentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e'),
          ),
          data: (students) {
            final available =
                students.where((s) => !enrolledIds.contains(s.id)).toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text('Add students', style: tt.titleLarge),
                ),
                if (available.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Text('All your students are already in this class.'),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: available.length,
                      itemBuilder: (ctx, i) {
                        final s = available[i];
                        return ListTile(
                          leading: CircleAvatar(child: Text(_initials(s))),
                          title: Text(s.fullName),
                          subtitle: s.studentNumber.isEmpty
                              ? null
                              : Text('No. ${s.studentNumber}'),
                          trailing: const Icon(Icons.add),
                          onTap: () => _enroll(ctx, ref, s),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _enroll(BuildContext ctx, WidgetRef ref, Student s) async {
    try {
      await ref.read(classroomsProvider.notifier).enroll(classroomId, s.id);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Added ${s.fullName}')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Could not add: $e')));
      }
    }
  }

  String _initials(Student s) {
    final f = s.firstName.isNotEmpty ? s.firstName[0] : '';
    final l = s.lastName.isNotEmpty ? s.lastName[0] : '';
    final res = '$f$l'.toUpperCase();
    return res.isEmpty ? '?' : res;
  }
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.groups_outlined,
            size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Center(
          child: Text('No students in this class yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('Tap “Add Students” to build the roster.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }
}
