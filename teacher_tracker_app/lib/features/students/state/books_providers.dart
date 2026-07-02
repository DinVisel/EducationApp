import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/book.dart';
import '../data/books_repository.dart';

/// Books for one student, keyed by studentId.
class BooksNotifier extends AsyncNotifier<List<Book>> {
  BooksNotifier(this.studentId);

  final int studentId;

  @override
  Future<List<Book>> build() =>
      ref.read(booksRepositoryProvider).getForStudent(studentId);

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(booksRepositoryProvider).getForStudent(studentId),
    );
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
