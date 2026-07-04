import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/classroom.dart';
import '../state/classrooms_providers.dart';
import 'class_detail_screen.dart';

/// Lists the teacher's classes with enrolled counts; create / rename / delete.
class ClassesListScreen extends ConsumerWidget {
  const ClassesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classroomsAsync = ref.watch(classroomsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createClass(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Class'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(classroomsProvider.future),
        child: classroomsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Retry(
            message: '$e',
            onRetry: () => ref.invalidate(classroomsProvider),
          ),
          data: (classes) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, MediaQuery.of(context).padding.top + 24, 20, 8),
                  child: Text('Classes',
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
                    itemCount: classes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _ClassCard(
                      classroom: classes[i],
                      cs: cs,
                      tt: tt,
                      onTap: () => _openDetail(ctx, classes[i]),
                      onRename: () => _renameClass(ctx, ref, classes[i]),
                      onDelete: () => _deleteClass(ctx, ref, classes[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext ctx, Classroom c) {
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => ClassDetailScreen(classroom: c)),
    );
  }

  Future<void> _createClass(BuildContext ctx, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(ctx);
    final name = await _promptName(ctx, title: 'New Class');
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(classroomsProvider.notifier).add(name);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not create class: $e')));
    }
  }

  Future<void> _renameClass(BuildContext ctx, WidgetRef ref, Classroom c) async {
    final messenger = ScaffoldMessenger.of(ctx);
    final name = await _promptName(ctx, title: 'Rename Class', initial: c.name);
    if (name == null || name.isEmpty || name == c.name) return;
    try {
      await ref.read(classroomsProvider.notifier).rename(c.id, name);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not rename class: $e')));
    }
  }

  Future<void> _deleteClass(BuildContext ctx, WidgetRef ref, Classroom c) async {
    final messenger = ScaffoldMessenger.of(ctx);
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Delete class?'),
        content: Text('Remove "${c.name}"? Students stay, only the class and '
            'its enrollments are removed.'),
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
      await ref.read(classroomsProvider.notifier).remove(c.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete class: $e')));
    }
  }

  Future<String?> _promptName(BuildContext ctx,
      {required String title, String? initial}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Class name'),
          onSubmitted: (v) => Navigator.pop(d, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(d, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
  }
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
                  '${classroom.studentCount} '
                  '${classroom.studentCount == 1 ? 'student' : 'students'}',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
            onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_outlined,
              size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No classes yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Tap “New Class” to create one.',
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
          child:
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}
