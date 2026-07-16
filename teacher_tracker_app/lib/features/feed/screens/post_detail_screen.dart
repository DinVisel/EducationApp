import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/post.dart';
import '../data/feed_repository.dart';
import '../widgets/post_card.dart';

/// A single post opened by id — the landing screen for a shared/deep-linked post
/// (`/post/:id`). Fetches the post fresh since it may not be in the current feed
/// page, then renders it with the shared [PostCard] (like / comment / share).
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final int postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  Post? _post;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await ref.read(feedRepositoryProvider).getPost(widget.postId);
      if (mounted) setState(() => _post = post);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike() async {
    final post = _post;
    if (post == null) return;
    // Optimistic flip, revert on failure.
    setState(() => _post = post.copyWith(
          likedByMe: !post.likedByMe,
          likeCount: post.likeCount + (post.likedByMe ? -1 : 1),
        ));
    final repo = ref.read(feedRepositoryProvider);
    try {
      if (post.likedByMe) {
        await repo.unlike(post.id);
      } else {
        await repo.like(post.id);
      }
    } catch (_) {
      if (mounted) setState(() => _post = post);
    }
  }

  Future<void> _rate(int value) async {
    final post = _post;
    if (post == null) return;
    try {
      await ref.read(feedRepositoryProvider).ratePost(post.id, value);
      await _load(); // refresh average/count/myRating from the server
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not rate: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _post == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("This post couldn't be loaded."),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          PostCard(
            post: _post!,
            onToggleLike: _toggleLike,
            onRate: _rate,
            onDelete: () async {
              await ref.read(feedRepositoryProvider).delete(_post!.id);
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
