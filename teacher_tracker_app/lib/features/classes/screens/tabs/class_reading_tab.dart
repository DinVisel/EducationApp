import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/book.dart';
import '../../../../models/classroom.dart';
import '../../../../models/student.dart';
import '../../../students/state/books_providers.dart';
import '../../state/classrooms_providers.dart';

/// Reading overview for one class: each roster student's books, with an
/// add-book action scoped to the class roster.
class ClassReadingTab extends ConsumerWidget {
  const ClassReadingTab({super.key, required this.classroom});

  final Classroom classroom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(classroomDetailProvider(classroom.id));
    final loc = AppLocalizations.of(context)!;

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(loc.commonError('$e'))),
      data: (detail) {
        final students = detail.students;
        return RefreshIndicator(
          onRefresh: () =>
              ref.refresh(classroomDetailProvider(classroom.id).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(loc.classTabReading,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700)),
                  ),
                  FilledButton.icon(
                    onPressed: students.isEmpty
                        ? null
                        : () => _addBook(context, ref, students),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(loc.classReadingAddBook),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (students.isEmpty)
                _EmptyHint(text: loc.attendanceEmptyRoster)
              else
                for (final s in students)
                  _StudentBooks(student: s),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addBook(
      BuildContext ctx, WidgetRef ref, List<Student> students) async {
    await showDialog<void>(
      context: ctx,
      builder: (_) => _AddBookDialog(
        students: students,
        initialStudentId: students.first.id,
        onSubmit: (studentId, title, author, status) => ref
            .read(booksProvider(studentId).notifier)
            .add(title: title, author: author, status: status),
      ),
    );
  }
}

class _StudentBooks extends ConsumerWidget {
  const _StudentBooks({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final booksAsync = ref.watch(booksProvider(student.id));

    return booksAsync.maybeWhen(
      data: (books) {
        if (books.isEmpty) return const SizedBox.shrink();
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
                      child: Text(_initial(student),
                          style: tt.labelSmall?.copyWith(color: cs.primary)),
                    ),
                    const SizedBox(width: 8),
                    Text(student.fullName,
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              for (final b in books)
                _BookRow(book: b, studentId: student.id),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  static String _initial(Student s) =>
      s.firstName.isNotEmpty ? s.firstName[0].toUpperCase() : '?';
}

class _BookRow extends ConsumerWidget {
  const _BookRow({required this.book, required this.studentId});
  final Book book;
  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final done = book.status == BookStatus.completed;
    final statusLabel = done ? loc.readingCompleted : loc.readingStatusReading;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(done ? Icons.check_circle : Icons.menu_book,
                color: done ? cs.primary : cs.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style:
                          tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    book.author?.isNotEmpty == true
                        ? '${book.author} · $statusLabel'
                        : statusLabel,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (!done)
              IconButton(
                icon: Icon(Icons.done_all, size: 20, color: cs.primary),
                tooltip: loc.classReadingMarkCompleted,
                onPressed: () => ref.read(booksProvider(studentId).notifier).save(
                      Book(
                        id: book.id,
                        title: book.title,
                        author: book.author,
                        status: BookStatus.completed,
                        rating: book.rating,
                        createdAt: book.createdAt,
                        studentId: book.studentId,
                      ),
                    ),
              ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
              tooltip: loc.commonRemove,
              onPressed: () =>
                  ref.read(booksProvider(studentId).notifier).remove(book.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant)),
      ),
    );
  }
}

// ── Add book dialog (roster-scoped) ──────────────────────────────────────────

class _AddBookDialog extends StatefulWidget {
  const _AddBookDialog({
    required this.students,
    required this.initialStudentId,
    required this.onSubmit,
  });
  final List<Student> students;
  final int initialStudentId;
  final Future<void> Function(
      int studentId, String title, String? author, BookStatus status) onSubmit;

  @override
  State<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<_AddBookDialog> {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  late int _studentId;
  BookStatus _status = BookStatus.reading;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _studentId = widget.initialStudentId;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.classReadingAddBook),
      content: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _studentId,
              decoration: InputDecoration(labelText: loc.readingStudent),
              items: widget.students
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.fullName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _studentId = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: loc.readingBookTitle),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? loc.commonRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _author,
              decoration: InputDecoration(labelText: loc.readingAuthorOptional),
            ),
            const SizedBox(height: 12),
            SegmentedButton<BookStatus>(
              segments: [
                ButtonSegment(
                    value: BookStatus.reading,
                    label: Text(loc.readingStatusReading)),
                ButtonSegment(
                    value: BookStatus.completed,
                    label: Text(loc.readingCompleted)),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.commonCancel),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  if (!_key.currentState!.validate()) return;
                  setState(() => _loading = true);
                  try {
                    await widget.onSubmit(
                      _studentId,
                      _title.text.trim(),
                      _author.text.trim().isEmpty ? null : _author.text.trim(),
                      _status,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.commonError('$e'))));
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(loc.commonAdd),
        ),
      ],
    );
  }
}
