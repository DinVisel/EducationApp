/// Mirrors `FileObjectDto` from the backend — metadata for a file stored in R2.
/// The bytes are fetched via a short-lived download URL, not from this object.
class FileObject {
  const FileObject({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.createdAt,
  });

  final int id;
  final String fileName;
  final String contentType;
  final int size;
  final DateTime createdAt;

  bool get isImage => contentType.startsWith('image/');
  bool get isVideo => contentType.startsWith('video/');

  factory FileObject.fromJson(Map<String, dynamic> json) => FileObject(
        id: json['id'] as int,
        fileName: json['fileName'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
