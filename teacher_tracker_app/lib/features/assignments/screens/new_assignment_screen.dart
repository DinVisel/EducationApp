import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/classroom.dart';
import '../../../models/file_object.dart';
import '../../files/data/files_repository.dart';
import '../state/assignments_providers.dart';

/// Compose and publish an assignment to a class: title, optional description,
/// due date, and attachments. Files are uploaded to R2 as they are picked;
/// publishing sends their ids with the assignment.
class NewAssignmentScreen extends ConsumerStatefulWidget {
  const NewAssignmentScreen({super.key, required this.classroom});

  final Classroom classroom;

  @override
  ConsumerState<NewAssignmentScreen> createState() =>
      _NewAssignmentScreenState();
}

class _NewAssignmentScreenState extends ConsumerState<NewAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime? _dueDate;
  final List<FileObject> _attachments = [];
  bool _uploading = false;
  bool _saving = false;

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
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploading = true);
    final repo = ref.read(filesRepositoryProvider);
    try {
      for (final f in result.files) {
        final bytes = f.bytes;
        if (bytes == null) continue; // withData failed for this entry
        final uploaded =
            await repo.upload(bytes: bytes, fileName: f.name);
        if (mounted) setState(() => _attachments.add(uploaded));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeAttachment(FileObject f) async {
    // Best-effort cleanup of the orphaned upload; drop it from the list either way.
    setState(() => _attachments.remove(f));
    try {
      await ref.read(filesRepositoryProvider).delete(f.id);
    } catch (_) {
      // Not fatal — the file just lingers unattached in the bucket.
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(assignmentActionsProvider).create(
            widget.classroom.id,
            title: _title.text.trim(),
            description: _description.text.trim(),
            dueDate: _dueDate,
            fileIds: _attachments.map((f) => f.id).toList(),
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Assignment published')),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not publish: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final busy = _saving || _uploading;

    return GlassScaffold(
      appBar: AppBar(
        title: Text('New Assignment · ${widget.classroom.name}'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Read chapter 3',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            // Due date row
            GlassCard(
              onTap: _pickDue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'Set a due date (optional)'
                          : 'Due ${_fmtDate(_dueDate!)}',
                      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                    ),
                  ),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Attachments',
                    style: tt.titleMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _uploading ? null : _pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Add files'),
                ),
              ],
            ),
            if (_uploading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (_attachments.isEmpty && !_uploading)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Exercises, videos, or files students can download.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            for (final f in _attachments)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(_iconFor(f), color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(f.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                        onPressed: () => _removeAttachment(f),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: busy ? null : _publish,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_saving ? 'Publishing…' : 'Publish to class'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(FileObject f) {
    if (f.isImage) return Icons.image_outlined;
    if (f.isVideo) return Icons.videocam_outlined;
    return Icons.insert_drive_file_outlined;
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
