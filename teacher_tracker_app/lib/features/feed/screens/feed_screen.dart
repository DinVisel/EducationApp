import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/post.dart';
import '../../../models/post_subject.dart';
import '../../files/widgets/attachment_tile.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../data/feed_repository.dart';
import '../state/feed_providers.dart';
import '../widgets/report_dialog.dart';
import 'new_post_screen.dart';
import 'post_comments_screen.dart';

/// The global teacher social hub: a shared feed of posts (text + subject +
/// attachments) that any teacher can browse, filter by subject, like, and
/// comment on. Rendered as the first tab of the teacher shell.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
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
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final notifier = ref.read(feedProvider.notifier);
    if (!notifier.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      await notifier.loadMore();
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _newPost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewPostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);
    final activeSubject = ref.watch(feedProvider.notifier).subject;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newPost,
        icon: const Icon(Icons.post_add),
        label: const Text('New Post'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(feedProvider.future),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 24, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Community Hub',
                          style: tt.headlineMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700)),
                    ),
                    const NotificationBell(),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SubjectFilterBar(active: activeSubject),
            ),
            ...feedAsync.when(
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Error: $e')),
                ),
              ],
              data: (posts) {
                if (posts.isEmpty) {
                  return const [
                    SliverFillRemaining(
                        hasScrollBody: false, child: _Empty()),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: posts.length + (_loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        if (i >= posts.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _PostCard(post: posts[i]);
                      },
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of subject filter chips (All + each subject).
class _SubjectFilterBar extends ConsumerWidget {
  const _SubjectFilterBar({required this.active});
  final String? active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void select(String? value) =>
        ref.read(feedProvider.notifier).setSubjectFilter(value);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: active == null,
              onSelected: (_) => select(null),
            ),
          ),
          for (final s in PostSubject.all)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(s.icon, size: 16),
                label: Text(s.label),
                selected: active == s.value,
                onSelected: (_) => select(s.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                child: Text(
                  _initials(post.authorName),
                  style: tt.labelLarge?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        style: tt.titleSmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700)),
                    Text(_fmtWhen(post.createdAt),
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              _SubjectChip(subject: post.subject),
              _PostMenu(post: post),
            ],
          ),
          if (post.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(post.text,
                style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
          ],
          for (final f in post.attachments)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AttachmentTile(
                fileId: f.fileId,
                fileName: f.fileName,
                contentType: f.contentType,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionButton(
                icon: post.likedByMe
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: post.likedByMe ? cs.error : cs.onSurfaceVariant,
                label: '${post.likeCount}',
                onTap: () => ref.read(feedProvider.notifier).toggleLike(post.id),
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.mode_comment_outlined,
                color: cs.onSurfaceVariant,
                label: '${post.commentCount}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostCommentsScreen(post: post),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  static String _fmtWhen(DateTime d) {
    final local = d.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}

/// Overflow menu: delete on your own posts, report on everyone else's.
class _PostMenu extends ConsumerWidget {
  const _PostMenu({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
      onSelected: (v) =>
          v == 'delete' ? _confirmDelete(context, ref) : _report(context, ref),
      itemBuilder: (_) => [
        if (post.isMine)
          const PopupMenuItem(value: 'delete', child: Text('Delete'))
        else
          const PopupMenuItem(value: 'report', child: Text('Report')),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This removes it from the feed for everyone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(feedProvider.notifier).remove(post.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showReportDialog(context, 'post');
    if (reason == null) return;
    try {
      await ref.read(feedRepositoryProvider).reportPost(post.id, reason);
      messenger.showSnackBar(
          const SnackBar(content: Text('Reported — thanks. An admin will review it.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not report: $e')));
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(label, style: tt.labelLarge?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.subject});
  final String subject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PostSubject.iconFor(subject), size: 15, color: cs.primary),
          const SizedBox(width: 6),
          Text(PostSubject.labelFor(subject),
              style: tt.labelSmall?.copyWith(
                  color: cs.onSurface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined,
              size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No posts yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Tap “New Post” to share a resource with other teachers.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
