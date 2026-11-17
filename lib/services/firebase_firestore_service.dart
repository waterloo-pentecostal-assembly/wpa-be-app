import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/common/exceptions.dart';

/// Maps Firestore errors to domain exceptions with user-safe messages.
class FirebaseFirestoreService {
  const FirebaseFirestoreService();

  BaseApplicationException handleException(Object e) {
    if (e is BaseApplicationException) return e;
    if (e is FirebaseException && e.code == 'permission-denied') {
      return DatabaseException(
        code: DatabaseExceptionCode.permissionDenied,
        message: 'You do not have permission to execute this operation',
        details: e,
      );
    }
    return ApplicationException.unknown(e);
  }
}
