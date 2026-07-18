import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/assignment.dart';
import '../../../models/classroom.dart';
import '../../files/widgets/attachment_tile.dart';
import '../state/assignments_providers.dart';
import 'new_assignment_screen.dart';

/// Assignments published to one class, with fan-out progress and attachments.
class ClassAssignmentsScreen extends ConsumerWidget {
  const ClassAssignmentsScreen({super.key, required this.classroom});

  final Classroom classroom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync =
        ref.watch(classroomAssignmentsProvider(classroom.id));
    final loc = AppLocalizations.of(context)!;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(loc.assignmentsTitle(classroom.name)),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newAssignment(context),
        icon: const Icon(Icons.post_add),
        label: Text(loc.hwTrackerNewAssignment),
      ),
      body: assignmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(loc.commonError('$e'))),
        data: (assignments) {
          if (assignments.isEmpty) return const _Empty();
          return RefreshIndicator(
            onRefresh: () => ref
                .refresh(classroomAssignmentsProvider(classroom.id).future),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: assignments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _AssignmentCard(
                assignment: assignments[i],
                onDelete: () => _delete(ctx, ref, assignments[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _newAssignment(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewAssignmentScreen(classroom: classroom),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, WidgetRef ref, Assignment a) async {
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
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(a.title,
                    style: tt.titleMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700)),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: Icons.people_alt_outlined,
                label: loc.assignmentsDone(a.completedCount, a.studentCount),
                cs: cs,
                tt: tt,
              ),
              if (a.dueDate != null)
                _Chip(
                  icon: Icons.event_outlined,
                  label: loc.hwTrackerDue(_fmtDate(a.dueDate!)),
                  cs: cs,
                  tt: tt,
                ),
              if (a.attachments.isNotEmpty)
                _Chip(
                  icon: Icons.attach_file,
                  label: loc.assignmentsFiles(a.attachments.length),
                  cs: cs,
                  tt: tt,
                ),
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
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
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
              style: tt.labelSmall?.copyWith(
                  color: cs.onSurface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.assignment_outlined,
            size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Center(
          child: Text(loc.assignmentsEmptyTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(loc.assignmentsEmptySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }
}
