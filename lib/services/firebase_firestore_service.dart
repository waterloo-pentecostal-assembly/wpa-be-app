import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/common/exceptions.dart';

class FirebaseFirestoreService {
  Exception handleException(Exception e) {
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return FirebaseFirestoreException(
          code: FirebaseFirestoreExceptionCode.PERMISSION_DENIED,
          message: 'You do not have permission to execute this operation',
          details: e,
        );
      }
    }
    return ApplicationException(
      code: ApplicationExceptionCode.UNKNOWN,
      message: 'An unknown error occurred',
      details: e,
    );
  }
}
