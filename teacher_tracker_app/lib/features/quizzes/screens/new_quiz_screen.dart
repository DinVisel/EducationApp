import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/classroom.dart';
import '../../../models/quiz.dart';
import '../../../models/quiz_draft.dart';
import '../state/quizzes_providers.dart';

/// Author and publish a multiple-choice quiz to a class: title, category,
/// optional book reference, and a dynamic list of questions each with choices
/// and a correct-answer selection.
class NewQuizScreen extends ConsumerStatefulWidget {
  const NewQuizScreen({super.key, required this.classroom});

  final Classroom classroom;

  @override
  ConsumerState<NewQuizScreen> createState() => _NewQuizScreenState();
}

class _NewQuizScreenState extends ConsumerState<NewQuizScreen> {
  final _draft = QuizDraft();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(loc.newQuizTitle(widget.classroom.name)),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            TextFormField(
              initialValue: _draft.title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: loc.newQuizTitleLabel,
                hintText: loc.newQuizTitleHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? loc.newQuizTitleRequired
                  : null,
              onChanged: (v) => _draft.title = v,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _draft.description,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: loc.newQuizDescriptionLabel,
                alignLabelWithHint: true,
              ),
              onChanged: (v) => _draft.description = v,
            ),
            const SizedBox(height: 20),
            Text(loc.newQuizCategory,
                style:
                    tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<QuizCategory>(
              segments: [
                ButtonSegment(
                    value: QuizCategory.bookExam,
                    label: Text(loc.newQuizCategoryBook),
                    icon: const Icon(Icons.auto_stories_outlined)),
                ButtonSegment(
                    value: QuizCategory.practice,
                    label: Text(loc.newQuizCategoryPractice),
                    icon: const Icon(Icons.fitness_center_outlined)),
                ButtonSegment(
                    value: QuizCategory.general,
                    label: Text(loc.newQuizCategoryGeneral),
                    icon: const Icon(Icons.quiz_outlined)),
              ],
              selected: {_draft.category},
              onSelectionChanged: (s) =>
                  setState(() => _draft.category = s.first),
            ),
            if (_draft.category == QuizCategory.bookExam) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _draft.bookReference,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: loc.newQuizBookLabel,
                  hintText: loc.newQuizBookHint,
                ),
                onChanged: (v) => _draft.bookReference = v,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(loc.newQuizQuestions,
                      style:
                          tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Text('${_draft.questions.length}',
                    style: tt.titleMedium?.copyWith(color: cs.primary)),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < _draft.questions.length; i++)
              _QuestionEditor(
                key: ObjectKey(_draft.questions[i]),
                index: i,
                question: _draft.questions[i],
                canRemove: _draft.questions.length > 1,
                onRemove: () =>
                    setState(() => _draft.questions.removeAt(i)),
                onChanged: () => setState(() {}),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _draft.questions.add(QuizQuestionDraft())),
              icon: const Icon(Icons.add),
              label: Text(loc.newQuizAddQuestion),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _publish,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_saving ? loc.newQuizPublishing : loc.newQuizPublish),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateQuestions(AppLocalizations loc) {
    for (var i = 0; i < _draft.questions.length; i++) {
      final q = _draft.questions[i];
      if (q.text.trim().isEmpty) return loc.newQuizQuestionNeedsText(i + 1);
      final filled = q.choices.where((c) => c.text.trim().isNotEmpty).toList();
      if (filled.length < 2) {
        return loc.newQuizQuestionNeedsChoices(i + 1);
      }
      if (!filled.any((c) => c.isCorrect)) {
        return loc.newQuizQuestionNeedsCorrect(i + 1);
      }
    }
    return null;
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context)!;
    final problem = _validateQuestions(loc);
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
      return;
    }

    // Drop empty trailing choices before sending.
    for (final q in _draft.questions) {
      q.choices.removeWhere((c) => c.text.trim().isEmpty);
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(quizActionsProvider)
          .create(widget.classroom.id, _draft);
      messenger.showSnackBar(SnackBar(content: Text(loc.newQuizPublished)));
      navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
          SnackBar(content: Text(loc.newQuizCouldNotPublish('$e'))));
    }
  }
}

/// Editor for one question: prompt text, its choices, and which is correct.
class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({
    super.key,
    required this.index,
    required this.question,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final QuizQuestionDraft question;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        float: true,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(loc.newQuizQuestionLabel(index + 1),
                    style: tt.titleSmall
                        ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                    tooltip: loc.newQuizRemoveQuestion,
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: question.text,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: loc.newQuizQuestionHint),
              onChanged: (v) => question.text = v,
            ),
            const SizedBox(height: 12),
            Text(loc.newQuizChooseCorrectHint,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            for (int i = 0; i < question.choices.length; i++)
              _ChoiceRow(
                choice: question.choices[i],
                canRemove: question.choices.length > 2,
                onSelectCorrect: () {
                  for (final c in question.choices) {
                    c.isCorrect = false;
                  }
                  question.choices[i].isCorrect = true;
                  onChanged();
                },
                onRemove: () {
                  question.choices.removeAt(i);
                  onChanged();
                },
              ),
            TextButton.icon(
              onPressed: () {
                question.choices.add(QuizChoiceDraft());
                onChanged();
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.newQuizAddChoice),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.choice,
    required this.canRemove,
    required this.onSelectCorrect,
    required this.onRemove,
  });

  final QuizChoiceDraft choice;
  final bool canRemove;
  final VoidCallback onSelectCorrect;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              choice.isCorrect
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: choice.isCorrect ? cs.primary : cs.onSurfaceVariant,
            ),
            tooltip: loc.newQuizMarkCorrect,
            onPressed: onSelectCorrect,
          ),
          Expanded(
            child: TextFormField(
              initialValue: choice.text,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                isDense: true,
                hintText: loc.newQuizChoiceHint,
              ),
              onChanged: (v) => choice.text = v,
            ),
          ),
          if (canRemove)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
              tooltip: loc.newQuizRemoveChoice,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
