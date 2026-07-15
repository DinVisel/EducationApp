import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/student_quiz.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../state/student_providers.dart';
import 'student_quiz_screen.dart';

/// The student's quizzes across all their classes. Unsolved quizzes open the
/// gamified solve screen; completed ones show the locked score.
class StudentQuizzesScreen extends ConsumerWidget {
  const StudentQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentQuizzesProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentQuizzesProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(child: Text('Error: $e')),
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
                        child: Text('My Quizzes',
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
                    itemBuilder: (ctx, i) => _QuizCard(quiz: items[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});
  final StudentQuizSummary quiz;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final q = quiz;
    const green = Color(0xFF2E9E5B);

    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentQuizScreen(attemptId: q.attemptId),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: (q.isSubmitted ? green : cs.primary)
                .withValues(alpha: 0.15),
            child: Icon(q.isSubmitted ? Icons.emoji_events : q.category.icon,
                color: q.isSubmitted ? green : cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.title,
                    style: tt.titleMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text(q.className,
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  q.isSubmitted
                      ? 'Score ${q.score}/${q.totalQuestions}'
                      : '${q.questionCount} question'
                          '${q.questionCount == 1 ? '' : 's'} · Tap to start',
                  style: tt.bodySmall?.copyWith(
                      color: q.isSubmitted ? green : cs.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(
            q.isSubmitted ? Icons.check_circle : Icons.play_circle_fill,
            color: q.isSubmitted ? green : cs.primary,
            size: 28,
          ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined,
              size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No quizzes yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Quizzes your teacher assigns will show up here.',
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
