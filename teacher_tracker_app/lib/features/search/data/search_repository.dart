import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/search_result.dart';

/// Global discovery search over teachers and shared materials (quizzes and
/// documents), with Subject / Grade / Material-Type filters.
class SearchRepository {
  SearchRepository(this._dio);

  final Dio _dio;

  Future<SearchResults> search({
    String? q,
    String type = 'all',
    String? subject,
    String? grade,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/search',
      queryParameters: {
        'q': ?q,
        'type': type,
        'subject': ?subject,
        'grade': ?grade,
      },
    );
    return SearchResults.fromJson(res.data!);
  }
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(dioProvider)),
);
