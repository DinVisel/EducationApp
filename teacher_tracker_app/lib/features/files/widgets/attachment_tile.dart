import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/files_repository.dart';
import '../state/file_url_providers.dart';

/// A downloadable attachment. Images render inline (via a presigned GET URL);
/// any file opens in the browser on tap. Shared across the feed, class
/// assignments, and student assignments so the download UX stays consistent.
class AttachmentTile extends ConsumerWidget {
  const AttachmentTile({
    super.key,
    required this.fileId,
    required this.fileName,
    required this.contentType,
  });

  final int fileId;
  final String fileName;
  final String contentType;

  bool get _isImage => contentType.startsWith('image/');
  bool get _isVideo => contentType.startsWith('video/');

  IconData get _icon {
    if (_isImage) return Icons.image_outlined;
    if (_isVideo) return Icons.videocam_outlined;
    return Icons.insert_drive_file_outlined;
  }

  /// Opens the file in the browser; falls back to copying the link if the
  /// platform can't launch it.
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await ref.read(filesRepositoryProvider).getDownloadUrl(fileId);
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: url));
        messenger.showSnackBar(SnackBar(
            content: Text('Download link for "$fileName" copied')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open file: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _open(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isImage) _ImagePreview(fileId: fileId),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(_icon, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                ),
                Icon(Icons.open_in_new,
                    size: 18, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline image thumbnail rendered from a presigned URL, with graceful loading
/// and error states.
class _ImagePreview extends ConsumerWidget {
  const _ImagePreview({required this.fileId});
  final int fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final urlAsync = ref.watch(fileUrlProvider(fileId));

    Widget frame(Widget child) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 220),
            width: double.infinity,
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            child: child,
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: urlAsync.when(
        loading: () => frame(const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        )),
        error: (_, _) => frame(SizedBox(
          height: 100,
          child: Center(
            child: Icon(Icons.broken_image_outlined,
                color: cs.onSurfaceVariant),
          ),
        )),
        data: (url) => frame(
          Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (ctx, child, progress) => progress == null
                ? child
                : const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
            errorBuilder: (ctx, _, _) => SizedBox(
              height: 100,
              child: Center(
                child: Icon(Icons.broken_image_outlined,
                    color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
