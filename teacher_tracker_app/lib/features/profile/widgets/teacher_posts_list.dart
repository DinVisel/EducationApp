import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/state/feed_providers.dart';
import '../../feed/widgets/post_card.dart';

/// The posts authored by one teacher (pinned first), rendered as a column of
/// [PostCard]s. When [canManage] is true (viewing your own profile) the author-
/// only pin/delete actions are enabled.
class TeacherPostsList extends ConsumerWidget {
  const TeacherPostsList({
    super.key,
    required this.userId,
    required this.canManage,
  });

  final int userId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(authorPostsProvider(userId));
    final actions = ref.read(profilePostActionsProvider(userId));

    return postsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text('Error: $e')),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const _EmptyPosts();
        }
        return Column(
          children: [
            for (final post in posts)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PostCard(
                  post: post,
                  showPinAction: canManage,
                  onToggleLike: () => actions.toggleLike(post.id, post.likedByMe),
                  onTogglePin: canManage
                      ? () => actions.togglePin(post.id, post.isPinned)
                      : null,
                  onDelete: canManage ? () => actions.delete(post.id) : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.forum_outlined,
              size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No posts yet',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
