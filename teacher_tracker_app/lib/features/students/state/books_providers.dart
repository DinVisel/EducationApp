import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/book.dart';
import '../data/books_repository.dart';

/// Books for one student, keyed by studentId.
class BooksNotifier extends AsyncNotifier<List<Book>> {
  BooksNotifier(this.studentId);

  static const _pageSize = 20;

  final int studentId;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<Book>> build() async {
    final page = await ref
        .read(booksRepositoryProvider)
        .getForStudent(studentId, limit: _pageSize);
    _hasMore = page.length == _pageSize;
    return page;
  }

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(booksRepositoryProvider)
          .getForStudent(studentId, limit: _pageSize);
      _hasMore = page.length == _pageSize;
      return page;
    });
  }

  /// Appends the next page after the last-loaded book.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isEmpty || !_hasMore) return;

    final next = await ref.read(booksRepositoryProvider).getForStudent(
          studentId,
          beforeId: current.last.id,
          limit: _pageSize,
        );
    _hasMore = next.length == _pageSize;
    state = AsyncData([...current, ...next]);
  }

  Future<void> add({
    required String title,
    String? author,
    required BookStatus status,
    int? rating,
  }) async {
    await ref.read(booksRepositoryProvider).create(
          studentId,
          title: title,
          author: author,
          status: status,
          rating: rating,
        );
    await _reload();
  }

  Future<void> save(Book book) async {
    await ref.read(booksRepositoryProvider).update(studentId, book);
    await _reload();
  }

  Future<void> remove(int id) async {
    await ref.read(booksRepositoryProvider).delete(studentId, id);
    await _reload();
  }
}

final booksProvider =
    AsyncNotifierProvider.family<BooksNotifier, List<Book>, int>(
  BooksNotifier.new,
);
