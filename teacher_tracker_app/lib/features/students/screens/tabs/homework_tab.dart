import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/homework.dart';
import '../../../../models/student.dart' show formatDateOnly;
import '../../state/homework_providers.dart';
import '../../widgets/async_list.dart';

class HomeworkTab extends ConsumerStatefulWidget {
  const HomeworkTab({super.key, required this.studentId});

  final int studentId;

  @override
  ConsumerState<HomeworkTab> createState() => _HomeworkTabState();
}

class _HomeworkTabState extends ConsumerState<HomeworkTab> {
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
    final notifier = ref.read(homeworkProvider(widget.studentId).notifier);
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
    final studentId = widget.studentId;
    final async = ref.watch(homeworkProvider(studentId));
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, ref),
        child: const Icon(Icons.add),
      ),
      body: AsyncList<Homework>(
        value: async,
        onRefresh: () => ref.refresh(homeworkProvider(studentId).future),
        onRetry: () => ref.invalidate(homeworkProvider(studentId)),
        emptyIcon: Icons.assignment_outlined,
        emptyText: loc.homeworkTabEmpty,
        scrollController: _scroll,
        loadingMore: _loadingMore,
        itemBuilder: (hw) => Card(
          child: ListTile(
            leading: Checkbox(
              value: hw.isDone,
              onChanged: (v) => ref
                  .read(homeworkProvider(studentId).notifier)
                  .toggleDone(hw, v ?? false),
            ),
            title: Text(
              hw.title,
              style: hw.isDone
                  ? const TextStyle(
                      decoration: TextDecoration.lineThrough,
                    )
                  : null,
            ),
            subtitle: _subtitle(loc, hw),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: loc.commonDelete,
              onPressed: () => ref
                  .read(homeworkProvider(studentId).notifier)
                  .remove(hw.id),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _subtitle(AppLocalizations loc, Homework hw) {
    final parts = <String>[
      if (hw.description != null && hw.description!.isNotEmpty) hw.description!,
      if (hw.dueDate != null) loc.hwTrackerDue(formatDateOnly(hw.dueDate!)),
    ];
    return parts.isEmpty ? null : Text(parts.join('\n'));
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_HomeworkInput>(
      context: context,
      builder: (_) => const _HomeworkDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(homeworkProvider(widget.studentId).notifier).add(
            title: result.title,
            description: result.description,
            dueDate: result.dueDate,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.commonAddFailed('$e'))));
      }
    }
  }
}

class _HomeworkInput {
  const _HomeworkInput(this.title, this.description, this.dueDate);
  final String title;
  final String? description;
  final DateTime? dueDate;
}

class _HomeworkDialog extends StatefulWidget {
  const _HomeworkDialog();

  @override
  State<_HomeworkDialog> createState() => _HomeworkDialogState();
}

class _HomeworkDialogState extends State<_HomeworkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.homeworkTabAdd),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.commonTitle,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? loc.commonRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: loc.commonDescriptionOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDue,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _dueDate == null
                          ? loc.homeworkTabDueOptional
                          : loc.hwTrackerDue(formatDateOnly(_dueDate!)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_dueDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _dueDate = null),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _HomeworkInput(
                _title.text.trim(),
                _description.text.trim(),
                _dueDate,
              ),
            );
          },
          child: Text(loc.commonAdd),
        ),
      ],
    );
  }
}
