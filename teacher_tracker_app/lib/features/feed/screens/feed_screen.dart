import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/post_subject.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../../profile/screens/teacher_profile_view_screen.dart';
import '../state/feed_providers.dart';
import '../widgets/post_card.dart';
import 'new_post_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);
    final activeSubject = ref.watch(feedProvider.notifier).subject;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return RefreshIndicator(
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
                    child: Text(loc.feedTitle,
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
                      final post = posts[i];
                      return PostCard(
                        post: post,
                        onToggleLike: () =>
                            ref.read(feedProvider.notifier).toggleLike(post.id),
                        onRate: (v) =>
                            ref.read(feedProvider.notifier).rate(post.id, v),
                        onDelete: () =>
                            ref.read(feedProvider.notifier).remove(post.id),
                        onTapAuthor: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TeacherProfileViewScreen(
                                userId: post.authorUserId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// Opens the new-post composer. Lifted out of [_FeedScreenState] so the
/// shell that owns the floating action button (which lives in the same
/// [Scaffold] as the nav bar, not this screen's own) can trigger it too.
Future<void> openNewPost(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const NewPostScreen()),
  );
}

/// Horizontal row of subject filter chips (All + each subject).
class _SubjectFilterBar extends ConsumerWidget {
  const _SubjectFilterBar({required this.active});
  final String? active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
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
              label: Text(loc.feedFilterAll),
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

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined,
              size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(loc.feedEmptyTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(loc.feedEmptyBody,
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
