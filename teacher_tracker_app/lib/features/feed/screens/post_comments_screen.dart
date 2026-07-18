import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../core/time_ago.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/post.dart';
import '../../../models/post_comment.dart';
import '../data/feed_repository.dart';
import '../state/feed_providers.dart';
import '../widgets/report_dialog.dart';

/// Full-screen comments for one feed post: the thread plus a compose row.
class PostCommentsScreen extends ConsumerStatefulWidget {
  const PostCommentsScreen({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends ConsumerState<PostCommentsScreen> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    try {
      await ref.read(feedCommentActionsProvider).add(widget.post.id, text);
      _input.clear();
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(loc.commentsCouldNotAdd('$e'))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(PostComment c) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    try {
      await ref.read(feedCommentActionsProvider).remove(widget.post.id, c.id);
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(loc.feedCouldNotDelete('$e'))));
    }
  }

  Future<void> _report(PostComment c) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final reason = await showReportDialog(context, loc.reportCommentTitle);
    if (reason == null) return;
    try {
      await ref
          .read(feedRepositoryProvider)
          .reportComment(widget.post.id, c.id, reason);
      messenger.showSnackBar(SnackBar(content: Text(loc.feedReported)));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.feedCouldNotReport('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(loc.commentsTitle),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: commentsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(loc.commonError('$e'))),
                data: (comments) {
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(loc.commentsEmpty,
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref
                        .refresh(postCommentsProvider(widget.post.id).future),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _CommentCard(
                        comment: comments[i],
                        onDelete: () => _delete(comments[i]),
                        onReport: () => _report(comments[i]),
                      ),
                    ),
                  );
                },
              ),
            ),
            _Composer(
              controller: _input,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.onDelete,
    required this.onReport,
  });
  final PostComment comment;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(comment.authorName,
                    style: tt.titleSmall?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700)),
              ),
              Text(timeAgo(loc, comment.createdAt),
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              if (comment.isMine)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                  tooltip: loc.commonDelete,
                  onPressed: onDelete,
                )
              else
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.flag_outlined,
                      size: 18, color: cs.onSurfaceVariant),
                  tooltip: loc.commonReport,
                  onPressed: onReport,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment.text,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: loc.commentsHint,
              ),
            ),
          ),
          const SizedBox(width: 8),
          sending
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton.filled(
                  onPressed: onSend,
                  icon: const Icon(Icons.send),
                  color: cs.onPrimary,
                ),
        ],
      ),
    );
  }
}
