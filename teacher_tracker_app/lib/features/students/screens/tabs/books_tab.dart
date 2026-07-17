import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/book.dart';
import '../../state/books_providers.dart';
import '../../widgets/async_list.dart';

class BooksTab extends ConsumerStatefulWidget {
  const BooksTab({super.key, required this.studentId});

  final int studentId;

  @override
  ConsumerState<BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends ConsumerState<BooksTab> {
  final _scroll = ScrollController();
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final notifier = ref.read(booksProvider(widget.studentId).notifier);
    if (!notifier.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      await notifier.loadMore();
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentId = widget.studentId;
    final async = ref.watch(booksProvider(studentId));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, ref),
        child: const Icon(Icons.add),
      ),
      body: AsyncList<Book>(
        value: async,
        onRefresh: () => ref.refresh(booksProvider(studentId).future),
        onRetry: () => ref.invalidate(booksProvider(studentId)),
        emptyIcon: Icons.menu_book_outlined,
        emptyText: 'No books yet',
        scrollController: _scroll,
        loadingMore: _loadingMore,
        itemBuilder: (book) => Card(
          child: ListTile(
            leading: Icon(
              book.status == BookStatus.completed
                  ? Icons.check_circle
                  : Icons.menu_book,
              color: book.status == BookStatus.completed
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
            title: Text(book.title),
            subtitle: Text(_subtitle(book)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () =>
                  ref.read(booksProvider(studentId).notifier).remove(book.id),
            ),
            onTap: () => _add(context, ref, existing: book),
          ),
        ),
      ),
    );
  }

  String _subtitle(Book book) {
    final parts = <String>[
      if (book.author != null && book.author!.isNotEmpty) book.author!,
      book.status.label,
      if (book.rating != null) '${'★' * book.rating!}${'☆' * (5 - book.rating!)}',
    ];
    return parts.join(' • ');
  }

  Future<void> _add(BuildContext context, WidgetRef ref, {Book? existing}) async {
    final result = await showDialog<_BookInput>(
      context: context,
      builder: (_) => _BookDialog(existing: existing),
    );
    if (result == null) return;
    final notifier = ref.read(booksProvider(widget.studentId).notifier);
    try {
      if (existing == null) {
        await notifier.add(
          title: result.title,
          author: result.author,
          status: result.status,
          rating: result.rating,
        );
      } else {
        await notifier.save(
          Book(
            id: existing.id,
            title: result.title,
            author: result.author,
            status: result.status,
            rating: result.rating,
            createdAt: existing.createdAt,
            studentId: existing.studentId,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }
}

class _BookInput {
  const _BookInput(this.title, this.author, this.status, this.rating);
  final String title;
  final String? author;
  final BookStatus status;
  final int? rating;
}

class _BookDialog extends StatefulWidget {
  const _BookDialog({this.existing});

  final Book? existing;

  @override
  State<_BookDialog> createState() => _BookDialogState();
}

class _BookDialogState extends State<_BookDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late BookStatus _status;
  int? _rating;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _title = TextEditingController(text: b?.title ?? '');
    _author = TextEditingController(text: b?.author ?? '');
    _status = b?.status ?? BookStatus.reading;
    _rating = b?.rating;
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
      title: Text(widget.existing == null ? 'Add book' : 'Edit book'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _author,
              decoration: const InputDecoration(
                labelText: 'Author (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<BookStatus>(
              segments: const [
                ButtonSegment(
                  value: BookStatus.reading,
                  label: Text('Reading'),
                ),
                ButtonSegment(
                  value: BookStatus.completed,
                  label: Text('Completed'),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
            const SizedBox(height: 12),
            _RatingPicker(
              rating: _rating,
              onChanged: (r) => setState(() => _rating = r),
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
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _BookInput(
                _title.text.trim(),
                _author.text.trim(),
                _status,
                _rating,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _RatingPicker extends StatelessWidget {
  const _RatingPicker({required this.rating, required this.onChanged});

  final int? rating;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              (rating ?? 0) >= i ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            // Tapping the current rating clears it.
            onPressed: () => onChanged(rating == i ? null : i),
          ),
      ],
    );
  }
}
