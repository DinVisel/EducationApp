import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/post.dart';
import '../../../models/post_comment.dart';
import '../../auth/state/auth_controller.dart';
import '../data/feed_repository.dart';

/// The global teacher feed with a subject filter and cursor pagination. Owns the
/// list plus mutations (compose, delete, like, load-more), reloading on
/// login/logout.
class FeedNotifier extends AsyncNotifier<List<Post>> {
  static const _pageSize = 20;

  /// Active subject filter (wire value), or null for "all".
  String? _subject;

  /// Whether the last page came back full — a hint that more may exist.
  bool _hasMore = true;

  bool get hasMore => _hasMore;
  String? get subject => _subject;

  @override
  Future<List<Post>> build() async {
    // Rebuild on login/logout; only load when signed in.
    final auth = ref.watch(authControllerProvider).value;
    if (auth == null) return [];
    final page = await ref
        .read(feedRepositoryProvider)
        .getFeed(subject: _subject, limit: _pageSize);
    _hasMore = page.length == _pageSize;
    return page;
  }

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(feedRepositoryProvider)
          .getFeed(subject: _subject, limit: _pageSize);
      _hasMore = page.length == _pageSize;
      return page;
    });
  }

  /// Switches the subject filter (null = all) and reloads from the top.
  Future<void> setSubjectFilter(String? subject) async {
    if (subject == _subject) return;
    _subject = subject;
    await _reload();
  }

  /// Appends the next page after the oldest post currently loaded.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isEmpty || !_hasMore) return;

    final next = await ref.read(feedRepositoryProvider).getFeed(
          subject: _subject,
          beforeId: current.last.id,
          limit: _pageSize,
        );
    _hasMore = next.length == _pageSize;
    state = AsyncData([...current, ...next]);
  }

  Future<Post> create({
    required String text,
    required String subject,
    List<int> fileIds = const [],
  }) async {
    final created = await ref.read(feedRepositoryProvider).create(
          text: text,
          subject: subject,
          fileIds: fileIds,
        );
    await _reload();
    return created;
  }

  Future<void> remove(int id) async {
    await ref.read(feedRepositoryProvider).delete(id);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.where((p) => p.id != id).toList());
    }
  }

  /// Toggles the caller's like, updating the count optimistically and rolling
  /// back if the request fails.
  Future<void> toggleLike(int id) async {
    final current = state.value;
    if (current == null) return;
    final idx = current.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final post = current[idx];
    final liked = post.likedByMe;

    List<Post> withPost(Post p) {
      final copy = [...current];
      copy[idx] = p;
      return copy;
    }

    // Optimistic flip.
    state = AsyncData(withPost(post.copyWith(
      likedByMe: !liked,
      likeCount: post.likeCount + (liked ? -1 : 1),
    )));

    try {
      final repo = ref.read(feedRepositoryProvider);
      liked ? await repo.unlike(id) : await repo.like(id);
    } catch (_) {
      // Roll back on failure.
      state = AsyncData(withPost(post));
    }
  }
}

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, List<Post>>(FeedNotifier.new);

/// Comments for one post, keyed by post id.
final postCommentsProvider =
    FutureProvider.family<List<PostComment>, int>((ref, postId) {
  return ref.watch(feedRepositoryProvider).getComments(postId);
});

/// Add/delete comment helpers that refresh the per-post comment list and the
/// feed (so comment counts stay current).
class FeedCommentActions {
  FeedCommentActions(this._ref);
  final Ref _ref;

  Future<void> add(int postId, String text) async {
    await _ref.read(feedRepositoryProvider).addComment(postId, text);
    _ref.invalidate(postCommentsProvider(postId));
    _ref.invalidate(feedProvider);
  }

  Future<void> remove(int postId, int commentId) async {
    await _ref.read(feedRepositoryProvider).deleteComment(postId, commentId);
    _ref.invalidate(postCommentsProvider(postId));
    _ref.invalidate(feedProvider);
  }
}

final feedCommentActionsProvider =
    Provider<FeedCommentActions>((ref) => FeedCommentActions(ref));
