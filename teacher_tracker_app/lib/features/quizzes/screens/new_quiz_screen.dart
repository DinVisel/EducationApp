import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
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

    return GlassScaffold(
      appBar: AppBar(
        title: Text('New Quiz · ${widget.classroom.name}'),
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
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Charlotte’s Web — Chapter 1',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              onChanged: (v) => _draft.title = v,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _draft.description,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
              ),
              onChanged: (v) => _draft.description = v,
            ),
            const SizedBox(height: 20),
            Text('Category',
                style:
                    tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<QuizCategory>(
              segments: const [
                ButtonSegment(
                    value: QuizCategory.bookExam,
                    label: Text('Book'),
                    icon: Icon(Icons.auto_stories_outlined)),
                ButtonSegment(
                    value: QuizCategory.practice,
                    label: Text('Practice'),
                    icon: Icon(Icons.fitness_center_outlined)),
                ButtonSegment(
                    value: QuizCategory.general,
                    label: Text('General'),
                    icon: Icon(Icons.quiz_outlined)),
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
                decoration: const InputDecoration(
                  labelText: 'Book',
                  hintText: 'e.g. Charlotte’s Web',
                ),
                onChanged: (v) => _draft.bookReference = v,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Questions',
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
              label: const Text('Add question'),
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
              label: Text(_saving ? 'Publishing…' : 'Publish to class'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateQuestions() {
    for (var i = 0; i < _draft.questions.length; i++) {
      final q = _draft.questions[i];
      if (q.text.trim().isEmpty) return 'Question ${i + 1} needs text.';
      final filled = q.choices.where((c) => c.text.trim().isNotEmpty).toList();
      if (filled.length < 2) {
        return 'Question ${i + 1} needs at least two answer choices.';
      }
      if (!filled.any((c) => c.isCorrect)) {
        return 'Question ${i + 1} needs a correct answer selected.';
      }
    }
    return null;
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    final problem = _validateQuestions();
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
      messenger.showSnackBar(const SnackBar(content: Text('Quiz published')));
      navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not publish: $e')));
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
                Text('Question ${index + 1}',
                    style: tt.titleSmall
                        ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                    tooltip: 'Remove question',
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: question.text,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Enter the question'),
              onChanged: (v) => question.text = v,
            ),
            const SizedBox(height: 12),
            Text('Tap the circle to mark the correct answer',
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
              label: const Text('Add choice'),
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
            tooltip: 'Mark correct',
            onPressed: onSelectCorrect,
          ),
          Expanded(
            child: TextFormField(
              initialValue: choice.text,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Answer choice',
              ),
              onChanged: (v) => choice.text = v,
            ),
          ),
          if (canRemove)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
              tooltip: 'Remove choice',
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
