import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/assignment.dart';
import '../../../../models/classroom.dart';
import '../../../../models/homework.dart';
import '../../../../models/student.dart';
import '../../../assignments/screens/new_assignment_screen.dart';
import '../../../assignments/state/assignments_providers.dart';
import '../../../files/widgets/attachment_tile.dart';
import '../../../students/state/homework_providers.dart';
import '../../state/classrooms_providers.dart';

/// Homework overview for one class: the class's published Assignments (fan-out)
/// plus each roster student's individual homework.
class ClassHomeworkTab extends ConsumerWidget {
  const ClassHomeworkTab({super.key, required this.classroom});

  final Classroom classroom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final assignmentsAsync = ref.watch(classroomAssignmentsProvider(classroom.id));
    final detailAsync = ref.watch(classroomDetailProvider(classroom.id));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(classroomAssignmentsProvider(classroom.id));
        ref.invalidate(classroomDetailProvider(classroom.id));
        await ref.read(classroomDetailProvider(classroom.id).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Class assignments ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(loc.classHwAssignments,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewAssignmentScreen(classroom: classroom),
                  ),
                ),
                icon: const Icon(Icons.post_add, size: 18),
                label: Text(loc.commonNew),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          assignmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(loc.commonError('$e')),
            data: (assignments) {
              if (assignments.isEmpty) {
                return _Hint(text: loc.classHwNoAssignments);
              }
              return Column(
                children: [
                  for (final a in assignments)
                    _AssignmentCard(
                      assignment: a,
                      onDelete: () => _deleteAssignment(context, ref, a),
                    ),
                ],
              );
            },
          ),

          // ── Per-student homework ───────────────────────────────────────
          const SizedBox(height: 24),
          Text(loc.classHwStudentHomework,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(loc.classHwStudentHomeworkHint,
              style: tt.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          detailAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text(loc.commonError('$e')),
            data: (detail) {
              if (detail.students.isEmpty) {
                return _Hint(text: loc.attendanceEmptyRoster);
              }
              return Column(
                children: [
                  for (final s in detail.students) _StudentHomework(student: s),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAssignment(
      BuildContext ctx, WidgetRef ref, Assignment a) async {
    final messenger = ScaffoldMessenger.of(ctx);
    final loc = AppLocalizations.of(ctx)!;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(loc.assignmentsDeleteTitle),
        content: Text(loc.assignmentsDeleteBody(a.title, a.studentCount)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(loc.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(loc.commonDelete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(assignmentActionsProvider).delete(classroom.id, a.id);
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.commonCouldNotDelete('$e'))));
    }
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment, required this.onDelete});
  final Assignment assignment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final a = assignment;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(a.title,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: loc.commonDelete,
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
              ],
            ),
            if (a.description != null && a.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(a.description!,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniChip(
                    icon: Icons.people_alt_outlined,
                    label:
                        loc.assignmentsDone(a.completedCount, a.studentCount)),
                if (a.dueDate != null)
                  _MiniChip(
                      icon: Icons.event_outlined,
                      label: loc.hwTrackerDue(_fmtDate(a.dueDate!))),
              ],
            ),
            if (a.attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final f in a.attachments)
                AttachmentTile(
                  fileId: f.fileId,
                  fileName: f.fileName,
                  contentType: f.contentType,
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _StudentHomework extends ConsumerWidget {
  const _StudentHomework({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hwAsync = ref.watch(homeworkProvider(student.id));

    return hwAsync.maybeWhen(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: cs.primaryContainer.withValues(alpha: 0.4),
                      child: Text(
                        student.firstName.isNotEmpty
                            ? student.firstName[0].toUpperCase()
                            : '?',
                        style: tt.labelSmall?.copyWith(color: cs.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(student.fullName,
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              for (final hw in items)
                _HomeworkRow(
                  hw: hw,
                  onToggle: (v) =>
                      ref.read(homeworkProvider(student.id).notifier).toggleDone(hw, v),
                  onDelete: () =>
                      ref.read(homeworkProvider(student.id).notifier).remove(hw.id),
                ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _HomeworkRow extends StatelessWidget {
  const _HomeworkRow({
    required this.hw,
    required this.onToggle,
    required this.onDelete,
  });
  final Homework hw;
  final void Function(bool) onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final done = hw.isDone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? cs.primary : cs.onSurfaceVariant,
              ),
              tooltip: done ? loc.hwTrackerMarkUndone : loc.hwTrackerMarkDone,
              onPressed: () => onToggle(!done),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hw.title,
                      style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration:
                              done ? TextDecoration.lineThrough : null)),
                  if (hw.dueDate != null)
                    Text(loc.hwTrackerDue(formatDateOnly(hw.dueDate!)),
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
              tooltip: loc.commonRemove,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 6),
          Text(label,
              style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant)),
    );
  }
}
