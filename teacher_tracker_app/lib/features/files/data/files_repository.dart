import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> delete(int id) => _dio.delete<void>('/api/files/$id');
}

final filesRepositoryProvider = Provider<FilesRepository>(
  (ref) => FilesRepository(ref.watch(dioProvider)),
);
