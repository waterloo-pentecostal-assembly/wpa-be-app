import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/common/exceptions.dart';

class FirebaseStorageService {
  final FirebaseStorage _firebaseStorage;

  FirebaseStorageService(this._firebaseStorage);

  Future<String> getDownloadUrl(String gsUrl) async {
    try {
      String downloadUrl = await _firebaseStorage.refFromURL(gsUrl).getDownloadURL();
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
}
