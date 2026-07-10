import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/files_repository.dart';

/// A short-lived presigned download URL for a file, keyed by file id. Cached so
/// inline previews don't re-fetch a URL on every rebuild.
final fileUrlProvider = FutureProvider.family<String, int>((ref, fileId) {
  return ref.watch(filesRepositoryProvider).getDownloadUrl(fileId);
});
