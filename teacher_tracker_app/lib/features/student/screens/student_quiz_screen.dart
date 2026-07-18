import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/student_quiz.dart';
import '../data/student_module_repository.dart';
import '../state/student_providers.dart';

/// Gamified, card-by-card quiz solving. Each question is a card; tapping a
/// choice gives immediate green/red feedback (graded locally from the payload's
/// `isCorrect`), then advances. On the last card the answers are submitted and
/// the server-authoritative score is shown.
class StudentQuizScreen extends ConsumerStatefulWidget {
  const StudentQuizScreen({super.key, required this.attemptId});

  final int attemptId;

  @override
  ConsumerState<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends ConsumerState<StudentQuizScreen> {
  StudentQuizDetail? _quiz;
  bool _loading = true;
  String? _error;

  int _index = 0;
  // question id → chosen choice id
  final Map<int, int> _answers = {};
  int _localScore = 0;
  bool _revealed = false; // whether the current card's answer is locked in

  bool _submitting = false;
  QuizResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final quiz = await ref
          .read(studentModuleRepositoryProvider)
          .getQuiz(widget.attemptId);
      setState(() {
        _quiz = quiz;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _choose(StudentQuizQuestion question, StudentQuizChoice choice) {
    if (_revealed) return; // one answer per card
    setState(() {
      _answers[question.questionId] = choice.id;
      if (choice.isCorrect) _localScore++;
      _revealed = true;
    });
  }

  Future<void> _next() async {
    final quiz = _quiz!;
    if (_index < quiz.questions.length - 1) {
      setState(() {
        _index++;
        _revealed = false;
      });
      return;
    }
    // Last question → submit.
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(studentModuleRepositoryProvider)
          .submitQuiz(widget.attemptId, _answers);
      ref.invalidate(studentQuizzesProvider);
      setState(() {
        _result = result;
        _submitting = false;
      });
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.stuQuizCouldNotSubmit('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return GlassScaffold(
      appBar: AppBar(
        title: Text(_quiz?.title ?? loc.newPostQuizFallback),
        backgroundColor: Colors.transparent,
      ),
      body: _buildBody(loc),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(loc.commonError('$_error')));
    final quiz = _quiz!;

    // Already submitted earlier → show the locked result.
    if (quiz.isSubmitted && _result == null) {
      return _ResultView(
        score: quiz.score,
        total: quiz.totalQuestions,
        alreadyDone: true,
      );
    }
    if (_result != null) {
      return _ResultView(
        score: _result!.score,
        total: _result!.totalQuestions,
        alreadyDone: false,
      );
    }
    if (quiz.questions.isEmpty) {
      return Center(child: Text(loc.stuQuizNoQuestions));
    }

    final question = quiz.questions[_index];
    final progress = (_index + (_revealed ? 1 : 0)) / quiz.questions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(loc.stuQuizQuestionOf(_index + 1, quiz.questions.length),
                      style: Theme.of(context).textTheme.labelMedium),
                  const Spacer(),
                  Icon(Icons.stars, size: 16, color: AppPalette.secondaryContainer),
                  const SizedBox(width: 4),
                  Text('$_localScore',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppPalette.secondaryContainer)),
                ],
              ),
              const SizedBox(height: 8),
              LiquidProgressBar(value: progress.clamp(0, 1).toDouble()),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _QuestionCard(
              key: ValueKey(question.questionId),
              question: question,
              chosenChoiceId: _answers[question.questionId],
              revealed: _revealed,
              onChoose: (c) => _choose(question, c),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton.icon(
              onPressed: (_revealed && !_submitting) ? _next : null,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_index < quiz.questions.length - 1
                      ? Icons.arrow_forward
                      : Icons.check),
              label: Text(_index < quiz.questions.length - 1
                  ? loc.stuQuizNext
                  : (_submitting ? loc.stuQuizSubmitting : loc.stuQuizFinish)),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.question,
    required this.chosenChoiceId,
    required this.revealed,
    required this.onChoose,
  });

  final StudentQuizQuestion question;
  final int? chosenChoiceId;
  final bool revealed;
  final void Function(StudentQuizChoice) onChoose;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            float: true,
            padding: const EdgeInsets.all(24),
            child: Text(question.text,
                style: tt.headlineSmall
                    ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),
          for (final choice in question.choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChoiceTile(
                choice: choice,
                selected: chosenChoiceId == choice.id,
                revealed: revealed,
                onTap: () => onChoose(choice),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.choice,
    required this.selected,
    required this.revealed,
    required this.onTap,
  });

  final StudentQuizChoice choice;
  final bool selected;
  final bool revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    const green = Color(0xFF2E9E5B);
    Color? fill;
    IconData? trailing;
    Color trailingColor = cs.onSurfaceVariant;

    if (revealed) {
      if (choice.isCorrect) {
        fill = green.withValues(alpha: 0.18);
        trailing = Icons.check_circle;
        trailingColor = green;
      } else if (selected) {
        fill = cs.error.withValues(alpha: 0.16);
        trailing = Icons.cancel;
        trailingColor = cs.error;
      }
    } else if (selected) {
      fill = cs.primaryContainer.withValues(alpha: 0.30);
    }

    return GlassCard(
      onTap: revealed ? null : onTap,
      fill: fill,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(choice.text,
                style: tt.bodyLarge?.copyWith(
                    color: cs.onSurface, fontWeight: FontWeight.w600)),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Icon(trailing, color: trailingColor),
          ],
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.score,
    required this.total,
    required this.alreadyDone,
  });

  final int score;
  final int total;
  final bool alreadyDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final pct = total == 0 ? 0.0 : score / total;
    final passed = pct >= 0.5;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          float: true,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(passed ? Icons.emoji_events : Icons.school,
                  size: 72,
                  color: passed ? AppPalette.secondaryContainer : cs.primary),
              const SizedBox(height: 16),
              Text(alreadyDone ? loc.stuQuizAlreadyDone : loc.stuQuizComplete,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('$score / $total',
                  style: tt.displaySmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(loc.stuQuizPctCorrect((pct * 100).round()),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                child: LiquidProgressBar(value: pct.clamp(0, 1).toDouble()),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.commonDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
