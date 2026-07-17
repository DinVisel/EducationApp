import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/student.dart';
import '../state/students_providers.dart';
import 'student_detail_screen.dart';
import 'student_form_screen.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
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
    final notifier = ref.read(studentsProvider.notifier);
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
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add student'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentsProvider.future),
        child: studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorState(
            message: '$err',
            onRetry: () => ref.invalidate(studentsProvider),
          ),
          data: (students) => students.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: students.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    if (i >= students.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final s = students[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(_initials(s))),
                      title: Text(s.fullName),
                      subtitle: s.studentNumber.isEmpty
                          ? null
                          : Text('No. ${s.studentNumber}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context, ref, s),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentDetailScreen(student: s),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _initials(Student s) {
    final f = s.firstName.isNotEmpty ? s.firstName[0] : '';
    final l = s.lastName.isNotEmpty ? s.lastName[0] : '';
    final res = '$f$l'.toUpperCase();
    return res.isEmpty ? '?' : res;
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StudentFormScreen()),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Remove ${s.fullName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(studentsProvider.notifier).remove(s.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${s.fullName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.group_add_outlined,
            size: 64, color: Theme.of(context).hintColor),
        const SizedBox(height: 16),
        const Center(child: Text('No students yet')),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Tap “Add student” to create your first one.',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
        const SizedBox(height: 12),
        const Center(child: Text('Could not load students')),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, textAlign: TextAlign.center),
        ),
        Center(
          child: FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
