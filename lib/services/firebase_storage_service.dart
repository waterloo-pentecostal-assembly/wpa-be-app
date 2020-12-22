import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../domain/common/exceptions.dart';

class FirebaseStorageService {
  final FirebaseStorage _firebaseStorage;

  FirebaseStorageService(this._firebaseStorage);

  Future<String> getDownloadUrl(String gsUrl) async {
    if (gsUrl == null) {
      return null;
    }

    try {
      String downloadUrl =
          await _firebaseStorage.refFromURL(gsUrl).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (e.code == 'object-not-found') {
        throw FirebaseStorageException(
          code: FirebaseStorageExceptionCode.OBJECT_NOT_FOUND,
          message: e.message,
          details: e,
        );
      } else if (e.code == 'unauthorized') {
        throw FirebaseStorageException(
          code: FirebaseStorageExceptionCode.UNAUTHORIZED,
          message: e.message,
          details: e,
        );
      } else {
        throw FirebaseStorageException(
          code: FirebaseStorageExceptionCode.UNKNOWN,
          message: e.message,
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
