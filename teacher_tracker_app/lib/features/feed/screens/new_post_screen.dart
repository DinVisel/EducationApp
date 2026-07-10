import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/file_object.dart';
import '../../../models/post_subject.dart';
import '../../files/data/files_repository.dart';
import '../../files/mime.dart';
import '../state/feed_providers.dart';

/// Compose and publish a post to the global feed: text, a subject tag, and
/// attachments. Files are uploaded to R2 as they are picked; publishing sends
/// their ids with the post.
class NewPostScreen extends ConsumerStatefulWidget {
  const NewPostScreen({super.key});

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  String _subject = PostSubject.all.first.value;
  final List<FileObject> _attachments = [];
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
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
        final uploaded = await repo.uploadDirect(
          bytes: bytes,
          fileName: f.name,
          contentType: mimeForFileName(f.name),
        );
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
      await ref.read(feedProvider.notifier).create(
            text: _text.text.trim(),
            subject: _subject,
            fileIds: _attachments.map((f) => f.id).toList(),
          );
      messenger.showSnackBar(const SnackBar(content: Text('Post published')));
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
        title: const Text('New Post'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            TextFormField(
              controller: _text,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Share something',
                hintText: 'An exercise, a tip, a resource…',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Write something to post' : null,
            ),
            const SizedBox(height: 20),
            Text('Subject',
                style: tt.titleMedium?.copyWith(
                    color: cs.onSurface, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in PostSubject.all)
                  ChoiceChip(
                    avatar: Icon(s.icon,
                        size: 16,
                        color: _subject == s.value ? cs.onPrimary : cs.primary),
                    label: Text(s.label),
                    selected: _subject == s.value,
                    onSelected: (_) => setState(() => _subject = s.value),
                  ),
              ],
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
                  'Exercises, videos, or files other teachers can download.',
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
              label: Text(_saving ? 'Publishing…' : 'Post to hub'),
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
}
