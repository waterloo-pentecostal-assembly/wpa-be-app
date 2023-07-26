import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../domain/common/exceptions.dart';

class FirebaseStorageService {
  final FirebaseStorage _firebaseStorage;

  FirebaseStorageService(this._firebaseStorage);

  String get storageBucket => _firebaseStorage.bucket;

  Future<String?> getDownloadUrl(String? gsUrl) async {
    if (gsUrl == null) {
      return null;
    }

    try {
      String downloadUrl =
          await _firebaseStorage.refFromURL(gsUrl).getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      // See error codes here: https://firebase.google.com/docs/storage/flutter/handle-errors
      if (e.code.contains('object-not-found')) {
        throw FirebaseStorageException(
          code: FirebaseStorageExceptionCode.OBJECT_NOT_FOUND,
          message: e.message ?? 'No specific error message',
          details: e,
        );
      } else if (e.code.contains('unauthorized')) {
        throw FirebaseStorageException(
          code: FirebaseStorageExceptionCode.UNAUTHORIZED,
          message: e.message ?? 'No specific error message',
          details: e,
        );
      } else {
        throw FirebaseStorageException(
          code: FirebaseStorageExceptionCode.UNKNOWN,
          message: e.message ?? 'No specific error message',
          details: e,
        );
      }
    }
  }

  UploadTask startFileUpload(String filePath, File file) {
    try {
      return _firebaseStorage.ref().child(filePath).putFile(file);
    } catch (e) {
      throw FirebaseStorageException(
        code: FirebaseStorageExceptionCode.UNABLE_TO_START_UPLOAD,
        message: "Unable to start upload",
        details: e,
      );
    }
  }

  Future<void> deleteFile(String gsUrl) {
    try {
      return _firebaseStorage.refFromURL(gsUrl).delete();
    } catch (e) {
      throw FirebaseStorageException(
        code: FirebaseStorageExceptionCode.UNABLE_TO_DELETE_FILE,
        message: "Unable to delete file",
        details: e,
      );
    }
  }
}
