import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/classroom.dart';
import '../state/classrooms_providers.dart';
import 'class_detail_screen.dart';

/// Lists the teacher's classes with enrolled counts; create / rename / delete.
class ClassesListScreen extends ConsumerStatefulWidget {
  const ClassesListScreen({super.key});

  @override
  ConsumerState<ClassesListScreen> createState() => _ClassesListScreenState();
}

class _ClassesListScreenState extends ConsumerState<ClassesListScreen> {
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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final notifier = ref.read(classroomsProvider.notifier);
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
    final classroomsAsync = ref.watch(classroomsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(classroomsProvider.future),
      child: classroomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Retry(
          message: '$e',
          onRetry: () => ref.invalidate(classroomsProvider),
        ),
        data: (classes) => CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 24, 20, 8),
                child: Text(loc.classesTitle,
                    style: tt.headlineMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700)),
              ),
            ),
            if (classes.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _Empty(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList.separated(
                  itemCount: classes.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    if (i >= classes.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _ClassCard(
                      classroom: classes[i],
                      cs: cs,
                      tt: tt,
                      onTap: () => _openDetail(ctx, classes[i]),
                      onRename: () => _renameClass(ctx, ref, classes[i]),
                      onDelete: () => _deleteClass(ctx, ref, classes[i]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext ctx, Classroom c) {
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => ClassDetailScreen(classroom: c)),
    );
  }

  Future<void> _renameClass(BuildContext ctx, WidgetRef ref, Classroom c) async {
    final messenger = ScaffoldMessenger.of(ctx);
    final loc = AppLocalizations.of(ctx)!;
    final name =
        await _promptClassName(ctx, title: loc.classesRenameTitle, initial: c.name);
    if (name == null || name.isEmpty || name == c.name) return;
    try {
      await ref.read(classroomsProvider.notifier).rename(c.id, name);
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.classesCouldNotRename('$e'))));
    }
  }

  Future<void> _deleteClass(BuildContext ctx, WidgetRef ref, Classroom c) async {
    final messenger = ScaffoldMessenger.of(ctx);
    final loc = AppLocalizations.of(ctx)!;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(loc.classesDeleteTitle),
        content: Text(loc.classesDeleteBody(c.name)),
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
      await ref.read(classroomsProvider.notifier).remove(c.id);
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.classesCouldNotDelete('$e'))));
    }
  }

}

/// Prompts for a class create dialog, then creates it. Lifted to a top-level
/// function so the shell that owns the floating action button (which lives
/// in the same [Scaffold] as the nav bar, not this screen's own) can trigger
/// it too.
Future<void> createClass(BuildContext ctx, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(ctx);
  final loc = AppLocalizations.of(ctx)!;
  final name = await _promptClassName(ctx, title: loc.classesNewTitle);
  if (name == null || name.isEmpty) return;
  try {
    await ref.read(classroomsProvider.notifier).add(name);
  } catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text(loc.classesCouldNotCreate('$e'))));
  }
}

Future<String?> _promptClassName(BuildContext ctx,
    {required String title, String? initial}) {
  final controller = TextEditingController(text: initial);
  final loc = AppLocalizations.of(ctx)!;
  return showDialog<String>(
    context: ctx,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: loc.classesNameLabel),
        onSubmitted: (v) => Navigator.pop(d, v.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(d), child: Text(loc.commonCancel)),
        FilledButton(
            onPressed: () => Navigator.pop(d, controller.text.trim()),
            child: Text(loc.commonSave)),
      ],
    ),
  );
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classroom,
    required this.cs,
    required this.tt,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });
  final Classroom classroom;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
            child: Icon(Icons.class_, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(classroom.name,
                    style: tt.titleMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  AppLocalizations.of(context)!
                      .classesStudentCount(classroom.studentCount),
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
            onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'rename',
                  child: Text(AppLocalizations.of(context)!.classesRename)),
              PopupMenuItem(
                  value: 'delete',
                  child: Text(AppLocalizations.of(context)!.commonDelete)),
            ],
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
          Icon(Icons.class_outlined,
              size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(loc.classesEmptyTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(loc.classesEmptySubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, textAlign: TextAlign.center),
        ),
        Center(
          child: FilledButton.tonal(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.commonRetry)),
        ),
      ],
    );
  }
}
