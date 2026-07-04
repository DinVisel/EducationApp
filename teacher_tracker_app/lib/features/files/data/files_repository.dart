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
