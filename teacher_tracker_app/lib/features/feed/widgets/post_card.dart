import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config.dart';
import '../../../core/design.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/time_ago.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/classroom.dart';
import '../../../models/post.dart';
import '../../../models/post_subject.dart';
import '../../classes/state/classrooms_providers.dart';
import '../../files/state/file_url_providers.dart';
import '../../files/widgets/attachment_tile.dart';
import '../../quizzes/data/quizzes_repository.dart';
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
    this.onRate,
    this.showPinAction = false,
  });

  final Post post;
  final VoidCallback? onToggleLike;
  final Future<void> Function()? onDelete;
  final VoidCallback? onTogglePin;
  final VoidCallback? onTapAuthor;

  /// Called when the caller taps a star on a shared-quiz post. Null makes the
  /// stars read-only (e.g. on a profile list).
  final void Function(int value)? onRate;
  final bool showPinAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

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
                      Text(timeAgo(loc, post.createdAt),
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
          if (post.sharedQuiz != null) ...[
            const SizedBox(height: 12),
            _SharedQuizCard(
              post: post,
              onRate: onRate,
              onAssign: () => _assignToClass(context, ref),
            ),
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
                onTap: () {
                  ref.read(hapticServiceProvider).tap();
                  onToggleLike?.call();
                },
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
                label: loc.commonShare,
                onTap: () => _share(context, loc, post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shares a link to this post. If the recipient has the app, the OS deep-links
  // straight to the post; otherwise the web fallback sends them to the store.
  void _share(BuildContext context, AppLocalizations loc, Post post) {
    final url = '$publicWebBaseUrl/post/${post.id}';
    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      url,
      subject: loc.feedShareSubject(post.authorName),
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero,
    );
  }

  // "Assign to My Class": pick one of the teacher's classes, then clone the
  // shared quiz into it (fans out to that class's students).
  Future<void> _assignToClass(BuildContext context, WidgetRef ref) async {
    final quiz = post.sharedQuiz;
    if (quiz == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;

    final classroom = await showModalBottomSheet<Classroom>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _ClassPickerSheet(),
    );
    if (classroom == null) return;

    try {
      await ref.read(quizzesRepositoryProvider).clone(quiz.quizId, classroom.id);
      messenger.showSnackBar(SnackBar(
          content: Text(loc.feedQuizAssigned(quiz.title, classroom.name))));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.feedCouldNotAssign('$e'))));
    }
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
        backgroundImage:
            CachedNetworkImageProvider(url, cacheKey: 'file-${fileId!}'),
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
    final loc = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
      onSelected: (v) {
        switch (v) {
          case 'delete':
            _confirmDelete(context, ref);
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
              child: Text(post.isPinned
                  ? loc.feedUnpinFromProfile
                  : loc.feedPinToProfile),
            ),
          PopupMenuItem(value: 'delete', child: Text(loc.commonDelete)),
        ] else
          PopupMenuItem(value: 'report', child: Text(loc.commonReport)),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    ref.read(hapticServiceProvider).warning();
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(loc.feedDeletePostTitle),
        content: Text(loc.feedDeletePostBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(loc.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(loc.commonDelete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await onDelete?.call();
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.feedCouldNotDelete('$e'))));
    }
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final reason = await showReportDialog(context, loc.reportPostTitle);
    if (reason == null) return;
    try {
      await ref.read(feedRepositoryProvider).reportPost(post.id, reason);
      messenger
          .showSnackBar(SnackBar(content: Text(loc.feedReported)));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.feedCouldNotReport('$e'))));
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

/// The shared-quiz preview inside a post: title, question count, a 1–5 star
/// rating row, and an "Assign to My Class" button.
class _SharedQuizCard extends StatelessWidget {
  const _SharedQuizCard({
    required this.post,
    required this.onRate,
    required this.onAssign,
  });
  final Post post;
  final void Function(int value)? onRate;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final quiz = post.sharedQuiz!;

    return GlassCard(
      fill: cs.tertiaryContainer.withValues(alpha: 0.18),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_outlined, color: cs.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(quiz.title,
                    style: tt.titleSmall?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              '${loc.feedQuizQuestionCount(quiz.questionCount)}'
              ' · ${quiz.category.label}',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          Row(
            children: [
              _StarRating(
                rating: post.myRating ?? 0,
                onRate: onRate,
              ),
              const SizedBox(width: 8),
              if (post.ratingCount > 0)
                Text(
                  '${post.averageRating!.toStringAsFixed(1)} '
                  '(${post.ratingCount})',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                )
              else
                Text(loc.feedNotRatedYet,
                    style:
                        tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onAssign,
              icon: const Icon(Icons.add_task, size: 18),
              label: Text(loc.feedAssignToClass),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of five stars. Read-only when [onRate] is null.
class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, this.onRate});
  final int rating;
  final void Function(int value)? onRate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const amber = Color(0xFFF5A623);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onRate == null ? null : () => onRate!(i),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                i <= rating ? Icons.star : Icons.star_border,
                size: 24,
                color: i <= rating ? amber : cs.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Bottom sheet listing the teacher's classes to assign a cloned quiz to.
class _ClassPickerSheet extends ConsumerWidget {
  const _ClassPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final classesAsync = ref.watch(classroomsProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: classesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(loc.commonError('$e'))),
          data: (classes) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(loc.feedAssignWhichClass, style: tt.titleLarge),
              ),
              if (classes.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Text(loc.feedNoClassesYet),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: classes.length,
                    itemBuilder: (ctx, i) {
                      final c = classes[i];
                      return ListTile(
                        leading: const Icon(Icons.class_outlined),
                        title: Text(c.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(ctx, c),
                      );
                    },
                  ),
                ),
            ],
          ),
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
