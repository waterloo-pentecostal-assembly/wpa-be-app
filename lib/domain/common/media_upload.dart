import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Platform-neutral image picked by the user (bytes + original file name).
class ImageData extends Equatable {
  const ImageData({required this.bytes, required this.fileName, this.mimeType});

  final Uint8List bytes;
  final String fileName;
  final String? mimeType;

  /// File extension including the leading dot (e.g. `.jpg`), or `''`.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot);
  }

  /// Content type used for uploads. Storage triggers (thumbnail generation)
  /// rely on an `image/*` content type.
  String get contentType {
    if (mimeType != null && mimeType!.startsWith('image/')) return mimeType!;
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  @override
  List<Object?> get props => [fileName, mimeType, bytes.length];
}

class UploadProgress extends Equatable {
  const UploadProgress({required this.bytesTransferred, this.totalBytes});

  final int bytesTransferred;
  final int? totalBytes;

  /// Percentage rounded up, 0 when the total is unknown.
  int get percent {
    final total = totalBytes;
    if (total == null || total == 0) return 0;
    return ((bytesTransferred / total) * 100).ceil();
  }

  @override
  List<Object?> get props => [bytesTransferred, totalBytes];
}

/// A running upload. [location] completes with the `gs://` location of the
/// uploaded object.
abstract class UploadHandle {
  Stream<UploadProgress> get progress;
  Future<String> get location;
}
