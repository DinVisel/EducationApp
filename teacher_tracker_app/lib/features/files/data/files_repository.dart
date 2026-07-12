import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_client.dart';
import '../../../models/file_object.dart';

/// Uploads/downloads files through the API, which brokers Cloudflare R2.
/// The reusable storage layer the social hub and assignments build on.
class FilesRepository {
  FilesRepository(this._dio);

  final Dio _dio;

  /// Proxy-uploads [bytes] to R2 via `POST /api/files` and returns its metadata.
  /// Kept as a fallback for small files; prefer [uploadDirect].
  Future<FileObject> upload({
    required List<int> bytes,
    required String fileName,
    String? contentType,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/files',
      data: form,
    );
    return FileObject.fromJson(res.data!);
  }

  /// Uploads [bytes] straight to R2 with a presigned PUT (bypassing the proxy),
  /// then confirms so the API records the metadata. Preferred for large media.
  Future<FileObject> uploadDirect({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    // 1. Ask the API for a presigned PUT URL + the key it issued us.
    final presign = await _dio.post<Map<String, dynamic>>(
      '/api/files/presign',
      data: {'fileName': fileName, 'contentType': contentType},
    );
    final uploadUrl = presign.data!['uploadUrl'] as String;
    final key = presign.data!['key'] as String;

    // 2. PUT the bytes directly to R2. Use a bare client so the app's bearer
    //    token/base URL are never sent to the signed URL. Stream the body in one
    //    chunk with an explicit length so the SDK-signed PUT matches.
    await Dio().put<void>(
      uploadUrl,
      data: Stream.value(bytes),
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );

    // 3. Confirm — the API HEADs the object and stores its metadata.
    final confirm = await _dio.post<Map<String, dynamic>>(
      '/api/files/confirm',
      data: {'key': key, 'fileName': fileName, 'contentType': contentType},
    );
    return FileObject.fromJson(confirm.data!);
  }

  /// A short-lived direct-download URL for the file (presigned by the API).
  Future<String> getDownloadUrl(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/files/$id');
    return res.data!['url'] as String;
  }

  /// Downloads a file to device storage. Images/videos are saved into the
  /// Gallery (via `gal`, which requests the add-to-gallery permission itself);
  /// other files (PDFs/docs) are downloaded then handed to the OS save/share
  /// sheet so the user can keep them in Files/Downloads. Returns a short
  /// user-facing status message. Throws [GalException] if gallery access is
  /// denied so the caller can prompt for settings.
  Future<String> downloadToDevice({
    required int fileId,
    required String fileName,
    required bool isImage,
    required bool isVideo,
  }) async {
    final url = await getDownloadUrl(fileId);

    // Stream to a temp file first. Use a bare Dio so the app's bearer token /
    // base URL are never sent to the presigned R2 URL.
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    await Dio().download(url, path);

    if (isImage) {
      await Gal.putImage(path, album: 'TeacherTracker');
      return 'Saved "$fileName" to your gallery';
    }
    if (isVideo) {
      await Gal.putVideo(path, album: 'TeacherTracker');
      return 'Saved "$fileName" to your gallery';
    }
    // Documents: let the OS save sheet place it in Files/Downloads.
    await Share.shareXFiles([XFile(path)], subject: fileName);
    return 'Ready to save "$fileName"';
  }

  Future<void> delete(int id) => _dio.delete<void>('/api/files/$id');
}

final filesRepositoryProvider = Provider<FilesRepository>(
  (ref) => FilesRepository(ref.watch(dioProvider)),
);
