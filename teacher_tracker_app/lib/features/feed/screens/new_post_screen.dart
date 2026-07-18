import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/file_object.dart';
import '../../../models/grade_level.dart';
import '../../../models/my_quiz.dart';
import '../../../models/post_subject.dart';
import '../../files/data/files_repository.dart';
import '../../files/image_processing.dart';
import '../../files/mime.dart';
import '../../quizzes/data/quizzes_repository.dart';
import '../state/feed_providers.dart';

/// Compose and publish a post to the global feed: text, a subject tag, an
/// optional grade level, an optional shared quiz, and file attachments. Files
/// are uploaded to R2 as they are picked; publishing sends their ids.
class NewPostScreen extends ConsumerStatefulWidget {
  const NewPostScreen({
    super.key,
    this.initialQuizId,
    this.initialQuizTitle,
  });

  /// Pre-attach a quiz (used by "Share to Hub" from the class Quizzes tab).
  final int? initialQuizId;
  final String? initialQuizTitle;

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  String _subject = PostSubject.all.first.value;
  String? _grade;
  int? _sharedQuizId;
  String? _sharedQuizTitle;
  final List<FileObject> _attachments = [];
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sharedQuizId = widget.initialQuizId;
    _sharedQuizTitle = widget.initialQuizTitle;
  }

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
        var bytes = f.bytes;
        if (bytes == null) continue; // withData failed for this entry
        var fileName = f.name;
        var contentType = mimeForFileName(f.name);
        // Shrink raster images before upload; other file types pass through.
        if (f.path != null && isCompressibleImage(f.name)) {
          final processed =
              await compressImage(path: f.path!, originalName: f.name);
          if (processed != null) {
            bytes = processed.bytes;
            fileName = processed.fileName;
            contentType = processed.contentType;
          }
        }
        final uploaded = await repo.uploadDirect(
          bytes: bytes,
          fileName: fileName,
          contentType: contentType,
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

  Future<void> _pickQuiz() async {
    final quiz = await showModalBottomSheet<MyQuiz>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _QuizPickerSheet(),
    );
    if (quiz != null) {
      setState(() {
        _sharedQuizId = quiz.id;
        _sharedQuizTitle = quiz.title;
      });
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
            gradeLevel: _grade,
            sharedQuizId: _sharedQuizId,
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
            const SizedBox(height: 20),
            Text('Grade level (optional)',
                style: tt.titleMedium?.copyWith(
                    color: cs.onSurface, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in GradeLevel.all)
                  ChoiceChip(
                    label: Text(g.label),
                    selected: _grade == g.value,
                    onSelected: (sel) =>
                        setState(() => _grade = sel ? g.value : null),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Share a quiz (optional)',
                style: tt.titleMedium?.copyWith(
                    color: cs.onSurface, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_sharedQuizId == null)
              OutlinedButton.icon(
                onPressed: _pickQuiz,
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Attach one of my quizzes'),
              )
            else
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.quiz, color: cs.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_sharedQuizTitle ?? 'Quiz',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              tt.bodyMedium?.copyWith(color: cs.onSurface)),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                      onPressed: () => setState(() {
                        _sharedQuizId = null;
                        _sharedQuizTitle = null;
                      }),
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

/// Bottom sheet listing the teacher's quizzes to attach to a post.
class _QuizPickerSheet extends ConsumerWidget {
  const _QuizPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final quizzesAsync = ref.watch(_myQuizzesProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: quizzesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              Padding(padding: const EdgeInsets.all(24), child: Text('Error: $e')),
          data: (quizzes) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text('Share which quiz?', style: tt.titleLarge),
              ),
              if (quizzes.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Text('You haven’t created any quizzes yet.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: quizzes.length,
                    itemBuilder: (ctx, i) {
                      final q = quizzes[i];
                      return ListTile(
                        leading: const Icon(Icons.quiz_outlined),
                        title: Text(q.title),
                        subtitle: Text('${q.className} · ${q.questionCount} '
                            'question${q.questionCount == 1 ? '' : 's'}'),
                        onTap: () => Navigator.pop(ctx, q),
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

/// The signed-in teacher's quizzes for the share picker.
final _myQuizzesProvider = FutureProvider.autoDispose<List<MyQuiz>>(
  (ref) => ref.watch(quizzesRepositoryProvider).getMine(),
);
