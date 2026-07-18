import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/classroom.dart';
import '../../../models/quiz_analytics.dart';
import '../state/quizzes_providers.dart';

/// Teacher analytics for one quiz: participation, average score, per-question
/// correct-rate, and per-student results.
class QuizAnalyticsScreen extends ConsumerWidget {
  const QuizAnalyticsScreen({
    super.key,
    required this.classroom,
    required this.quizId,
    required this.title,
  });

  final Classroom classroom;
  final int quizId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (classroomId: classroom.id, quizId: quizId);
    final analyticsAsync = ref.watch(quizAnalyticsProvider(key));
    final loc = AppLocalizations.of(context)!;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(loc.commonError('$e'))),
        data: (a) => RefreshIndicator(
          onRefresh: () => ref.refresh(quizAnalyticsProvider(key).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _Overview(analytics: a),
              const SizedBox(height: 24),
              _SectionTitle(loc.quizAnalyticsPerQuestion),
              const SizedBox(height: 12),
              for (int i = 0; i < a.questions.length; i++)
                _QuestionStatCard(index: i, stat: a.questions[i]),
              const SizedBox(height: 12),
              _SectionTitle(loc.quizAnalyticsStudents),
              const SizedBox(height: 12),
              for (final r in a.results) _StudentResultRow(result: r),
            ],
          ),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.analytics});
  final QuizAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final a = analytics;
    final loc = AppLocalizations.of(context)!;
    return GlassCard(
      float: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: loc.quizAnalyticsParticipation,
                  value: '${a.submittedCount}/${a.assignedCount}',
                  progress: a.participation,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _Stat(
                  label: loc.quizAnalyticsAverageScore,
                  value: a.averageScorePct == null
                      ? '—'
                      : '${a.averageScorePct!.round()}%',
                  progress: (a.averageScorePct ?? 0) / 100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.progress,
  });
  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value,
            style: tt.headlineSmall
                ?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        LiquidProgressBar(value: progress.clamp(0, 1).toDouble()),
      ],
    );
  }
}

class _QuestionStatCard extends StatelessWidget {
  const _QuestionStatCard({required this.index, required this.stat});
  final int index;
  final QuizQuestionStat stat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
                  child: Text('${index + 1}. ${stat.text}',
                      style: tt.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Text('${stat.correctRatePct.round()}%',
                    style: tt.titleMedium?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            LiquidProgressBar(
                value: (stat.correctRatePct / 100).clamp(0, 1).toDouble()),
            const SizedBox(height: 12),
            for (final c in stat.choices)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      c.isCorrect
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 16,
                      color: c.isCorrect ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c.text,
                          style: tt.bodyMedium?.copyWith(
                              color: c.isCorrect
                                  ? cs.onSurface
                                  : cs.onSurfaceVariant,
                              fontWeight: c.isCorrect
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                    Text('${c.chosenCount}',
                        style: tt.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentResultRow extends StatelessWidget {
  const _StudentResultRow({required this.result});
  final QuizStudentResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final r = result;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              r.isSubmitted ? Icons.check_circle : Icons.hourglass_empty,
              color: r.isSubmitted ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(r.studentName,
                  style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (r.isSubmitted)
              Text('${r.score}/${r.totalQuestions}',
                  style: tt.titleSmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700))
            else
              Text(loc.quizAnalyticsNotYet,
                  style: tt.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}
