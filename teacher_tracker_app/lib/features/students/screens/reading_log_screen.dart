import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/book.dart';
import '../../../models/student.dart';
import '../state/books_providers.dart';
import '../state/students_providers.dart';

/// Reading Log screen — matches the "Reading Log" Stitch screen.
/// Glassmorphic book cards with liquid-progress reading bars, grouped by student.
class ReadingLogScreen extends ConsumerStatefulWidget {
  const ReadingLogScreen({super.key});

  @override
  ConsumerState<ReadingLogScreen> createState() => _ReadingLogScreenState();
}

class _ReadingLogScreenState extends ConsumerState<ReadingLogScreen> {
  int? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: _ReadingAppBar(cs: cs, tt: tt)),
          // ── Header ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reading Log',
                            style: tt.displaySmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 36)),
                        Text("Track Grade 3-B's reading adventures.",
                            style: tt.bodyLarge
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _addBook(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Book'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40)),
                  ),
                ],
              ),
            ),
          ),
          // ── Student filter ────────────────────────────────────────────
          studentsAsync.maybeWhen(
            data: (students) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _selectedStudentId == null,
                        onTap: () => setState(() => _selectedStudentId = null),
                        cs: cs,
                        tt: tt,
                      ),
                      ...students.map((s) => _FilterChip(
                            label: s.firstName,
                            selected: _selectedStudentId == s.id,
                            onTap: () =>
                                setState(() => _selectedStudentId = s.id),
                            cs: cs,
                            tt: tt,
                          )),
                    ],
                  ),
                ),
              ),
            ),
            orElse: () => const SliverToBoxAdapter(child: SizedBox()),
          ),
          // ── Book grid ────────────────────────────────────────────────
          studentsAsync.maybeWhen(
            data: (students) {
              final filtered = _selectedStudentId == null
                  ? students
                  : students.where((s) => s.id == _selectedStudentId).toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _StudentBooksSection(
                    student: filtered[i],
                    cs: cs,
                    tt: tt,
                  ),
                  childCount: filtered.length,
                ),
              );
            },
            orElse: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Future<void> _addBook(BuildContext ctx, WidgetRef ref) async {
    final students = ref.read(studentsProvider).maybeWhen(
          data: (list) => list, orElse: () => <dynamic>[]);
    if (students.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Add students first')));
      return;
    }
    final targetId = _selectedStudentId ?? students.first.id;
    await showDialog(
      context: ctx,
      builder: (_) => _AddBookDialog(
        students: students,
        initialStudentId: targetId,
        onSubmit: (studentId, title, author, status) async {
          await ref.read(booksProvider(studentId).notifier).add(
                title: title,
                author: author,
                status: status,
              );
        },
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ReadingAppBar extends StatelessWidget {
  const _ReadingAppBar({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: kToolbarHeight + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top, left: 20, right: 20),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.6),
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_stories, color: cs.primary),
              const SizedBox(width: 12),
              Text('Reading Log',
                  style: tt.headlineMedium?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700)),
              const Spacer(),
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
                child: Icon(Icons.person, color: cs.primary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.cs,
      required this.tt});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(99),
          border: selected
              ? Border.all(color: cs.primary.withValues(alpha: 0.3))
              : Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: tt.labelMedium?.copyWith(
                color: selected ? cs.primary : cs.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

class _StudentBooksSection extends ConsumerWidget {
  const _StudentBooksSection(
      {required this.student, required this.cs, required this.tt});
  final Student student;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider(student.id));
    return booksAsync.maybeWhen(
      data: (books) {
        if (books.isEmpty) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          cs.primaryContainer.withValues(alpha: 0.4),
                      child: Text(
                        student.firstName.isNotEmpty
                            ? student.firstName[0]
                            : '?',
                        style: tt.labelMedium
                            ?.copyWith(color: cs.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(student.fullName,
                        style: tt.titleMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              ...books
                  .map((b) => _BookCard(
                        book: b,
                        studentId: student.id,
                        cs: cs,
                        tt: tt,
                      ))
                  .toList(),
            ],
          ),
        );
      },
      orElse: () => const SizedBox(),
    );
  }
}

class _BookCard extends ConsumerWidget {
  const _BookCard({
    required this.book,
    required this.studentId,
    required this.cs,
    required this.tt,
  });
  final Book book;
  final int studentId;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = book.status == BookStatus.completed;
    final progress = isCompleted ? 1.0 : 0.35;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book icon / cover placeholder
                Container(
                  width: 56,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.tertiaryContainer.withValues(alpha: 0.6),
                        cs.primary.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.menu_book,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title,
                          style: tt.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (book.author != null && book.author!.isNotEmpty)
                        Text(book.author!,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      _GenreChip(status: book.status, cs: cs, tt: tt),
                    ],
                  ),
                ),
                // More menu
                IconButton(
                  icon: Icon(Icons.more_vert,
                      size: 20, color: cs.onSurfaceVariant),
                  onPressed: () =>
                      _showOptions(context, ref),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress section
            Row(
              children: [
                Expanded(
                  child: Text(
                    isCompleted ? 'Finished!' : 'In progress',
                    style: tt.labelMedium?.copyWith(color: cs.onSurface),
                  ),
                ),
                Text(
                  isCompleted ? 'Complete' : '${(progress * 100).toInt()}%',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LiquidProgressBar(value: progress),
            const SizedBox(height: 10),
            // Action button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isCompleted
                    ? null
                    : () => _updateProgress(context, ref),
                icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.update,
                    size: 16),
                label: Text(isCompleted ? 'Completed' : 'Update Progress'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProgress(BuildContext ctx, WidgetRef ref) async {
    // Toggle status to completed as simple "update progress"
    final updated = Book(
      id: book.id,
      title: book.title,
      author: book.author,
      status: BookStatus.completed,
      rating: book.rating,
      createdAt: book.createdAt,
      studentId: book.studentId,
    );
    await ref.read(booksProvider(studentId).notifier).save(updated);
  }

  Future<void> _showOptions(BuildContext ctx, WidgetRef ref) async {
    await showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(booksProvider(studentId).notifier).remove(book.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.status, required this.cs, required this.tt});
  final BookStatus status;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == BookStatus.completed;
    final color = isCompleted ? cs.primary : cs.tertiary;
    final label = isCompleted ? 'Completed' : 'Reading';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: tt.labelSmall?.copyWith(color: color)),
    );
  }
}

// ── Add book dialog ───────────────────────────────────────────────────────────

class _AddBookDialog extends StatefulWidget {
  const _AddBookDialog({
    required this.students,
    required this.initialStudentId,
    required this.onSubmit,
  });
  final List students;
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
    return AlertDialog(
      title: const Text('Add New Book'),
      content: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _studentId,
              decoration: const InputDecoration(labelText: 'Student'),
              items: widget.students
                  .map<DropdownMenuItem<int>>((s) => DropdownMenuItem(
                        value: s.id as int,
                        child: Text(s.fullName as String),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _studentId = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Book Title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _author,
              decoration:
                  const InputDecoration(labelText: 'Author (optional)'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<BookStatus>(
              segments: const [
                ButtonSegment(
                    value: BookStatus.reading, label: Text('Reading')),
                ButtonSegment(
                    value: BookStatus.completed, label: Text('Completed')),
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
          child: const Text('Cancel'),
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
                          SnackBar(content: Text('Error: $e')));
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
              : const Text('Add'),
        ),
      ],
    );
  }
}
