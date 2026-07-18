import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/classroom.dart';
import '../../../models/quiz.dart';
import '../../feed/screens/new_post_screen.dart';
import '../state/quizzes_providers.dart';
import 'new_quiz_screen.dart';
import 'quiz_analytics_screen.dart';

/// Quizzes published to one class, with fan-out progress. Tapping a quiz opens
/// its analytics dashboard.
class ClassQuizzesTab extends ConsumerWidget {
  const ClassQuizzesTab({super.key, required this.classroom});

  final Classroom classroom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final quizzesAsync = ref.watch(classroomQuizzesProvider(classroom.id));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(classroomQuizzesProvider(classroom.id).future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(loc.classQuizTitle,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewQuizScreen(classroom: classroom),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(loc.commonNew),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          quizzesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(loc.commonError('$e')),
            data: (quizzes) {
              if (quizzes.isEmpty) return const _Empty();
              return Column(
                children: [
                  for (final q in quizzes)
                    _QuizCard(
                      quiz: q,
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizAnalyticsScreen(
                            classroom: classroom,
                            quizId: q.id,
                            title: q.title,
                          ),
                        ),
                      ),
                      onShare: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NewPostScreen(
                            initialQuizId: q.id,
                            initialQuizTitle: q.title,
                          ),
                        ),
                      ),
                      onDelete: () => _delete(context, ref, q),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, WidgetRef ref, Quiz q) async {
    final messenger = ScaffoldMessenger.of(ctx);
    final loc = AppLocalizations.of(ctx)!;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(loc.classQuizDeleteTitle),
        content: Text(loc.classQuizDeleteBody(q.title, q.assignedCount)),
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
      await ref.read(quizActionsProvider).delete(classroom.id, q.id);
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.commonCouldNotDelete('$e'))));
    }
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.quiz,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
  });
  final Quiz quiz;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final q = quiz;
    final progress = q.assignedCount == 0 ? 0.0 : q.submittedCount / q.assignedCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onOpen,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(q.title,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: Icon(Icons.ios_share, color: cs.primary),
                  tooltip: loc.classQuizShareToHub,
                  visualDensity: VisualDensity.compact,
                  onPressed: onShare,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: loc.commonDelete,
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(icon: q.category.icon, label: q.category.label),
                if (q.category == QuizCategory.bookExam &&
                    (q.bookReference?.isNotEmpty ?? false))
                  _Chip(icon: Icons.menu_book_outlined, label: q.bookReference!),
                _Chip(
                    icon: Icons.help_outline,
                    label: loc.feedQuizQuestionCount(q.questionCount)),
                if (q.averageScorePct != null)
                  _Chip(
                      icon: Icons.emoji_events_outlined,
                      label: loc.classQuizAvg(q.averageScorePct!.round())),
              ],
            ),
            const SizedBox(height: 12),
            LiquidProgressBar(value: progress.clamp(0, 1).toDouble()),
            const SizedBox(height: 6),
            Text(loc.classQuizSubmitted(q.submittedCount, q.assignedCount),
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
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

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined,
              size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(loc.classQuizEmptyTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(loc.classQuizEmptySubtitle,
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
