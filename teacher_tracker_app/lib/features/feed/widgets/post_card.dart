import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config.dart';
import '../../../core/design.dart';
import '../../../models/post.dart';
import '../../../models/post_subject.dart';
import '../../files/state/file_url_providers.dart';
import '../../files/widgets/attachment_tile.dart';
import '../data/feed_repository.dart';
import '../screens/post_comments_screen.dart';
import 'report_dialog.dart';

/// A single feed/profile post card. Shared by the Hub feed and a teacher's
/// profile. Mutations are delegated to callbacks so each host controls its own
/// list refresh; [showPinAction] gates the author-only Pin/Unpin menu item
/// (used on the profile, not the Hub feed).
class PostCard extends ConsumerWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onToggleLike,
    this.onDelete,
    this.onTogglePin,
    this.onTapAuthor,
    this.showPinAction = false,
  });

  final Post post;
  final VoidCallback? onToggleLike;
  final Future<void> Function()? onDelete;
  final VoidCallback? onTogglePin;
  final VoidCallback? onTapAuthor;
  final bool showPinAction;

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
              GestureDetector(
                onTap: onTapAuthor,
                child: _AuthorAvatar(
                    fileId: post.authorAvatarFileId, name: post.authorName),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTapAuthor,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(post.authorName,
                                style: tt.titleSmall?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (post.isPinned) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.push_pin, size: 14, color: cs.primary),
                          ],
                        ],
                      ),
                      Text(_fmtWhen(post.createdAt),
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              _SubjectChip(subject: post.subject),
              _PostMenu(
                post: post,
                onDelete: onDelete,
                onTogglePin: onTogglePin,
                showPinAction: showPinAction,
              ),
            ],
          ),
          if (post.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(post.text, style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
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
                icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                color: post.likedByMe ? cs.error : cs.onSurfaceVariant,
                label: '${post.likeCount}',
                onTap: onToggleLike ?? () {},
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
              const Spacer(),
              _ActionButton(
                icon: Icons.ios_share,
                color: cs.onSurfaceVariant,
                label: 'Share',
                onTap: () => _share(post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shares a link to this post. If the recipient has the app, the OS deep-links
  // straight to the post; otherwise the web fallback sends them to the store.
  void _share(Post post) {
    final url = '$publicWebBaseUrl/post/${post.id}';
    Share.share(url, subject: '${post.authorName} shared a post');
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

class _AuthorAvatar extends ConsumerWidget {
  const _AuthorAvatar({required this.fileId, required this.name});
  final int? fileId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    Widget fallback() => CircleAvatar(
          radius: 20,
          backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
          child: Text(_initials(name),
              style: tt.labelLarge?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.w700)),
        );

    if (fileId == null) return fallback();
    final urlAsync = ref.watch(fileUrlProvider(fileId!));
    return urlAsync.maybeWhen(
      data: (url) => CircleAvatar(
        radius: 20,
        backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
        backgroundImage: NetworkImage(url),
      ),
      orElse: fallback,
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

/// Overflow menu: delete (+ pin/unpin when [showPinAction]) on your own posts,
/// report on everyone else's.
class _PostMenu extends ConsumerWidget {
  const _PostMenu({
    required this.post,
    required this.onDelete,
    required this.onTogglePin,
    required this.showPinAction,
  });
  final Post post;
  final Future<void> Function()? onDelete;
  final VoidCallback? onTogglePin;
  final bool showPinAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
      onSelected: (v) {
        switch (v) {
          case 'delete':
            _confirmDelete(context);
          case 'pin':
          case 'unpin':
            onTogglePin?.call();
          case 'report':
            _report(context, ref);
        }
      },
      itemBuilder: (_) => [
        if (post.isMine) ...[
          if (showPinAction)
            PopupMenuItem(
              value: post.isPinned ? 'unpin' : 'pin',
              child: Text(post.isPinned ? 'Unpin from profile' : 'Pin to profile'),
            ),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ] else
          const PopupMenuItem(value: 'report', child: Text('Report')),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
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
      await onDelete?.call();
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
      messenger.showSnackBar(const SnackBar(
          content: Text('Reported — thanks. An admin will review it.')));
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
