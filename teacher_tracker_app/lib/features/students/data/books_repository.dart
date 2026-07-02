import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/book.dart';

class BooksRepository {
  BooksRepository(this._dio);

  final Dio _dio;

  String _base(int studentId) => '/api/students/$studentId/books';

  Future<List<Book>> getForStudent(int studentId) async {
    final res = await _dio.get<List<dynamic>>(_base(studentId));
    return (res.data ?? [])
        .map((e) => Book.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Book> create(
    int studentId, {
    required String title,
    String? author,
    required BookStatus status,
    int? rating,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _base(studentId),
      data: Book.writeJson(
        title: title,
        author: author,
        status: status,
        rating: rating,
      ),
    );
    return Book.fromJson(res.data!);
  }

  Future<void> update(int studentId, Book book) async {
    await _dio.put(
      '${_base(studentId)}/${book.id}',
      data: Book.writeJson(
        title: book.title,
        author: book.author,
        status: book.status,
        rating: book.rating,
      ),
    );
  }

  Future<void> delete(int studentId, int id) async {
    await _dio.delete('${_base(studentId)}/$id');
  }
}

final booksRepositoryProvider = Provider<BooksRepository>(
  (ref) => BooksRepository(ref.watch(dioProvider)),
);
