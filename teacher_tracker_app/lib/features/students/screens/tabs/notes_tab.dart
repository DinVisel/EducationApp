import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/tracking_note.dart';
import '../../state/notes_providers.dart';
import '../../widgets/async_list.dart';

class NotesTab extends ConsumerWidget {
  const NotesTab({super.key, required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider(studentId));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context, ref),
        child: const Icon(Icons.add),
      ),
      body: AsyncList<TrackingNote>(
        value: notesAsync,
        onRefresh: () => ref.refresh(notesProvider(studentId).future),
        onRetry: () => ref.invalidate(notesProvider(studentId)),
        emptyIcon: Icons.sticky_note_2_outlined,
        emptyText: 'No notes yet',
        itemBuilder: (note) => Card(
          child: ListTile(
            title: Text(note.content),
            subtitle: Text(
              '${note.category} • ${_formatDate(note.createdAt)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () async {
                await ref.read(notesProvider(studentId).notifier).remove(note.id);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String category, String content})>(
      context: context,
      builder: (_) => const _NoteDialog(),
    );
    if (result == null) return;
    try {
      await ref
          .read(notesProvider(studentId).notifier)
          .add(category: result.category, content: result.content);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Add failed: $e')));
      }
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _content = TextEditingController();
  String _category = 'Behavior';

  static const _categories = ['Behavior', 'Academic', 'Social', 'Other'];

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add note'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Other'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _content,
              minLines: 2,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              (category: _category, content: _content.text.trim()),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
