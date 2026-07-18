import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/student_assignment.dart';
import '../../files/widgets/attachment_tile.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../state/student_providers.dart';

/// The student's assignments across all their classes: due-first, with the
/// teacher's attachments and a "mark done" toggle (their submission).
class StudentAssignmentsScreen extends ConsumerWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentAssignmentsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentAssignmentsProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(child: Text(loc.commonError('$e'))),
          ]),
          data: (items) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, MediaQuery.of(context).padding.top + 24, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(loc.stuMyAssignments,
                            style: tt.headlineMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700)),
                      ),
                      const NotificationBell(),
                    ],
                  ),
                ),
              ),
              if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Empty(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _AssignmentCard(item: items[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  const _AssignmentCard({required this.item});
  final StudentAssignmentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final overdue = item.dueDate != null &&
        !item.isDone &&
        item.dueDate!.isBefore(DateTime.now());

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: tt.titleMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                            decoration: item.isDone
                                ? TextDecoration.lineThrough
                                : null)),
                    Text(item.className,
                        style:
                            tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              _DoneToggle(item: item),
            ],
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.description!,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.dueDate != null)
                _Chip(
                  icon: Icons.event_outlined,
                  label: loc.hwTrackerDue(_fmtDate(item.dueDate!)),
                  color: overdue ? cs.error : cs.primary,
                  cs: cs,
                  tt: tt,
                ),
              if (item.isDone)
                _Chip(
                  icon: Icons.check_circle,
                  label: loc.commonDone,
                  color: Colors.green,
                  cs: cs,
                  tt: tt,
                ),
            ],
          ),
          for (final f in item.attachments)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AttachmentTile(
                fileId: f.fileId,
                fileName: f.fileName,
                contentType: f.contentType,
              ),
            ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _DoneToggle extends ConsumerStatefulWidget {
  const _DoneToggle({required this.item});
  final StudentAssignmentItem item;

  @override
  ConsumerState<_DoneToggle> createState() => _DoneToggleState();
}

class _DoneToggleState extends ConsumerState<_DoneToggle> {
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    try {
      await ref
          .read(studentAssignmentsProvider.notifier)
          .setDone(widget.item.id, !widget.item.isDone);
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.stuCouldNotUpdate('$e'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
            width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final loc = AppLocalizations.of(context)!;
    return IconButton(
      onPressed: _toggle,
      tooltip: widget.item.isDone ? loc.stuMarkNotDone : loc.hwTrackerMarkDone,
      icon: Icon(
        widget.item.isDone
            ? Icons.check_circle
            : Icons.radio_button_unchecked,
        color: widget.item.isDone ? Colors.green : cs.onSurfaceVariant,
        size: 28,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String label;
  final Color color;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined,
              size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(loc.assignmentsEmptyTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(loc.stuAssignmentsEmptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
