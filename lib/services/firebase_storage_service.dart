import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';

import '../domain/common/exceptions.dart';
import '../domain/common/media_upload.dart';

/// Thin wrapper over Firebase Storage with an in-memory download URL cache.
class FirebaseStorageService {
  FirebaseStorageService(this._firebaseStorage);

  final FirebaseStorage _firebaseStorage;

  /// Pending or resolved URL per `gs://` location. Concurrent lookups of the
  /// same location (e.g. one author's avatar on many posts) share a single
  /// request; failed lookups are evicted so they can be retried.
  final Map<String, Future<String>> _downloadUrls = {};

  String get storageBucket => _firebaseStorage.bucket;

  /// Resolves a `gs://` location to a download URL (cached per location).
  Future<String> getDownloadUrl(String gsUrl) {
    final cached = _downloadUrls[gsUrl];
    if (cached != null) return cached;
    final request = _fetchDownloadUrl(gsUrl);
    _downloadUrls[gsUrl] = request;
    // Evict failures (callers still receive the error from [request]).
    unawaited(request.then<void>((_) {}, onError: (Object _) {
      if (identical(_downloadUrls[gsUrl], request)) _downloadUrls.remove(gsUrl);
    }));
    return request;
  }

  Future<String> _fetchDownloadUrl(String gsUrl) async {
    try {
      return await _firebaseStorage.refFromURL(gsUrl).getDownloadURL();
    } on FirebaseException catch (e) {
      // See https://firebase.google.com/docs/storage/flutter/handle-errors
      final code = e.code.contains('object-not-found')
          ? StorageExceptionCode.objectNotFound
          : e.code.contains('unauthorized')
              ? StorageExceptionCode.unauthorized
              : StorageExceptionCode.unknown;
      throw StorageException(
        code: code,
        message: e.message ?? 'No specific error message',
        details: e,
      );
    }
  }

  Future<String?> getNullableDownloadUrl(String? gsUrl) async {
    if (gsUrl == null) return null;
    return getDownloadUrl(gsUrl);
  }

  /// Best-effort lookup for decorative images (avatars, thumbnails): `null`
  /// when there is no location or it cannot be resolved (e.g. the file was
  /// deleted), so one missing image never fails a whole list.
  Future<String?> tryGetDownloadUrl(String? gsUrl) async {
    if (gsUrl == null || gsUrl.isEmpty) return null;
    try {
      return await getDownloadUrl(gsUrl);
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      return null;
    }
  }

  /// Starts uploading [image] to [filePath] (relative to the bucket root).
  UploadHandle startUpload(String filePath, ImageData image) {
    try {
      final task = _firebaseStorage.ref().child(filePath).putData(
            image.bytes,
            SettableMetadata(contentType: image.contentType),
          );
      return FirebaseUploadHandle(task);
    } catch (e) {
      throw StorageException(
        code: StorageExceptionCode.unableToStartUpload,
        message: 'Unable to start upload',
        details: e,
      );
    }
  }

  Future<void> deleteFile(String gsUrl) async {
    unawaited(_downloadUrls.remove(gsUrl));
    try {
      await _firebaseStorage.refFromURL(gsUrl).delete();
    } catch (e) {
      throw StorageException(
        code: StorageExceptionCode.unableToDeleteFile,
        message: 'Unable to delete file',
        details: e,
      );
    }
  }
}

/// [UploadHandle] backed by a Firebase [UploadTask].
class FirebaseUploadHandle implements UploadHandle {
  FirebaseUploadHandle(this._task);

  final UploadTask _task;

  @override
  Stream<UploadProgress> get progress => _task.snapshotEvents.map(
        (s) => UploadProgress(
          bytesTransferred: s.bytesTransferred,
          totalBytes: s.totalBytes,
        ),
      );

  @override
  Future<String> get location async {
    final snapshot = await _task;
    return 'gs://${snapshot.ref.bucket}/${snapshot.ref.fullPath}';
  }
}
