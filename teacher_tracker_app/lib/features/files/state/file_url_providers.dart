import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/files_repository.dart';

/// A short-lived presigned download URL for a file, keyed by file id. Cached so
/// inline previews don't re-fetch a URL on every rebuild.
///
/// Auto-disposed: the presigned URL is short-lived, so we'd rather re-mint a
/// fresh one when a widget needs it again than hold an expiring URL alive for
/// the app's lifetime. The image *bytes* are cached separately by
/// `cached_network_image` (keyed on file id), so re-minting the URL doesn't
/// re-download the image.
final fileUrlProvider =
    FutureProvider.autoDispose.family<String, int>((ref, fileId) {
  return ref.watch(filesRepositoryProvider).getDownloadUrl(fileId);
});
