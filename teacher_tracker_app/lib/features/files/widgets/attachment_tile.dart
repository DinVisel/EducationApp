import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../data/files_repository.dart';
import '../state/file_url_providers.dart';

/// A downloadable attachment. Images render inline (via a presigned GET URL);
/// tapping opens the file in the browser, and a Download action saves it to the
/// device (Gallery for media, the OS save sheet for documents). Shared across the
/// feed, class assignments, and student assignments so the UX stays consistent.
class AttachmentTile extends ConsumerStatefulWidget {
  const AttachmentTile({
    super.key,
    required this.fileId,
    required this.fileName,
    required this.contentType,
  });

  final int fileId;
  final String fileName;
  final String contentType;

  @override
  ConsumerState<AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends ConsumerState<AttachmentTile> {
  bool _downloading = false;

  int get fileId => widget.fileId;
  String get fileName => widget.fileName;
  String get contentType => widget.contentType;

  bool get _isImage => contentType.startsWith('image/');
  bool get _isVideo => contentType.startsWith('video/');

  IconData get _icon {
    if (_isImage) return Icons.image_outlined;
    if (_isVideo) return Icons.videocam_outlined;
    return Icons.insert_drive_file_outlined;
  }

  /// Opens the file in the browser; falls back to copying the link if the
  /// platform can't launch it.
  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    try {
      final url = await ref.read(filesRepositoryProvider).getDownloadUrl(fileId);
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: url));
        messenger.showSnackBar(
            SnackBar(content: Text(loc.attachLinkCopied(fileName))));
      }
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.attachCouldNotOpen('$e'))));
    }
  }

  /// Saves the file to the device (Gallery for media, OS save sheet for docs).
  Future<void> _download(BuildContext context) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    try {
      final message = await ref.read(filesRepositoryProvider).downloadToDevice(
            fileId: fileId,
            fileName: fileName,
            isImage: _isImage,
            isVideo: _isVideo,
          );
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on GalException catch (e) {
      // Gallery permission denied / not granted — point the user at settings.
      messenger.showSnackBar(SnackBar(
          content: Text(loc.attachStoragePermission(e.type.message))));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.attachCouldNotDownload('$e'))));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _open(context),
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
                _downloading
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.download_outlined,
                            size: 20, color: cs.primary),
                        tooltip: AppLocalizations.of(context)!.attachSaveToDevice,
                        onPressed: () => _download(context),
                      ),
                Icon(Icons.open_in_new, size: 18, color: cs.onSurfaceVariant),
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
