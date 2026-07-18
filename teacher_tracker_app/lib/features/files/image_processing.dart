import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';

import 'mime.dart';

/// The output of a crop/compress pass: final bytes plus the filename and
/// content type to upload them under. The extension is forced to match the
/// compressed format, because [mimeForFileName] derives the content type purely
/// from the extension (and that flows into both the presign call and the R2 PUT
/// header).
class ProcessedImage {
  const ProcessedImage({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

/// Whether a picked file is a raster image we can crop/compress. SVGs and
/// non-images are excluded.
bool isCompressibleImage(String fileName) {
  final mime = mimeForFileName(fileName);
  return mime.startsWith('image/') && mime != 'image/svg+xml';
}

String _baseName(String fileName) {
  final slash = fileName.lastIndexOf(RegExp(r'[\\/]'));
  final name = slash >= 0 ? fileName.substring(slash + 1) : fileName;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}

/// Present a crop UI at [ratioX]:[ratioY], then compress the result to JPEG.
/// Returns null if the user cancels the crop (or compression fails), so callers
/// can fall back to the raw upload.
Future<ProcessedImage?> cropAndCompress({
  required String path,
  required String originalName,
  required double ratioX,
  required double ratioY,
  required String toolbarTitle,
}) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: path,
    aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
    compressFormat: ImageCompressFormat.jpg,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: toolbarTitle,
        lockAspectRatio: true,
        hideBottomControls: false,
      ),
      IOSUiSettings(title: toolbarTitle, aspectRatioLockEnabled: true),
    ],
  );
  if (cropped == null) return null;

  final bytes = await FlutterImageCompress.compressWithFile(
    cropped.path,
    quality: 82,
    format: CompressFormat.jpeg,
    autoCorrectionAngle: true,
  );
  if (bytes == null) return null;

  return ProcessedImage(
    bytes: bytes,
    fileName: '${_baseName(originalName)}.jpg',
    contentType: 'image/jpeg',
  );
}

/// Compress an image in place (no crop), preserving PNG/WebP where it matters
/// and transcoding everything else (incl. HEIC) to JPEG. Returns null on
/// failure so callers can fall back to the raw bytes.
Future<ProcessedImage?> compressImage({
  required String path,
  required String originalName,
}) async {
  final mime = mimeForFileName(originalName);
  final CompressFormat format;
  final String ext;
  switch (mime) {
    case 'image/png':
      format = CompressFormat.png;
      ext = 'png';
    case 'image/webp':
      format = CompressFormat.webp;
      ext = 'webp';
    default:
      format = CompressFormat.jpeg;
      ext = 'jpg';
  }

  final bytes = await FlutterImageCompress.compressWithFile(
    path,
    quality: 82,
    format: format,
    autoCorrectionAngle: true,
  );
  if (bytes == null) return null;

  final fileName = '${_baseName(originalName)}.$ext';
  return ProcessedImage(
    bytes: bytes,
    fileName: fileName,
    contentType: mimeForFileName(fileName),
  );
}
