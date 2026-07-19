import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/student_assignment.dart';
import '../../auth/state/auth_controller.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../state/student_providers.dart';

/// The student's landing tab: a greeting plus at-a-glance cards for what's due
/// soon, quiz progress, and class count — all composed from the existing student
/// providers (no dedicated endpoint). Tapping a card jumps to the matching tab
/// via [onNavigate] (Assignments = 1, Quizzes = 2, Classes = 3).
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProvider);
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);
    final quizzesAsync = ref.watch(studentQuizzesProvider);
    final classesAsync = ref.watch(studentClassesProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentAssignmentsProvider);
          ref.invalidate(studentQuizzesProvider);
          ref.invalidate(studentClassesProvider);
          await ref.read(studentClassesProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 24, 20, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.stuHomeGreeting(student?.firstName ?? loc.stuStudentFallback),
                    style: tt.headlineMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700),
                  ),
                ),
                const NotificationBell(),
              ],
            ),
            const SizedBox(height: 20),

            // --- Due soon ---
            _SectionHeader(
              title: loc.stuHomeDueSoon,
              onSeeAll: () => onNavigate(1),
              seeAllLabel: loc.stuHomeSeeAll,
            ),
            const SizedBox(height: 8),
            assignmentsAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _MessageCard(text: loc.commonError('$e')),
              data: (items) {
                final dueSoon = _dueSoon(items);
                if (dueSoon.isEmpty) {
                  return _MessageCard(text: loc.stuHomeNoDueSoon);
                }
                return Column(
                  children: [
                    for (final a in dueSoon)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    cs.primaryContainer.withValues(alpha: 0.5),
                                child: Icon(Icons.assignment_outlined,
                                    color: cs.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.titleSmall?.copyWith(
                                            color: cs.onSurface,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                      a.dueDate != null
                                          ? loc.hwTrackerDue(_fmtDate(a.dueDate!))
                                          : a.className,
                                      style: tt.labelMedium?.copyWith(
                                          color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // --- Quiz progress ---
            _SectionHeader(
              title: loc.stuHomeQuizProgress,
              onSeeAll: () => onNavigate(2),
              seeAllLabel: loc.stuHomeSeeAll,
            ),
            const SizedBox(height: 8),
            quizzesAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _MessageCard(text: loc.commonError('$e')),
              data: (quizzes) {
                final total = quizzes.length;
                final done = quizzes.where((q) => q.isSubmitted).length;
                final pending = total - done;
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.stuHomeQuizzesDone(done, total),
                              style: tt.titleMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w700)),
                          Text(loc.stuHomePendingQuizzes(pending),
                              style: tt.labelLarge
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          minHeight: 8,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // --- Classes ---
            classesAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _MessageCard(text: loc.commonError('$e')),
              data: (classes) => GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.class_outlined, color: cs.primary),
                  title: Text(loc.classesTitle),
                  subtitle: Text(loc.stuHomeClassesCount(classes.length)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onNavigate(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Not-done assignments that have a due date, soonest first, capped at three.
  static List<StudentAssignmentItem> _dueSoon(List<StudentAssignmentItem> items) {
    final list = items
        .where((a) => !a.isDone && a.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return list.take(3).toList();
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
    required this.seeAllLabel,
  });

  final String title;
  final VoidCallback onSeeAll;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: tt.titleMedium
                ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
        TextButton(onPressed: onSeeAll, child: Text(seeAllLabel)),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const GlassCard(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Text(text,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
    );
  }
}
