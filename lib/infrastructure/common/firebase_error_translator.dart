import 'package:firebase_core/firebase_core.dart';

import '../../domain/common/exceptions.dart';

/// [ErrorTranslator] for Firebase errors, installed by the composition root.
/// Repositories let Firebase errors propagate; this gives them their
/// user-facing message where they are shown.
BaseApplicationException? translateFirebaseError(Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') {
    return DatabaseException(
      code: DatabaseExceptionCode.permissionDenied,
      message: 'You do not have permission to execute this operation',
      details: error,
    );
  }
  return null;
}
