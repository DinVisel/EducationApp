import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../models/post.dart';
import '../../../models/post_comment.dart';

/// The global teacher social hub. All endpoints require a teacher token and hit
/// one shared feed (not scoped to a single teacher). Attachments are uploaded
/// separately via [FilesRepository] and referenced here by file id.
class FeedRepository {
  FeedRepository(this._dio);

  final Dio _dio;

  /// A page of the feed, newest first. [subject] filters by tag; [beforeId]
  /// pages backwards (pass the id of the last post you have).
  Future<List<Post>> getFeed({
    String? subject,
    int? beforeId,
    int limit = 20,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/posts',
      queryParameters: {
        'subject': ?subject,
        'beforeId': ?beforeId,
        'limit': limit,
      },
    );
    return (res.data ?? [])
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// A teacher's own posts (their profile), pinned first then newest.
  Future<List<Post>> getByAuthor(int authorUserId, {int limit = 50}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/posts',
      queryParameters: {'authorUserId': authorUserId, 'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> pin(int id) => _dio.post<void>('/api/posts/$id/pin');

  Future<void> unpin(int id) => _dio.delete<void>('/api/posts/$id/pin');

  /// Publishes a post to the global feed. [fileIds] are ids of files already
  /// uploaded via the files endpoint.
  Future<Post> create({
    required String text,
    required String subject,
    List<int> fileIds = const [],
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/posts',
      data: {
        'text': text,
        'subject': subject,
        'fileIds': fileIds,
      },
    );
    return Post.fromJson(res.data!);
  }

  Future<void> delete(int id) => _dio.delete<void>('/api/posts/$id');

  Future<void> like(int id) => _dio.post<void>('/api/posts/$id/like');

  Future<void> unlike(int id) => _dio.delete<void>('/api/posts/$id/like');

  Future<List<PostComment>> getComments(int postId) async {
    final res =
        await _dio.get<List<dynamic>>('/api/posts/$postId/comments');
    return (res.data ?? [])
        .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PostComment> addComment(int postId, String text) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/posts/$postId/comments',
      data: {'text': text},
    );
    return PostComment.fromJson(res.data!);
  }

  Future<void> deleteComment(int postId, int commentId) =>
      _dio.delete<void>('/api/posts/$postId/comments/$commentId');

  Future<void> reportPost(int postId, String reason) => _dio.post<void>(
        '/api/posts/$postId/report',
        data: {'reason': reason},
      );

  Future<void> reportComment(int postId, int commentId, String reason) =>
      _dio.post<void>(
        '/api/posts/$postId/comments/$commentId/report',
        data: {'reason': reason},
      );
}

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepository(ref.watch(dioProvider)),
);
